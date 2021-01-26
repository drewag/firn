import NIO
import NIOHTTP1
import NIOWebSocket
import NIOSSL

public final class API {

    public struct ListeningAPI {
        public let port: Int
    }

    public enum Host {
        case ipv4(String)
        case ipv6(String)
        case any
    }

    public enum Port {
        case specific(UInt16)
        case automatic
    }

    let host: Host
    let port: Port
    let ssl: SSL
    let allowCrossOriginRequests: Bool

    var router = Router()
    var authenticator = Authenticator()
    var approvedUpgrades = [String:SocketConnectionHandler]()

    public init(host: Host = .any, port: Port = .automatic, ssl: SSL = .none, allowCrossOriginRequests: Bool = false) {
        self.host = host
        self.port = port
        self.allowCrossOriginRequests = allowCrossOriginRequests
        self.ssl = ssl
    }

    public func configureAuthentication<User: AnyUser>(for userType: User.Type, authenticate: @escaping (Request) -> User?) {
        self.authenticator.append(UserAuthenticator(authenticate: authenticate))
    }

    public func addRoutes(@RouteBuilder _ build: () -> ProcessorCollection) throws {
        try self.router.append(build())
    }

    public func run(onListening: ((ListeningAPI) -> ())? = nil) {
        do {
            let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
            let threadPool = NIOThreadPool(numberOfThreads: System.coreCount)
            threadPool.start()

            var upgraders = [NIOWebSocketServerUpgrader]()
            if self.router.hasSocketRoutes {
                upgraders.append(NIOWebSocketServerUpgrader(
                    shouldUpgrade: { channel, head  in
                        do {
                            guard let key = head.headers["Sec-WebSocket-Key"].first else {
                                return channel.eventLoop.makeSucceededFuture(nil)
                            }

                            var request = Request(head: head, authenticator: self.authenticator)
                            guard let (route, params) = self.router.processor(for: request.uri, by: request.head.method)
                                , let processor = route as? WebSocketProcessor
                                else
                            {
                                return channel.eventLoop.makeSucceededFuture(nil)
                            }
                            request.pathParams = params
                            try request.verify(for: processor)

                            guard let handler = try processor.getHandler(request) else {
                                return channel.eventLoop.makeSucceededFuture(nil)
                            }

                            self.approvedUpgrades[key] = handler

                            return channel.eventLoop.makeSucceededFuture(HTTPHeaders())
                        }
                        catch {
                            print("Failed to upgrade to web socket: \(error)")
                            return channel.eventLoop.makeSucceededFuture(nil)
                        }
                    },
                    upgradePipelineHandler: { channel, head in
                        guard let key = head.headers["Sec-WebSocket-Key"].first
                            , let handler = self.approvedUpgrades[key]
                            else
                        {
                            return channel.pipeline.addHandler(EmptyWebSocketHandler())
                        }

                        self.approvedUpgrades[key] = nil

                        return channel.pipeline.addHandler(WebSocketHandler(handler: handler))
                    }
                ))
            }

            let fileIO = NonBlockingFileIO(threadPool: threadPool)
            let bootstrap = ServerBootstrap(group: group)
                // Specify backlog and enable SO_REUSEADDR for the server itself
                .serverChannelOption(ChannelOptions.backlog, value: 256)
                .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

                // Set the handlers that are applied to the accepted Channels
                .childChannelInitializer(configureHTTPSSLBlock(fileIO: fileIO, upgraders: upgraders))

                // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
                .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
                .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
                .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
                .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: true)

            defer {
                try! group.syncShutdownGracefully()
                try! threadPool.syncShutdownGracefully()
            }

            let channel = try { () -> Channel in
                let address: SocketAddress
                var sAddr = sockaddr_in()
                switch port {
                case .automatic:
                    sAddr.sin_port = 0
                case .specific(let port):
                    sAddr.sin_port = port.bigEndian
                }
                switch host {
                case .any:
                    sAddr.sin_family = sa_family_t(AF_INET)
                    sAddr.sin_addr.s_addr = INADDR_ANY.bigEndian
                    address = SocketAddress(sAddr, host: "")
                case .ipv4(let ip):
                    sAddr.sin_family = sa_family_t(AF_INET)
                    inet_pton(AF_INET, ip, &sAddr.sin_addr)
                    address = SocketAddress(sAddr, host: "")
                case .ipv6(let ip):
                    sAddr.sin_family = sa_family_t(AF_INET)
                    inet_pton(AF_INET6, ip, &sAddr.sin_addr)
                    address = SocketAddress(sAddr, host: "")
                }
                return try bootstrap.bind(to: address).wait()
            }()

            guard let localAddress = channel.localAddress else {
                fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
            }
            print("Server started and listening on \(localAddress)")
            onListening?(ListeningAPI(
                port: localAddress.port ?? 0
            ))
            try channel.closeFuture.wait()

            print("Server closed")
        }
        catch {
            print("Error starting server: \(error)")
        }
    }

    private func configureHTTPSSLBlock(fileIO: NonBlockingFileIO, upgraders: [NIOWebSocketServerUpgrader]) -> (Channel) -> EventLoopFuture<Void> {
        guard let sslContext = self.sslContext else {
            return configureHTTPBlock(fileIO: fileIO, upgraders: upgraders)
        }

        return { channel in
            channel.pipeline.addHandler(NIOSSLServerHandler(context: sslContext))
                .flatMap {
                    self.configureHTTPBlock(fileIO: fileIO, upgraders: upgraders)(channel)
                }
        }
    }

    private func configureHTTPBlock(fileIO: NonBlockingFileIO, upgraders: [NIOWebSocketServerUpgrader]) -> (Channel) -> EventLoopFuture<Void> {
        return { channel in
            let httpHandler = HTTPHandler(
                fileIO: fileIO,
                allowCrossOriginRequests: self.allowCrossOriginRequests,
                router: self.router,
                authenticator: self.authenticator
            )

            let config: NIOHTTPServerUpgradeConfiguration = (
                upgraders: upgraders,
                completionHandler: { ctx in
                    channel.pipeline.removeHandler(httpHandler, promise: nil)
                }
            )

            return channel.pipeline.configureHTTPServerPipeline(withServerUpgrade: config, withErrorHandling: true).flatMap {
                channel.pipeline.addHandler(httpHandler)
            }.flatMapError { error in
                print("error: \(error)")
                return channel.eventLoop.makeFailedFuture(error)
            }
        }
    }

    lazy var sslContext: NIOSSLContext? = {
        switch self.ssl {
        case let .fileSystem(keyPath, certPaths):
            do {
                let privateKey = NIOSSLPrivateKeySource.privateKey(
                    try NIOSSLPrivateKey(file: keyPath, format: .pem)
                )
                let certificates = try certPaths.map { path in
                    NIOSSLCertificateSource.certificate(
                        try NIOSSLCertificate(file: path, format: .pem)
                    )
                }

                let configuration = TLSConfiguration.forServer(certificateChain: certificates, privateKey: privateKey)
                return try NIOSSLContext(configuration: configuration)
            }
            catch {
                print("Failed to configure SSL context: \(error)")
                return nil
            }
        case .none:
            return nil
        }
    }()
}

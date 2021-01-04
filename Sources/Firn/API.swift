import NIO
import NIOHTTP1
import NIOWebSocket

public final class API {
    var host: String
    var port: Int
    let allowCrossOriginRequests: Bool

    var router = Router()
    var authenticator = Authenticator()
    var approvedUpgrades = [String:SocketConnectionHandler]()

    public init(host: String = "::1", port: Int = 8080, allowCrossOriginRequests: Bool = false) {
        self.host = host
        self.port = port
        self.allowCrossOriginRequests = allowCrossOriginRequests
    }

    public func configureAuthentication<User: AnyUser>(for userType: User.Type, authenticate: @escaping (Request) -> User?) {
        self.authenticator.append(UserAuthenticator(authenticate: authenticate))
    }

    public func addRoutes(@RouteBuilder _ build: () -> ProcessorCollection) throws {
        try self.router.append(build())
    }

    public func run() {
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
                .childChannelInitializer { channel in
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
                return try bootstrap.bind(host: host, port: port).wait()
            }()

            guard let localAddress = channel.localAddress else {
                fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
            }
            print("Server started and listening on \(localAddress)")
            try channel.closeFuture.wait()

            print("Server closed")
        }
        catch {
            print("Error starting server: \(error)")
        }
    }
}

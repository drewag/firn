import NIO
import PostgreSQL

public final class API {
    var host: String
    var port: Int
    let htdocs: String

    var router = Router()
    var authenticator = Authenticator()
    var database: PostgreSQLDatabase?

    public init(host: String = "::1", port: Int = 8080, htdocs: String = "/dev/null") {
        self.host = host
        self.port = port
        self.htdocs = htdocs
    }

    public func configureAuthentication<User: AnyUser>(for userType: User.Type, authenticate: @escaping (Request) -> User?) {
        self.authenticator.append(UserAuthenticator(authenticate: authenticate))
    }

    public func addRoutes(@RouteBuilder _ build: () -> ProcessorCollection) throws {
        try self.router.append(build())
    }

    public func configureDatabase(
        hostname: String = "localhost",
        port: Int = 5432,
        name: String,
        username: String,
        password: String? = nil
        )
    {
        let config = PostgreSQLDatabaseConfig(
            hostname: hostname,
            port: port,
            username: username,
            database: name,
            password: password
        )
        self.database = PostgreSQLDatabase(config: config)
    }

    public func run() {
        do {
            let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
            let threadPool = BlockingIOThreadPool(numberOfThreads: 6)
            threadPool.start()

//            let connection = try database.newConnection(on: group).wait()
//            let result = try connection.query("SELECT * FROM tasks").wait()
//            print(result[0])
//            if let value = result[0].firstValue(name: "name") {
//                print(value)
//                print(value.text)
//                print(value.binary)
//            }


            let fileIO = NonBlockingFileIO(threadPool: threadPool)
            let bootstrap = ServerBootstrap(group: group)
                // Specify backlog and enable SO_REUSEADDR for the server itself
                .serverChannelOption(ChannelOptions.backlog, value: 256)
                .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

                // Set the handlers that are applied to the accepted Channels
                .childChannelInitializer { channel in
                    channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).then {_ in
                        channel.pipeline.add(handler: HTTPHandler(
                            fileIO: fileIO,
                            htdocsPath: self.htdocs,
                            router: self.router,
                            authenticator: self.authenticator,
                            createConnection: { () -> PostgreSQLConnection in
                                guard let database = self.database else {
                                    throw ServeError.databaseNotConfigured
                                }

                                return try database.newConnection(on: group).wait()
                            }
                        ))
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
            print("Server started and listening on \(localAddress), htdocs path \(htdocs)")
            try channel.closeFuture.wait()

            print("Server closed")
        }
        catch {
            print("Error starting server: \(error)")
        }
    }
}

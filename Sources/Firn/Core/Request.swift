import NIOHTTP1
import PostgreSQL

public struct Request {
    let head: HTTPRequestHead
    let authenticator: Authenticator
    public internal(set) var pathParams = PathParams()

    var authenticatedUser: AnyUser?
    let createConnection: () throws -> PostgreSQLConnection
    var connection: PostgreSQLConnection?

    init(head: HTTPRequestHead, authenticator: Authenticator, createConnection: @escaping () throws -> PostgreSQLConnection) {
        self.head = head
        self.authenticator = authenticator
        self.createConnection = createConnection
    }

    public var uri: String {
        return self.head.uri
    }

    public var headers: Headers {
        return Headers(headers: self.head.headers)
    }

    @discardableResult
    public mutating func authorizedUser<User: AnyUser>(_ type: User.Type) throws -> User {
        guard let user = self.authenticatedUser as? User else {
            throw ServeError.endpointNotConfiguredForAuth
        }
        return user
    }

    @discardableResult
    mutating func authenticate<User: AnyUser>(_ type: User.Type, validate: ((User) throws -> Bool)? = nil) throws -> User {
        let user = try (self.authenticatedUser as? User) ?? self.authenticator.authenticate(self)
        self.authenticatedUser = user
        guard try validate?(user) ?? true else {
            throw ServeError.unauthorized
        }
        return user
    }

    func connectToDB() throws -> PostgreSQLConnection {
        return try self.connection ?? self.createConnection()
    }
}

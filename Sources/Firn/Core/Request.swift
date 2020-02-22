import NIOHTTP1

public struct Request {
    let head: HTTPRequestHead
    let authenticator: Authenticator
    public internal(set) var pathParams = PathParams()

    init(head: HTTPRequestHead, authenticator: Authenticator) {
        self.head = head
        self.authenticator = authenticator
    }

    var authenticatedUser: AnyUser?

    public var uri: String {
        return self.head.uri
    }

    public var headers: Headers {
        return Headers(headers: self.head.headers)
    }

    @discardableResult
    public mutating func authenticate<User: AnyUser>(_ type: User.Type, validate: ((User) throws -> Bool)? = nil) throws -> User {
        let user = try (self.authenticatedUser as? User) ?? self.authenticator.authenticate(self)
        self.authenticatedUser = user
        guard try validate?(user) ?? true else {
            throw ServeError.unauthorized
        }
        return user
    }
}

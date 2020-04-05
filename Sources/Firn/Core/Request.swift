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

    public var bearerToken: String? {
        guard let authorization = self.headers["Authorization"].first
            , authorization.lowercased().hasPrefix("bearer ")
            else
        {
            return nil
        }

        let start = authorization.index(authorization.startIndex, offsetBy: 7)
        return String(authorization[start ..< authorization.endIndex])
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

    mutating func verify(for route: AnyRequestProcessor) throws {
        guard route._routingHelper.requiresAuthentication else {
            return
        }

        for block in route._routingHelper.authenticationValidation {
            try block(&self)
        }
    }
}

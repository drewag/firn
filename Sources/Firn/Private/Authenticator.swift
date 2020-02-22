protocol AnyUserAuthenticator {
    var userType: AnyUser.Type {get}
}

struct UserAuthenticator<User: AnyUser>: AnyUserAuthenticator {
    let authenticate: (Request) -> User?

    var userType: AnyUser.Type {
        return User.self
    }
}

struct Authenticator {
    var authenticators = [AnyUserAuthenticator]()

    mutating func append(_ authenticator: AnyUserAuthenticator) {
        self.authenticators.append(authenticator)
    }

    func authenticate<User: AnyUser>(_ request: Request) throws -> User {
        for authenticator in self.authenticators {
            if authenticator.userType == User.self {
                let authenticator = authenticator as! UserAuthenticator<User>
                guard let user = authenticator.authenticate(request) else {
                    throw ServeError.unauthorized
                }
                return user
            }
        }

        throw ServeError.authenticatorNotConfigured(type: "\(User.self)")
    }
}

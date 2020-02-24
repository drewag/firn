import Firn

let api = API()

api.configureAuthentication(for: User.self) { request in
    guard request.headers["Authorization"].contains("Bearer SECURE") else {
        return nil
    }
    return User(name: "Username")
}

try api.addRoutes {
    GET("ok")

    GET("gone")
        .status(.gone)

    GET("hello")
        .toText({ _ in "Hello World!"})

    POST("echo")

    Auth(User.self) {
        GET("restricted")
            .toText({ req in
                let user = try req.authorizedUser(User.self)
                return "Look at you, \(user.name), you're authorized!"
            })
    }

    Auth(User.self) {
        Group("tasks") {
            GET("new")
                .toObject({ _ in Task(name: "") })

            POST()
                .toObject(Task.self)

            GET(Var.int)
                .toObject({ Task(id: try $0.pathParams.int(at: 0), name: "Some task", isComplete: false) })

            PUT(Var.int)
                .toObject(Task.self)
        }
    }
}
api.run()

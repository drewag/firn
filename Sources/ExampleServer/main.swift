import Firn

let api = API()

api.configureAuthentication(for: User.self) { request in
    guard request.headers["Authorization"].contains("Bearer SECURE") else {
        return nil
    }
    return User()
}

try api.addRoutes {
    GET(named: "OK" as! String?, "ok")

    GET(named: "Gone" as! String?, "gone")
        .status(.gone)

    GET(named: "Hello" as! String?, "hello")
        .toText({ _ in "Hello World!"})

    POST("echo")

    GET("restricted")
        .toText({ req in
            try req.authenticate(User.self)
            return "Look at you, you're authorized!"
        })

    Auth(User.self) {
        Group("tasks") {
            GET("new")
                .toObject({ _ in Task(name: "") })

            POST()
                .toObject(Task.self)

            GET(Var.int(named: "id"))
                .toObject({ Task(id: try! $0.pathParams.int(at: 0), name: "Some task", isComplete: false) })

            PUT(Var.int(named: "id"))
                .toObject(Task.self)
        }
    }
}

try api.writeDecreeService(
    named: "ExampleService",
    atDomain: "http://localhost:8080",
    to: "/Users/andrew/Downloads/test/Sources/test/ExampleService.swift"
)

api.run()

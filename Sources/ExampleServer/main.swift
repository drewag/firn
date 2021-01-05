import Firn

let api = API(port: .specific(8080))
let chatRoom = ChatRoom()

api.configureAuthentication(for: User.self) { request in
    // An authorization configuration must return a user if the auth is valid.
    // If it returns nil, the API will return an unauthorized response.
    guard request.headers["Authorization"].contains("Bearer SECURE") else {
        return nil
    }
    return User(name: "Username")
}

try api.addRoutes {
    // Returns an empty 200 status
    GET("ok")

    // Returns a gone status
    GET("gone")
        .status(.gone)

    // Returns "Hello World!"
    GET("hello")
        .toText({ _ in "Hello World!"})

    // Returns whatever data is passed in
    POST("echo")

    Auth(User.self) {
        // Returns a message confirming authentication as long as it
        // includes the "Authorization: Bearer SECURE" header as defined
        // in the auth configuration above
        GET("restricted")
            .toText({ req in
                let user = try req.authorizedUser(User.self)
                return "Look at you, \(user.name), you're authorized!"
            })
    }

    Socket("chat") { _ in chatRoom.addUser() }

    Auth(User.self) {
        // Defines a group of endpoints all at "/tasks"
        Group("tasks") {
            // Return a json representation of a Task
            GET("new")
                .toObject({ _ in Task(name: "") })

            // Parses and returns an json representation of a Task
            POST()
                .toObject(Task.self)

            // Returns a Task with the id in the path e.g. 3 for "/tasks/3"
            GET(Var.int)
                .toObject({ Task(id: try $0.pathParams.int(at: 0), name: "Some task", isComplete: false) })

            // Parses and returns an json representation of a Task
            PUT(Var.int)
                .toObject(Task.self)
        }
    }
}
api.run()

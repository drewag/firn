import Firn

class ChatRoomConnection: SocketConnectionHandler {
    override func handleNewConnection() {
        self.send("Welcome to the chat room!")
    }

    override func handle(text: String) {
        chatRoom.send(text)
    }
}

class ChatRoom {
    var connections = [ChatRoomConnection]()

    func addUser() -> ChatRoomConnection {
        let new = ChatRoomConnection()
        self.connections.append(new)
        return new
    }

    func send(_ text: String) {
        for connection in self.connections {
            connection.send(text)
        }
    }
}

//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 3/25/20.
//

import Foundation

open class SocketConnectionHandler {
    weak var handler: WebSocketHandler?

    public init() {}

    func connect(with handler: WebSocketHandler) {
        self.handler = handler
    }

    open func handleNewConnection() {}
    open func handle(text: String) {}

    public func send(_ data: Data) {
        self.handler?.send(data: data)
    }

    public func send(_ text: String) {
        self.send(text.data(using: .utf8) ?? Data())
    }
}

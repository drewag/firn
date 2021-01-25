//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 3/25/20.
//

import Foundation

open class SocketConnectionHandler {
    let pingInterval: Int?
    let pongTimeout: Int
    weak var handler: WebSocketHandler?

    public init(pingInterval: Int?, pongTimeout: Int = 60) {
        self.pingInterval = pingInterval
        self.pongTimeout = pongTimeout
    }

    func connect(with handler: WebSocketHandler) {
        self.handler = handler
    }

    public func close() {
        self.handler?.close()
    }

    open func handleOpen() {}
    open func handleClose() {}
    open func handle(text: String) -> Bool {
        return false
    }
    open func handle(data: Data) -> Bool {
        return false
    }

    public func send(_ data: Data) {
        self.handler?.send(data: data)
    }

    public func send(_ text: String) {
        self.send(text.data(using: .utf8) ?? Data())
    }

    public func send<Value: Encodable>(_ value: Value) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        self.send(data)
    }
}

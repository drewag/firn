//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 2/20/20.
//

import Foundation
import NIO

public struct DataBuffer {
    enum Mode {
        case buffer(ByteBuffer)
        case data(Data)
    }
    var mode: Mode

    init(_ byteBuffer: ByteBuffer) {
        self.mode = .buffer(byteBuffer)
    }

    init(_ data: Data) {
        self.mode = .data(data)
    }

    func toData() -> Data {
        switch self.mode {
        case .buffer(var byteBuffer):
            guard let bytes = byteBuffer.readBytes(length: byteBuffer.readableBytes) else {
                return Data()
            }
            return Data(bytes)
        case .data(let data):
            return data
        }
    }
}

import Foundation
import NIO
import NIOWebSocket

final class EmptyWebSocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame
}

final class WebSocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame

    private var awaitingClose: Bool = false

    let handler: SocketConnectionHandler
    var context: ChannelHandlerContext?

    init(handler: SocketConnectionHandler) {
        self.handler = handler
        handler.connect(with: self)
    }

    func handlerAdded(ctx: ChannelHandlerContext) {
        self.context = ctx
        self.handler.handleOpen()
    }

    func handlerRemoved(ctx: ChannelHandlerContext) {
        self.handler.handleClose()
        self.context = nil
    }

    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let frame = self.unwrapInboundIn(data)

        switch frame.opcode {
        case .connectionClose:
            self.receivedClose(ctx: ctx, frame: frame)
        case .ping:
            self.pong(ctx: ctx, frame: frame)
        case .text:
            var data = frame.unmaskedData
            let text = data.readString(length: data.readableBytes) ?? ""
            guard !self.handler.handle(text: text) else {
                return
            }
            guard !self.handler.handle(data: text.data(using: .utf8) ?? Data()) else {
                return
            }
        case .binary:
            var bytes = frame.unmaskedData
            let data = Data(bytes.readBytes(length: bytes.readableBytes) ?? [])
            guard !self.handler.handle(data: data) else {
                return
            }
        case .continuation, .pong:
            // We ignore these frames.
            break
        default:
            // Unknown frames are errors.
            self.closeOnError(ctx: ctx)
        }
    }

    func channelReadComplete(ctx: ChannelHandlerContext) {
        ctx.flush()
    }

    func send(data: Data) {
        guard let context = self.context else { return }

        context.eventLoop.execute {
            guard context.channel.isActive else { return }

            // We can't send if we sent a close message.
            guard !self.awaitingClose else { return }

            var buffer = context.channel.allocator.buffer(capacity: data.count)
            buffer.writeBytes(data)

            let frame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
            context.writeAndFlush(self.wrapOutboundOut(frame))
                .whenFailure { (_: Error) in
                    context.close(promise: nil)
                    self.context = nil
                }
        }
    }

    private func receivedClose(ctx: ChannelHandlerContext, frame: WebSocketFrame) {
        // Handle a received close frame. In websockets, we're just going to send the close
        // frame and then close, unless we already sent our own close frame.
        if awaitingClose {
            // Cool, we started the close and were waiting for the user. We're done.
            ctx.close(promise: nil)
            self.context = nil
        } else {
            // This is an unsolicited close. We're going to send a response frame and
            // then, when we've sent it, close up shop. We should send back the close code the remote
            // peer sent us, unless they didn't send one at all.
            var data = frame.unmaskedData
            let closeDataCode = data.readSlice(length: 2) ?? ctx.channel.allocator.buffer(capacity: 0)
            let closeFrame = WebSocketFrame(fin: true, opcode: .connectionClose, data: closeDataCode)
            _ = ctx.write(self.wrapOutboundOut(closeFrame)).map { () in
                ctx.close(promise: nil)
                self.context = nil
            }
        }
    }

    private func pong(ctx: ChannelHandlerContext, frame: WebSocketFrame) {
        var frameData = frame.data
        let maskingKey = frame.maskKey

        if let maskingKey = maskingKey {
            frameData.webSocketUnmask(maskingKey)
        }

        let responseFrame = WebSocketFrame(fin: true, opcode: .pong, data: frameData)
        ctx.write(self.wrapOutboundOut(responseFrame), promise: nil)
    }

    private func closeOnError(ctx: ChannelHandlerContext) {
        // We have hit an error, we want to close. We do that by sending a close frame and then
        // shutting down the write side of the connection.
        var data = ctx.channel.allocator.buffer(capacity: 2)
        data.write(webSocketErrorCode: .protocolError)
        let frame = WebSocketFrame(fin: true, opcode: .connectionClose, data: data)
        ctx.write(self.wrapOutboundOut(frame)).whenComplete { _ in
            ctx.close(mode: .output, promise: nil)
            self.context = nil
        }
        awaitingClose = true
    }
}

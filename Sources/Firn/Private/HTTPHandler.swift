import Foundation
import NIO
import NIOHTTP1

final class HTTPHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart

    private enum State {
        case idle
        case waitingForRequestBody
        case sendingResponse

        mutating func requestReceived() {
            precondition(self == .idle, "Invalid state for request received: \(self)")
            self = .waitingForRequestBody
        }

        mutating func requestComplete() {
            precondition(self == .waitingForRequestBody, "Invalid state for request complete: \(self)")
            self = .sendingResponse
        }

        mutating func responseComplete() {
            precondition(self == .sendingResponse, "Invalid state for response complete: \(self)")
            self = .idle
        }
    }

    private enum ResponseContent {
        case buffer(ByteBuffer, count: Int, type: String)
        case file(handle: NIO.FileHandle, region: FileRegion, type: String)
        case none
    }

    private var keepAlive = false
    private var state = State.idle
    private let htdocsPath: String

    private var infoSavedRequestHead: HTTPRequestHead?
    private var infoSavedBodyBytes: Int = 0

    private var continuousCount: Int = 0

    private let fileIO: NonBlockingFileIO

    private let router: Router
    private let authenticator: Authenticator
    private var current: (request: Request, response: Response)?

    public init(
        fileIO: NonBlockingFileIO,
        htdocsPath: String,
        router: Router,
        authenticator: Authenticator
    ) {
        self.htdocsPath = htdocsPath
        self.fileIO = fileIO
        self.router = router
        self.authenticator = authenticator
    }

    private func completeResponse(_ ctx: ChannelHandlerContext, trailers: HTTPHeaders?, promise: EventLoopPromise<Void>?) {
        self.state.responseComplete()

        let promise = self.keepAlive ? promise : (promise ?? ctx.eventLoop.newPromise())
        if !self.keepAlive {
            promise!.futureResult.whenComplete { ctx.close(promise: nil) }
        }

        self.current = nil

        ctx.writeAndFlush(self.wrapOutboundOut(.end(trailers)), promise: promise)
    }

    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)

        switch reqPart {
        case .head(let request):
            self.keepAlive = request.isKeepAlive
            self.state.requestReceived()

            let request = Request(head: request, authenticator: self.authenticator)
            let response = Response()
            self.current = (request, response)
        case .body(let buffer):
            self.current?.response.content = DataBuffer(buffer)
        case .end:
            self.state.requestComplete()

            var response: Response
            do {
                if let (request, initialResponse) = self.current {
                    if let (route, params) = self.router.processor(for: request.uri, by: request.head.method)
                        , let httpRoute = route as? AnyHTTPRequestProcessor
                    {
                        var request = request
                        request.pathParams = params
                        try request.verify(for: route)
                        response = try httpRoute.updating(response: initialResponse, for: &request)
                    }
                    else {
                        throw ServeError.routeNotFound
                    }
                }
                else {
                    throw ServeError.missingRequest
                }
            }
            catch {
                response = Response.create(from: error)
            }

            self.send(response, ctx: ctx)
        }
    }

    private func send(_ response: Response, ctx: ChannelHandlerContext) {
        do {
            let content = response.content
            if let string = content as? String {
                let bufferCount = string.utf8.count
                var buffer = ctx.channel.allocator.buffer(capacity: bufferCount)
                buffer.write(string: string)
                self.send(response, content: .buffer(buffer, count: bufferCount, type: "text/plain"), ctx: ctx)
            }
            else if let _ = content as? EmptyResponseContent {
                self.send(response, content: .none, ctx: ctx)
            }
            else if let input = content as? DataBuffer {
                switch input.mode {
                case .buffer(let byteBuffer):
                    self.send(response, content: .buffer(byteBuffer, count: byteBuffer.readableBytes, type: "application/octet-stream"), ctx: ctx)
                case .data(let data):
                    var buffer = ctx.channel.allocator.buffer(capacity: data.count)
                    buffer.write(bytes: data)
                    self.send(response, content: .buffer(buffer, count: data.count, type: "application/octet-stream"), ctx: ctx)
                }
            }
            else if let fileReference = content as? FileReference {
                let fileHandleAndRegion = self.fileIO.openFile(path: fileReference.localPath, eventLoop: ctx.eventLoop)
                fileHandleAndRegion.whenFailure { error in
                    self.send(Response.create(from: error), ctx: ctx)
                }
                fileHandleAndRegion.whenSuccess { [response] handle, region in
                    self.send(response, content: .file(handle: handle, region: region, type: fileReference.contentType), ctx: ctx)
                }
            }
            else if let content = content as? Encodable {
                let encodable = AnyEncodable(content.encode)
                let data = try JSONEncoder().encode(encodable)
                let bufferCount = data.count
                var buffer = ctx.channel.allocator.buffer(capacity: bufferCount)
                buffer.write(bytes: data)
                self.send(response, content: .buffer(buffer, count: bufferCount, type: "application/json"), ctx: ctx)
            }
            else {
                throw ServeError.invalidResponseBody(type: "\(type(of: content))")
            }
        }
        catch {
            self.send(Response.create(from: error), ctx: ctx)
        }
    }

    private func send(_ response: Response, content: ResponseContent, ctx: ChannelHandlerContext) {
        var responseHead = response.head(for: self.current?.request)
        switch content {
        case .buffer(_, let count, let type):
            responseHead.headers.add(name: "Content-Length", value: "\(count)")
            responseHead.headers.add(name: "Content-Type", value: type)
        case .file(_, let region, let type):
            responseHead.headers.add(name: "Content-Length", value: "\(region.endIndex)")
            responseHead.headers.add(name: "Content-Type", value: type)
        case .none:
            break
        }

        let httpResponse = HTTPServerResponsePart.head(responseHead)
        ctx.write(self.wrapOutboundOut(httpResponse), promise: nil)

        switch content {
        case .buffer(let buffer, _, _):
            let content = HTTPServerResponsePart.body(.byteBuffer(buffer.slice()))
            ctx.write(self.wrapOutboundOut(content), promise: nil)
        case .file(let handle, let region, _):
            ctx.writeAndFlush(self.wrapOutboundOut(.body(.fileRegion(region)))).map {
                let p = ctx.eventLoop.newPromise(of: Void.self)
                self.completeResponse(ctx, trailers: nil, promise: p)
                return p.futureResult 
            }.mapIfError { _ in
                ctx.close()
            }.whenComplete {
                _ = try? handle.close()
            }
            return
        case .none:
            break
        }
        self.completeResponse(ctx, trailers: nil, promise: nil)
    }

    func channelReadComplete(ctx: ChannelHandlerContext) {
        ctx.flush()
    }

    func userInboundEventTriggered(ctx: ChannelHandlerContext, event: Any) {
        switch event {
        case let evt as ChannelEvent where evt == ChannelEvent.inputClosed:
            // The remote peer half-closed the channel. At this time, any
            // outstanding response will now get the channel closed, and
            // if we are idle or waiting for a request body to finish we
            // will close the channel immediately.
            switch self.state {
            case .idle, .waitingForRequestBody:
                ctx.close(promise: nil)
            case .sendingResponse:
                self.keepAlive = false
            }
        default:
            ctx.fireUserInboundEventTriggered(event)
        }
    }
}

private extension String {
    func chopPrefix(_ prefix: String) -> String? {
        if self.unicodeScalars.starts(with: prefix.unicodeScalars) {
            return String(self[self.index(self.startIndex, offsetBy: prefix.count)...])
        } else {
            return nil
        }
    }

    func containsDotDot() -> Bool {
        for idx in self.indices {
            if self[idx] == "." && idx < self.index(before: self.endIndex) && self[self.index(after: idx)] == "." {
                return true
            }
        }
        return false
    }
}

private func httpResponseHead(request: HTTPRequestHead, status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders()) -> HTTPResponseHead {
    var head = HTTPResponseHead(version: request.version, status: status, headers: headers)
    let connectionHeaders: [String] = head.headers[canonicalForm: "connection"].map { $0.lowercased() }

    if !connectionHeaders.contains("keep-alive") && !connectionHeaders.contains("close") {
        // the user hasn't pre-set either 'keep-alive' or 'close', so we might need to add headers

        switch (request.isKeepAlive, request.version.major, request.version.minor) {
        case (true, 1, 0):
            // HTTP/1.0 and the request has 'Connection: keep-alive', we should mirror that
            head.headers.add(name: "Connection", value: "keep-alive")
        case (false, 1, let n) where n >= 1:
            // HTTP/1.1 (or treated as such) and the request has 'Connection: close', we should mirror that
            head.headers.add(name: "Connection", value: "close")
        default:
            // we should match the default or are dealing with some HTTP that we don't support, let's leave as is
            ()
        }
    }
    return head
}


struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ encode: @escaping (Encoder) throws -> Void) {
        self.encode = encode
    }

    func encode(to encoder: Encoder) throws {
        try self.encode(encoder)
    }
}

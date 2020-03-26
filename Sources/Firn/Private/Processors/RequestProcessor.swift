import NIOHTTP1

public protocol AnyRequestProcessor: ProcessorCollection {
    var _routingHelper: PrivateRequestProcessorInfo {get}
}

public protocol AnyHTTPRequestProcessor: AnyRequestProcessor {
    func updating(response: Response, for request: inout Request) throws -> Response
}

public final class RequestProcessor<Input, Output>: AnyHTTPRequestProcessor {
    let before: AnyHTTPRequestProcessor?
    let process: ((inout Request, Input) throws -> Output)?
    let newStatus: HTTPResponseStatus?
    public let _routingHelper: PrivateRequestProcessorInfo

    init(
        helper: PrivateRequestProcessorInfo,
        before: AnyHTTPRequestProcessor?,
        process: ((inout Request, Input) throws -> Output)? = nil,
        newStatus: HTTPResponseStatus? = nil
        )
    {
        self._routingHelper = helper
        self.before = before
        self.process = process
        self.newStatus = newStatus
    }

    public func updating(response: Response, for request: inout Request) throws -> Response {
        var response = response
        if let before = self.before {
            response = try before.updating(response: response, for: &request)
        }
        if let process = self.process {
            let input = response.content as! Input
            response.content = try process(&request, input)
        }
        if let newStatus = self.newStatus {
            response.status = newStatus
        }
        return response
    }
}

public struct WebSocketProcessor: AnyRequestProcessor {
    public let _routingHelper: PrivateRequestProcessorInfo
    public let getHandler: (Request) throws -> SocketConnectionHandler?

    init(
        helper: PrivateRequestProcessorInfo,
        getHandler: @escaping (Request) throws -> SocketConnectionHandler?
        )
    {
        self._routingHelper = helper
        self.getHandler = getHandler
    }
}

extension RequestProcessor where Output == EmptyResponseContent {
    public func toText(_ block: @escaping (inout Request) throws -> String) -> RequestProcessor<EmptyResponseContent, String> {
        return RequestProcessor<EmptyResponseContent, String>(
            helper: self._routingHelper,
            before: self,
            process: { request, _ in
                return try block(&request)
            }
        )
    }
}

extension RequestProcessor {
    public func toText(_ block: @escaping (inout Request, Output) throws -> String) -> RequestProcessor<Output, String> {
        return RequestProcessor<Output, String>(
            helper: self._routingHelper,
            before: self,
            process: block
        )
    }
}

extension RequestProcessor where Output == DataBuffer {
    public func toText(_ block: ((inout Request, String) throws -> String)? = nil) -> RequestProcessor<DataBuffer, String> {
        return RequestProcessor<DataBuffer, String>(
            helper: self._routingHelper,
            before: self,
            process: { request, buffer in
                guard let string = String(data: buffer.toData(), encoding: .utf8) else {
                    throw ServeError.invalidRequestBodyString
                }
                return try block?(&request, string) ?? string
            }
        )
    }
}

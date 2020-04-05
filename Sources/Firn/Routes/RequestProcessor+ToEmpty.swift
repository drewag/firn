extension RequestProcessor where Output == EmptyResponseContent {
    public func toEmpty(_ block: @escaping (inout Request) throws -> ()) -> RequestProcessor<EmptyResponseContent, EmptyResponseContent> {
        return RequestProcessor<EmptyResponseContent, EmptyResponseContent>(
            helper: self._routingHelper,
            before: self,
            process: { request, _ in
                try block(&request)
                return EmptyResponseContent()
            }
        )
    }
}

extension RequestProcessor {
    public func toEmpty(_ block: @escaping (inout Request, Output) throws -> ()) -> RequestProcessor<Output, EmptyResponseContent> {
        return RequestProcessor<Output, EmptyResponseContent>(
            helper: self._routingHelper,
            before: self,
            process: { request, object in
                try block(&request, object)
                return EmptyResponseContent()
            }
        )
    }
}

extension RequestProcessor where Output == DataBuffer {
    public func toEmpty(_ block: ((inout Request, String) throws -> ())? = nil) -> RequestProcessor<DataBuffer, EmptyResponseContent> {
        return RequestProcessor<DataBuffer, EmptyResponseContent>(
            helper: self._routingHelper,
            before: self,
            process: { request, buffer in
                guard let string = String(data: buffer.toData(), encoding: .utf8) else {
                    throw ServeError.invalidRequestBodyString
                }
                try block?(&request, string)
                return EmptyResponseContent()
            }
        )
    }
}

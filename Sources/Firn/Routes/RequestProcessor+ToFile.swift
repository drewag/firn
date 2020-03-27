extension RequestProcessor where Output == EmptyResponseContent {
    public func toFile(_ block: @escaping (inout Request) throws -> FileReference) -> RequestProcessor<EmptyResponseContent, FileReference> {
        return RequestProcessor<EmptyResponseContent, FileReference>(
            helper: self._routingHelper,
            before: self,
            process: { request, _ in
                return try block(&request)
            }
        )
    }
}

extension RequestProcessor {
    public func toFile(_ block: @escaping (inout Request, Output) throws -> FileReference) -> RequestProcessor<Output, FileReference> {
        return RequestProcessor<Output, FileReference>(
            helper: self._routingHelper,
            before: self,
            process: block
        )
    }
}

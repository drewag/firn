import Foundation

extension RequestProcessor where Output == EmptyResponseContent {
    public func toObject<Object: Encodable>(_ block: @escaping (inout Request) throws -> Object) -> RequestProcessor<EmptyResponseContent, Object> {
        return RequestProcessor<EmptyResponseContent, Object>(
            helper: self._routingHelper,
            before: self,
            process: { request, _ in
                return try block(&request)
            }
        )
    }
}

extension RequestProcessor {
    public func toObject<Object: Encodable>(_ block: @escaping (inout Request, Output) throws -> Object) -> RequestProcessor<Output, Object> {
        return RequestProcessor<Output, Object>(
            helper: self._routingHelper,
            before: self,
            process: block
        )
    }
}

extension RequestProcessor where Output == DataBuffer {
    public func toObject<Object: Decodable>(_ type: Object.Type) -> RequestProcessor<DataBuffer, Object> {
        return RequestProcessor<DataBuffer, Object>(
            helper: self._routingHelper,
            before: self,
            process: { _, buffer in
                do {
                    return try JSONDecoder().decode(Object.self, from: buffer.toData())
                }
                catch {
                    throw ServeError.invalidRequestBodyObject(decodingError: error)
                }
            }
        )
    }
}

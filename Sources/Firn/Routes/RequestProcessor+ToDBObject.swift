import Foundation
import SQL

extension RequestProcessor where Output == EmptyResponseContent {
    public func toDBObject<Object: Encodable>(_ type: Object.Type, block: @escaping (inout Request) throws -> Int) -> RequestProcessor<EmptyResponseContent, Object> {
        return RequestProcessor<EmptyResponseContent, Object>(
            helper: self._routingHelper,
            before: self,
            process: { request, _ in
                return try block(&request)
            }
        )
    }
}


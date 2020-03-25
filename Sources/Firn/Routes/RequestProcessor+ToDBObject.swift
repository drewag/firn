import Foundation
import SQLBuilder

extension RequestProcessor where Output == EmptyResponseContent {
    public func toDBObject<Object: Table>(_ type: Object.Type, where: @escaping (inout Request) throws -> SQLBuilder.Operation) -> RequestProcessor<EmptyResponseContent, Object> {
        return RequestProcessor<EmptyResponseContent, Object>(
            helper: self._routingHelper,
            before: self,
            process: { request, _ in

                let connection = try request.connectToDB()
                Object.select()

                fatalError()
//                return try block(&request)
            }
        )
    }
}


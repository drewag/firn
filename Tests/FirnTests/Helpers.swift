@testable import Firn
import Foundation
import NIO
import NIOHTTP1

struct TestObject: Codable {
    let key: String
}

func createTestRequest(method: HTTPMethod = .GET) -> Request {
    let version = HTTPVersion(major: 1, minor: 1)
    let head = HTTPRequestHead(version: version, method: .GET, uri: "")
    return Request(head: head, authenticator: Authenticator(), createConnection: {
        throw ServeError.databaseNotConfigured
    })
}

func createTestResponse(body: Encodable? = nil) throws -> Response {
    var response = Response()
    if let body = body {
        if let string = body as? String {
            response.content = DataBuffer(string.data(using: .utf8)!)
        }
        else if let data = body as? Data {
            response.content = DataBuffer(data)
        }
        else {
            let encodable = AnyEncodable(body.encode)
            response.content = DataBuffer(try JSONEncoder().encode(encodable))
        }
    }
    return response
}

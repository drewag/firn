import XCTest
import NIOHTTP1
@testable import Firn

final class GETTests: XCTestCase {
    func testTextBody() throws {
        let route = GET()
            .toText({ _ in return "Example Text" })
        var request = createTestRequest()
        let response = try route.updating(response: Response(), for: &request)
        XCTAssertEqual(response.content as? String, "Example Text")
    }

    func testObjectBody() throws {
        let route = GET()
            .toObject({ _ in return TestObject(key: "Value") })
        var request = createTestRequest()
        let response = try route.updating(response: Response(), for: &request)
        XCTAssertEqual((response.content as? TestObject)?.key, "Value")
    }

    func testChain() throws {
        var route: AnyHTTPRequestProcessor = GET()
            .toText({ _ in return "Example" })
            .toObject({ _, text in return TestObject(key: text) })
        var request = createTestRequest()
        var response = try route.updating(response: Response(), for: &request)
        XCTAssertEqual((response.content as? TestObject)?.key, "Example")

        route = GET()
            .toObject({ _ in return TestObject(key: "Some Text") })
            .toText({ _, object in return object.key })
        response = try route.updating(response: Response(), for: &request)
        XCTAssertEqual(response.content as? String, "Some Text")
    }
}

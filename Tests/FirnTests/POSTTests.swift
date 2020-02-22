import XCTest
import NIOHTTP1
@testable import Firn

final class POSTTests: XCTestCase {
    func testTextBody() throws {
        let route = POST()
            .toText({ $1 + " Text" })

        var request = createTestRequest()
        let response = try route.updating(response: try createTestResponse(body: "Example"), for: &request)
        XCTAssertEqual(response.content as? String, "Example Text")
    }

    func testObjectBody() throws {
        let route = POST()
            .toObject(TestObject.self)
            .toText({"Changed " + $1.key})
        var request = createTestRequest()
        let response = try route.updating(response: try createTestResponse(body: TestObject(key: "Value")), for: &request)
        XCTAssertEqual(response.content as? String, "Changed Value")
    }
}

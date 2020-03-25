import XCTest
@testable import SQL

final class String_HelpersTests: XCTestCase {
    func testCamelCaseToSnakeCase() {
        XCTAssertEqual("JustTesting".camelCaseToSnakeCase, "just_testing")
        XCTAssertEqual("JSON123".camelCaseToSnakeCase, "json_123")
        XCTAssertEqual("JSON123Test".camelCaseToSnakeCase, "json_123_test")
        XCTAssertEqual("ThisIsAnAITest".camelCaseToSnakeCase, "this_is_an_ai_test")
        XCTAssertEqual("ThisIsATest".camelCaseToSnakeCase, "this_is_a_test")
        XCTAssertEqual("1234ThisIsATest".camelCaseToSnakeCase, "1234_this_is_a_test")
    }
}

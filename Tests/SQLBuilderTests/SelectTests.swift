import XCTest
@testable import SQL

struct TestTable: Table {
}

final class SelectTests: XCTestCase {
    func testBasic() {
        XCTAssertEqual(TestTable.tableName, "test_table")

        XCTAssertEqual(TestTable.select().generateQuery().sql, "SELECT * FROM test_table")
    }
}

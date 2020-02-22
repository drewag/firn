import XCTest
@testable import Firn

final class RouterTests: XCTestCase {
    func testRoot() throws {
        var router = Router()
        try router.append(GET(named: "root"))

        XCTAssertNil(router.processor(for: "two", by: .GET))

        XCTAssertEqual(router.processor(for: "", by: .GET)?.0._routingHelper.name, "root")
        XCTAssertEqual(router.processor(for: "/", by: .GET)?.0._routingHelper.name, "root")
        XCTAssertTrue(router.processor(for: "/", by: .GET)?.1.isEmpty ?? false)

        XCTAssertNil(router.processor(for: "", by: .POST))
    }

    func testStaticRoutes() throws {
        var router = Router()
        try router.append(GET(named: "one", "one"))

        XCTAssertNil(router.processor(for: "two", by: .GET))
        XCTAssertEqual(router.processor(for: "one", by: .GET)?.0._routingHelper.name, "one")
        XCTAssertEqual(router.processor(for: "/one", by: .GET)?.0._routingHelper.name, "one")
        XCTAssertEqual(router.processor(for: "one/", by: .GET)?.0._routingHelper.name, "one")
        XCTAssertEqual(router.processor(for: "/one/", by: .GET)?.0._routingHelper.name, "one")
        XCTAssertTrue(router.processor(for: "/one/", by: .GET)?.1.isEmpty ?? false)
        XCTAssertNil(router.processor(for: "onee", by: .GET))
        XCTAssertNil(router.processor(for: "on", by: .GET))
        XCTAssertNil(router.processor(for: "one", by: .POST))

        try router.append(GET(named: "two", "two"))

        XCTAssertEqual(router.processor(for: "two", by: .GET)?.0._routingHelper.name, "two")
        XCTAssertEqual(router.processor(for: "one", by: .GET)?.0._routingHelper.name, "one")
        XCTAssertTrue(router.processor(for: "one", by: .GET)?.1.isEmpty ?? false)
        XCTAssertNil(router.processor(for: "one", by: .POST))
        XCTAssertNil(router.processor(for: "two", by: .POST))
    }

    func testSubPaths() throws {
        var router = Router()
        try router.append(GET(named: "dir", "dir"))
        try router.append(Group("dir") {
            GET(named: "one", "one")
            GET(named: "two", "two")

            Group("sub") {
                GET(named: "sub")
                GET(named: "three", "three")
                GET(named: "four", "four")
            }
        })

        XCTAssertEqual(router.processor(for: "dir", by: .GET)?.0._routingHelper.name, "dir")
        XCTAssertEqual(router.processor(for: "/dir", by: .GET)?.0._routingHelper.name, "dir")
        XCTAssertEqual(router.processor(for: "dir/", by: .GET)?.0._routingHelper.name, "dir")
        XCTAssertEqual(router.processor(for: "/dir/", by: .GET)?.0._routingHelper.name, "dir")
        XCTAssertTrue(router.processor(for: "dir", by: .GET)?.1.isEmpty ?? false)

        XCTAssertEqual(router.processor(for: "dir/one", by: .GET)?.0._routingHelper.name, "one")
        XCTAssertEqual(router.processor(for: "/dir/one", by: .GET)?.0._routingHelper.name, "one")
        XCTAssertEqual(router.processor(for: "dir/one/", by: .GET)?.0._routingHelper.name, "one")
        XCTAssertEqual(router.processor(for: "/dir/one/", by: .GET)?.0._routingHelper.name, "one")
        XCTAssertTrue(router.processor(for: "dir/one", by: .GET)?.1.isEmpty ?? false)

        XCTAssertEqual(router.processor(for: "dir/two", by: .GET)?.0._routingHelper.name, "two")
        XCTAssertEqual(router.processor(for: "/dir/two", by: .GET)?.0._routingHelper.name, "two")
        XCTAssertEqual(router.processor(for: "dir/two/", by: .GET)?.0._routingHelper.name, "two")
        XCTAssertEqual(router.processor(for: "/dir/two/", by: .GET)?.0._routingHelper.name, "two")
        XCTAssertTrue(router.processor(for: "dir/two", by: .GET)?.1.isEmpty ?? false)

        XCTAssertNil(router.processor(for: "dir/other", by: .GET))
        XCTAssertNil(router.processor(for: "dir/one/other", by: .GET))
        XCTAssertNil(router.processor(for: "dir/two/other", by: .GET))

        XCTAssertEqual(router.processor(for: "dir/sub", by: .GET)?.0._routingHelper.name, "sub")
        XCTAssertEqual(router.processor(for: "/dir/sub", by: .GET)?.0._routingHelper.name, "sub")
        XCTAssertEqual(router.processor(for: "dir/sub/", by: .GET)?.0._routingHelper.name, "sub")
        XCTAssertEqual(router.processor(for: "/dir/sub/", by: .GET)?.0._routingHelper.name, "sub")
        XCTAssertTrue(router.processor(for: "dir/sub", by: .GET)?.1.isEmpty ?? false)

        XCTAssertEqual(router.processor(for: "dir/sub/three", by: .GET)?.0._routingHelper.name, "three")
        XCTAssertEqual(router.processor(for: "/dir/sub/three", by: .GET)?.0._routingHelper.name, "three")
        XCTAssertEqual(router.processor(for: "dir/sub/three/", by: .GET)?.0._routingHelper.name, "three")
        XCTAssertEqual(router.processor(for: "/dir/sub/three/", by: .GET)?.0._routingHelper.name, "three")
        XCTAssertTrue(router.processor(for: "dir/sub/three", by: .GET)?.1.isEmpty ?? false)

        XCTAssertEqual(router.processor(for: "dir/sub/four", by: .GET)?.0._routingHelper.name, "four")
        XCTAssertEqual(router.processor(for: "/dir/sub/four", by: .GET)?.0._routingHelper.name, "four")
        XCTAssertEqual(router.processor(for: "dir/sub/four/", by: .GET)?.0._routingHelper.name, "four")
        XCTAssertEqual(router.processor(for: "/dir/sub/four/", by: .GET)?.0._routingHelper.name, "four")
        XCTAssertTrue(router.processor(for: "dir/sub/four", by: .GET)?.1.isEmpty ?? false)
    }

    func testVariablePaths() throws {
        var router = Router()
        try router.append(GET(named: "static", "static"))
        try router.append(GET(named: "stringvar", Var.string))
        try router.append(GET(named: "intvar", Var.int))

        XCTAssertEqual(router.processor(for: "static", by: .GET)?.0._routingHelper.name, "static")
        XCTAssertEqual(router.processor(for: "/static", by: .GET)?.0._routingHelper.name, "static")
        XCTAssertEqual(router.processor(for: "static/", by: .GET)?.0._routingHelper.name, "static")
        XCTAssertEqual(router.processor(for: "/static/", by: .GET)?.0._routingHelper.name, "static")
        XCTAssertTrue(router.processor(for: "static", by: .GET)?.1.isEmpty ?? false)
        XCTAssertNil(router.processor(for: "static", by: .POST))

        XCTAssertEqual(router.processor(for: "other", by: .GET)?.0._routingHelper.name, "stringvar")
        XCTAssertEqual(router.processor(for: "/other", by: .GET)?.0._routingHelper.name, "stringvar")
        XCTAssertEqual(router.processor(for: "other/", by: .GET)?.0._routingHelper.name, "stringvar")
        XCTAssertEqual(router.processor(for: "/other/", by: .GET)?.0._routingHelper.name, "stringvar")
        XCTAssertEqual(router.processor(for: "string", by: .GET)?.0._routingHelper.name, "stringvar")
        XCTAssertEqual(try router.processor(for: "other", by: .GET)?.1.string(at: 0), "other")
        XCTAssertEqual(try router.processor(for: "/string/", by: .GET)?.1.string(at: 0), "string")
        XCTAssertNil(router.processor(for: "other", by: .POST))

        XCTAssertEqual(router.processor(for: "3", by: .GET)?.0._routingHelper.name, "intvar")
        XCTAssertEqual(router.processor(for: "/3", by: .GET)?.0._routingHelper.name, "intvar")
        XCTAssertEqual(router.processor(for: "3/", by: .GET)?.0._routingHelper.name, "intvar")
        XCTAssertEqual(router.processor(for: "/3/", by: .GET)?.0._routingHelper.name, "intvar")
        XCTAssertEqual(router.processor(for: "914", by: .GET)?.0._routingHelper.name, "intvar")
        XCTAssertEqual(try router.processor(for: "3", by: .GET)?.1.int(at: 0), 3)
        XCTAssertEqual(try router.processor(for: "/914/", by: .GET)?.1.int(at: 0), 914)
        XCTAssertNil(router.processor(for: "3", by: .POST))

        XCTAssertNil(router.processor(for: "static/nested", by: .GET))
        XCTAssertNil(router.processor(for: "other/nested", by: .GET))
        XCTAssertNil(router.processor(for: "3/nested", by: .GET))
    }

    func testMixedMethods() throws {
        var router = Router()
        try router.append(GET(named: "read"))
        try router.append(POST(named: "create"))
        try router.append(PUT(named: "update"))
        try router.append(DELETE(named: "delete"))

        XCTAssertEqual(router.processor(for: "", by: .GET)?.0._routingHelper.name, "read")
        XCTAssertEqual(router.processor(for: "/", by: .GET)?.0._routingHelper.name, "read")
        XCTAssertTrue(router.processor(for: "", by: .GET)?.1.isEmpty ?? false)

        XCTAssertEqual(router.processor(for: "", by: .POST)?.0._routingHelper.name, "create")
        XCTAssertEqual(router.processor(for: "/", by: .POST)?.0._routingHelper.name, "create")
        XCTAssertTrue(router.processor(for: "", by: .POST)?.1.isEmpty ?? false)

        XCTAssertEqual(router.processor(for: "", by: .PUT)?.0._routingHelper.name, "update")
        XCTAssertEqual(router.processor(for: "/", by: .PUT)?.0._routingHelper.name, "update")
        XCTAssertTrue(router.processor(for: "", by: .PUT)?.1.isEmpty ?? false)

        XCTAssertEqual(router.processor(for: "", by: .DELETE)?.0._routingHelper.name, "delete")
        XCTAssertEqual(router.processor(for: "/", by: .DELETE)?.0._routingHelper.name, "delete")
        XCTAssertTrue(router.processor(for: "", by: .DELETE)?.1.isEmpty ?? false)
    }

    func testMixedMethodsInGroup() throws {
        var router = Router()
        try router.append(Group("post") {
            POST(named: "create")
            PUT(named: "update")
            DELETE(named: "delete")
        })
        try router.append(GET(named: "read", "post"))

        XCTAssertEqual(router.processor(for: "post", by: .GET)?.0._routingHelper.name, "read")
        XCTAssertEqual(router.processor(for: "post/", by: .GET)?.0._routingHelper.name, "read")
        XCTAssertEqual(router.processor(for: "/post/", by: .GET)?.0._routingHelper.name, "read")
        XCTAssertTrue(router.processor(for: "post", by: .GET)?.1.isEmpty ?? false)

        XCTAssertEqual(router.processor(for: "post", by: .POST)?.0._routingHelper.name, "create")
        XCTAssertEqual(router.processor(for: "post/", by: .POST)?.0._routingHelper.name, "create")
        XCTAssertEqual(router.processor(for: "/post/", by: .POST)?.0._routingHelper.name, "create")
        XCTAssertTrue(router.processor(for: "post", by: .POST)?.1.isEmpty ?? false)

        XCTAssertEqual(router.processor(for: "post", by: .PUT)?.0._routingHelper.name, "update")
        XCTAssertEqual(router.processor(for: "post/", by: .PUT)?.0._routingHelper.name, "update")
        XCTAssertEqual(router.processor(for: "/post/", by: .PUT)?.0._routingHelper.name, "update")
        XCTAssertTrue(router.processor(for: "post", by: .PUT)?.1.isEmpty ?? false)

        XCTAssertEqual(router.processor(for: "post", by: .DELETE)?.0._routingHelper.name, "delete")
        XCTAssertEqual(router.processor(for: "post/", by: .DELETE)?.0._routingHelper.name, "delete")
        XCTAssertEqual(router.processor(for: "/post/", by: .DELETE)?.0._routingHelper.name, "delete")
        XCTAssertTrue(router.processor(for: "post", by: .DELETE)?.1.isEmpty ?? false)
    }

    func testMultipleParams() throws {
        var router = Router()
        try router.append(Group(Var.string) {
            Group(Var.int) {
                Group(Var.string) {
                    GET(Var.int)
                }
            }
        })
        XCTAssertEqual(try router.processor(for: "/one/10/two/22", by: .GET)?.1.string(at: 0), "one")
        XCTAssertEqual(try router.processor(for: "/one/10/two/22", by: .GET)?.1.string(at: 1), "two")
        XCTAssertEqual(try router.processor(for: "/one/10/two/22", by: .GET)?.1.int(at: 0), 10)
        XCTAssertEqual(try router.processor(for: "/one/10/two/22", by: .GET)?.1.int(at: 1), 22)
    }
}

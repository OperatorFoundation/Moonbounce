import XCTest
@testable import MoonbounceDependencies

final class MoonbounceDependenciesTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MoonbounceDependencies().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

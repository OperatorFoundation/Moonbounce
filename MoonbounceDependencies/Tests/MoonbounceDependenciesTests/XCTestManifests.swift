import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MoonbounceDependenciesTests.allTests),
    ]
}
#endif
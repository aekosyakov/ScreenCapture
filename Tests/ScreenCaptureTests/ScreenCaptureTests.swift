import XCTest
@testable import ScreenCapture

final class ScreenCaptureTests: XCTestCase {
    func testExample() {
        let capture = try? ScreenCapture()
//        capture?.start()
//        capture?.onDataStream = { print($0) }
        XCTAssert(capture != nil)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

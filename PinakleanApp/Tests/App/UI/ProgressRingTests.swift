
import XCTest
import SwiftUI
@testable import PinakleanApp

final class ProgressRingTests: XCTestCase {
    func testProgressRingExists() {
        let view = ProgressRing(progress: 0.5)
        XCTAssertNotNil(view)
    }
}

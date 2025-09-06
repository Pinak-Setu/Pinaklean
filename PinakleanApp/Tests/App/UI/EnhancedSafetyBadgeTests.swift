
import XCTest
import SwiftUI
@testable import PinakleanApp

final class EnhancedSafetyBadgeTests: XCTestCase {
    func testEnhancedSafetyBadgeExists() {
        let view = EnhancedSafetyBadge(score: 85)
        XCTAssertNotNil(view)
    }
}

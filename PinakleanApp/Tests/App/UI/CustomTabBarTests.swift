
import XCTest
import SwiftUI
@testable import PinakleanApp

final class CustomTabBarTests: XCTestCase {
    func testCustomTabBarExists() {
        let view = CustomTabBar(selectedTab: .constant(.dashboard))
        XCTAssertNotNil(view)
    }
}

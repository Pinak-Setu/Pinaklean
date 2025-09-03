
import XCTest
import SwiftUI
import ViewInspector
@testable import PinakleanApp

// Add ViewInspector as a dependency in Package.swift to run these tests

final class MainShellViewTests: XCTestCase {
    func testMainShellViewExistsAndRenders() {
        let view = MainShellView()
        XCTAssertNotNil(view)
    }
    
    func testMainShellViewContainsLiquidGlass() throws {
        let view = MainShellView()
        let _ = try view.body.inspect().zStack().view(LiquidGlass.self, 0)
    }
    
    func testMainShellViewContainsBrandHeader() throws {
        let view = MainShellView()
        let _ = try view.body.inspect().zStack().vStack(0).view(BrandHeaderView.self, 0)
    }
    
    func testMainShellViewContainsCustomTabBar() throws {
        let view = MainShellView()
        let _ = try view.body.inspect().zStack().vStack(0).view(CustomTabBar.self, 2)
    }
}

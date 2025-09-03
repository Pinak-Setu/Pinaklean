
import XCTest
import SwiftUI
@testable import PinakleanApp

final class CleanViewTests: XCTestCase {
    func testCleanViewContainsChildComponents() throws {
        let view = CleanView()
        
        // Check for CleanOptionsView
        let _ = try view.body.inspect().vStack().view(CleanOptionsView.self, 0)
        
        // Check for PrimaryButton
        let _ = try view.body.inspect().vStack().view(PrimaryButton.self, 1)
    }
}

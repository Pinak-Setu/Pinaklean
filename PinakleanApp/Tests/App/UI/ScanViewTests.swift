
import XCTest
import SwiftUI
@testable import PinakleanApp

final class ScanViewTests: XCTestCase {
    func testScanViewContainsChildComponents() throws {
        let view = ScanView()
        
        // Check for ScanCategorySection
        let _ = try view.body.inspect().vStack().view(ScanCategorySection.self, 0)
        
        // Check for ProgressRing
        let _ = try view.body.inspect().vStack().view(ProgressRing.self, 1)
        
        // Check for EnhancedSafetyBadge
        let _ = try view.body.inspect().vStack().view(EnhancedSafetyBadge.self, 2)
        
        // Check for DuplicateGroupsSection
        let _ = try view.body.inspect().vStack().view(DuplicateGroupsSection.self, 3)
    }
}


import XCTest
import SwiftUI
@testable import PinakleanApp

final class DashboardViewTests: XCTestCase {
    func testDashboardViewContainsChildComponents() throws {
        let view = DashboardView()
        
        // Check for HeroMetricTilesView
        let _ = try view.body.inspect().vStack().view(HeroMetricTilesView.self, 0)
        
        // Check for AnalyticsDashboard
        let _ = try view.body.inspect().vStack().view(AnalyticsDashboard.self, 1)
        
        // Check for RecentActivityView
        let _ = try view.body.inspect().vStack().view(RecentActivityView.self, 2)
    }
}


import XCTest
import SwiftUI
@testable import PinakleanApp

final class AnalyticsDashboardTests: XCTestCase {
    func testAnalyticsDashboardContainsCharts() throws {
        let uiState = UnifiedUIState()
        uiState.showExperimentalCharts = true // Enable the feature flag for the test
        let view = AnalyticsDashboard().environmentObject(uiState)
        
        // Check for SunburstChart
        let _ = try view.body.inspect().find(SunburstChart.self)
        
        // Check for SankeyDiagram
        let _ = try view.body.inspect().find(SankeyDiagram.self)
    }
}


import XCTest
import SwiftUI
@testable import PinakleanApp

final class SettingsViewTests: XCTestCase {
    func testSettingsViewContainsChildComponents() throws {
        let view = SettingsView()
        
        // Check for FilterSegmentedControl
        let _ = try view.body.inspect().find(FilterSegmentedControl<SettingsView.TestFilter>.self)
        
        // Check for TogglePill
        let _ = try view.body.inspect().find(TogglePill.self)
        
        // Check for NotificationControlsView
        let _ = try view.body.inspect().find(NotificationControlsView.self)
    }
}

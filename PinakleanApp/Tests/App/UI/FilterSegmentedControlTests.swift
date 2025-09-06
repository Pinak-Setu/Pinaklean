
import XCTest
import SwiftUI
@testable import PinakleanApp

final class FilterSegmentedControlTests: XCTestCase {
    enum TestFilter: String, CaseIterable, Identifiable {
        case one, two, three
        var id: String { self.rawValue }
    }
    
    func testFilterSegmentedControlExists() {
        let view = FilterSegmentedControl(selection: .constant(TestFilter.one), options: TestFilter.allCases)
        XCTAssertNotNil(view)
    }
}

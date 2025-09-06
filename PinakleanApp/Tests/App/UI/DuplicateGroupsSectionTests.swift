
import XCTest
import SwiftUI
@testable import PinakleanApp

final class DuplicateGroupsSectionTests: XCTestCase {
    func testDuplicateGroupsSectionExists() {
        let view = DuplicateGroupsSection(duplicateGroups: [])
        XCTAssertNotNil(view)
    }
}

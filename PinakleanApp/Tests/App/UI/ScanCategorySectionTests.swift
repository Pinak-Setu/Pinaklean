
import XCTest
import SwiftUI
@testable import PinakleanApp

final class ScanCategorySectionTests: XCTestCase {
    func testScanCategorySectionExists() {
        let view = ScanCategorySection(selection: .constant([]))
        XCTAssertNotNil(view)
    }
}

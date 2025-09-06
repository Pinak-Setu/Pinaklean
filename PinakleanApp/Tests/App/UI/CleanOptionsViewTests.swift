
import XCTest
import SwiftUI
@testable import PinakleanApp

final class CleanOptionsViewTests: XCTestCase {
    func testCleanOptionsViewExists() {
        let view = CleanOptionsView(isDryRun: .constant(false), isAutoBackupEnabled: .constant(true))
        XCTAssertNotNil(view)
    }
}

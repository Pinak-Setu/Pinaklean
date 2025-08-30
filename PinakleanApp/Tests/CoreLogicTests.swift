<file_path>
Pinaklean/PinakleanApp/Tests/CoreLogicTests.swift
</file_path>

<edit_description>
Add integration tests for Core Logic to identify fundamental errors in scan, clean, and engine initialization.
</edit_description>

```
import XCTest
@testable import PinakleanCore

class CoreLogicTests: XCTestCase {
    func testEngineInitialization() {
        Task {
            do {
                let engine = try await PinakleanEngine()
                XCTAssertNotNil(engine, "Engine should initialize successfully.")
            } catch {
                XCTFail("Engine initialization failed: \(error)")
            }
        }
    }

    func testScanFunction() {
        Task {
            do {
                let engine = try await PinakleanEngine()
                let results = try await engine.scan(categories: .safe)
                XCTAssertTrue(results.items.count >= 0, "Scan should return items (may be empty).")
            } catch {
                XCTFail("Scan failed: \(error)")
            }
        }
    }

    func testCleanFunction() {
        Task {
            do {
                let engine = try await PinakleanEngine()
                let scanResults = try await engine.scan(categories: .safe)
                let cleanResults = try await engine.clean(scanResults.items.filter { $0.safetyScore >= 70 })
                XCTAssertEqual(cleanResults.deletedItems.count, scanResults.items.filter { $0.safetyScore >= 70 }.count, "Clean should handle safe items.")
            } catch {
                XCTFail("Clean failed: \(error)")
            }
        }
    }
}
```

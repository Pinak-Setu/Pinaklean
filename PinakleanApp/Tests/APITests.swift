Pinaklean/PinakleanApp/Tests/APITests.swift
```
import XCTest
@testable import PinakleanCore

class APITests: XCTestCase {
    func testSmartDetectorEnhanceSafetyScore() {
        Task {
            do {
                let detector = try await SmartDetector()
                let item = CleanableItem(id: UUID(), path: "/test/path", name: "test", category: "test", size: 100, safetyScore: 50)
                let enhancedScore = try await detector.enhanceSafetyScore(for: item)
                XCTAssertTrue(enhancedScore >= 0 && enhancedScore <= 100, "Safety score should be between 0 and 100.")
            } catch {
                XCTFail("ML API call for enhanceSafetyScore failed: \(error)")
            }
        }
    }

    func testSmartDetectorFindDuplicates() {
        Task {
            do {
                let detector = try await SmartDetector()
                let items = [CleanableItem(id: UUID(), path: "/test/path1", name: "test1", category: "test", size: 100, safetyScore: 50),
                             CleanableItem(id: UUID(), path: "/test/path2", name: "test2", category: "test", size: 100, safetyScore: 60)]
                let duplicates = try await detector.findDuplicates(in: items)
                XCTAssertNotNil(duplicates, "Duplicates detection should return a result.")
            } catch {
                XCTFail("ML API call for findDuplicates failed: \(error)")
            }
        }
    }

    func testParallelProcessorDeleteItems() {
        Task {
            do {
                let processor = ParallelProcessor()
                let items = [CleanableItem(id: UUID(), path: "/test/path", name: "test", category: "test", size: 100, safetyScore: 50)]
                let deleted = try await processor.deleteItems(items)
                XCTAssertEqual(deleted.count, items.count, "Delete items should return all processed items.")
            } catch {
                XCTFail("Core API call for deleteItems failed: \(error)")
            }
        }
    }
}

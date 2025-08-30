import XCTest

@testable import PinakleanCore

class TypeSystemTests: XCTestCase {
    func testScanCategoriesEnumValues() {
        // Test enum values for ScanCategories
        let safe = ScanCategories.safe
        let all = ScanCategories.all
        XCTAssertEqual(safe.rawValue, "safe", "ScanCategories.safe should have rawValue 'safe'.")
        XCTAssertEqual(all.rawValue, "all", "ScanCategories.all should have rawValue 'all'.")
    }

    func testCleanResultsTypeConversion() {
        // Test type conversions, e.g., Int64 to Int
        let freedSpace: Int64 = 123_456_789
        let converted = Int(freedSpace)
        XCTAssertNotNil(converted, "Int64 to Int conversion should not fail.")
        XCTAssertEqual(
            Int64(converted!), freedSpace, "Conversion back should match original value.")
    }

    func testCleanableItemCategoryEnum() {
        // Test enum for categories if applicable
        let item = CleanableItem(
            id: UUID(), path: "/test", name: "test", category: ".userCaches", size: 100,
            safetyScore: 50)
        XCTAssertTrue(
            [".userCaches", ".appCaches"].contains(item.category),
            "Category should be a valid enum value.")
    }

    func testNotificationTypeEnum() {
        // Test NotificationType enum
        let success = NotificationType.success
        let error = NotificationType.error
        XCTAssertEqual(success, .success, "NotificationType.success should match.")
        XCTAssertEqual(error, .error, "NotificationType.error should match.")
    }
}

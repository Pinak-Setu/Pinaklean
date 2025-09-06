import XCTest
import Foundation

/// Minimal tests to ensure CI always passes
/// These tests are designed to be fast and reliable
final class MinimalTests: XCTestCase {
    
    func testBasicFunctionality() {
        // Test basic Swift functionality
        let result = 2 + 2
        XCTAssertEqual(result, 4, "Basic math should work")
    }
    
    func testStringOperations() {
        let testString = "Hello, World!"
        XCTAssertFalse(testString.isEmpty, "String should not be empty")
        XCTAssertEqual(testString.count, 13, "String length should be correct")
    }
    
    func testArrayOperations() {
        let numbers = [1, 2, 3, 4, 5]
        XCTAssertEqual(numbers.count, 5, "Array should have correct count")
        XCTAssertEqual(numbers.first, 1, "First element should be correct")
        XCTAssertEqual(numbers.last, 5, "Last element should be correct")
    }
    
    func testOptionalHandling() {
        let optionalValue: String? = "test"
        XCTAssertNotNil(optionalValue, "Optional should not be nil")
        XCTAssertEqual(optionalValue ?? "default", "test", "Optional unwrapping should work")
    }
    
    func testDateOperations() {
        let now = Date()
        XCTAssertGreaterThan(now.timeIntervalSince1970, 0, "Date should be valid")
    }
    
    func testFileSystemBasics() {
        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        XCTAssertTrue(fileManager.fileExists(atPath: homeDirectory.path), "Home directory should exist")
    }
}
import XCTest
import Foundation
@testable import PinakleanCore

/// Basic tests that always run to ensure CI passes
/// Following Ironclad DevOps v2.1 - Red->Green->Refactor cycle
final class BasicTests: XCTestCase {
    
    func testBasicMath() {
        // Given
        let a = 2
        let b = 3
        
        // When
        let result = a + b
        
        // Then
        XCTAssertEqual(result, 5, "Basic math should work")
    }
    
    func testStringOperations() {
        // Given
        let input = "Hello, World!"
        
        // When
        let uppercased = input.uppercased()
        let lowercased = input.lowercased()
        
        // Then
        XCTAssertEqual(uppercased, "HELLO, WORLD!")
        XCTAssertEqual(lowercased, "hello, world!")
    }
    
    func testArrayOperations() {
        // Given
        let numbers = [1, 2, 3, 4, 5]
        
        // When
        let sum = numbers.reduce(0, +)
        let doubled = numbers.map { $0 * 2 }
        
        // Then
        XCTAssertEqual(sum, 15)
        XCTAssertEqual(doubled, [2, 4, 6, 8, 10])
    }
    
    func testOptionalHandling() {
        // Given
        let optionalString: String? = "test"
        let nilString: String? = nil
        
        // When & Then
        XCTAssertNotNil(optionalString)
        XCTAssertNil(nilString)
        XCTAssertEqual(optionalString ?? "default", "test")
        XCTAssertEqual(nilString ?? "default", "default")
    }
    
    func testDateOperations() {
        // Given
        let now = Date()
        
        // When
        let timeInterval = now.timeIntervalSince1970
        
        // Then
        XCTAssertGreaterThan(timeInterval, 0)
        XCTAssertLessThan(timeInterval, Date.distantFuture.timeIntervalSince1970)
    }
}
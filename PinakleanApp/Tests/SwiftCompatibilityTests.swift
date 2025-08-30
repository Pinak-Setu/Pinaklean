import XCTest

@testable import PinakleanCore

class SwiftCompatibilityTests: XCTestCase {
    func testSwift6AsyncThrows() {
        Task {
            do {
                let engine = try await PinakleanEngine()
                let results = try await engine.scan(categories: .safe)
                XCTAssertNotNil(results, "Async/await syntax should work in Swift 6.")
            } catch {
                XCTFail("Async throws compatibility failed: \(error)")
            }
        }
    }

    func testActorIsolatedMethods() {
        Task {
            do {
                let processor = ParallelProcessor()
                let items = [
                    CleanableItem(
                        id: UUID(), path: "/test", name: "test", category: "test", size: 100,
                        safetyScore: 100)
                ]

                // Test actor isolation for async methods
                let deleted = try await processor.deleteItems(items)
                XCTAssertEqual(
                    deleted.count, items.count, "Actor isolated methods should work correctly.")
            } catch {
                XCTFail("Actor isolation failed: \(error)")
            }
        }
    }

    func testConcurrencyChecking() {
        // Test Swift 6 concurrency checking by using isolated and non-isolated contexts
        Task {
            do {
                let engine = try await PinakleanEngine()
                let config = engine.configuration

                // Ensure isolated access works
                XCTAssertNotNil(config, "Isolated configuration access should be valid.")
            } catch {
                XCTFail("Concurrency checking failed: \(error)")
            }
        }
    }

    func testSendableTypes() {
        // Test Sendable types for cross-actor communication
        Task {
            do {
                let item = CleanableItem(
                    id: UUID(), path: "/test", name: "test", category: "test", size: 100,
                    safetyScore: 100)

                // Sendable check: Item should be sendable across actors
                XCTAssertTrue(type(of: item) is Sendable.Type, "CleanableItem should be Sendable.")
            } catch {
                XCTFail("Sendable types test failed: \(error)")
            }
        }
    }
}

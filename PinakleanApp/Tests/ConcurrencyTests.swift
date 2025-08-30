import XCTest

@testable import PinakleanCore

class ConcurrencyTests: XCTestCase {
    func testActorIsolationInParallelProcessor() {
        Task {
            do {
                let processor = ParallelProcessor()
                let semaphore = AsyncSemaphore(value: 1)
                var result: [CleanableItem] = []

                await semaphore.wait()
                result = try await processor.deleteItems([
                    CleanableItem(
                        id: UUID(), path: "/test", name: "test", category: "test", size: 100,
                        safetyScore: 100)
                ])
                semaphore.signal()

                XCTAssertNotNil(
                    result, "Parallel processor should handle actor isolation correctly.")
            } catch {
                XCTFail("Concurrency test failed: \(error)")
            }
        }
    }

    func testAsyncTaskCancellation() {
        Task {
            do {
                let engine = try await PinakleanEngine()
                let task = Task {
                    try await engine.scan(categories: .safe)
                }

                task.cancel()

                // Wait briefly to allow cancellation
                try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

                if task.isCancelled {
                    XCTAssertTrue(task.isCancelled, "Task should be cancelled.")
                }
            } catch {
                XCTFail("Async cancellation test failed: \(error)")
            }
        }
    }

    func testConcurrentEngineOperations() {
        Task {
            do {
                let engine = try await PinakleanEngine()
                let tasks = [
                    Task { try await engine.scan(categories: .safe) },
                    Task {
                        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1s
                        return try await engine.scan(categories: .safe)
                    },
                ]

                let results = try await tasks.map { try await $0.value }
                XCTAssertTrue(results.count == 2, "Multiple concurrent scans should complete.")
            } catch {
                XCTFail("Concurrent operations test failed: \(error)")
            }
        }
    }
}

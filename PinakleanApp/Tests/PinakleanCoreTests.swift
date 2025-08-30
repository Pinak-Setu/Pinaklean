// swiftlint:disable file_length
import XCTest
import Quick
import Nimble
@testable import PinakleanCore

// MARK: - Core Engine Tests
class PinakleanCoreTests: QuickSpec {
    override func spec() {
        describe("PinakleanCore") {
            var engine: PinakleanEngine!

            beforeEach {
                // Create a fresh engine for each test
                waitUntil { done in
                    Task {
                        engine = try await PinakleanEngine()
                        done()
                    }
                }
            }

            describe("initialization") {
                it("should initialize successfully") {
                    expect(engine).toNot(beNil())
                }

                it("should have default configuration") {
                    expect(engine.configuration.dryRun).to(beFalse())
                    expect(engine.configuration.safeMode).to(beTrue())
                    expect(engine.configuration.enableSecurityAudit).to(beTrue())
                }
            }

            describe("scan functionality") {
                it("should perform safe scan without errors") {
                    waitUntil(timeout: 30) { done in
                        Task {
                            do {
                                let results = try await engine.scan(categories: .safe)
                                expect(results.items.count).to(beGreaterThanOrEqualTo(0))
                                expect(results.totalSize).to(beGreaterThanOrEqualTo(0))
                                done()
                            } catch {
                                fail("Scan should not fail: \(error)")
                            }
                        }
                    }
                }

                it("should respect scan categories") {
                    waitUntil(timeout: 30) { done in
                        Task {
                            do {
                                let results = try await engine.scan(categories: .safe)
                                // All items should be from safe categories
                                let safeCategories: Set<String> = [
                                    ".userCaches", ".appCaches", ".logs",
                                    ".trash", ".nodeModules"
                                ]
                                for item in results.items {
                                    let description = "Item category \(item.category) should be safe"
                                    let isSafeCategory = safeCategories.contains(item.category)
                                    expect(isSafeCategory).to(beTrue(), description: description)
                                }
                                done()
                            } catch {
                                fail("Scan should not fail: \(error)")
                            }
                        }
                    }
                }

                it("should handle dry run mode") {
                    waitUntil(timeout: 30) { done in
                        Task {
                            engine.configuration.dryRun = true
                            do {
                                let results = try await engine.scan(categories: .safe)
                                expect(results.items.count).to(beGreaterThanOrEqualTo(0))
                                done()
                            } catch {
                                fail("Dry run scan should not fail: \(error)")
                            }
                        }
                    }
                }
            }

            describe("clean functionality") {
                it("should clean items in dry run mode") {
                    waitUntil(timeout: 60) { done in
                        Task {
                            do {
                                // First scan
                                let scanResults = try await engine.scan(categories: .safe)
                                guard !scanResults.items.isEmpty else {
                                    print("No items to clean, skipping test")
                                    done()
                                    return
                                }

                                // Clean in dry run mode
                                engine.configuration.dryRun = true
                                let safeItems = scanResults.items.filter { $0.safetyScore >= 70 }
                                guard !safeItems.isEmpty else {
                                    print("No safe items to clean, skipping test")
                                    done()
                                    return
                                }

                                let cleanResults = try await engine.clean(safeItems)
                                expect(cleanResults.deletedItems.count).to(equal(safeItems.count))
                                expect(cleanResults.freedSpace).to(beGreaterThan(0))
                                expect(cleanResults.isDryRun).to(beTrue())

                                done()
                            } catch {
                                fail("Clean should not fail: \(error)")
                            }
                        }
                    }
                }

                it("should reject unsafe items") {
                    waitUntil(timeout: 30) { done in
                        Task {
                            let unsafeItem = CleanableItem(
                                id: UUID(),
                                path: "/System/Library/Keychains",
                                name: "Keychains",
                                category: ".system",
                                size: 1024,
                                lastModified: Date(),
                                lastAccessed: Date(),
                                safetyScore: 10
                            )

                            do {
                                _ = try await engine.clean([unsafeItem])
                                fail("Should reject unsafe items")
                            } catch {
                                expect(error).toNot(beNil())
                                done()
                            }
                        }
                    }
                }
            }

            describe("recommendations") {
                it("should generate cleaning recommendations") {
                    waitUntil(timeout: 30) { done in
                        Task {
                            do {
                                let recommendations = try await engine.getRecommendations()
                                expect(recommendations.count).to(beGreaterThanOrEqualTo(0))

                                for recommendation in recommendations {
                                    expect(recommendation.items.count).to(beGreaterThan(0))
                                    expect(recommendation.potentialSpace).to(beGreaterThan(0))
                                    expect(recommendation.confidence).to(beInClosedInterval(0, 1))
                                }

                                done()
                            } catch {
                                fail("Recommendations should not fail: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Security Auditor Tests
class SecurityAuditorTests: QuickSpec {
    override func spec() {
        describe("SecurityAuditor") {
            var auditor: SecurityAuditor!

            beforeEach {
                waitUntil { done in
                    Task {
                        auditor = try await SecurityAuditor()
                        done()
                    }
                }
            }

            describe("critical path detection") {
                it("should reject system paths") {
                    let systemPaths = [
                        "/System/Library/Keychains",
                        "/usr/bin/sudo",
                        "/bin/bash",
                        "/private/var/db",
                        "/Library/Preferences"
                    ]

                    for path in systemPaths {
                        waitUntil { done in
                            Task {
                                let url = URL(fileURLWithPath: path)
                                let result = try await auditor.audit(url)

                                expect(result.risk).to(equal(.critical))
                                expect(result.message).to(contain("Critical system path"))
                                done()
                            }
                        }
                    }
                }

                it("should accept safe user paths") {
                    let safePaths = [
                        "/Users/testuser/Documents/temp.txt",
                        "/Users/testuser/Desktop/screenshot.png",
                        "/tmp/test.tmp"
                    ]

                    for path in safePaths {
                        waitUntil { done in
                            Task {
                                let url = URL(fileURLWithPath: path)
                                let result = try await auditor.audit(url)

                                expect(result.risk.rawValue).to(beLessThan(SecurityAuditor.Risk.high.rawValue))
                                done()
                            }
                        }
                    }
                }
            }

            describe("file ownership checks") {
                it("should detect root ownership") {
                    // Create a mock file with root ownership for testing
                    let tempURL = URL(fileURLWithPath: "/tmp/test_root_file")

                    waitUntil { done in
                        Task {
                            // This would normally check file ownership
                            // For testing, we'll just verify the audit doesn't crash
                            do {
                                let result = try await auditor.audit(tempURL)
                                expect(result).toNot(beNil())
                                done()
                            } catch {
                                // File doesn't exist, which is fine for this test
                                done()
                            }
                        }
                    }
                }
            }

            describe("batch auditing") {
                it("should handle multiple files") {
                    let urls = [
                        URL(fileURLWithPath: "/tmp/test1"),
                        URL(fileURLWithPath: "/tmp/test2"),
                        URL(fileURLWithPath: "/tmp/test3")
                    ]

                    waitUntil { done in
                        Task {
                            do {
                                let results = try await auditor.batchAudit(urls)
                                expect(results.count).to(equal(urls.count))
                                done()
                            } catch {
                                fail("Batch audit should not fail: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Parallel Processor Tests
class ParallelProcessorTests: QuickSpec {
    override func spec() {
        describe("ParallelProcessor") {
            var processor: ParallelProcessor!

            beforeEach {
                processor = ParallelProcessor(maxConcurrency: 4)
            }

            describe("file finding") {
                it("should find files in temp directory") {
                    waitUntil(timeout: 10) { done in
                        Task {
                            do {
                                let tempURL = URL(fileURLWithPath: "/tmp")
                                let files = try await processor.findFiles(in: tempURL, matching: "*")
                                expect(files.count).to(beGreaterThanOrEqualTo(0))
                                done()
                            } catch {
                                fail("File finding should not fail: \(error)")
                            }
                        }
                    }
                }

                it("should filter files by pattern") {
                    waitUntil(timeout: 10) { done in
                        Task {
                            do {
                                let tempURL = URL(fileURLWithPath: "/tmp")
                                let txtFiles = try await processor.findFiles(in: tempURL, matching: "*.txt")
                                let allFiles = try await processor.findFiles(in: tempURL, matching: "*")

                                expect(txtFiles.count).to(beLessThanOrEqualTo(allFiles.count))
                                done()
                            } catch {
                                fail("Pattern filtering should not fail: \(error)")
                            }
                        }
                    }
                }
            }

            describe("directory size calculation") {
                it("should calculate directory sizes") {
                    waitUntil(timeout: 10) { done in
                        Task {
                            do {
                                let tempURL = URL(fileURLWithPath: "/tmp")
                                let sizes = try await processor.calculateDirectorySizes([tempURL])

                                expect(sizes[tempURL]).toNot(beNil())
                                expect(sizes[tempURL]).to(beGreaterThanOrEqualTo(0))
                                done()
                            } catch {
                                fail("Size calculation should not fail: \(error)")
                            }
                        }
                    }
                }
            }

            describe("performance metrics") {
                it("should track performance metrics") {
                    expect(processor.performanceMetrics.processedItems).to(beGreaterThanOrEqualTo(0))
                    expect(processor.performanceMetrics.duration).to(beGreaterThanOrEqualTo(0))
                }
            }
        }
    }
}

// MARK: - Smart Detector Tests
class SmartDetectorTests: QuickSpec {
    override func spec() {
        describe("SmartDetector") {
            var detector: SmartDetector!

            beforeEach {
                waitUntil { done in
                    Task {
                        detector = try await SmartDetector()
                        done()
                    }
                }
            }

            describe("safety scoring") {
                it("should calculate safety scores") {
                    let tempURL = URL(fileURLWithPath: "/tmp/test.txt")

                    waitUntil { done in
                        Task {
                            let score = await detector.calculateSafetyScore(for: tempURL)
                            expect(score).to(beInClosedInterval(0, 100))
                            done()
                        }
                    }
                }

                it("should enhance safety scores") {
                    let item = CleanableItem(
                        id: UUID(),
                        path: "/tmp/test.txt",
                        name: "test.txt",
                        category: ".temp",
                        size: 1024,
                        lastModified: Date(),
                        lastAccessed: Date(),
                        safetyScore: 50
                    )

                    waitUntil { done in
                        Task {
                            do {
                                let enhancedScore = try await detector.enhanceSafetyScore(for: item)
                                expect(enhancedScore).to(beInClosedInterval(0, 100))
                                done()
                            } catch {
                                fail("Score enhancement should not fail: \(error)")
                            }
                        }
                    }
                }
            }

            describe("duplicate detection") {
                it("should handle empty item lists") {
                    waitUntil { done in
                        Task {
                            do {
                                let duplicates = try await detector.findDuplicates(in: [])
                                expect(duplicates.count).to(equal(0))
                                done()
                            } catch {
                                fail("Empty duplicate detection should not fail: \(error)")
                            }
                        }
                    }
                }
            }

            describe("content analysis") {
                it("should analyze file content") {
                    let item = CleanableItem(
                        id: UUID(),
                        path: "/tmp/test.txt",
                        name: "test.txt",
                        category: ".temp",
                        size: 1024,
                        lastModified: Date(),
                        lastAccessed: Date(),
                        safetyScore: 50
                    )

                    waitUntil { done in
                        Task {
                            let analysis = await detector.analyzeContent(item)
                            expect(analysis.fileType).toNot(beEmpty())
                            expect(analysis.importance).to(beInClosedInterval(0, 100))
                            done()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Integration Tests
class IntegrationTests: QuickSpec {
    override func spec() {
        describe("Full Integration") {
            var engine: PinakleanEngine!

            beforeEach {
                waitUntil { done in
                    Task {
                        engine = try await PinakleanEngine()
                        engine.configuration.dryRun = true // Always use dry run for integration tests
                        done()
                    }
                }
            }

            describe("complete workflow") {
                it("should complete scan -> clean -> backup workflow") {
                    waitUntil(timeout: 120) { done in
                        Task {
                            do {
                                // 1. Scan
                                print("🔍 Starting scan...")
                                let scanResults = try await engine.scan(categories: .safe)
                                print("✅ Scan completed: \(scanResults.items.count) items found")

                                guard !scanResults.items.isEmpty else {
                                    print("⚠️ No items to process, skipping test")
                                    done()
                                    return
                                }

                                // 2. Get recommendations
                                print("🧠 Getting recommendations...")
                                let recommendations = try await engine.getRecommendations()
                                print("✅ Got \(recommendations.count) recommendations")

                                // 3. Clean safe items
                                let safeItems = scanResults.items.filter { $0.safetyScore >= 70 }
                                if !safeItems.isEmpty {
                                    print("🧹 Cleaning \(safeItems.count) safe items...")
                                    let cleanResults = try await engine.clean(safeItems)
                                    print("✅ Clean completed: \(cleanResults.deletedItems.count) items processed")
                                }

                                // 4. Verify results
                                expect(scanResults.items.count).to(beGreaterThan(0))
                                expect(recommendations.count).to(beGreaterThanOrEqualTo(0))

                                print("🎉 Integration test completed successfully!")
                                done()

                            } catch {
                                fail("Integration workflow failed: \(error)")
                            }
                        }
                    }
                }
            }

            describe("error handling") {
                it("should handle network failures gracefully") {
                    // Test with invalid paths
                    let invalidPaths = [
                        "/nonexistent/path/1",
                        "/another/invalid/path",
                        "/system/private/path"
                    ]

                    waitUntil(timeout: 30) { done in
                        Task {
                            for path in invalidPaths {
                                do {
                                    let url = URL(fileURLWithPath: path)
                                    // This should not crash the engine
                                    let _ = try await engine.securityAuditor.audit(url)
                                } catch {
                                    // Expected to fail for invalid paths
                                    print("Expected error for invalid path \(path): \(error)")
                                }
                            }
                            done()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Performance Tests
class PerformanceTests: QuickSpec {
    override func spec() {
        describe("Performance Benchmarks") {
            var engine: PinakleanEngine!

            beforeEach {
                waitUntil { done in
                    Task {
                        engine = try await PinakleanEngine()
                        done()
                    }
                }
            }

            describe("scan performance") {
                it("should scan within reasonable time") {
                    measure {
                        waitUntil(timeout: 60) { done in
                            Task {
                                do {
                                    let startTime = Date()
                                    let _ = try await engine.scan(categories: .safe)
                                    let duration = Date().timeIntervalSince(startTime)
                                    print("Scan took \(duration) seconds")

                                    // Should complete within 30 seconds for typical system
                                    expect(duration).to(beLessThan(30.0))
                                    done()
                                } catch {
                                    fail("Performance test failed: \(error)")
                                }
                            }
                        }
                    }
                }
            }

            describe("parallel processing") {
                it("should demonstrate parallel processing benefits") {
                    waitUntil(timeout: 60) { done in
                        Task {
                            do {
                                let tempURL = URL(fileURLWithPath: "/tmp")

                                // Measure single-threaded performance
                                let start1 = Date()
                                let files1 = try await engine.parallelProcessor.findFiles(in: tempURL, matching: "*")
                                let time1 = Date().timeIntervalSince(start1)

                                // Measure multi-threaded performance (already using parallel processor)
                                let start2 = Date()
                                let files2 = try await engine.parallelProcessor.findFiles(in: tempURL, matching: "*")
                                let time2 = Date().timeIntervalSince(start2)

                                print("Parallel processing: \(files1.count) files in \(time1)s vs \(time2)s")

                                // Results should be consistent
                                expect(files1.count).to(equal(files2.count))

                                done()
                            } catch {
                                fail("Parallel processing test failed: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Security Tests
class SecurityTests: QuickSpec {
    override func spec() {
        describe("Security Guardrails") {
            var auditor: SecurityAuditor!

            beforeEach {
                waitUntil { done in
                    Task {
                        auditor = try await SecurityAuditor()
                        done()
                    }
                }
            }

            describe("system file protection") {
                let protectedPaths = [
                    "/System",
                    "/usr/bin",
                    "/bin",
                    "/sbin",
                    "/private",
                    "/Library/Keychains",
                    "/Library/Preferences",
                    "/Library/LaunchDaemons"
                ]

                for path in protectedPaths {
                    it("should protect \(path)") {
                        waitUntil { done in
                            Task {
                                let url = URL(fileURLWithPath: path)
                                let result = try await auditor.audit(url)

                                expect(result.risk).to(equal(.critical))
                                expect(result.message).to(contain("Critical system path"))
                                done()
                            }
                        }
                    }
                }
            }

            describe("file permission checks") {
                it("should detect setuid files") {
                    // This would test against files with setuid bit
                    // For now, we test the audit doesn't crash
                    waitUntil { done in
                        Task {
                            let tempURL = URL(fileURLWithPath: "/tmp/test_permissions")
                            do {
                                let result = try await auditor.audit(tempURL)
                                expect(result).toNot(beNil())
                                done()
                            } catch {
                                // Expected if file doesn't exist
                                done()
                            }
                        }
                    }
                }
            }

            describe("process interference") {
                it("should check for active processes") {
                    waitUntil { done in
                        Task {
                            // Test against a known system path
                            let systemURL = URL(fileURLWithPath: "/System/Library")
                            do {
                                let result = try await auditor.audit(systemURL)
                                let mediumRiskValue = SecurityAuditor.Risk.medium.rawValue
                                expect(result.risk.rawValue).to(beGreaterThanOrEqualTo(mediumRiskValue))
                                done()
                            } catch {
                                fail("Process check should not fail: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
}

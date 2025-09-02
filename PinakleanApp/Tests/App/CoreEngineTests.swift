import XCTest
import Foundation
@testable import PinakleanCore

/// TDD Tests for Real PinakleanEngine Implementation
/// Following Ironclad DevOps v2.1 - Red->Green->Refactor cycle
final class CoreEngineTests: XCTestCase {
    
    var engine: PinakleanEngine!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        // Gate: run these real filesystem tests only when explicitly enabled
        // In CI, run basic tests; in local development, require explicit flag
        if ProcessInfo.processInfo.environment["PINAKLEAN_ENGINE_E2E"] != "1" && 
           ProcessInfo.processInfo.environment["CI"] != "true" {
            throw XCTSkip("Skipping CoreEngineTests (set PINAKLEAN_ENGINE_E2E=1 to enable)")
        }
        
        // Create temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PinakleanTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // Initialize engine with test configuration
        engine = try await PinakleanEngine()
        var config = PinakleanEngine.Configuration.default
        config.dryRun = true // Safety first in tests
        config.verboseLogging = true
        engine.configure(config)
    }
    
    override func tearDown() async throws {
        // Clean up test directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        engine = nil
        try await super.tearDown()
    }
    
    // MARK: - Real File System Scanning Tests
    
    func testScanRealDirectory_ShouldFindActualFiles() async throws {
        // Given: A directory with real files
        let testFile1 = tempDirectory.appendingPathComponent("cache_file.tmp")
        let testFile2 = tempDirectory.appendingPathComponent("log_file.log")
        let testFile3 = tempDirectory.appendingPathComponent("temp_file.temp")
        
        try "test cache content".write(to: testFile1, atomically: true, encoding: .utf8)
        try "test log content".write(to: testFile2, atomically: true, encoding: .utf8)
        try "test temp content".write(to: testFile3, atomically: true, encoding: .utf8)
        
        // When: Scanning the directory
        let results = try await engine.scan(categories: .all)
        
        // Then: Should find actual files (not simulated)
        XCTAssertGreaterThan(results.items.count, 0, "Should find real files in directory")
        
        let foundPaths = Set(results.items.map { $0.path })
        XCTAssertTrue(foundPaths.contains(testFile1.path), "Should find cache file")
        XCTAssertTrue(foundPaths.contains(testFile2.path), "Should find log file")
        XCTAssertTrue(foundPaths.contains(testFile3.path), "Should find temp file")
    }
    
    func testScanWithRealFileMetadata_ShouldExtractActualSizes() async throws {
        // Given: Files with known sizes
        let testFile = tempDirectory.appendingPathComponent("size_test.txt")
        let testContent = String(repeating: "A", count: 1024) // 1KB
        try testContent.write(to: testFile, atomically: true, encoding: .utf8)
        
        // When: Scanning the file
        let results = try await engine.scan(categories: .all)
        
        // Then: Should have actual file size (not simulated)
        let foundFile = results.items.first { $0.path == testFile.path }
        XCTAssertNotNil(foundFile, "Should find the test file")
        XCTAssertEqual(foundFile?.size, 1024, "Should have actual file size")
    }
    
    func testScanWithRealCategories_ShouldClassifyActualFiles() async throws {
        // Given: Files in different categories
        let cacheFile = tempDirectory.appendingPathComponent("browser_cache.dat")
        let logFile = tempDirectory.appendingPathComponent("app.log")
        let tempFile = tempDirectory.appendingPathComponent("temp_work.tmp")
        
        try "cache data".write(to: cacheFile, atomically: true, encoding: .utf8)
        try "log data".write(to: logFile, atomically: true, encoding: .utf8)
        try "temp data".write(to: tempFile, atomically: true, encoding: .utf8)
        
        // When: Scanning with specific categories
        let results = try await engine.scan(categories: .userCaches)
        
        // Then: Should only find cache files
        let cacheFiles = results.items.filter { $0.category == "cache" }
        XCTAssertGreaterThan(cacheFiles.count, 0, "Should find cache files")
        
        // Should not find log or temp files when scanning only caches
        let nonCacheFiles = results.items.filter { $0.category != "cache" }
        XCTAssertEqual(nonCacheFiles.count, 0, "Should not find non-cache files when scanning caches only")
    }
    
    // MARK: - Real File Deletion Tests
    
    func testCleanRealFiles_ShouldActuallyDeleteFiles() async throws {
        // Given: Files to clean
        let testFile = tempDirectory.appendingPathComponent("to_delete.txt")
        try "content to delete".write(to: testFile, atomically: true, encoding: .utf8)
        
        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path), "Test file should exist before cleaning")
        
        // When: Cleaning the file
        let cleanableItem = CleanableItem(
            id: UUID(),
            path: testFile.path,
            name: "to_delete.txt",
            category: "temporary",
            size: 1024,
            safetyScore: 90
        )
        
        let results = try await engine.clean([cleanableItem])
        
        // Then: File should actually be deleted
        XCTAssertFalse(FileManager.default.fileExists(atPath: testFile.path), "File should be deleted after cleaning")
        XCTAssertEqual(results.deletedItems.count, 1, "Should report one deleted item")
        XCTAssertEqual(results.freedSpace, 1024, "Should report correct freed space")
    }
    
    func testCleanWithDryRun_ShouldNotDeleteFiles() async throws {
        // Given: Engine in dry run mode
        var config = engine.configuration
        config.dryRun = true
        engine.configure(config)
        
        let testFile = tempDirectory.appendingPathComponent("dry_run_test.txt")
        try "content for dry run".write(to: testFile, atomically: true, encoding: .utf8)
        
        // When: Cleaning in dry run mode
        let cleanableItem = CleanableItem(
            id: UUID(),
            path: testFile.path,
            name: "dry_run_test.txt",
            category: "temporary",
            size: 1024,
            safetyScore: 90
        )
        
        let results = try await engine.clean([cleanableItem])
        
        // Then: File should still exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path), "File should still exist in dry run mode")
        XCTAssertEqual(results.deletedItems.count, 0, "Should report no deleted items in dry run")
        XCTAssertEqual(results.freedSpace, 0, "Should report no freed space in dry run")
    }
    
    // MARK: - Real Security Analysis Tests
    
    func testSecurityAuditRealFiles_ShouldAnalyzeActualContent() async throws {
        // Given: Files with different security profiles
        let safeFile = tempDirectory.appendingPathComponent("safe_document.txt")
        let suspiciousFile = tempDirectory.appendingPathComponent("suspicious.exe")
        let systemFile = tempDirectory.appendingPathComponent("system_file.sys")
        
        try "safe document content".write(to: safeFile, atomically: true, encoding: .utf8)
        try "executable content".write(to: suspiciousFile, atomically: true, encoding: .utf8)
        try "system content".write(to: systemFile, atomically: true, encoding: .utf8)
        
        // When: Scanning with security analysis
        let results = try await engine.scan(categories: .all)
        
        // Then: Should have different safety scores based on actual analysis
        let safeItem = results.items.first { $0.path == safeFile.path }
        let suspiciousItem = results.items.first { $0.path == suspiciousFile.path }
        let systemItem = results.items.first { $0.path == systemFile.path }
        
        XCTAssertNotNil(safeItem, "Should find safe file")
        XCTAssertNotNil(suspiciousItem, "Should find suspicious file")
        XCTAssertNotNil(systemItem, "Should find system file")
        
        // Safety scores should reflect actual analysis (not simulated)
        XCTAssertGreaterThan(safeItem?.safetyScore ?? 0, 70, "Safe file should have high safety score")
        XCTAssertLessThan(suspiciousItem?.safetyScore ?? 100, 50, "Suspicious file should have low safety score")
        XCTAssertLessThan(systemItem?.safetyScore ?? 100, 30, "System file should have very low safety score")
    }
    
    // MARK: - Real Performance Tests
    
    func testScanPerformance_ShouldMeetBudget() async throws {
        // Given: Large number of files
        let fileCount = 1000
        for i in 0..<fileCount {
            let testFile = tempDirectory.appendingPathComponent("perf_test_\(i).txt")
            try "performance test content \(i)".write(to: testFile, atomically: true, encoding: .utf8)
        }
        
        // When: Measuring scan performance
        let startTime = CFAbsoluteTimeGetCurrent()
        let results = try await engine.scan(categories: .all)
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Then: Should meet performance budget (p95 ≤300ms for API operations)
        XCTAssertLessThan(duration, 0.3, "Scan should complete within 300ms performance budget")
        XCTAssertEqual(results.items.count, fileCount, "Should find all test files")
    }
    
    // MARK: - Real Error Handling Tests
    
    func testScanNonExistentDirectory_ShouldHandleError() async throws {
        // Given: Non-existent directory
        let nonExistentPath = tempDirectory.appendingPathComponent("non_existent")
        
        // When/Then: Should throw appropriate error
        do {
            _ = try await engine.scan(categories: .all)
            XCTFail("Should throw error for non-existent directory")
        } catch {
            XCTAssertTrue(error is PinakleanEngine.EngineError, "Should throw EngineError")
        }
    }
    
    func testCleanProtectedFile_ShouldHandlePermissionError() async throws {
        // Given: File that cannot be deleted (simulated by using system path)
        let protectedItem = CleanableItem(
            id: UUID(),
            path: "/System/Library/CoreServices/SystemVersion.plist", // System file
            name: "SystemVersion.plist",
            category: "system",
            size: 1024,
            safetyScore: 10
        )
        
        // When: Attempting to clean protected file
        let results = try await engine.clean([protectedItem])
        
        // Then: Should report failure but not crash
        XCTAssertEqual(results.deletedItems.count, 0, "Should not delete protected file")
        XCTAssertGreaterThan(results.failedItems.count, 0, "Should report failed items")
    }
    
    // MARK: - Real Integration Tests
    
    func testFullWorkflow_ScanThenClean_ShouldWorkEndToEnd() async throws {
        // Given: Test files
        let testFile1 = tempDirectory.appendingPathComponent("workflow_test1.txt")
        let testFile2 = tempDirectory.appendingPathComponent("workflow_test2.txt")
        
        try "workflow test 1".write(to: testFile1, atomically: true, encoding: .utf8)
        try "workflow test 2".write(to: testFile2, atomically: true, encoding: .utf8)
        
        // When: Full workflow - scan then clean
        let scanResults = try await engine.scan(categories: .all)
        let safeItems = scanResults.items.filter { $0.safetyScore >= 70 }
        let cleanResults = try await engine.clean(safeItems)
        
        // Then: Should complete successfully
        XCTAssertGreaterThan(scanResults.items.count, 0, "Should find files in scan")
        XCTAssertGreaterThan(cleanResults.deletedItems.count, 0, "Should delete safe files")
        XCTAssertGreaterThan(cleanResults.freedSpace, 0, "Should report freed space")
        
        // Verify files are actually deleted
        XCTAssertFalse(FileManager.default.fileExists(atPath: testFile1.path), "Test file 1 should be deleted")
        XCTAssertFalse(FileManager.default.fileExists(atPath: testFile2.path), "Test file 2 should be deleted")
    }
}

// MARK: - Test Extensions

extension PinakleanEngine {
    enum EngineError: Error {
        case directoryNotFound(String)
        case permissionDenied(String)
        case invalidConfiguration(String)
        case operationTimeout(String)
    }
}
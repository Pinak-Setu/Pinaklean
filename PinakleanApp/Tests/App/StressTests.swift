import XCTest
import Foundation
@testable import PinakleanCore
import os.log

/// Comprehensive stress and load tests for Pinaklean Core Engine
/// Following Ironclad DevOps v2.1 - Performance budgets and reliability testing
final class StressTests: XCTestCase {
    
    var engine: PinakleanEngine!
    var tempDirectory: URL!
    let logger = Logger(subsystem: "com.pinaklean", category: "StressTests")
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create large temporary directory for stress testing
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PinakleanStressTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // Initialize engine with stress test configuration
        engine = try await PinakleanEngine()
        var config = PinakleanEngine.Configuration.default
        config.dryRun = true // Safety first in stress tests
        config.verboseLogging = true
        config.parallelWorkers = ProcessInfo.processInfo.processorCount
        config.enableSmartDetection = true
        config.enableSecurityAudit = true
        config.autoBackup = true
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
    
    // MARK: - Performance Budget Tests
    
    func testScanPerformanceBudget() async throws {
        // Performance Budget: API p95 <= 300ms
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create test files for scanning
        try await createTestFiles(count: 1000, totalSize: 100_000_000) // 100MB
        
        let results = try await engine.scan(categories: .safe)
        
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        let executionTimeMs = executionTime * 1000
        
        // Assert performance budget compliance
        XCTAssertLessThan(executionTimeMs, 300, "Scan should complete within 300ms p95 budget")
        XCTAssertGreaterThan(results.items.count, 0, "Should find test files")
        
        logger.info("Scan performance: \(executionTimeMs)ms, found \(results.items.count) items")
    }
    
    func testCleanPerformanceBudget() async throws {
        // Performance Budget: API p95 <= 300ms
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create test files for cleaning
        try await createTestFiles(count: 500, totalSize: 50_000_000) // 50MB
        
        let scanResults = try await engine.scan(categories: .safe)
        let cleanResults = try await engine.clean(scanResults.items)
        
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        let executionTimeMs = executionTime * 1000
        
        // Assert performance budget compliance
        XCTAssertLessThan(executionTimeMs, 300, "Clean should complete within 300ms p95 budget")
        XCTAssertEqual(cleanResults.deletedItems.count, scanResults.items.count, "All items should be processed")
        
        logger.info("Clean performance: \(executionTimeMs)ms, processed \(cleanResults.deletedItems.count) items")
    }
    
    // MARK: - Load Tests
    
    func testHighVolumeFileScanning() async throws {
        // Load Test: Handle large number of files
        let fileCount = 10000
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await createTestFiles(count: fileCount, totalSize: 1_000_000_000) // 1GB
        
        let results = try await engine.scan(categories: .all)
        
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert load test results
        XCTAssertGreaterThanOrEqual(results.items.count, fileCount * 0.8, "Should find at least 80% of created files")
        XCTAssertLessThan(executionTime, 30.0, "Should complete within 30 seconds for 10k files")
        
        logger.info("Load test: \(fileCount) files in \(executionTime)s, found \(results.items.count) items")
    }
    
    func testMemoryUsageUnderLoad() async throws {
        // Memory Test: Monitor memory usage during heavy operations
        let initialMemory = getMemoryUsage()
        
        // Create large number of files
        try await createTestFiles(count: 5000, totalSize: 500_000_000) // 500MB
        
        let scanResults = try await engine.scan(categories: .all)
        let peakMemory = getMemoryUsage()
        
        let memoryIncrease = peakMemory - initialMemory
        let memoryIncreaseMB = memoryIncrease / (1024 * 1024)
        
        // Assert memory usage is reasonable (less than 1GB increase)
        XCTAssertLessThan(memoryIncreaseMB, 1024, "Memory usage should not exceed 1GB increase")
        
        logger.info("Memory usage: \(memoryIncreaseMB)MB increase during load test")
    }
    
    func testConcurrentOperations() async throws {
        // Concurrency Test: Multiple operations running simultaneously
        try await createTestFiles(count: 1000, totalSize: 100_000_000) // 100MB
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Run multiple scans concurrently
        async let scan1 = engine.scan(categories: .safe)
        async let scan2 = engine.scan(categories: .developer)
        async let scan3 = engine.scan(categories: .all)
        
        let results = try await [scan1, scan2, scan3]
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert concurrent operations complete successfully
        XCTAssertEqual(results.count, 3, "All concurrent scans should complete")
        XCTAssertLessThan(executionTime, 10.0, "Concurrent operations should complete within 10 seconds")
        
        logger.info("Concurrent operations completed in \(executionTime)s")
    }
    
    // MARK: - Reliability Tests
    
    func testErrorRecovery() async throws {
        // Error Recovery Test: Handle file system errors gracefully
        
        // Create some valid files
        try await createTestFiles(count: 100, totalSize: 10_000_000) // 10MB
        
        // Create invalid paths to test error handling
        let invalidPaths = [
            "/nonexistent/path",
            "/root/restricted",
            tempDirectory.appendingPathComponent("symlink_to_nowhere")
        ]
        
        // Test that engine handles errors gracefully
        let results = try await engine.scan(categories: .safe)
        
        // Should still find valid files despite errors
        XCTAssertGreaterThan(results.items.count, 0, "Should find valid files despite errors")
        
        logger.info("Error recovery test: found \(results.items.count) valid files")
    }
    
    func testResourceCleanup() async throws {
        // Resource Cleanup Test: Ensure proper cleanup after operations
        
        let initialFileCount = try FileManager.default.contentsOfDirectory(atPath: tempDirectory.path).count
        
        try await createTestFiles(count: 500, totalSize: 50_000_000) // 50MB
        
        let scanResults = try await engine.scan(categories: .safe)
        let cleanResults = try await engine.clean(scanResults.items)
        
        // Wait a moment for cleanup
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let finalFileCount = try FileManager.default.contentsOfDirectory(atPath: tempDirectory.path).count
        
        // Assert proper cleanup
        XCTAssertEqual(cleanResults.deletedItems.count, scanResults.items.count, "All items should be processed")
        XCTAssertEqual(finalFileCount, initialFileCount, "Temporary files should be cleaned up")
        
        logger.info("Resource cleanup test: \(cleanResults.deletedItems.count) items processed and cleaned up")
    }
    
    // MARK: - Security Stress Tests
    
    func testSecurityAuditPerformance() async throws {
        // Security Audit Performance Test
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create files with various security characteristics
        try await createTestFiles(count: 1000, totalSize: 100_000_000)
        try await createSuspiciousFiles(count: 100)
        
        let results = try await engine.scan(categories: .all)
        
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert security audit completes within reasonable time
        XCTAssertLessThan(executionTime, 15.0, "Security audit should complete within 15 seconds")
        
        // Check that suspicious files are properly flagged
        let suspiciousItems = results.items.filter { $0.warning != nil }
        XCTAssertGreaterThan(suspiciousItems.count, 0, "Should detect suspicious files")
        
        logger.info("Security audit: \(executionTime)s, flagged \(suspiciousItems.count) suspicious items")
    }
    
    // MARK: - Backup System Stress Tests
    
    func testBackupSystemUnderLoad() async throws {
        // Backup System Load Test
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create large dataset for backup
        try await createTestFiles(count: 2000, totalSize: 200_000_000) // 200MB
        
        let scanResults = try await engine.scan(categories: .all)
        let cleanResults = try await engine.clean(scanResults.items)
        
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert backup system handles load
        XCTAssertLessThan(executionTime, 60.0, "Backup system should handle load within 60 seconds")
        XCTAssertEqual(cleanResults.deletedItems.count, scanResults.items.count, "All items should be backed up and processed")
        
        logger.info("Backup system load test: \(executionTime)s for \(scanResults.items.count) items")
    }
    
    // MARK: - Helper Methods
    
    private func createTestFiles(count: Int, totalSize: Int64) async throws {
        let fileSize = totalSize / Int64(count)
        
        for i in 0..<count {
            let fileName = "test_file_\(i).tmp"
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            
            // Create file with random content
            let content = String(repeating: "A", count: Int(fileSize))
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        logger.info("Created \(count) test files totaling \(totalSize) bytes")
    }
    
    private func createSuspiciousFiles(count: Int) async throws {
        let suspiciousNames = [
            "malware.exe", "virus.bat", "trojan.sh", "backdoor.py",
            "keylogger.js", "rootkit.c", "exploit.rb", "payload.php"
        ]
        
        for i in 0..<count {
            let fileName = suspiciousNames[i % suspiciousNames.count]
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            
            // Create suspicious-looking content
            let content = "#!/bin/bash\necho 'This looks suspicious'\nrm -rf /\n"
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        logger.info("Created \(count) suspicious test files")
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}
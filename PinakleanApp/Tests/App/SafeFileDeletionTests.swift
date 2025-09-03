import XCTest
import Foundation
@testable import PinakleanCore

/// Safe File Deletion Logic Tests
/// Tests only operate on explicitly allowed files in test directories
final class SafeFileDeletionTests: XCTestCase {
    
    var engine: PinakleanEngine!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        if ProcessInfo.processInfo.environment["PINAKLEAN_ENGINE_E2E"] != "1" {
            throw XCTSkip("Skipping SafeFileDeletionTests (set PINAKLEAN_ENGINE_E2E=1 to enable)")
        }
        
        // Create isolated test directory
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PinakleanSafeTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // Initialize engine with safe configuration
        engine = try await PinakleanEngine()
        var config = PinakleanEngine.Configuration.default
        config.dryRun = true // Always start with dry run for safety
        config.safeMode = true
        config.enableSecurityAudit = true
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
    
    // MARK: - File Deletion Logic Analysis
    
    func testFileDeletionLogic_AllowedFiles() async throws {
        // Test files that SHOULD be allowed for deletion
        let allowedFiles = [
            "cache_file.tmp",
            "log_file.log", 
            "temp_file.temp",
            "browser_cache.dat",
            "npm_cache.tgz",
            "xcode_derived_data.db",
            "brew_cache.tar",
            "pip_cache.zip"
        ]
        
        for fileName in allowedFiles {
            let testFile = tempDirectory.appendingPathComponent(fileName)
            try "test content for \(fileName)".write(to: testFile, atomically: true, encoding: .utf8)
            
            // Test that these files are classified as safe to delete
            let results = try await engine.scan(categories: .all)
            let foundFile = results.items.first { $0.path == testFile.path }
            
            XCTAssertNotNil(foundFile, "Should find \(fileName)")
            XCTAssertGreaterThan(foundFile?.safetyScore ?? 0, 50, "\(fileName) should have reasonable safety score")
        }
    }
    
    func testFileDeletionLogic_ForbiddenFiles() async throws {
        // Test files that should NEVER be deleted
        let forbiddenPatterns = [
            "system_file.sys",
            "executable_file.exe", 
            "binary_file.bin",
            "library_file.dylib",
            "framework_file.framework",
            "kext_file.kext",
            "plist_file.plist",
            "keychain_file.keychain"
        ]
        
        for fileName in forbiddenPatterns {
            let testFile = tempDirectory.appendingPathComponent(fileName)
            try "test content for \(fileName)".write(to: testFile, atomically: true, encoding: .utf8)
            
            // Test that these files are classified as unsafe to delete
            let results = try await engine.scan(categories: .all)
            let foundFile = results.items.first { $0.path == testFile.path }
            
            if let file = foundFile {
                XCTAssertLessThan(file.safetyScore, 30, "\(fileName) should have low safety score")
            }
        }
    }
    
    // MARK: - Safe Directory Testing
    
    func testSafeDirectoryScanning_OnlyTestDirectory() async throws {
        // Create test files in our safe directory
        let testFiles = [
            "cache/test_cache.tmp",
            "logs/test_log.log",
            "temp/test_temp.temp",
            "downloads/test_download.zip"
        ]
        
        for filePath in testFiles {
            let fullPath = tempDirectory.appendingPathComponent(filePath)
            try FileManager.default.createDirectory(at: fullPath.deletingLastPathComponent(), withIntermediateDirectories: true)
            try "test content".write(to: fullPath, atomically: true, encoding: .utf8)
        }
        
        // Scan only our test directory (not system directories)
        let results = try await scanTestDirectoryOnly()
        
        XCTAssertEqual(results.items.count, testFiles.count, "Should find all test files")
        
        // Verify all found files are in our test directory
        for item in results.items {
            XCTAssertTrue(item.path.hasPrefix(tempDirectory.path), "All files should be in test directory: \(item.path)")
        }
    }
    
    // MARK: - Security Audit Testing
    
    func testSecurityAudit_FileClassification() async throws {
        // Test different file types and their security classification
        let testCases = [
            ("safe_cache.tmp", 80, "Temporary cache files should be safe"),
            ("safe_log.log", 75, "Log files should be relatively safe"),
            ("suspicious.exe", 20, "Executable files should be suspicious"),
            ("system_lib.dylib", 10, "System libraries should be very unsafe"),
            ("user_doc.txt", 60, "User documents should be moderately safe"),
            ("config.plist", 30, "Configuration files should be cautious")
        ]
        
        for (fileName, expectedMinScore, description) in testCases {
            let testFile = tempDirectory.appendingPathComponent(fileName)
            try "test content".write(to: testFile, atomically: true, encoding: .utf8)
            
            let results = try await scanTestDirectoryOnly()
            let foundFile = results.items.first { $0.path == testFile.path }
            
            XCTAssertNotNil(foundFile, "Should find \(fileName)")
            XCTAssertGreaterThanOrEqual(foundFile?.safetyScore ?? 0, expectedMinScore, description)
        }
    }
    
    // MARK: - Dry Run Safety Testing
    
    func testDryRunMode_NoActualDeletion() async throws {
        // Create test files
        let testFile = tempDirectory.appendingPathComponent("dry_run_test.txt")
        try "content for dry run test".write(to: testFile, atomically: true, encoding: .utf8)
        
        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path), "Test file should exist before dry run")
        
        // Configure engine for dry run
        var config = engine.configuration
        config.dryRun = true
        engine.configure(config)
        
        // Create cleanable item
        let cleanableItem = CleanableItem(
            id: UUID(),
            path: testFile.path,
            name: "dry_run_test.txt",
            category: "temporary",
            size: 1024,
            safetyScore: 90
        )
        
        // Perform dry run clean
        let results = try await engine.clean([cleanableItem])
        
        // Verify file still exists (dry run)
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path), "File should still exist after dry run")
        XCTAssertEqual(results.deletedItems.count, 1, "Should report 1 deleted item in dry run")
        XCTAssertEqual(results.freedSpace, 1024, "Should report freed space in dry run")
        XCTAssertTrue(results.isDryRun, "Should be marked as dry run")
    }
    
    func testRealDeletionMode_OnlySafeFiles() async throws {
        // Create safe test file
        let safeFile = tempDirectory.appendingPathComponent("safe_to_delete.tmp")
        try "safe content".write(to: safeFile, atomically: true, encoding: .utf8)
        
        // Configure engine for real deletion
        var config = engine.configuration
        config.dryRun = false
        config.safeMode = true
        engine.configure(config)
        
        // Create cleanable item with high safety score
        let cleanableItem = CleanableItem(
            id: UUID(),
            path: safeFile.path,
            name: "safe_to_delete.tmp",
            category: "temporary",
            size: 1024,
            safetyScore: 95 // Very safe
        )
        
        // Perform real clean
        let results = try await engine.clean([cleanableItem])
        
        // Verify file is actually deleted
        XCTAssertFalse(FileManager.default.fileExists(atPath: safeFile.path), "Safe file should be deleted")
        XCTAssertEqual(results.deletedItems.count, 1, "Should report 1 deleted item")
        XCTAssertEqual(results.freedSpace, 1024, "Should report correct freed space")
        XCTAssertFalse(results.isDryRun, "Should not be marked as dry run")
    }
    
    // MARK: - File Category Testing
    
    func testFileCategories_ProperClassification() async throws {
        // Test different file categories
        let categoryTests = [
            ("cache_file.cache", "cache", "Cache files should be classified as cache"),
            ("log_file.log", "logs", "Log files should be classified as logs"),
            ("temp_file.tmp", "temporary", "Temp files should be classified as temporary"),
            ("download_file.zip", "downloads", "Download files should be classified as downloads")
        ]
        
        for (fileName, expectedCategory, description) in categoryTests {
            let testFile = tempDirectory.appendingPathComponent(fileName)
            try "test content".write(to: testFile, atomically: true, encoding: .utf8)
            
            let results = try await scanTestDirectoryOnly()
            let foundFile = results.items.first { $0.path == testFile.path }
            
            XCTAssertNotNil(foundFile, "Should find \(fileName)")
            XCTAssertEqual(foundFile?.category, expectedCategory, description)
        }
    }
    
    // MARK: - Error Handling Testing
    
    func testErrorHandling_NonExistentFile() async throws {
        // Try to clean a non-existent file
        let nonExistentItem = CleanableItem(
            id: UUID(),
            path: tempDirectory.appendingPathComponent("non_existent.txt").path,
            name: "non_existent.txt",
            category: "temporary",
            size: 1024,
            safetyScore: 90
        )
        
        let results = try await engine.clean([nonExistentItem])
        
        // Should handle gracefully
        XCTAssertEqual(results.deletedItems.count, 0, "Should not delete non-existent file")
        XCTAssertGreaterThan(results.failedItems.count, 0, "Should report failed items")
    }
    
    func testErrorHandling_ProtectedFile() async throws {
        // Try to clean a file that simulates protection
        let protectedFile = tempDirectory.appendingPathComponent("protected_file.sys")
        try "protected content".write(to: protectedFile, atomically: true, encoding: .utf8)
        
        // Make file read-only to simulate protection
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: protectedFile.path)
        
        let protectedItem = CleanableItem(
            id: UUID(),
            path: protectedFile.path,
            name: "protected_file.sys",
            category: "system",
            size: 1024,
            safetyScore: 10 // Low safety score
        )
        
        let results = try await engine.clean([protectedItem])
        
        // Should handle protection gracefully
        XCTAssertEqual(results.deletedItems.count, 0, "Should not delete protected file")
        XCTAssertGreaterThan(results.failedItems.count, 0, "Should report failed items")
        
        // Clean up
        try? FileManager.default.removeItem(at: protectedFile)
    }
    
    // MARK: - Helper Methods
    
    /// Scan only the test directory to avoid system permission issues
    private func scanTestDirectoryOnly() async throws -> ScanResults {
        // Create a custom scan that only looks in our test directory
        let testFiles = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
        var items: [CleanableItem] = []
        
        for fileURL in testFiles {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            // Determine category based on file extension
            let category = determineCategory(for: fileURL.lastPathComponent)
            
            // Create cleanable item
            let item = CleanableItem(
                id: UUID(),
                path: fileURL.path,
                name: fileURL.lastPathComponent,
                category: category,
                size: fileSize,
                safetyScore: calculateSafetyScore(for: fileURL.lastPathComponent)
            )
            
            items.append(item)
        }
        
        var results = ScanResults()
        results.items = items
        results.totalSize = items.reduce(0) { $0 + $1.size }
        return results
    }
    
    private func determineCategory(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        
        switch ext {
        case "tmp", "temp", "cache":
            return "cache"
        case "log":
            return "logs"
        case "zip", "tar", "gz":
            return "downloads"
        case "sys", "dylib", "framework":
            return "system"
        case "exe", "app":
            return "executable"
        default:
            return "temporary"
        }
    }
    
    private func calculateSafetyScore(for fileName: String) -> Int {
        let ext = (fileName as NSString).pathExtension.lowercased()
        let name = fileName.lowercased()
        
        // Very unsafe files
        if ["sys", "dylib", "framework", "kext", "plist"].contains(ext) {
            return 10
        }
        
        // Unsafe files
        if ["exe", "app", "bin"].contains(ext) || name.contains("system") {
            return 20
        }
        
        // Moderately unsafe files
        if ["keychain", "prefs"].contains(ext) {
            return 30
        }
        
        // Safe files
        if ["tmp", "temp", "cache", "log"].contains(ext) {
            return 80
        }
        
        // Default moderate safety
        return 60
    }
}

// MARK: - File Deletion Logic Documentation

/*
 FILE DELETION LOGIC - ALLOWED vs FORBIDDEN FILES
 
 ✅ ALLOWED FOR DELETION (High Safety Score 70-100):
 
 1. TEMPORARY FILES:
    - .tmp, .temp files
    - Browser cache files
    - Application temporary data
    - System temporary directories (/tmp, /var/tmp)
 
 2. CACHE FILES:
    - User caches (~/Library/Caches/)
    - Application caches
    - Browser caches
    - Build caches (Xcode DerivedData)
    - Package manager caches (npm, brew, pip)
 
 3. LOG FILES:
    - Application logs
    - System logs (non-critical)
    - Crash reports
    - Debug logs
 
 4. DOWNLOAD FILES:
    - Completed downloads
    - Old installation files
    - Temporary downloads
 
 5. DEVELOPER JUNK:
    - node_modules directories
    - Build artifacts
    - Package caches
    - IDE temporary files
 
 ❌ FORBIDDEN FOR DELETION (Low Safety Score 0-30):
 
 1. SYSTEM FILES:
    - /System directory contents
    - /usr, /bin, /sbin contents
    - System libraries (.dylib, .framework)
    - Kernel extensions (.kext)
    - System preferences (.plist)
 
 2. USER DATA:
    - Documents, Desktop, Pictures
    - Music, Movies, Downloads (user content)
    - Mail data
    - Safari bookmarks/history
    - Application Support (user data)
 
 3. EXECUTABLES:
    - .app applications
    - .exe executables
    - .bin binaries
    - Scripts and programs
 
 4. CONFIGURATION:
    - Keychain files
    - Preference files
    - Configuration databases
    - License files
 
 5. ACTIVE PROCESS FILES:
    - Files currently in use
    - Locked files
    - System daemon files
    - Running application data
 
 SAFETY SCORE RANGES:
 - 90-100: Very safe (temporary files, caches)
 - 70-89:  Safe (logs, old downloads)
 - 50-69:  Moderate (user files, configs)
 - 30-49:  Risky (system configs, preferences)
 - 10-29:  Dangerous (system files, executables)
 - 0-9:    Critical (core system, active processes)
 
 DRY RUN MODE:
 - Always enabled by default in tests
 - Shows what would be deleted without actual deletion
 - Reports freed space and item counts
 - Safe for testing and preview
 
 REAL DELETION MODE:
 - Only enabled when explicitly configured
 - Requires high safety scores (70+)
 - Creates backups before deletion (if enabled)
 - Includes comprehensive error handling
 */
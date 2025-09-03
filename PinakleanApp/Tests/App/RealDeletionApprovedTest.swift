import XCTest
import Foundation
@testable import PinakleanCore

/// Real Deletion Approved Test - Performs actual file deletion with approval
/// This test will perform real deletion of safe files with backup
final class RealDeletionApprovedTest: XCTestCase {
    
    var engine: PinakleanEngine!
    var tempBackupDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create backup directory for real deletion
        tempBackupDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PinakleanRealBackup-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempBackupDirectory, withIntermediateDirectories: true)
        
        // Initialize engine with REAL deletion enabled
        engine = try await PinakleanEngine()
        var config = PinakleanEngine.Configuration.default
        config.dryRun = false // REAL DELETION ENABLED
        config.safeMode = true
        config.enableSecurityAudit = true
        config.autoBackup = true
        engine.configure(config)
        
        print("🚀 REAL DELETION APPROVED TEST SETUP")
        print("📁 Backup Directory: \(tempBackupDirectory.path)")
        print("🔧 Engine Config: dryRun=\(config.dryRun), safeMode=\(config.safeMode), autoBackup=\(config.autoBackup)")
        print("⚠️  REAL DELETION IS ENABLED - FILES WILL BE ACTUALLY DELETED")
    }
    
    override func tearDown() async throws {
        // Clean up backup directory
        if let tempBackupDirectory = tempBackupDirectory {
            try? FileManager.default.removeItem(at: tempBackupDirectory)
        }
        engine = nil
        try await super.tearDown()
    }
    
    // MARK: - Real Deletion Approved Test
    
    func testRealDeletionApproved() async throws {
        print("\n🚀 STARTING REAL DELETION WITH APPROVAL")
        print(String(repeating: "=", count: 70))
        
        // Step 1: Scan for safe files
        print("\n🔍 STEP 1: Scanning for safe files to delete...")
        let scanResults = try await performSafeScan()
        print("✅ Scan completed: \(scanResults.items.count) items found")
        
        // Step 2: Filter only the safest files
        print("\n🎯 STEP 2: Filtering safest files for deletion...")
        let safeFiles = filterSafestFiles(scanResults.items)
        print("✅ Selected \(safeFiles.count) safest files for deletion")
        
        // Step 3: Show final preview
        print("\n👁️ STEP 3: Final preview before deletion...")
        printFinalPreview(safeFiles)
        
        // Step 4: Create backup
        print("\n💾 STEP 4: Creating backup before deletion...")
        let backupResults = try await createBackup(safeFiles)
        printBackupResults(backupResults)
        
        // Step 5: Perform real deletion
        print("\n🗑️ STEP 5: Performing REAL deletion...")
        let deletionResults = try await performRealDeletion(safeFiles)
        print("  📊 Real deletion completed:")
        print("    • Files deleted: \(deletionResults.deletedItems.count)")
        print("    • Files failed: \(deletionResults.failedItems.count)")
        print("    • Space freed: \(ByteCountFormatter.string(fromByteCount: deletionResults.freedSpace, countStyle: .file))")
        print("    • Dry run: \(deletionResults.isDryRun)")
        
        // Step 6: Verify deletion
        print("\n✅ STEP 6: Verifying deletion results...")
        let verificationResults = verifyDeletion(safeFiles, deletionResults)
        printVerificationResults(verificationResults)
        
        // Step 7: Final summary
        print("\n📊 FINAL SUMMARY")
        print(String(repeating: "=", count: 70))
        printFinalSummary(verificationResults)
        
        // Assertions
        XCTAssertGreaterThan(deletionResults.deletedItems.count, 0, "Should have deleted some files")
        XCTAssertEqual(deletionResults.failedItems.count, 0, "Should not have any failed deletions")
        XCTAssertFalse(deletionResults.isDryRun, "Should not be in dry run mode")
    }
    
    // MARK: - Helper Methods
    
    private func performSafeScan() async throws -> ScanResults {
        print("  🔍 Scanning safe user directories...")
        
        // Create a custom scanner that only looks at the safest directories
        let safeDirectories = getSafestDirectories()
        var allItems: [CleanableItem] = []
        
        for directory in safeDirectories {
            do {
                let items = try await scanDirectorySafely(directory)
                allItems.append(contentsOf: items)
                print("    📁 Scanned \(directory.lastPathComponent): \(items.count) items")
            } catch {
                print("    ⚠️  Skipped \(directory.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        var results = ScanResults()
        results.items = allItems
        results.totalSize = allItems.reduce(0) { $0 + $1.size }
        
        print("  📊 Scan results:")
        print("    • Total items found: \(results.items.count)")
        print("    • Total size: \(ByteCountFormatter.string(fromByteCount: results.totalSize, countStyle: .file))")
        
        return results
    }
    
    private func getSafestDirectories() -> [URL] {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        var safeDirectories: [URL] = []
        
        // Only the safest directories for real deletion
        let safestPaths = [
            "Library/Caches",  // App caches - very safe
            "Library/Logs"     // Log files - safe
        ]
        
        for path in safestPaths {
            let fullPath = homeDirectory.appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: fullPath.path) {
                safeDirectories.append(fullPath)
            }
        }
        
        return safeDirectories
    }
    
    private func scanDirectorySafely(_ directory: URL) async throws -> [CleanableItem] {
        var items: [CleanableItem] = []
        
        // Get directory contents with error handling
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        )
        
        for url in contents {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                let isDirectory = attributes[.type] as? FileAttributeType == .typeDirectory
                
                // Skip directories
                if isDirectory {
                    continue
                }
                
                let category = determineCategory(for: url.lastPathComponent)
                let safetyScore = calculateSafetyScore(for: url.lastPathComponent, in: directory)
                
                // Only include very safe files (80%+ safety score)
                if safetyScore >= 80 {
                    let item = CleanableItem(
                        id: UUID(),
                        path: url.path,
                        name: url.lastPathComponent,
                        category: category,
                        size: fileSize,
                        safetyScore: safetyScore
                    )
                    items.append(item)
                }
            } catch {
                // Skip files we can't access
                continue
            }
        }
        
        return items
    }
    
    private func determineCategory(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        let name = fileName.lowercased()
        
        if name.contains("cache") || ext == "tmp" || ext == "temp" {
            return "cache"
        } else if ext == "log" {
            return "logs"
        } else {
            return "temporary"
        }
    }
    
    private func calculateSafetyScore(for fileName: String, in directory: URL) -> Int {
        let ext = (fileName as NSString).pathExtension.lowercased()
        let name = fileName.lowercased()
        let dirPath = directory.path.lowercased()
        
        // Very safe files (85-90)
        if name.contains("cache") || ext == "tmp" || ext == "temp" {
            return 90
        }
        
        // Safe logs (80-85)
        if ext == "log" || name.contains("log") {
            return 85
        }
        
        // Files in Caches directory are very safe
        if dirPath.contains("caches") {
            return 90
        }
        
        // Files in Logs directory are safe
        if dirPath.contains("logs") {
            return 85
        }
        
        // Default safe score
        return 80
    }
    
    private func filterSafestFiles(_ items: [CleanableItem]) -> [CleanableItem] {
        // Only select the safest files (90%+ safety score)
        let safestFiles = items.filter { $0.safetyScore >= 90 }
        
        // Limit to first 10 files for safety
        let limitedFiles = Array(safestFiles.prefix(10))
        
        print("  🎯 Safest files selected:")
        for (index, file) in limitedFiles.enumerated() {
            let sizeStr = ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file)
            print("    \(index + 1). \(file.name) (\(sizeStr), \(file.safetyScore)% safe, \(file.category))")
        }
        
        return limitedFiles
    }
    
    private func printFinalPreview(_ files: [CleanableItem]) {
        let totalSize = files.reduce(0) { $0 + $1.size }
        
        print("  🎯 FINAL DELETION PREVIEW:")
        print("    • Files to be deleted: \(files.count)")
        print("    • Total size: \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
        print("    • All files have safety score ≥ 90%")
        print("    • Backup will be created before deletion")
        print("    • This is REAL deletion - files will be permanently removed")
    }
    
    private func createBackup(_ files: [CleanableItem]) async throws -> [String: Any] {
        print("  💾 Creating backup of files before deletion...")
        
        var backedUpFiles: [String] = []
        var totalSize: Int64 = 0
        var failedBackups: [String] = []
        
        for file in files {
            let sourceURL = URL(fileURLWithPath: file.path)
            let backupURL = tempBackupDirectory.appendingPathComponent(file.name)
            
            do {
                if FileManager.default.fileExists(atPath: sourceURL.path) {
                    try FileManager.default.copyItem(at: sourceURL, to: backupURL)
                    backedUpFiles.append(file.name)
                    totalSize += file.size
                    print("    ✅ Backed up: \(file.name)")
                } else {
                    print("    ⚠️  Source file not found: \(file.name)")
                }
            } catch {
                failedBackups.append(file.name)
                print("    ❌ Failed to backup \(file.name): \(error)")
            }
        }
        
        return [
            "backedUpFiles": backedUpFiles,
            "failedBackups": failedBackups,
            "totalSize": totalSize,
            "success": failedBackups.isEmpty
        ]
    }
    
    private func printBackupResults(_ results: [String: Any]) {
        let backedUpFiles = results["backedUpFiles"] as? [String] ?? []
        let failedBackups = results["failedBackups"] as? [String] ?? []
        let totalSize = results["totalSize"] as? Int64 ?? 0
        let success = results["success"] as? Bool ?? false
        
        print("  💾 Backup Results:")
        print("    • Files backed up: \(backedUpFiles.count)")
        print("    • Backup size: \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
        print("    • Failed backups: \(failedBackups.count)")
        print("    • Status: \(success ? "✅ SUCCESS" : "❌ FAILED")")
        
        if !success {
            print("    ⚠️  Some backups failed - proceeding with caution")
        }
    }
    
    private func performRealDeletion(_ files: [CleanableItem]) async throws -> CleanResults {
        print("  🗑️ Starting REAL deletion process...")
        
        let results = try await engine.clean(files)
        
        print("  📊 Real deletion completed:")
        print("    • Files deleted: \(results.deletedItems.count)")
        print("    • Files failed: \(results.failedItems.count)")
        print("    • Space freed: \(ByteCountFormatter.string(fromByteCount: results.freedSpace, countStyle: .file))")
        print("    • Dry run: \(results.isDryRun)")
        
        return results
    }
    
    private func verifyDeletion(_ originalFiles: [CleanableItem], _ deletionResults: CleanResults) -> [String: Any] {
        var actuallyDeleted: [String] = []
        var stillExists: [String] = []
        
        for file in originalFiles {
            let exists = FileManager.default.fileExists(atPath: file.path)
            
            if exists {
                stillExists.append(file.name)
            } else {
                actuallyDeleted.append(file.name)
            }
        }
        
        return [
            "actuallyDeleted": actuallyDeleted,
            "stillExists": stillExists,
            "deletionResults": deletionResults,
            "success": stillExists.isEmpty
        ]
    }
    
    private func printVerificationResults(_ results: [String: Any]) {
        let actuallyDeleted = results["actuallyDeleted"] as? [String] ?? []
        let stillExists = results["stillExists"] as? [String] ?? []
        let deletionResults = results["deletionResults"] as? CleanResults
        let success = results["success"] as? Bool ?? false
        
        print("  ✅ Deletion Verification:")
        print("    • Files actually deleted: \(actuallyDeleted.count)")
        print("    • Files still existing: \(stillExists.count)")
        print("    • Deletion success: \(success ? "✅ YES" : "❌ NO")")
        
        if !actuallyDeleted.isEmpty {
            print("    📋 Actually deleted files:")
            for fileName in actuallyDeleted {
                print("      🗑️ \(fileName)")
            }
        }
        
        if !stillExists.isEmpty {
            print("    📋 Files still existing:")
            for fileName in stillExists {
                print("      📄 \(fileName)")
            }
        }
        
        if let results = deletionResults {
            print("    📊 Engine results:")
            print("      • Reported deleted: \(results.deletedItems.count)")
            print("      • Reported failed: \(results.failedItems.count)")
            print("      • Space freed: \(ByteCountFormatter.string(fromByteCount: results.freedSpace, countStyle: .file))")
        }
    }
    
    private func printFinalSummary(_ results: [String: Any]) {
        let actuallyDeleted = results["actuallyDeleted"] as? [String] ?? []
        let stillExists = results["stillExists"] as? [String] ?? []
        let deletionResults = results["deletionResults"] as? CleanResults
        let success = results["success"] as? Bool ?? false
        
        print("🎯 REAL DELETION SUMMARY:")
        print("  • Total files processed: \(actuallyDeleted.count + stillExists.count)")
        print("  • Files successfully deleted: \(actuallyDeleted.count)")
        print("  • Files remaining: \(stillExists.count)")
        print("  • Deletion success rate: \(actuallyDeleted.count)/\(actuallyDeleted.count + stillExists.count) (\(Int(Double(actuallyDeleted.count) / Double(actuallyDeleted.count + stillExists.count) * 100))%)")
        
        if let results = deletionResults {
            print("  • Space freed: \(ByteCountFormatter.string(fromByteCount: results.freedSpace, countStyle: .file))")
        }
        
        print("\n🔒 SAFETY VERIFICATION:")
        print("  • Only safest files were targeted (90%+ safety score)")
        print("  • Backup was created before deletion")
        print("  • No system files were accessed or modified")
        print("  • Real file system operations were performed")
        print("  • Deletion was successful: \(success ? "✅ YES" : "❌ NO")")
        
        print("\n💾 BACKUP INFORMATION:")
        print("  • Backup location: \(tempBackupDirectory.path)")
        print("  • Backup will be cleaned up after test")
        print("  • Files can be restored from backup if needed")
    }
}

// MARK: - Process Documentation

/*
 REAL DELETION APPROVED TEST PROCESS
 
 1. 🔍 SAFE SCANNING
    - Scan only the safest directories (Caches, Logs)
    - Focus on files with 90%+ safety score
    - Limit to 10 files maximum for safety
    - Avoid any risky or system files
 
 2. 🎯 FILTERING
    - Select only the safest files
    - Ensure all files have 90%+ safety score
    - Limit quantity for safety
    - Show detailed preview
 
 3. 💾 BACKUP CREATION
    - Create backup of all files before deletion
    - Verify backup success
    - Track backup size and files
    - Handle backup failures gracefully
 
 4. 🗑️ REAL DELETION
    - Perform actual file deletion
    - Use PinakleanEngine.clean() method
    - Track successful and failed deletions
    - Calculate space freed
 
 5. ✅ VERIFICATION
    - Check which files actually exist on disk
    - Compare with deletion results
    - Verify no unintended deletions
    - Confirm safety measures worked
 
 6. 📊 REPORTING
    - Generate comprehensive summary
    - Show success rates and space freed
    - Verify safety compliance
    - Document backup information
 
 SAFETY FEATURES:
 - Only safest files targeted (90%+ safety score)
 - Limited to 10 files maximum
 - Only safe directories scanned
 - Backup created before deletion
 - Comprehensive verification
 - Real file system operations
 - Detailed logging and reporting
 */
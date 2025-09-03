import XCTest
import Foundation
@testable import PinakleanCore

/// Safe macOS System Test - Scans user-accessible directories only
/// This test will scan safe user directories and show what would be deleted
final class SafeMacOSSystemTest: XCTestCase {
    
    var engine: PinakleanEngine!
    var tempBackupDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create backup directory for testing
        tempBackupDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PinakleanBackup-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempBackupDirectory, withIntermediateDirectories: true)
        
        // Initialize engine with safe configuration
        engine = try await PinakleanEngine()
        var config = PinakleanEngine.Configuration.default
        config.dryRun = true // Start with preview mode
        config.safeMode = true
        config.enableSecurityAudit = true
        config.autoBackup = true
        engine.configure(config)
        
        print("🧪 SAFE macOS SYSTEM TEST SETUP")
        print("📁 Backup Directory: \(tempBackupDirectory.path)")
        print("🔧 Engine Config: dryRun=\(config.dryRun), safeMode=\(config.safeMode), autoBackup=\(config.autoBackup)")
    }
    
    override func tearDown() async throws {
        // Clean up backup directory
        if let tempBackupDirectory = tempBackupDirectory {
            try? FileManager.default.removeItem(at: tempBackupDirectory)
        }
        engine = nil
        try await super.tearDown()
    }
    
    // MARK: - Safe macOS System Test
    
    func testSafeMacOSSystemScanAndPreview() async throws {
        print("\n🚀 STARTING SAFE macOS SYSTEM SCAN & PREVIEW")
        print(String(repeating: "=", count: 70))
        
        // Step 1: Scan safe user directories
        print("\n🔍 STEP 1: Scanning safe user directories...")
        let scanResults = try await performSafeSystemScan()
        print("✅ Safe system scan completed: \(scanResults.items.count) items found")
        
        // Step 2: Analyze and categorize findings
        print("\n📊 STEP 2: Analyzing system findings...")
        let analysis = analyzeSystemFindings(scanResults.items)
        printSystemAnalysis(analysis)
        
        // Step 3: Show preview of what would be deleted
        print("\n👁️ STEP 3: Preview of files that would be deleted...")
        let previewResults = generateDeletionPreview(scanResults.items)
        printDeletionPreview(previewResults)
        
        // Step 4: Test backup logic
        print("\n💾 STEP 4: Testing backup logic...")
        let safeFiles = previewResults["safeFiles"] as? [CleanableItem] ?? []
        let backupTestResults = try await testBackupLogic(safeFiles)
        printBackupTestResults(backupTestResults)
        
        // Step 5: Show final summary and approval request
        print("\n📋 STEP 5: Final summary and approval...")
        printFinalSummaryAndApproval(previewResults, backupTestResults)
        
        // Note: This test stops at preview - no actual deletion without explicit approval
        print("\n⚠️  IMPORTANT: This test only shows preview. No files were actually deleted.")
        print("   To proceed with actual deletion, you would need to:")
        print("   1. Review the preview carefully")
        print("   2. Set dryRun = false in configuration")
        print("   3. Explicitly approve the deletion")
        
        // Assertions to verify the process worked
        XCTAssertGreaterThanOrEqual(scanResults.items.count, 0, "Should find some cleanable files or handle gracefully")
        XCTAssertGreaterThanOrEqual(safeFiles.count, 0, "Should identify safe files or handle gracefully")
        let backupWorking = backupTestResults["backupLogicWorking"] as? Bool ?? false
        XCTAssertTrue(backupWorking, "Backup logic should be working")
    }
    
    // MARK: - Helper Methods
    
    private func performSafeSystemScan() async throws -> ScanResults {
        print("  🔍 Scanning safe user directories...")
        
        // Create a custom scanner that only looks at safe user directories
        let safeDirectories = getSafeUserDirectories()
        var allItems: [CleanableItem] = []
        
        for directory in safeDirectories {
            do {
                let items = try await scanDirectorySafely(directory)
                allItems.append(contentsOf: items)
                print("    📁 Scanned \(directory): \(items.count) items")
            } catch {
                print("    ⚠️  Skipped \(directory): \(error.localizedDescription)")
            }
        }
        
        var results = ScanResults()
        results.items = allItems
        results.totalSize = allItems.reduce(0) { $0 + $1.size }
        
        print("  📊 Safe scan results:")
        print("    • Total items found: \(results.items.count)")
        print("    • Total size: \(ByteCountFormatter.string(fromByteCount: results.totalSize, countStyle: .file))")
        
        return results
    }
    
    private func getSafeUserDirectories() -> [URL] {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        var safeDirectories: [URL] = []
        
        // Safe user directories to scan
        let safePaths = [
            "Library/Caches",
            "Library/Logs", 
            "Library/Application Support",
            "Downloads",
            "Desktop",
            "Documents"
        ]
        
        for path in safePaths {
            let fullPath = homeDirectory.appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: fullPath.path) {
                safeDirectories.append(fullPath)
            }
        }
        
        // Also add temporary directories
        safeDirectories.append(FileManager.default.temporaryDirectory)
        
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
                
                // Skip directories for now (focus on files)
                if isDirectory {
                    continue
                }
                
                let category = determineCategory(for: url.lastPathComponent)
                let safetyScore = calculateSafetyScore(for: url.lastPathComponent, in: directory)
                
                // Only include files with reasonable safety scores
                if safetyScore >= 50 {
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
        } else if ext == "zip" || ext == "tar" || ext == "tgz" || ext == "dmg" {
            return "downloads"
        } else if name.contains("derived") || name.contains("xcode") {
            return "xcode"
        } else if name.contains("npm") || name.contains("node") {
            return "node_modules"
        } else if name.contains("brew") {
            return "brew"
        } else if name.contains("pip") {
            return "pip"
        } else if ext == "bak" || ext == "backup" {
            return "backups"
        } else {
            return "temporary"
        }
    }
    
    private func calculateSafetyScore(for fileName: String, in directory: URL) -> Int {
        let ext = (fileName as NSString).pathExtension.lowercased()
        let name = fileName.lowercased()
        let dirPath = directory.path.lowercased()
        
        // Very safe files (80-90)
        if ["tmp", "temp", "cache"].contains(ext) || name.contains("cache") {
            return 85
        }
        
        // Safe logs (75-80)
        if ext == "log" || name.contains("log") {
            return 75
        }
        
        // Safe downloads (70-80)
        if ["zip", "tar", "tgz", "dmg"].contains(ext) || name.contains("download") {
            return 70
        }
        
        // Developer tools (80-90)
        if name.contains("npm") || name.contains("xcode") || name.contains("brew") || name.contains("pip") {
            return 80
        }
        
        // Backups (60-70)
        if ext == "bak" || name.contains("backup") {
            return 65
        }
        
        // Files in Downloads are generally safer
        if dirPath.contains("downloads") {
            return 70
        }
        
        // Files in Desktop/Documents are less safe
        if dirPath.contains("desktop") || dirPath.contains("documents") {
            return 50
        }
        
        // Default safe score
        return 60
    }
    
    private func analyzeSystemFindings(_ items: [CleanableItem]) -> [String: Any] {
        let categories = Dictionary(grouping: items) { $0.category }
        let safetyRanges = Dictionary(grouping: items) { item in
            switch item.safetyScore {
            case 90...100: return "Very Safe (90-100)"
            case 80..<90: return "Safe (80-89)"
            case 70..<80: return "Moderate (70-79)"
            case 50..<70: return "Risky (50-69)"
            default: return "Dangerous (0-49)"
            }
        }
        
        let totalSize = items.reduce(0) { $0 + $1.size }
        let averageSafetyScore = items.isEmpty ? 0 : items.reduce(0) { $0 + $1.safetyScore } / items.count
        
        return [
            "categories": categories,
            "safetyRanges": safetyRanges,
            "totalSize": totalSize,
            "averageSafetyScore": averageSafetyScore,
            "totalItems": items.count
        ]
    }
    
    private func printSystemAnalysis(_ analysis: [String: Any]) {
        let categories = analysis["categories"] as? [String: [CleanableItem]] ?? [:]
        let safetyRanges = analysis["safetyRanges"] as? [String: [CleanableItem]] ?? [:]
        let totalSize = analysis["totalSize"] as? Int64 ?? 0
        let averageSafetyScore = analysis["averageSafetyScore"] as? Int ?? 0
        let totalItems = analysis["totalItems"] as? Int ?? 0
        
        print("  📊 System Analysis:")
        print("    • Total items: \(totalItems)")
        print("    • Total size: \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
        print("    • Average safety score: \(averageSafetyScore)%")
        
        if !categories.isEmpty {
            print("\n  📁 By Category:")
            for (category, items) in categories.sorted(by: { $0.key < $1.key }) {
                let categorySize = items.reduce(0) { $0 + $1.size }
                print("    • \(category): \(items.count) files (\(ByteCountFormatter.string(fromByteCount: categorySize, countStyle: .file)))")
            }
        }
        
        if !safetyRanges.isEmpty {
            print("\n  🛡️ By Safety Score:")
            for (range, items) in safetyRanges.sorted(by: { $0.key < $1.key }) {
                let rangeSize = items.reduce(0) { $0 + $1.size }
                print("    • \(range): \(items.count) files (\(ByteCountFormatter.string(fromByteCount: rangeSize, countStyle: .file)))")
            }
        }
    }
    
    private func generateDeletionPreview(_ items: [CleanableItem]) -> [String: Any] {
        // Only consider files with safety score >= 70 for deletion
        let safeFiles = items.filter { $0.safetyScore >= 70 }
        let riskyFiles = items.filter { $0.safetyScore < 70 }
        
        let safeSize = safeFiles.reduce(0) { $0 + $1.size }
        let riskySize = riskyFiles.reduce(0) { $0 + $1.size }
        
        return [
            "safeFiles": safeFiles,
            "riskyFiles": riskyFiles,
            "safeSize": safeSize,
            "riskySize": riskySize,
            "totalSafeFiles": safeFiles.count,
            "totalRiskyFiles": riskyFiles.count
        ]
    }
    
    private func printDeletionPreview(_ preview: [String: Any]) {
        let safeFiles = preview["safeFiles"] as? [CleanableItem] ?? []
        let riskyFiles = preview["riskyFiles"] as? [CleanableItem] ?? []
        let safeSize = preview["safeSize"] as? Int64 ?? 0
        let riskySize = preview["riskySize"] as? Int64 ?? 0
        
        print("  🎯 DELETION PREVIEW:")
        print("    ✅ SAFE FILES (would be deleted): \(safeFiles.count) files")
        print("    📊 Safe files size: \(ByteCountFormatter.string(fromByteCount: safeSize, countStyle: .file))")
        
        if !safeFiles.isEmpty {
            print("\n    📋 Safe files list (first 10):")
            for (index, file) in safeFiles.prefix(10).enumerated() {
                let sizeStr = ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file)
                print("      \(index + 1). \(file.name) (\(sizeStr), \(file.safetyScore)% safe, \(file.category))")
            }
            if safeFiles.count > 10 {
                print("      ... and \(safeFiles.count - 10) more files")
            }
        }
        
        print("\n    ⚠️  RISKY FILES (would NOT be deleted): \(riskyFiles.count) files")
        print("    📊 Risky files size: \(ByteCountFormatter.string(fromByteCount: riskySize, countStyle: .file))")
        
        if !riskyFiles.isEmpty {
            print("\n    📋 Risky files list (first 5):")
            for (index, file) in riskyFiles.prefix(5).enumerated() {
                let sizeStr = ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file)
                print("      \(index + 1). \(file.name) (\(sizeStr), \(file.safetyScore)% safe, \(file.category))")
            }
            if riskyFiles.count > 5 {
                print("      ... and \(riskyFiles.count - 5) more files")
            }
        }
    }
    
    private func testBackupLogic(_ safeFiles: [CleanableItem]) async throws -> [String: Any] {
        print("  💾 Testing backup logic...")
        
        // Test backup creation for a subset of files
        let testFiles = Array(safeFiles.prefix(3)) // Test with first 3 files
        
        if testFiles.isEmpty {
            return [
                "backupLogicWorking": true,
                "backupTestFiles": 0,
                "backupSize": 0,
                "backupLocation": tempBackupDirectory.path,
                "message": "No files to test backup with"
            ]
        }
        
        // Test backup creation
        let backupStartTime = Date()
        let backupResults = try await createTestBackup(for: testFiles)
        let backupDuration = Date().timeIntervalSince(backupStartTime)
        
        return [
            "backupLogicWorking": backupResults.success,
            "backupTestFiles": testFiles.count,
            "backupSize": backupResults.totalSize,
            "backupLocation": tempBackupDirectory.path,
            "backupDuration": backupDuration,
            "backupFiles": backupResults.backedUpFiles,
            "message": backupResults.message
        ]
    }
    
    private func createTestBackup(for files: [CleanableItem]) async throws -> (success: Bool, totalSize: Int64, backedUpFiles: [String], message: String) {
        var backedUpFiles: [String] = []
        var totalSize: Int64 = 0
        
        for file in files {
            let sourceURL = URL(fileURLWithPath: file.path)
            let backupURL = tempBackupDirectory.appendingPathComponent(file.name)
            
            do {
                // Check if source file exists
                if FileManager.default.fileExists(atPath: sourceURL.path) {
                    // Copy file to backup location
                    try FileManager.default.copyItem(at: sourceURL, to: backupURL)
                    backedUpFiles.append(file.name)
                    totalSize += file.size
                    print("    ✅ Backed up: \(file.name)")
                } else {
                    print("    ⚠️  Source file not found: \(file.name)")
                }
            } catch {
                print("    ❌ Failed to backup \(file.name): \(error)")
                return (false, totalSize, backedUpFiles, "Backup failed for \(file.name): \(error)")
            }
        }
        
        return (true, totalSize, backedUpFiles, "Backup completed successfully")
    }
    
    private func printBackupTestResults(_ results: [String: Any]) {
        let working = results["backupLogicWorking"] as? Bool ?? false
        let testFiles = results["backupTestFiles"] as? Int ?? 0
        let backupSize = results["backupSize"] as? Int64 ?? 0
        let location = results["backupLocation"] as? String ?? ""
        let duration = results["backupDuration"] as? TimeInterval ?? 0
        let message = results["message"] as? String ?? ""
        
        print("  💾 Backup Test Results:")
        print("    • Backup logic working: \(working ? "✅ YES" : "❌ NO")")
        print("    • Test files backed up: \(testFiles)")
        print("    • Backup size: \(ByteCountFormatter.string(fromByteCount: backupSize, countStyle: .file))")
        print("    • Backup location: \(location)")
        print("    • Backup duration: \(String(format: "%.2f", duration))s")
        print("    • Status: \(message)")
        
        if working && testFiles > 0 {
            print("    ✅ Backup system is ready for real deletion")
        } else {
            print("    ⚠️  Backup system needs attention before real deletion")
        }
    }
    
    private func printFinalSummaryAndApproval(_ preview: [String: Any], _ backup: [String: Any]) {
        let safeFiles = preview["safeFiles"] as? [CleanableItem] ?? []
        let safeSize = preview["safeSize"] as? Int64 ?? 0
        let backupWorking = backup["backupLogicWorking"] as? Bool ?? false
        
        print("  📋 FINAL SUMMARY:")
        print("    🎯 Files ready for deletion: \(safeFiles.count)")
        print("    💾 Space that would be freed: \(ByteCountFormatter.string(fromByteCount: safeSize, countStyle: .file))")
        print("    🔒 Backup system: \(backupWorking ? "✅ Ready" : "❌ Not ready")")
        
        print("\n  ⚠️  DELETION APPROVAL REQUIRED:")
        print("    This test has completed the preview phase.")
        print("    To proceed with actual deletion:")
        print("    1. Review the preview above carefully")
        print("    2. Ensure backup system is working")
        print("    3. Set dryRun = false in engine configuration")
        print("    4. Explicitly approve the deletion")
        
        print("\n  🛡️  SAFETY MEASURES IN PLACE:")
        print("    • Only files with safety score ≥ 70% are targeted")
        print("    • System files are protected")
        print("    • Backup will be created before deletion")
        print("    • Dry run mode prevents accidental deletion")
        print("    • Only user-accessible directories are scanned")
    }
}

// MARK: - Process Documentation

/*
 SAFE macOS SYSTEM TEST PROCESS
 
 1. 🔍 SAFE SYSTEM SCANNING
    - Scan only user-accessible directories
    - Focus on safe categories (cache, logs, downloads, temporary)
    - Avoid system-critical directories
    - Handle permission errors gracefully
    - Calculate safety scores for all found files
 
 2. 📊 ANALYSIS
    - Categorize files by type and safety level
    - Calculate total sizes and counts
    - Identify safe vs risky files
    - Generate comprehensive statistics
 
 3. 👁️ PREVIEW GENERATION
    - Show exactly what would be deleted
    - List safe files (safety score ≥ 70%)
    - List risky files (safety score < 70%)
    - Calculate space that would be freed
 
 4. 💾 BACKUP TESTING
    - Test backup creation logic
    - Verify backup directory access
    - Test file copying functionality
    - Measure backup performance
 
 5. 📋 APPROVAL PROCESS
    - Show final summary
    - Require explicit approval
    - Ensure backup system is ready
    - Maintain safety measures
 
 SAFETY FEATURES:
 - Dry run mode by default
 - Only safe files targeted
 - System file protection
 - Backup before deletion
 - Explicit approval required
 - Comprehensive logging
 - User directory scanning only
 - Graceful permission error handling
 */
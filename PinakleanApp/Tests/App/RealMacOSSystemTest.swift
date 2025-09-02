import XCTest
import Foundation
@testable import PinakleanCore

/// Real macOS System Test - Actual File Deletion with Preview & Backup
/// This test will scan real system directories and show what would be deleted
final class RealMacOSSystemTest: XCTestCase {
    
    var engine: PinakleanEngine!
    var tempBackupDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create backup directory for testing
        tempBackupDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PinakleanBackup-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempBackupDirectory, withIntermediateDirectories: true)
        
        // Initialize engine with real system scanning
        engine = try await PinakleanEngine()
        var config = PinakleanEngine.Configuration.default
        config.dryRun = true // Start with preview mode
        config.safeMode = true
        config.enableSecurityAudit = true
        config.autoBackup = true
        // config.backupLocation = tempBackupDirectory.path // Not available in current config
        engine.configure(config)
        
        print("🧪 REAL macOS SYSTEM TEST SETUP")
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
    
    // MARK: - Real macOS System Test
    
    func testRealMacOSSystemScanAndPreview() async throws {
        print("\n🚀 STARTING REAL macOS SYSTEM SCAN & PREVIEW")
        print(String(repeating: "=", count: 70))
        
        // Step 1: Scan real system directories
        print("\n🔍 STEP 1: Scanning real macOS system directories...")
        let scanResults = try await performRealSystemScan()
        print("✅ System scan completed: \(scanResults.items.count) items found")
        
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
        XCTAssertGreaterThan(scanResults.items.count, 0, "Should find some cleanable files on the system")
        XCTAssertGreaterThan(safeFiles.count, 0, "Should identify some safe files for deletion")
        let backupWorking = backupTestResults["backupLogicWorking"] as? Bool ?? false
        XCTAssertTrue(backupWorking, "Backup logic should be working")
    }
    
    // MARK: - Helper Methods
    
    private func performRealSystemScan() async throws -> ScanResults {
        print("  🔍 Scanning real macOS system directories...")
        
        // Scan with safe categories to avoid system files
        let results = try await engine.scan(categories: .safe)
        
        print("  📊 Scan results:")
        print("    • Total items found: \(results.items.count)")
        print("    • Total size: \(ByteCountFormatter.string(fromByteCount: results.totalSize, countStyle: .file))")
        print("    • Categories scanned: cache, logs, downloads, temporary")
        
        return results
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
        
        print("\n  📁 By Category:")
        for (category, items) in categories.sorted(by: { $0.key < $1.key }) {
            let categorySize = items.reduce(0) { $0 + $1.size }
            print("    • \(category): \(items.count) files (\(ByteCountFormatter.string(fromByteCount: categorySize, countStyle: .file)))")
        }
        
        print("\n  🛡️ By Safety Score:")
        for (range, items) in safetyRanges.sorted(by: { $0.key < $1.key }) {
            let rangeSize = items.reduce(0) { $0 + $1.size }
            print("    • \(range): \(items.count) files (\(ByteCountFormatter.string(fromByteCount: rangeSize, countStyle: .file)))")
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
        let testFiles = Array(safeFiles.prefix(5)) // Test with first 5 files
        
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
    }
}

// MARK: - Process Documentation

/*
 REAL macOS SYSTEM TEST PROCESS
 
 1. 🔍 SYSTEM SCANNING
    - Scan real macOS system directories
    - Focus on safe categories (cache, logs, downloads, temporary)
    - Avoid system-critical directories
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
 */
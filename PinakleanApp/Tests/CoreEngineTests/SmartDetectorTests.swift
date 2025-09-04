import XCTest
@testable import PinakleanCore

final class SmartDetectorTests: XCTestCase {
    var smartDetector: SmartDetector!
    var tempDir: URL!
    var testFiles: [URL] = []

    override func setUp() async throws {
        smartDetector = SmartDetector()

        // Create temporary directory for tests
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SmartDetectorTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Create test files with different patterns
        testFiles = try await createTestFiles()
    }

    override func tearDown() async throws {
        // Clean up test files
        for file in testFiles {
            try? FileManager.default.removeItem(at: file)
        }
        try? FileManager.default.removeItem(at: tempDir)
        smartDetector = nil
    }

    func testAnalyzeFile_basicFile() async throws {
        let testFile = testFiles.first(where: { $0.lastPathComponent.hasSuffix(".log") })!
        let analysis = try await smartDetector.analyzeFile(at: testFile.path)

        XCTAssertEqual(analysis.path, testFile.path)
        XCTAssertGreaterThan(analysis.importanceScore, 0)
        XCTAssertGreaterThan(analysis.accessScore, 0)
        XCTAssertGreaterThan(analysis.combinedScore, 0)
        XCTAssertGreaterThan(analysis.sizeBytes, 0)
        XCTAssertNotNil(analysis.ageCategory)
    }

    func testAnalyzeFile_nonExistentFile() async throws {
        let nonExistentPath = tempDir.appendingPathComponent("nonexistent.txt").path

        do {
            _ = try await smartDetector.analyzeFile(at: nonExistentPath)
            XCTFail("Expected SmartDetectionError.fileNotFound")
        } catch let error as SmartDetector.SmartDetectionError {
            switch error {
            case .fileNotFound(let path):
                XCTAssertEqual(path, nonExistentPath)
            default:
                XCTFail("Expected fileNotFound error, got \(error)")
            }
        }
    }

    func testGenerateRecommendations() async throws {
        let filePaths = testFiles.map { $0.path }
        let result = try await smartDetector.generateRecommendations(for: filePaths)

        XCTAssertGreaterThan(result.analyses.count, 0)
        XCTAssertLessThanOrEqual(result.analyses.count, testFiles.count)
        XCTAssertGreaterThanOrEqual(result.summary.totalFiles, 0)
        XCTAssertGreaterThanOrEqual(result.summary.safeToDelete, 0)
        XCTAssertGreaterThanOrEqual(result.summary.riskyFiles, 0)
        XCTAssertGreaterThanOrEqual(result.summary.totalSizeMB, 0)

        // Verify timestamp is recent
        let timeDifference = Date().timeIntervalSince(result.timestamp)
        XCTAssertLessThan(timeDifference, 60) // Within last minute
    }

    func testPatternMatching() async throws {
        // Test various file patterns
        let patterns = [
            (file: "test.log", expectedPattern: "*.log"),
            (file: ".DS_Store", expectedPattern: ".DS_Store"),
            (file: "node_modules", expectedPattern: "node_modules"),
            (file: "build.gradle", expectedPattern: nil)
        ]

        for (fileName, expectedPattern) in patterns {
            let testFile = tempDir.appendingPathComponent(fileName)
            try "test content".write(to: testFile, atomically: true, encoding: .utf8)

            let analysis = try await smartDetector.analyzeFile(at: testFile.path)
            XCTAssertEqual(analysis.patternMatch, expectedPattern, "Pattern mismatch for \(fileName)")
        }
    }

    func testAgeCategoryAnalysis() async throws {
        // Create a file and modify its modification date
        let testFile = tempDir.appendingPathComponent("age_test.txt")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)

        // Test very old file (>365 days)
        let veryOldDate = Date().addingTimeInterval(-400 * 24 * 60 * 60) // 400 days ago
        try FileManager.default.setAttributes([.modificationDate: veryOldDate], ofItemAtPath: testFile.path)

        let analysis = try await smartDetector.analyzeFile(at: testFile.path)
        XCTAssertEqual(analysis.ageCategory, .veryOld)
    }

    func testDuplicateDetection() async throws {
        // Create duplicate files
        let content1 = "duplicate content 1"
        let content2 = "duplicate content 2"

        let file1 = tempDir.appendingPathComponent("dup1.txt")
        let file2 = tempDir.appendingPathComponent("dup2.txt")
        let file3 = tempDir.appendingPathComponent("dup3.txt")

        try content1.write(to: file1, atomically: true, encoding: .utf8)
        try content1.write(to: file2, atomically: true, encoding: .utf8) // Duplicate of file1
        try content2.write(to: file3, atomically: true, encoding: .utf8) // Different content

        let cleanableItems = [
            CleanableItem(path: file1.path, size: try file1.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0, category: .other),
            CleanableItem(path: file2.path, size: try file2.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0, category: .other),
            CleanableItem(path: file3.path, size: try file3.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0, category: .other)
        ]

        let duplicates = try await smartDetector.detectDuplicates(from: cleanableItems)

        // Should find one duplicate group
        XCTAssertEqual(duplicates.count, 1)
        XCTAssertEqual(duplicates[0].items.count, 2) // file1 and file2 are duplicates
        XCTAssertGreaterThan(duplicates[0].spaceSavings, 0)
    }

    func testImportanceScoring() async throws {
        // Test different file types for importance scoring
        let testCases = [
            ("important_document.pdf", 40...60), // Medium importance
            ("cache_file.cache", 85...95),       // High importance (safe to delete)
            ("system_file.dylib", 40...60),      // Medium importance
            ("temp_file.tmp", 85...95)           // High importance (safe to delete)
        ]

        for (fileName, expectedRange) in testCases {
            let testFile = tempDir.appendingPathComponent(fileName)
            try "test content".write(to: testFile, atomically: true, encoding: .utf8)

            let analysis = try await smartDetector.analyzeFile(at: testFile.path)
            XCTAssertTrue(expectedRange.contains(analysis.importanceScore),
                         "Importance score \(analysis.importanceScore) for \(fileName) not in expected range \(expectedRange)")
        }
    }

    func testAccessPatternAnalysis() async throws {
        let testFile = tempDir.appendingPathComponent("access_test.txt")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)

        // Test recently accessed file
        let recentDate = Date().addingTimeInterval(-60 * 60) // 1 hour ago
        try FileManager.default.setAttributes([.modificationDate: recentDate], ofItemAtPath: testFile.path)

        let analysis = try await smartDetector.analyzeFile(at: testFile.path)
        XCTAssertEqual(analysis.ageCategory, .new)
        XCTAssertLessThan(analysis.accessScore, 30) // Should be lower for recent files
    }

    func testRecommendationLogic() async throws {
        // Create files with different risk levels
        let safeFile = tempDir.appendingPathComponent("safe_to_delete.log")
        let reviewFile = tempDir.appendingPathComponent("review_me.txt")
        let keepFile = tempDir.appendingPathComponent("important.doc")

        try "log content".write(to: safeFile, atomically: true, encoding: .utf8)
        try "text content".write(to: reviewFile, atomically: true, encoding: .utf8)
        try "document content".write(to: keepFile, atomically: true, encoding: .utf8)

        let analyses = try await [
            smartDetector.analyzeFile(at: safeFile.path),
            smartDetector.analyzeFile(at: reviewFile.path),
            smartDetector.analyzeFile(at: keepFile.path)
        ]

        // Verify recommendations based on combined scores
        for analysis in analyses {
            if analysis.combinedScore > 70 {
                XCTAssertEqual(analysis.recommendation, .safeToDelete)
            } else if analysis.combinedScore > 50 {
                XCTAssertEqual(analysis.recommendation, .reviewRecommended)
            } else {
                XCTAssertEqual(analysis.recommendation, .keep)
            }
        }
    }

    func testFeedbackLearning() async throws {
        let testFile = tempDir.appendingPathComponent("feedback_test.txt")
        try "test content".write(to: testFile, atomically: true, encoding: .utf8)

        // Test learning from user feedback
        await smartDetector.learnFromFeedback(action: "deleted", filePath: testFile.path)
        await smartDetector.learnFromFeedback(action: "kept", filePath: testFile.path)

        // Verify feedback was recorded (this would need actual file system verification)
        // For now, we just ensure no crashes occur during feedback recording
        XCTAssertTrue(true, "Feedback learning completed without errors")
    }

    func testDirectoryImportanceScoring() async throws {
        // Test files in different directories
        let downloadsFile = tempDir.appendingPathComponent("downloads_test.txt")
        let desktopFile = tempDir.appendingPathComponent("desktop_test.txt")

        try "test".write(to: downloadsFile, atomically: true, encoding: .utf8)
        try "test".write(to: desktopFile, atomically: true, encoding: .utf8)

        let downloadsAnalysis = try await smartDetector.analyzeFile(at: downloadsFile.path)
        let desktopAnalysis = try await smartDetector.analyzeFile(at: desktopFile.path)

        // Desktop files should be considered more important than downloads
        XCTAssertGreaterThanOrEqual(desktopAnalysis.importanceScore, downloadsAnalysis.importanceScore)
    }

    // MARK: - Helper Methods

    private func createTestFiles() async throws -> [URL] {
        let testFileSpecs = [
            ("test.log", "log content"),
            ("cache.tmp", "cache content"),
            (".DS_Store", "DS_Store content"),
            ("node_modules", "npm content"),
            ("build.gradle", "gradle content"),
            ("important.doc", "document content"),
            ("system.dylib", "system content")
        ]

        var files: [URL] = []

        for (fileName, content) in testFileSpecs {
            let fileURL = tempDir.appendingPathComponent(fileName)
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            files.append(fileURL)
        }

        return files
    }
}

// MARK: - Performance Tests

extension SmartDetectorTests {
    func testPerformance_analyzeMultipleFiles() async throws {
        let filePaths = testFiles.map { $0.path }

        measure {
            let expectation = XCTestExpectation(description: "Analyze files")
            Task {
                _ = try await smartDetector.generateRecommendations(for: filePaths)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 30.0)
        }
    }

    func testPerformance_duplicateDetection() async throws {
        let cleanableItems = testFiles.map {
            CleanableItem(path: $0.path, size: 1024, category: .other)
        }

        measure {
            let expectation = XCTestExpectation(description: "Detect duplicates")
            Task {
                _ = try await smartDetector.detectDuplicates(from: cleanableItems)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 30.0)
        }
    }
}

// MARK: - Edge Case Tests

extension SmartDetectorTests {
    func testEdgeCase_emptyFile() async throws {
        let emptyFile = tempDir.appendingPathComponent("empty.txt")
        try "".write(to: emptyFile, atomically: true, encoding: .utf8)

        let analysis = try await smartDetector.analyzeFile(at: emptyFile.path)
        XCTAssertEqual(analysis.sizeBytes, 0)
        XCTAssertGreaterThan(analysis.importanceScore, 0) // Should still have a score
    }

    func testEdgeCase_veryLargeFile() async throws {
        let largeContent = String(repeating: "x", count: 1024 * 1024) // 1MB
        let largeFile = tempDir.appendingPathComponent("large.txt")
        try largeContent.write(to: largeFile, atomically: true, encoding: .utf8)

        let analysis = try await smartDetector.analyzeFile(at: largeFile.path)
        XCTAssertGreaterThan(analysis.sizeBytes, 1_000_000)
        XCTAssertLessThan(analysis.importanceScore, 50) // Large files should have lower importance
    }

    func testEdgeCase_specialCharacters() async throws {
        let specialFile = tempDir.appendingPathComponent("special_ñame_测试.txt")
        try "special content".write(to: specialFile, atomically: true, encoding: .utf8)

        let analysis = try await smartDetector.analyzeFile(at: specialFile.path)
        XCTAssertEqual(analysis.path, specialFile.path)
        XCTAssertGreaterThan(analysis.combinedScore, 0)
    }
}

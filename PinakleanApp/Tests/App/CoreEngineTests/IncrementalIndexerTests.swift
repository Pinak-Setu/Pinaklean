//
//  IncrementalIndexerTests.swift
//  PinakleanAppTests
//
//  Comprehensive tests for the IncrementalIndexer functionality
//

import XCTest
@testable import PinakleanApp
import Foundation

@MainActor
final class IncrementalIndexerTests: XCTestCase {

    var indexer: IncrementalIndexer!
    var tempDirectory: URL!

    override func setUp() async throws {
        // Create temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PinakleanTest")
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Initialize indexer
        indexer = try await IncrementalIndexer()
    }

    override func tearDown() async throws {
        // Clean up
        try? FileManager.default.removeItem(at: tempDirectory)
        await indexer.clearIndex()
        indexer = nil
    }

    // MARK: - Initialization Tests

    func testInitialization() async throws {
        XCTAssertNotNil(indexer)
        let stats = await indexer.getStatistics()
        XCTAssertEqual(stats.totalFiles, 0)
        XCTAssertEqual(stats.totalSize, 0)
    }

    func testIndexStatePersistence() async throws {
        // Create a test file
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        let testContent = "Hello, World!"
        try testContent.write(to: testFile, atomically: true, encoding: .utf8)

        // Perform scan
        let scanStats = try await indexer.performFullScan(paths: [tempDirectory.path])
        XCTAssertGreaterThan(scanStats.totalFiles, 0)

        // Create new indexer instance (simulates app restart)
        let newIndexer = try await IncrementalIndexer()
        let newStats = await newIndexer.getStatistics()

        // Index should be loaded from persistence
        XCTAssertEqual(newStats.totalFiles, scanStats.totalFiles)
        XCTAssertEqual(newStats.totalSize, scanStats.totalSize)
    }

    // MARK: - Full Scan Tests

    func testFullScanSingleFile() async throws {
        // Create test file
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        let testContent = "Hello, World!"
        try testContent.write(to: testFile, atomically: true, encoding: .utf8)

        // Perform scan
        let stats = try await indexer.performFullScan(paths: [tempDirectory.path])

        XCTAssertEqual(stats.totalFiles, 1)
        XCTAssertEqual(stats.totalSize, Int64(testContent.utf8.count))
        XCTAssertGreaterThan(stats.indexedDirectories, 0)

        // Verify file is indexed
        XCTAssertTrue(await indexer.isPathIndexed(testFile.path))

        // Get index entry
        let entry = await indexer.getIndexEntry(for: testFile.path)
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.path, testFile.path)
        XCTAssertEqual(entry?.size, Int64(testContent.utf8.count))
        XCTAssertFalse(entry?.isDirectory ?? true)
    }

    func testFullScanDirectory() async throws {
        // Create test directory structure
        let subDir = tempDirectory.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

        let file1 = tempDirectory.appendingPathComponent("file1.txt")
        let file2 = subDir.appendingPathComponent("file2.txt")

        try "Content 1".write(to: file1, atomically: true, encoding: .utf8)
        try "Content 2".write(to: file2, atomically: true, encoding: .utf8)

        // Perform scan
        let stats = try await indexer.performFullScan(paths: [tempDirectory.path])

        XCTAssertEqual(stats.totalFiles, 2)
        XCTAssertEqual(stats.totalSize, Int64("Content 1Content 2".utf8.count))

        // Verify both files are indexed
        XCTAssertTrue(await indexer.isPathIndexed(file1.path))
        XCTAssertTrue(await indexer.isPathIndexed(file2.path))
    }

    func testFullScanNonexistentPath() async throws {
        let nonexistentPath = "/nonexistent/path"

        do {
            _ = try await indexer.performFullScan(paths: [nonexistentPath])
            XCTFail("Expected error for nonexistent path")
        } catch let error as IndexerError {
            switch error {
            case .pathNotFound:
                // Expected error
                break
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    // MARK: - Incremental Update Tests

    func testIncrementalUpdate() async throws {
        // Initial scan
        let stats1 = try await indexer.performFullScan(paths: [tempDirectory.path])

        // Create new file
        let newFile = tempDirectory.appendingPathComponent("newfile.txt")
        try "New content".write(to: newFile, atomically: true, encoding: .utf8)

        // Perform incremental update
        let updatedPaths = try await indexer.performIncrementalUpdate()

        // Should have detected the new file
        XCTAssertTrue(updatedPaths.contains(newFile.path))

        // Verify file is now indexed
        XCTAssertTrue(await indexer.isPathIndexed(newFile.path))
    }

    func testPathIndexingCheck() async throws {
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)

        // File not indexed yet
        XCTAssertFalse(await indexer.isPathIndexed(testFile.path))

        // Perform scan
        _ = try await indexer.performFullScan(paths: [tempDirectory.path])

        // File should be indexed now
        XCTAssertTrue(await indexer.isPathIndexed(testFile.path))
    }

    // MARK: - Index Entry Tests

    func testIndexEntryCreation() async throws {
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        let content = "Hello, World!"
        try content.write(to: testFile, atomically: true, encoding: .utf8)

        _ = try await indexer.performFullScan(paths: [tempDirectory.path])

        let entry = await indexer.getIndexEntry(for: testFile.path)
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.path, testFile.path)
        XCTAssertEqual(entry?.size, Int64(content.utf8.count))
        XCTAssertFalse(entry?.isDirectory ?? true)
        XCTAssertNotNil(entry?.modificationDate)
        XCTAssertNotNil(entry?.creationDate)
    }

    func testDirectoryIndexing() async throws {
        let subDir = tempDirectory.appendingPathComponent("testdir")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

        _ = try await indexer.performFullScan(paths: [tempDirectory.path])

        let entry = await indexer.getIndexEntry(for: subDir.path)
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.path, subDir.path)
        XCTAssertTrue(entry?.isDirectory ?? false)
        XCTAssertEqual(entry?.size, 0) // Directories have size 0 in our implementation
    }

    // MARK: - Statistics Tests

    func testStatisticsTracking() async throws {
        let stats1 = await indexer.getStatistics()
        XCTAssertEqual(stats1.totalFiles, 0)

        // Create and scan files
        let file1 = tempDirectory.appendingPathComponent("file1.txt")
        let file2 = tempDirectory.appendingPathComponent("file2.txt")
        try "content1".write(to: file1, atomically: true, encoding: .utf8)
        try "content2".write(to: file2, atomically: true, encoding: .utf8)

        let stats2 = try await indexer.performFullScan(paths: [tempDirectory.path])

        XCTAssertEqual(stats2.totalFiles, 2)
        XCTAssertEqual(stats2.totalSize, Int64("content1content2".utf8.count))
        XCTAssertNotNil(stats2.lastFullScan)
        XCTAssertGreaterThan(stats2.averageScanTime, 0)
    }

    // MARK: - Error Handling Tests

    func testConcurrentScanError() async throws {
        // Start first scan
        let scanTask1 = Task {
            try await self.indexer.performFullScan(paths: [self.tempDirectory.path])
        }

        // Try to start second scan (should fail)
        do {
            _ = try await indexer.performFullScan(paths: [tempDirectory.path])
            XCTFail("Expected concurrent scan error")
        } catch let error as IndexerError {
            switch error {
            case .scanInProgress:
                // Expected error
                break
            default:
                XCTFail("Unexpected error: \(error)")
            }
        }

        // Wait for first scan to complete
        _ = try await scanTask1.value
    }

    // MARK: - Index Management Tests

    func testIndexClearing() async throws {
        // Create and index files
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)

        _ = try await indexer.performFullScan(paths: [tempDirectory.path])
        XCTAssertTrue(await indexer.isPathIndexed(testFile.path))

        // Clear index
        await indexer.clearIndex()

        // File should no longer be indexed
        XCTAssertFalse(await indexer.isPathIndexed(testFile.path))

        let stats = await indexer.getStatistics()
        XCTAssertEqual(stats.totalFiles, 0)
        XCTAssertEqual(stats.totalSize, 0)
    }

    func testIndexedPathsRetrieval() async throws {
        let file1 = tempDirectory.appendingPathComponent("file1.txt")
        let file2 = tempDirectory.appendingPathComponent("file2.txt")
        try "content1".write(to: file1, atomically: true, encoding: .utf8)
        try "content2".write(to: file2, atomically: true, encoding: .utf8)

        _ = try await indexer.performFullScan(paths: [tempDirectory.path])

        let indexedPaths = await indexer.getIndexedPaths()
        XCTAssertEqual(indexedPaths.count, 2)
        XCTAssertTrue(indexedPaths.contains(file1.path))
        XCTAssertTrue(indexedPaths.contains(file2.path))
    }

    // MARK: - File Type Detection Tests

    func testFileTypeDetection() async throws {
        let textFile = tempDirectory.appendingPathComponent("test.txt")
        let imageFile = tempDirectory.appendingPathComponent("test.jpg")

        try "text content".write(to: textFile, atomically: true, encoding: .utf8)
        try Data([0xFF, 0xD8, 0xFF, 0xE0]).write(to: imageFile) // JPEG header

        _ = try await indexer.performFullScan(paths: [tempDirectory.path])

        let textEntry = await indexer.getIndexEntry(for: textFile.path)
        let imageEntry = await indexer.getIndexEntry(for: imageFile.path)

        XCTAssertNotNil(textEntry?.fileType)
        XCTAssertNotNil(imageEntry?.fileType)
    }

    // MARK: - Performance Tests

    func testLargeDirectoryScan() async throws {
        // Create many files for performance testing
        let fileCount = 100

        for i in 0..<fileCount {
            let file = tempDirectory.appendingPathComponent("file_\(i).txt")
            try "content \(i)".write(to: file, atomically: true, encoding: .utf8)
        }

        let startTime = Date()
        let stats = try await indexer.performFullScan(paths: [tempDirectory.path])
        let duration = Date().timeIntervalSince(startTime)

        XCTAssertEqual(stats.totalFiles, fileCount)
        XCTAssertLessThan(duration, 30.0) // Should complete within 30 seconds

        let indexedPaths = await indexer.getIndexedPaths()
        XCTAssertEqual(indexedPaths.count, fileCount)
    }

    // MARK: - Change Detection Tests

    func testFileModificationDetection() async throws {
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        try "original".write(to: testFile, atomically: true, encoding: .utf8)

        _ = try await indexer.performFullScan(paths: [tempDirectory.path])

        // Modify file
        try "modified".write(to: testFile, atomically: true, encoding: .utf8)

        // Simulate file system event (in real scenario this would come from FSEvents)
        // For testing, we'll manually update the index
        let updatedPaths = try await indexer.performIncrementalUpdate()

        XCTAssertTrue(updatedPaths.contains(testFile.path))

        let entry = await indexer.getIndexEntry(for: testFile.path)
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.size, Int64("modified".utf8.count))
    }

    // MARK: - Bloom Filter Tests

    func testBloomFilterFunctionality() async throws {
        let testPath = "/test/path"

        // Initially not in filter
        XCTAssertFalse(await indexer.isPathIndexed(testPath))

        // Add to index
        let testFile = tempDirectory.appendingPathComponent("bloom_test.txt")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)

        _ = try await indexer.performFullScan(paths: [tempDirectory.path])

        // Should be in filter now
        XCTAssertTrue(await indexer.isPathIndexed(testFile.path))

        // Non-existent path should not be in filter
        XCTAssertFalse(await indexer.isPathIndexed("/nonexistent/path"))
    }
}

import XCTest
import Quick
import Nimble
@testable import PinakleanCore

class DuplicateDetectionTests: QuickSpec {
    override func spec() {
        describe("DuplicateDetector") {
            var detector: DuplicateDetector!
            var tempDirectory: URL!
            
            beforeEach {
                detector = DuplicateDetector()
                tempDirectory = FileManager.default.temporaryDirectory
                    .appendingPathComponent("DuplicateDetectionTests")
                try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
            }
            
            afterEach {
                try? FileManager.default.removeItem(at: tempDirectory)
            }
            
            context("when detecting duplicates by content") {
                it("should find identical files") {
                    // Given
                    let content = "This is test content for duplicate detection"
                    let file1 = tempDirectory.appendingPathComponent("file1.txt")
                    let file2 = tempDirectory.appendingPathComponent("file2.txt")
                    
                    try content.write(to: file1, atomically: true, encoding: .utf8)
                    try content.write(to: file2, atomically: true, encoding: .utf8)
                    
                    // When
                    let duplicates = try detector.findDuplicatesByContent(in: [file1, file2])
                    
                    // Then
                    expect(duplicates).to(haveCount(1))
                    expect(duplicates.first?.files).to(contain(file1, file2))
                    expect(duplicates.first?.files).to(haveCount(2))
                }
                
                it("should not find duplicates for different content") {
                    // Given
                    let content1 = "This is test content 1"
                    let content2 = "This is test content 2"
                    let file1 = tempDirectory.appendingPathComponent("file1.txt")
                    let file2 = tempDirectory.appendingPathComponent("file2.txt")
                    
                    try content1.write(to: file1, atomically: true, encoding: .utf8)
                    try content2.write(to: file2, atomically: true, encoding: .utf8)
                    
                    // When
                    let duplicates = try detector.findDuplicatesByContent(in: [file1, file2])
                    
                    // Then
                    expect(duplicates).to(beEmpty())
                }
                
                it("should handle multiple duplicate groups") {
                    // Given
                    let content1 = "Content group 1"
                    let content2 = "Content group 2"
                    let file1 = tempDirectory.appendingPathComponent("file1.txt")
                    let file2 = tempDirectory.appendingPathComponent("file2.txt")
                    let file3 = tempDirectory.appendingPathComponent("file3.txt")
                    let file4 = tempDirectory.appendingPathComponent("file4.txt")
                    
                    try content1.write(to: file1, atomically: true, encoding: .utf8)
                    try content1.write(to: file2, atomically: true, encoding: .utf8)
                    try content2.write(to: file3, atomically: true, encoding: .utf8)
                    try content2.write(to: file4, atomically: true, encoding: .utf8)
                    
                    // When
                    let duplicates = try detector.findDuplicatesByContent(in: [file1, file2, file3, file4])
                    
                    // Then
                    expect(duplicates).to(haveCount(2))
                    expect(duplicates[0].files).to(contain(file1, file2))
                    expect(duplicates[1].files).to(contain(file3, file4))
                }
                
                it("should handle empty files") {
                    // Given
                    let file1 = tempDirectory.appendingPathComponent("empty1.txt")
                    let file2 = tempDirectory.appendingPathComponent("empty2.txt")
                    
                    try "".write(to: file1, atomically: true, encoding: .utf8)
                    try "".write(to: file2, atomically: true, encoding: .utf8)
                    
                    // When
                    let duplicates = try detector.findDuplicatesByContent(in: [file1, file2])
                    
                    // Then
                    expect(duplicates).to(haveCount(1))
                    expect(duplicates.first?.files).to(contain(file1, file2))
                }
                
                it("should handle large files efficiently") {
                    // Given
                    let largeContent = String(repeating: "A", count: 1024 * 1024) // 1MB
                    let file1 = tempDirectory.appendingPathComponent("large1.txt")
                    let file2 = tempDirectory.appendingPathComponent("large2.txt")
                    
                    try largeContent.write(to: file1, atomically: true, encoding: .utf8)
                    try largeContent.write(to: file2, atomically: true, encoding: .utf8)
                    
                    // When
                    let startTime = Date()
                    let duplicates = try detector.findDuplicatesByContent(in: [file1, file2])
                    let duration = Date().timeIntervalSince(startTime)
                    
                    // Then
                    expect(duplicates).to(haveCount(1))
                    expect(duplicates.first?.files).to(contain(file1, file2))
                    expect(duration).to(beLessThan(5.0)) // Should complete within 5 seconds
                }
            }
            
            context("when detecting duplicates by name") {
                it("should find files with identical names") {
                    // Given
                    let file1 = tempDirectory.appendingPathComponent("duplicate.txt")
                    let file2 = tempDirectory.appendingPathComponent("duplicate.txt")
                    
                    try "content1".write(to: file1, atomically: true, encoding: .utf8)
                    try "content2".write(to: file2, atomically: true, encoding: .utf8)
                    
                    // When
                    let duplicates = try detector.findDuplicatesByName(in: [file1, file2])
                    
                    // Then
                    expect(duplicates).to(haveCount(1))
                    expect(duplicates.first?.files).to(contain(file1, file2))
                }
                
                it("should handle case-insensitive name matching") {
                    // Given
                    let file1 = tempDirectory.appendingPathComponent("Document.txt")
                    let file2 = tempDirectory.appendingPathComponent("document.txt")
                    
                    try "content1".write(to: file1, atomically: true, encoding: .utf8)
                    try "content2".write(to: file2, atomically: true, encoding: .utf8)
                    
                    // When
                    let duplicates = try detector.findDuplicatesByName(in: [file1, file2])
                    
                    // Then
                    expect(duplicates).to(haveCount(1))
                    expect(duplicates.first?.files).to(contain(file1, file2))
                }
                
                it("should not find duplicates for different names") {
                    // Given
                    let file1 = tempDirectory.appendingPathComponent("file1.txt")
                    let file2 = tempDirectory.appendingPathComponent("file2.txt")
                    
                    try "content".write(to: file1, atomically: true, encoding: .utf8)
                    try "content".write(to: file2, atomically: true, encoding: .utf8)
                    
                    // When
                    let duplicates = try detector.findDuplicatesByName(in: [file1, file2])
                    
                    // Then
                    expect(duplicates).to(beEmpty())
                }
            }
            
            context("when detecting duplicates by size") {
                it("should find files with identical sizes") {
                    // Given
                    let content = "This content has exactly 40 characters!"
                    let file1 = tempDirectory.appendingPathComponent("file1.txt")
                    let file2 = tempDirectory.appendingPathComponent("file2.txt")
                    
                    try content.write(to: file1, atomically: true, encoding: .utf8)
                    try content.write(to: file2, atomically: true, encoding: .utf8)
                    
                    // When
                    let duplicates = try detector.findDuplicatesBySize(in: [file1, file2])
                    
                    // Then
                    expect(duplicates).to(haveCount(1))
                    expect(duplicates.first?.files).to(contain(file1, file2))
                }
                
                it("should not find duplicates for different sizes") {
                    // Given
                    let content1 = "Short"
                    let content2 = "This is a much longer content"
                    let file1 = tempDirectory.appendingPathComponent("file1.txt")
                    let file2 = tempDirectory.appendingPathComponent("file2.txt")
                    
                    try content1.write(to: file1, atomically: true, encoding: .utf8)
                    try content2.write(to: file2, atomically: true, encoding: .utf8)
                    
                    // When
                    let duplicates = try detector.findDuplicatesBySize(in: [file1, file2])
                    
                    // Then
                    expect(duplicates).to(beEmpty())
                }
            }
            
            context("when calculating file hashes") {
                it("should generate consistent hashes for identical content") {
                    // Given
                    let content = "Test content for hash generation"
                    let file1 = tempDirectory.appendingPathComponent("file1.txt")
                    let file2 = tempDirectory.appendingPathComponent("file2.txt")
                    
                    try content.write(to: file1, atomically: true, encoding: .utf8)
                    try content.write(to: file2, atomically: true, encoding: .utf8)
                    
                    // When
                    let hash1 = try detector.calculateFileHash(file1)
                    let hash2 = try detector.calculateFileHash(file2)
                    
                    // Then
                    expect(hash1).to(equal(hash2))
                    expect(hash1).toNot(beEmpty())
                }
                
                it("should generate different hashes for different content") {
                    // Given
                    let content1 = "Content 1"
                    let content2 = "Content 2"
                    let file1 = tempDirectory.appendingPathComponent("file1.txt")
                    let file2 = tempDirectory.appendingPathComponent("file2.txt")
                    
                    try content1.write(to: file1, atomically: true, encoding: .utf8)
                    try content2.write(to: file2, atomically: true, encoding: .utf8)
                    
                    // When
                    let hash1 = try detector.calculateFileHash(file1)
                    let hash2 = try detector.calculateFileHash(file2)
                    
                    // Then
                    expect(hash1).toNot(equal(hash2))
                }
                
                it("should handle empty files") {
                    // Given
                    let file = tempDirectory.appendingPathComponent("empty.txt")
                    try "".write(to: file, atomically: true, encoding: .utf8)
                    
                    // When
                    let hash = try detector.calculateFileHash(file)
                    
                    // Then
                    expect(hash).toNot(beEmpty())
                }
            }
            
            context("when handling errors") {
                it("should throw error for non-existent files") {
                    // Given
                    let nonExistentFile = tempDirectory.appendingPathComponent("nonexistent.txt")
                    
                    // When/Then
                    expect { try detector.calculateFileHash(nonExistentFile) }
                        .to(throwError(DuplicateDetectionError.fileNotFound(nonExistentFile)))
                }
                
                it("should throw error for directories") {
                    // Given
                    let directory = tempDirectory.appendingPathComponent("directory")
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                    
                    // When/Then
                    expect { try detector.calculateFileHash(directory) }
                        .to(throwError(DuplicateDetectionError.notAFile(directory)))
                }
                
                it("should handle permission errors gracefully") {
                    // Given
                    let file = tempDirectory.appendingPathComponent("restricted.txt")
                    try "content".write(to: file, atomically: true, encoding: .utf8)
                    
                    // Remove read permission
                    try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: file.path)
                    
                    // When/Then
                    expect { try detector.calculateFileHash(file) }
                        .to(throwError(DuplicateDetectionError.permissionDenied(file)))
                    
                    // Cleanup
                    try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: file.path)
                }
            }
            
            context("when performing comprehensive duplicate detection") {
                it("should find all types of duplicates") {
                    // Given
                    let content1 = "Identical content"
                    let content2 = "Different content"
                    
                    let file1 = tempDirectory.appendingPathComponent("file1.txt")
                    let file2 = tempDirectory.appendingPathComponent("file2.txt") // Same content as file1
                    let file3 = tempDirectory.appendingPathComponent("file1_copy.txt") // Same name as file1
                    let file4 = tempDirectory.appendingPathComponent("file4.txt")
                    
                    try content1.write(to: file1, atomically: true, encoding: .utf8)
                    try content1.write(to: file2, atomically: true, encoding: .utf8)
                    try content2.write(to: file3, atomically: true, encoding: .utf8)
                    try content2.write(to: file4, atomically: true, encoding: .utf8)
                    
                    // When
                    let results = try detector.findAllDuplicates(in: [file1, file2, file3, file4])
                    
                    // Then
                    expect(results.contentDuplicates).to(haveCount(2)) // file1+file2, file3+file4
                    expect(results.nameDuplicates).to(haveCount(1)) // file1+file3
                    expect(results.sizeDuplicates).to(haveCount(2)) // file1+file2, file3+file4
                }
                
                it("should provide duplicate statistics") {
                    // Given
                    let content = "Test content"
                    let file1 = tempDirectory.appendingPathComponent("file1.txt")
                    let file2 = tempDirectory.appendingPathComponent("file2.txt")
                    let file3 = tempDirectory.appendingPathComponent("file3.txt")
                    
                    try content.write(to: file1, atomically: true, encoding: .utf8)
                    try content.write(to: file2, atomically: true, encoding: .utf8)
                    try "different".write(to: file3, atomically: true, encoding: .utf8)
                    
                    // When
                    let results = try detector.findAllDuplicates(in: [file1, file2, file3])
                    let stats = results.generateStatistics()
                    
                    // Then
                    expect(stats.totalFiles).to(equal(3))
                    expect(stats.duplicateFiles).to(equal(2))
                    expect(stats.uniqueFiles).to(equal(1))
                    expect(stats.spaceWasted).to(beGreaterThan(0))
                }
            }
            
            context("when handling performance") {
                it("should process files in parallel for large datasets") {
                    // Given
                    let files = (0..<100).map { i in
                        tempDirectory.appendingPathComponent("file\(i).txt")
                    }
                    
                    // Create files with some duplicates
                    for (index, file) in files.enumerated() {
                        let content = index % 10 == 0 ? "duplicate_content" : "unique_content_\(index)"
                        try content.write(to: file, atomically: true, encoding: .utf8)
                    }
                    
                    // When
                    let startTime = Date()
                    let results = try detector.findAllDuplicates(in: files)
                    let duration = Date().timeIntervalSince(startTime)
                    
                    // Then
                    expect(results.contentDuplicates).toNot(beEmpty())
                    expect(duration).to(beLessThan(10.0)) // Should complete within 10 seconds
                }
            }
        }
    }
}
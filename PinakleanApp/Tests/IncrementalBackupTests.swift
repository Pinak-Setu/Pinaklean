import XCTest
import Quick
import Nimble
@testable import PinakleanCore

class IncrementalBackupTests: QuickSpec {
    override func spec() {
        describe("IncrementalBackupManager") {
            var backupManager: IncrementalBackupManager!
            var tempDirectory: URL!
            
            beforeEach {
                tempDirectory = FileManager.default.temporaryDirectory
                    .appendingPathComponent("IncrementalBackupTests")
                try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
                
                backupManager = IncrementalBackupManager()
            }
            
            afterEach {
                try? FileManager.default.removeItem(at: tempDirectory)
            }
            
            context("when calculating delta between snapshots") {
                it("should detect new files") {
                    // Given
                    let baseSnapshot = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
                        totalSize: 1000,
                        fileCount: 2,
                        metadata: ["type": "full"]
                    )
                    
                    let currentSnapshot = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date(),
                        totalSize: 2000,
                        fileCount: 3,
                        metadata: ["type": "incremental"]
                    )
                    
                    let baseFiles = [
                        BackupFileInfo(path: "/file1.txt", size: 500, hash: "hash1", modified: Date().addingTimeInterval(-3600)),
                        BackupFileInfo(path: "/file2.txt", size: 500, hash: "hash2", modified: Date().addingTimeInterval(-3600))
                    ]
                    
                    let currentFiles = [
                        BackupFileInfo(path: "/file1.txt", size: 500, hash: "hash1", modified: Date().addingTimeInterval(-3600)),
                        BackupFileInfo(path: "/file2.txt", size: 500, hash: "hash2", modified: Date().addingTimeInterval(-3600)),
                        BackupFileInfo(path: "/file3.txt", size: 1000, hash: "hash3", modified: Date())
                    ]
                    
                    // When
                    let delta = try backupManager.calculateDelta(
                        currentSnapshot: currentSnapshot,
                        currentFiles: currentFiles,
                        previousSnapshot: baseSnapshot,
                        previousFiles: baseFiles
                    )
                    
                    // Then
                    expect(delta.changes).to(haveCount(1))
                    expect(delta.changes.first?.changeType).to(equal(.added))
                    expect(delta.changes.first?.path).to(equal("/file3.txt"))
                    expect(delta.totalSizeDelta).to(equal(1000))
                }
                
                it("should detect modified files") {
                    // Given
                    let baseSnapshot = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date().addingTimeInterval(-3600),
                        totalSize: 1000,
                        fileCount: 2,
                        metadata: ["type": "full"]
                    )
                    
                    let currentSnapshot = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date(),
                        totalSize: 1500,
                        fileCount: 2,
                        metadata: ["type": "incremental"]
                    )
                    
                    let baseFiles = [
                        BackupFileInfo(path: "/file1.txt", size: 500, hash: "hash1", modified: Date().addingTimeInterval(-3600)),
                        BackupFileInfo(path: "/file2.txt", size: 500, hash: "hash2", modified: Date().addingTimeInterval(-3600))
                    ]
                    
                    let currentFiles = [
                        BackupFileInfo(path: "/file1.txt", size: 1000, hash: "hash1_modified", modified: Date()),
                        BackupFileInfo(path: "/file2.txt", size: 500, hash: "hash2", modified: Date().addingTimeInterval(-3600))
                    ]
                    
                    // When
                    let delta = try backupManager.calculateDelta(
                        currentSnapshot: currentSnapshot,
                        currentFiles: currentFiles,
                        previousSnapshot: baseSnapshot,
                        previousFiles: baseFiles
                    )
                    
                    // Then
                    expect(delta.changes).to(haveCount(1))
                    expect(delta.changes.first?.changeType).to(equal(.modified))
                    expect(delta.changes.first?.path).to(equal("/file1.txt"))
                    expect(delta.changes.first?.sizeDelta).to(equal(500))
                    expect(delta.totalSizeDelta).to(equal(500))
                }
                
                it("should detect deleted files") {
                    // Given
                    let baseSnapshot = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date().addingTimeInterval(-3600),
                        totalSize: 1000,
                        fileCount: 2,
                        metadata: ["type": "full"]
                    )
                    
                    let currentSnapshot = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date(),
                        totalSize: 500,
                        fileCount: 1,
                        metadata: ["type": "incremental"]
                    )
                    
                    let baseFiles = [
                        BackupFileInfo(path: "/file1.txt", size: 500, hash: "hash1", modified: Date().addingTimeInterval(-3600)),
                        BackupFileInfo(path: "/file2.txt", size: 500, hash: "hash2", modified: Date().addingTimeInterval(-3600))
                    ]
                    
                    let currentFiles = [
                        BackupFileInfo(path: "/file1.txt", size: 500, hash: "hash1", modified: Date().addingTimeInterval(-3600))
                    ]
                    
                    // When
                    let delta = try backupManager.calculateDelta(
                        currentSnapshot: currentSnapshot,
                        currentFiles: currentFiles,
                        previousSnapshot: baseSnapshot,
                        previousFiles: baseFiles
                    )
                    
                    // Then
                    expect(delta.changes).to(haveCount(1))
                    expect(delta.changes.first?.changeType).to(equal(.deleted))
                    expect(delta.changes.first?.path).to(equal("/file2.txt"))
                    expect(delta.changes.first?.sizeDelta).to(equal(-500))
                    expect(delta.totalSizeDelta).to(equal(-500))
                }
                
                it("should handle no changes") {
                    // Given
                    let baseSnapshot = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date().addingTimeInterval(-3600),
                        totalSize: 1000,
                        fileCount: 2,
                        metadata: ["type": "full"]
                    )
                    
                    let currentSnapshot = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date(),
                        totalSize: 1000,
                        fileCount: 2,
                        metadata: ["type": "incremental"]
                    )
                    
                    let baseFiles = [
                        BackupFileInfo(path: "/file1.txt", size: 500, hash: "hash1", modified: Date().addingTimeInterval(-3600)),
                        BackupFileInfo(path: "/file2.txt", size: 500, hash: "hash2", modified: Date().addingTimeInterval(-3600))
                    ]
                    
                    let currentFiles = baseFiles
                    
                    // When
                    let delta = try backupManager.calculateDelta(
                        currentSnapshot: currentSnapshot,
                        currentFiles: currentFiles,
                        previousSnapshot: baseSnapshot,
                        previousFiles: baseFiles
                    )
                    
                    // Then
                    expect(delta.changes).to(beEmpty())
                    expect(delta.totalSizeDelta).to(equal(0))
                }
                
                it("should handle complex changes") {
                    // Given
                    let baseSnapshot = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date().addingTimeInterval(-3600),
                        totalSize: 1000,
                        fileCount: 2,
                        metadata: ["type": "full"]
                    )
                    
                    let currentSnapshot = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date(),
                        totalSize: 1200,
                        fileCount: 3,
                        metadata: ["type": "incremental"]
                    )
                    
                    let baseFiles = [
                        BackupFileInfo(path: "/file1.txt", size: 500, hash: "hash1", modified: Date().addingTimeInterval(-3600)),
                        BackupFileInfo(path: "/file2.txt", size: 500, hash: "hash2", modified: Date().addingTimeInterval(-3600))
                    ]
                    
                    let currentFiles = [
                        BackupFileInfo(path: "/file1.txt", size: 600, hash: "hash1_modified", modified: Date()),
                        BackupFileInfo(path: "/file3.txt", size: 600, hash: "hash3", modified: Date())
                    ]
                    
                    // When
                    let delta = try backupManager.calculateDelta(
                        currentSnapshot: currentSnapshot,
                        currentFiles: currentFiles,
                        previousSnapshot: baseSnapshot,
                        previousFiles: baseFiles
                    )
                    
                    // Then
                    expect(delta.changes).to(haveCount(3))
                    
                    let addedChanges = delta.changes.filter { $0.changeType == .added }
                    let modifiedChanges = delta.changes.filter { $0.changeType == .modified }
                    let deletedChanges = delta.changes.filter { $0.changeType == .deleted }
                    
                    expect(addedChanges).to(haveCount(1))
                    expect(modifiedChanges).to(haveCount(1))
                    expect(deletedChanges).to(haveCount(1))
                    
                    expect(delta.totalSizeDelta).to(equal(200))
                }
            }
            
            context("when creating incremental backup") {
                it("should create incremental backup with only changes") {
                    // Given
                    let changes = [
                        BackupFileChange(
                            path: "/file1.txt",
                            changeType: .modified,
                            sizeDelta: 100,
                            timestamp: Date()
                        ),
                        BackupFileChange(
                            path: "/file2.txt",
                            changeType: .added,
                            sizeDelta: 500,
                            timestamp: Date()
                        )
                    ]
                    
                    // When
                    let incrementalBackup = try backupManager.createIncrementalBackup(changes: changes)
                    
                    // Then
                    expect(incrementalBackup.metadata["type"]).to(equal("incremental"))
                    expect(incrementalBackup.fileCount).to(equal(2))
                    expect(incrementalBackup.totalSize).to(equal(600))
                }
                
                it("should handle empty changes") {
                    // Given
                    let changes: [BackupFileChange] = []
                    
                    // When
                    let incrementalBackup = try backupManager.createIncrementalBackup(changes: changes)
                    
                    // Then
                    expect(incrementalBackup.metadata["type"]).to(equal("incremental"))
                    expect(incrementalBackup.fileCount).to(equal(0))
                    expect(incrementalBackup.totalSize).to(equal(0))
                }
            }
            
            context("when optimizing backup size") {
                it("should compress incremental backup data") {
                    // Given
                    let changes = [
                        BackupFileChange(
                            path: "/file1.txt",
                            changeType: .modified,
                            sizeDelta: 100,
                            timestamp: Date()
                        )
                    ]
                    
                    // When
                    let compressedData = try backupManager.compressIncrementalBackup(changes: changes)
                    
                    // Then
                    expect(compressedData).toNot(beEmpty())
                    expect(compressedData.count).to(beLessThan(1000)) // Should be compressed
                }
                
                it("should decompress incremental backup data") {
                    // Given
                    let originalChanges = [
                        BackupFileChange(
                            path: "/file1.txt",
                            changeType: .modified,
                            sizeDelta: 100,
                            timestamp: Date()
                        )
                    ]
                    
                    let compressedData = try backupManager.compressIncrementalBackup(changes: originalChanges)
                    
                    // When
                    let decompressedChanges = try backupManager.decompressIncrementalBackup(data: compressedData)
                    
                    // Then
                    expect(decompressedChanges).to(haveCount(1))
                    expect(decompressedChanges.first?.path).to(equal("/file1.txt"))
                    expect(decompressedChanges.first?.changeType).to(equal(.modified))
                    expect(decompressedChanges.first?.sizeDelta).to(equal(100))
                }
            }
            
            context("when handling backup metadata") {
                it("should generate backup metadata") {
                    // Given
                    let changes = [
                        BackupFileChange(
                            path: "/file1.txt",
                            changeType: .added,
                            sizeDelta: 500,
                            timestamp: Date()
                        )
                    ]
                    
                    // When
                    let metadata = backupManager.generateBackupMetadata(changes: changes)
                    
                    // Then
                    expect(metadata["change_count"] as? Int).to(equal(1))
                    expect(metadata["total_size_delta"] as? Int64).to(equal(500))
                    expect(metadata["backup_type"] as? String).to(equal("incremental"))
                    expect(metadata["timestamp"]).toNot(beNil())
                }
                
                it("should calculate backup statistics") {
                    // Given
                    let changes = [
                        BackupFileChange(path: "/file1.txt", changeType: .added, sizeDelta: 500, timestamp: Date()),
                        BackupFileChange(path: "/file2.txt", changeType: .modified, sizeDelta: 100, timestamp: Date()),
                        BackupFileChange(path: "/file3.txt", changeType: .deleted, sizeDelta: -200, timestamp: Date())
                    ]
                    
                    // When
                    let stats = backupManager.calculateBackupStatistics(changes: changes)
                    
                    // Then
                    expect(stats.totalChanges).to(equal(3))
                    expect(stats.addedFiles).to(equal(1))
                    expect(stats.modifiedFiles).to(equal(1))
                    expect(stats.deletedFiles).to(equal(1))
                    expect(stats.totalSizeDelta).to(equal(400))
                    expect(stats.spaceSaved).to(equal(200))
                }
            }
            
            context("when handling backup validation") {
                it("should validate incremental backup integrity") {
                    // Given
                    let changes = [
                        BackupFileChange(
                            path: "/file1.txt",
                            changeType: .modified,
                            sizeDelta: 100,
                            timestamp: Date()
                        )
                    ]
                    
                    let incrementalBackup = try backupManager.createIncrementalBackup(changes: changes)
                    
                    // When
                    let isValid = try backupManager.validateIncrementalBackup(incrementalBackup)
                    
                    // Then
                    expect(isValid).to(beTrue())
                }
                
                it("should detect corrupted incremental backup") {
                    // Given
                    let corruptedBackup = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date(),
                        totalSize: -1, // Invalid size
                        fileCount: 1,
                        metadata: ["type": "incremental"]
                    )
                    
                    // When/Then
                    expect { try backupManager.validateIncrementalBackup(corruptedBackup) }
                        .to(throwError(IncrementalBackupError.invalidBackup(reason: "Negative total size")))
                }
            }
            
            context("when handling performance") {
                it("should process large file sets efficiently") {
                    // Given
                    let baseFiles = (0..<1000).map { i in
                        BackupFileInfo(
                            path: "/file\(i).txt",
                            size: Int64(1000 + i),
                            hash: "hash\(i)",
                            modified: Date().addingTimeInterval(-3600)
                        )
                    }
                    
                    let currentFiles = baseFiles + [
                        BackupFileInfo(
                            path: "/newfile.txt",
                            size: 5000,
                            hash: "newhash",
                            modified: Date()
                        )
                    ]
                    
                    let baseSnapshot = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date().addingTimeInterval(-3600),
                        totalSize: baseFiles.reduce(0) { $0 + $1.size },
                        fileCount: baseFiles.count,
                        metadata: ["type": "full"]
                    )
                    
                    let currentSnapshot = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date(),
                        totalSize: currentFiles.reduce(0) { $0 + $1.size },
                        fileCount: currentFiles.count,
                        metadata: ["type": "incremental"]
                    )
                    
                    // When
                    let startTime = Date()
                    let delta = try backupManager.calculateDelta(
                        currentSnapshot: currentSnapshot,
                        currentFiles: currentFiles,
                        previousSnapshot: baseSnapshot,
                        previousFiles: baseFiles
                    )
                    let duration = Date().timeIntervalSince(startTime)
                    
                    // Then
                    expect(delta.changes).to(haveCount(1))
                    expect(duration).to(beLessThan(5.0)) // Should complete within 5 seconds
                }
            }
        }
    }
}
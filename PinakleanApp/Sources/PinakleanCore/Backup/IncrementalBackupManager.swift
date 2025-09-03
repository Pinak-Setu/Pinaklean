import Foundation
import Compression
import CryptoKit
import os.log

/// Advanced incremental backup manager with delta calculation and optimization
/// Provides efficient backup strategies by only storing changes between snapshots
public struct IncrementalBackupManager {
    
    private static let logger = Logger(subsystem: "com.pinaklean", category: "IncrementalBackupManager")
    
    // MARK: - Delta Calculation
    
    /// Calculate delta between current and previous backup snapshots
    /// - Parameters:
    ///   - currentSnapshot: Current disk snapshot
    ///   - currentFiles: Current file list with metadata
    ///   - previousSnapshot: Previous backup snapshot
    ///   - previousFiles: Previous file list with metadata
    /// - Returns: Delta containing all changes
    public func calculateDelta(
        currentSnapshot: DiskSnapshot,
        currentFiles: [BackupFileInfo],
        previousSnapshot: DiskSnapshot,
        previousFiles: [BackupFileInfo]
    ) throws -> BackupDelta {
        
        logger.info("Calculating delta between snapshots: \(previousSnapshot.id) -> \(currentSnapshot.id)")
        
        let startTime = Date()
        
        // Create lookup maps for efficient comparison
        let previousFileMap = Dictionary(uniqueKeysWithValues: previousFiles.map { ($0.path, $0) })
        let currentFileMap = Dictionary(uniqueKeysWithValues: currentFiles.map { ($0.path, $0) })
        
        var changes: [BackupFileChange] = []
        var totalSizeDelta: Int64 = 0
        
        // Find added and modified files
        for (path, currentFile) in currentFileMap {
            if let previousFile = previousFileMap[path] {
                // File exists in both - check if modified
                if currentFile.hash != previousFile.hash || currentFile.modified != previousFile.modified {
                    let sizeDelta = currentFile.size - previousFile.size
                    let change = BackupFileChange(
                        path: path,
                        changeType: .modified,
                        sizeDelta: sizeDelta,
                        timestamp: currentFile.modified
                    )
                    changes.append(change)
                    totalSizeDelta += sizeDelta
                    
                    logger.debug("Modified file: \(path), size delta: \(sizeDelta)")
                }
            } else {
                // New file
                let change = BackupFileChange(
                    path: path,
                    changeType: .added,
                    sizeDelta: currentFile.size,
                    timestamp: currentFile.modified
                )
                changes.append(change)
                totalSizeDelta += currentFile.size
                
                logger.debug("Added file: \(path), size: \(currentFile.size)")
            }
        }
        
        // Find deleted files
        for (path, previousFile) in previousFileMap {
            if currentFileMap[path] == nil {
                let change = BackupFileChange(
                    path: path,
                    changeType: .deleted,
                    sizeDelta: -previousFile.size,
                    timestamp: Date()
                )
                changes.append(change)
                totalSizeDelta -= previousFile.size
                
                logger.debug("Deleted file: \(path), size: \(previousFile.size)")
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        logger.info("Delta calculation completed in \(String(format: "%.2f", duration))s - \(changes.count) changes, \(totalSizeDelta) bytes delta")
        
        return BackupDelta(
            changes: changes,
            totalSizeDelta: totalSizeDelta,
            previousSnapshotId: previousSnapshot.id,
            currentSnapshotId: currentSnapshot.id,
            calculationTime: duration
        )
    }
    
    // MARK: - Incremental Backup Creation
    
    /// Create incremental backup from delta changes
    /// - Parameter changes: Array of file changes
    /// - Returns: Incremental backup snapshot
    public func createIncrementalBackup(changes: [BackupFileChange]) throws -> DiskSnapshot {
        logger.info("Creating incremental backup with \(changes.count) changes")
        
        let totalSize = changes.reduce(0) { $0 + abs($1.sizeDelta) }
        let metadata: [String: String] = [
            "type": "incremental",
            "change_count": String(changes.count),
            "total_size_delta": String(totalSize),
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let snapshot = DiskSnapshot(
            id: UUID(),
            timestamp: Date(),
            totalSize: totalSize,
            fileCount: changes.count,
            metadata: metadata
        )
        
        logger.info("Created incremental backup: \(snapshot.id)")
        return snapshot
    }
    
    // MARK: - Compression and Optimization
    
    /// Compress incremental backup data
    /// - Parameter changes: Array of file changes
    /// - Returns: Compressed data
    public func compressIncrementalBackup(changes: [BackupFileChange]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(changes)
        
        // Use zlib compression for better compression ratio
        let compressedData = try (jsonData as NSData).compressed(using: .zlib) as Data
        
        logger.debug("Compressed incremental backup: \(jsonData.count) -> \(compressedData.count) bytes (\(String(format: "%.1f", Double(compressedData.count) / Double(jsonData.count) * 100))%)")
        
        return compressedData
    }
    
    /// Decompress incremental backup data
    /// - Parameter data: Compressed data
    /// - Returns: Array of file changes
    public func decompressIncrementalBackup(data: Data) throws -> [BackupFileChange] {
        let decompressedData = try (data as NSData).decompressed(using: .zlib) as Data
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let changes = try decoder.decode([BackupFileChange].self, from: decompressedData)
        
        logger.debug("Decompressed incremental backup: \(data.count) -> \(decompressedData.count) bytes")
        
        return changes
    }
    
    // MARK: - Backup Metadata and Statistics
    
    /// Generate backup metadata
    /// - Parameter changes: Array of file changes
    /// - Returns: Metadata dictionary
    public func generateBackupMetadata(changes: [BackupFileChange]) -> [String: Any] {
        let stats = calculateBackupStatistics(changes: changes)
        
        return [
            "change_count": stats.totalChanges,
            "added_files": stats.addedFiles,
            "modified_files": stats.modifiedFiles,
            "deleted_files": stats.deletedFiles,
            "total_size_delta": stats.totalSizeDelta,
            "space_saved": stats.spaceSaved,
            "backup_type": "incremental",
            "timestamp": Date().timeIntervalSince1970,
            "compression_ratio": calculateCompressionRatio(changes: changes)
        ]
    }
    
    /// Calculate backup statistics
    /// - Parameter changes: Array of file changes
    /// - Returns: Backup statistics
    public func calculateBackupStatistics(changes: [BackupFileChange]) -> BackupStatistics {
        let addedFiles = changes.filter { $0.changeType == .added }.count
        let modifiedFiles = changes.filter { $0.changeType == .modified }.count
        let deletedFiles = changes.filter { $0.changeType == .deleted }.count
        
        let totalSizeDelta = changes.reduce(0) { $0 + $1.sizeDelta }
        let spaceSaved = changes.filter { $0.changeType == .deleted }.reduce(0) { $0 + abs($1.sizeDelta) }
        
        return BackupStatistics(
            totalChanges: changes.count,
            addedFiles: addedFiles,
            modifiedFiles: modifiedFiles,
            deletedFiles: deletedFiles,
            totalSizeDelta: totalSizeDelta,
            spaceSaved: spaceSaved,
            averageChangeSize: changes.isEmpty ? 0 : totalSizeDelta / Int64(changes.count)
        )
    }
    
    /// Calculate compression ratio for changes
    /// - Parameter changes: Array of file changes
    /// - Returns: Compression ratio (0.0 to 1.0)
    private func calculateCompressionRatio(changes: [BackupFileChange]) -> Double {
        do {
            let originalData = try JSONEncoder().encode(changes)
            let compressedData = try compressIncrementalBackup(changes: changes)
            return Double(compressedData.count) / Double(originalData.count)
        } catch {
            logger.error("Failed to calculate compression ratio: \(error.localizedDescription)")
            return 1.0
        }
    }
    
    // MARK: - Backup Validation
    
    /// Validate incremental backup integrity
    /// - Parameter backup: Backup snapshot to validate
    /// - Returns: True if valid, throws error if invalid
    public func validateIncrementalBackup(_ backup: DiskSnapshot) throws -> Bool {
        logger.debug("Validating incremental backup: \(backup.id)")
        
        // Check basic integrity
        guard backup.totalSize >= 0 else {
            throw IncrementalBackupError.invalidBackup(reason: "Negative total size")
        }
        
        guard backup.fileCount >= 0 else {
            throw IncrementalBackupError.invalidBackup(reason: "Negative file count")
        }
        
        // Check metadata
        guard backup.metadata["type"] == "incremental" else {
            throw IncrementalBackupError.invalidBackup(reason: "Invalid backup type")
        }
        
        // Validate timestamp
        guard backup.timestamp <= Date() else {
            throw IncrementalBackupError.invalidBackup(reason: "Future timestamp")
        }
        
        logger.debug("Incremental backup validation passed: \(backup.id)")
        return true
    }
    
    // MARK: - Backup Optimization
    
    /// Optimize backup by removing redundant changes
    /// - Parameter changes: Array of file changes
    /// - Returns: Optimized array of changes
    public func optimizeBackupChanges(_ changes: [BackupFileChange]) -> [BackupFileChange] {
        logger.debug("Optimizing \(changes.count) backup changes")
        
        var optimizedChanges: [BackupFileChange] = []
        var pathToLatestChange: [String: BackupFileChange] = [:]
        
        // Group changes by path and keep only the latest change for each file
        for change in changes {
            if let existingChange = pathToLatestChange[change.path] {
                // If we have multiple changes for the same file, keep the latest one
                if change.timestamp > existingChange.timestamp {
                    pathToLatestChange[change.path] = change
                }
            } else {
                pathToLatestChange[change.path] = change
            }
        }
        
        // Convert back to array
        optimizedChanges = Array(pathToLatestChange.values)
        
        let originalCount = changes.count
        let optimizedCount = optimizedChanges.count
        
        if originalCount != optimizedCount {
            logger.info("Optimized backup changes: \(originalCount) -> \(optimizedCount) (\(originalCount - optimizedCount) redundant changes removed)")
        }
        
        return optimizedChanges
    }
    
    /// Calculate backup efficiency metrics
    /// - Parameters:
    ///   - incrementalSize: Size of incremental backup
    ///   - fullBackupSize: Size of full backup
    /// - Returns: Efficiency metrics
    public func calculateBackupEfficiency(incrementalSize: Int64, fullBackupSize: Int64) -> BackupEfficiencyMetrics {
        let compressionRatio = fullBackupSize > 0 ? Double(incrementalSize) / Double(fullBackupSize) : 1.0
        let spaceSaved = max(0, fullBackupSize - incrementalSize)
        let efficiencyPercentage = fullBackupSize > 0 ? (1.0 - compressionRatio) * 100 : 0.0
        
        return BackupEfficiencyMetrics(
            incrementalSize: incrementalSize,
            fullBackupSize: fullBackupSize,
            compressionRatio: compressionRatio,
            spaceSaved: spaceSaved,
            efficiencyPercentage: efficiencyPercentage,
            isEfficient: compressionRatio < 0.5 // Consider efficient if less than 50% of full backup
        )
    }
    
    // MARK: - Backup Recovery
    
    /// Reconstruct full backup from incremental changes
    /// - Parameters:
    ///   - baseBackup: Base backup snapshot
    ///   - incrementalChanges: Array of incremental changes
    /// - Returns: Reconstructed full backup
    public func reconstructFullBackup(
        baseBackup: DiskSnapshot,
        incrementalChanges: [BackupFileChange]
    ) throws -> DiskSnapshot {
        logger.info("Reconstructing full backup from \(incrementalChanges.count) incremental changes")
        
        let stats = calculateBackupStatistics(changes: incrementalChanges)
        let newTotalSize = baseBackup.totalSize + stats.totalSizeDelta
        let newFileCount = baseBackup.fileCount + stats.addedFiles - stats.deletedFiles
        
        let reconstructedBackup = DiskSnapshot(
            id: UUID(),
            timestamp: Date(),
            totalSize: newTotalSize,
            fileCount: newFileCount,
            metadata: [
                "type": "reconstructed",
                "base_backup_id": baseBackup.id.uuidString,
                "incremental_changes": String(incrementalChanges.count),
                "reconstructed_at": ISO8601DateFormatter().string(from: Date())
            ]
        )
        
        logger.info("Reconstructed full backup: \(reconstructedBackup.id)")
        return reconstructedBackup
    }
}

// MARK: - Supporting Types

/// File information for backup operations
public struct BackupFileInfo: Codable, Equatable {
    public let path: String
    public let size: Int64
    public let hash: String
    public let modified: Date
    
    public init(path: String, size: Int64, hash: String, modified: Date) {
        self.path = path
        self.size = size
        self.hash = hash
        self.modified = modified
    }
}

/// Backup delta containing all changes between snapshots
public struct BackupDelta: Codable {
    public let changes: [BackupFileChange]
    public let totalSizeDelta: Int64
    public let previousSnapshotId: UUID
    public let currentSnapshotId: UUID
    public let calculationTime: TimeInterval
    
    /// Check if delta has any changes
    public var hasChanges: Bool {
        return !changes.isEmpty
    }
    
    /// Get changes by type
    public func changes(ofType type: BackupFileChange.ChangeType) -> [BackupFileChange] {
        return changes.filter { $0.changeType == type }
    }
    
    /// Calculate space that could be freed
    public var spaceThatCanBeFreed: Int64 {
        return changes.filter { $0.changeType == .deleted }.reduce(0) { $0 + abs($1.sizeDelta) }
    }
}

/// Backup statistics
public struct BackupStatistics: Codable {
    public let totalChanges: Int
    public let addedFiles: Int
    public let modifiedFiles: Int
    public let deletedFiles: Int
    public let totalSizeDelta: Int64
    public let spaceSaved: Int64
    public let averageChangeSize: Int64
    
    /// Calculate change distribution percentages
    public var changeDistribution: (added: Double, modified: Double, deleted: Double) {
        guard totalChanges > 0 else { return (0, 0, 0) }
        
        return (
            added: Double(addedFiles) / Double(totalChanges) * 100,
            modified: Double(modifiedFiles) / Double(totalChanges) * 100,
            deleted: Double(deletedFiles) / Double(totalChanges) * 100
        )
    }
}

/// Backup efficiency metrics
public struct BackupEfficiencyMetrics: Codable {
    public let incrementalSize: Int64
    public let fullBackupSize: Int64
    public let compressionRatio: Double
    public let spaceSaved: Int64
    public let efficiencyPercentage: Double
    public let isEfficient: Bool
    
    /// Formatted efficiency description
    public var efficiencyDescription: String {
        if isEfficient {
            return "Highly efficient (\(String(format: "%.1f", efficiencyPercentage))% space saved)"
        } else {
            return "Moderate efficiency (\(String(format: "%.1f", efficiencyPercentage))% space saved)"
        }
    }
}

// MARK: - Error Types

public enum IncrementalBackupError: LocalizedError {
    case invalidBackup(reason: String)
    case compressionFailed
    case decompressionFailed
    case deltaCalculationFailed
    case validationFailed(reason: String)
    case reconstructionFailed(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidBackup(let reason):
            return "Invalid backup: \(reason)"
        case .compressionFailed:
            return "Failed to compress backup data"
        case .decompressionFailed:
            return "Failed to decompress backup data"
        case .deltaCalculationFailed:
            return "Failed to calculate backup delta"
        case .validationFailed(let reason):
            return "Backup validation failed: \(reason)"
        case .reconstructionFailed(let reason):
            return "Backup reconstruction failed: \(reason)"
        }
    }
}
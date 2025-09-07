import Foundation
import os.log

/// Real file cleaner that performs actual file deletion operations
/// Replaces simulation with production-grade file cleaning
public actor RealFileCleaner {
    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: "com.pinaklean", category: "FileCleaner")
    
    public init() {}
    
    /// Clean (delete) a list of files
    public func cleanFiles(_ items: [CleanableItem], dryRun: Bool = false) async throws -> CleanResults {
        logger.info("Starting real file cleaning: \(items.count) items, dryRun: \(dryRun)")
        
        var results = CleanResults()
        results.timestamp = Date()
        results.isDryRun = dryRun
        
        for item in items {
            do {
                if dryRun {
                    // Dry run - just simulate
                    results.deletedItems.append(item)
                    results.freedSpace += item.size
                    logger.info("DRY RUN: Would delete \(item.path)")
                } else {
                    // Actually delete the file
                    try await deleteFile(at: item.path)
                    results.deletedItems.append(item)
                    results.freedSpace += item.size
                    logger.info("Deleted: \(item.path)")
                }
            } catch {
                logger.error("Failed to delete \(item.path): \(error)")
                results.failedItems.append(item)
            }
        }
        
        logger.info("Real cleaning completed: \(results.deletedItems.count) deleted, \(results.failedItems.count) failed")
        return results
    }
    
    /// Delete a single file with proper error handling
    private func deleteFile(at path: String) async throws {
        // Check if file exists
        guard fileManager.fileExists(atPath: path) else {
            throw FileCleanerError.fileNotFound(path)
        }
        
        // Check if file is writable (can be deleted)
        guard fileManager.isWritableFile(atPath: path) else {
            throw FileCleanerError.permissionDenied(path)
        }
        
        // Perform the actual deletion
        try fileManager.removeItem(atPath: path)
    }
}

/// File cleaner errors
public enum FileCleanerError: Error, LocalizedError, Sendable {
    case fileNotFound(String)
    case permissionDenied(String)
    case deletionFailed(String, Error)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .permissionDenied(let path):
            return "Permission denied for: \(path)"
        case .deletionFailed(let path, let error):
            return "Failed to delete \(path): \(error.localizedDescription)"
        }
    }
}
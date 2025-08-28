import Foundation
import SQLite

/// Incremental indexer for efficient file system monitoring and indexing
public actor IncrementalIndexer {
    // Database schema
    private let db: Connection
    private let filesTable = Table("files")
    private let scansTable = Table("scans")
    private let changesTable = Table("changes")

    // Index state
    private var lastScanTime: Date?
    private var indexedPaths: Set<String> = []
    private var isMonitoring = false

    // Configuration
    private let indexBatchSize = 1000
    private let maxConcurrentScans = 4
    private let dbPath: String

    public init() async throws {
        // Set up database path
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let pinakleanDir = appSupport.appendingPathComponent("Pinaklean", isDirectory: true)
        try? FileManager.default.createDirectory(at: pinakleanDir, withIntermediateDirectories: true)

        dbPath = pinakleanDir.appendingPathComponent("index.db").path

        // Initialize database
        db = try Connection(dbPath)
        try await setupDatabase()

        // Load existing index state
        await loadIndexState()
    }

    /// Start monitoring file system for changes
    public func startMonitoring() async {
        guard !isMonitoring else { return }

        isMonitoring = true
        print("Starting incremental file monitoring...")
        print("File monitoring started (simplified implementation)")
    }

    /// Stop monitoring
    public func stopMonitoring() {
        isMonitoring = false
        print("File monitoring stopped")
    }

    /// Perform incremental scan
    public func incrementalScan() async throws -> ScanDelta {
        let startTime = Date()
        print("Starting incremental scan...")

        var delta = ScanDelta()

        // Find changed files since last scan
        let changedFiles = try await findChangedFiles()

        // Process changes
        for change in changedFiles {
            switch change.type {
            case .added, .modified:
                if let fileInfo = try? await indexFile(at: change.path) {
                    delta.added.append(fileInfo)
                }
            case .deleted:
                delta.deleted.append(change.path)
                try await removeFromIndex(change.path)
            }
        }

        // Update scan metadata
        try await recordScan(startTime: startTime, delta: delta)
        lastScanTime = Date()

        print("Incremental scan completed: \(delta.added.count) added, \(delta.deleted.count) deleted")

        return delta
    }

    /// Get files changed since timestamp
    public func getFilesChanged(since timestamp: Date) async throws -> [IndexedFile] {
        let query = filesTable
            .filter(filesTable[Expression<Date>("modified_date")] > timestamp)
            .order(filesTable[Expression<Date>("modified_date")].desc)

        return try db.prepare(query).map { row in
            IndexedFile(
                path: row[Expression<String>("path")],
                size: row[Expression<Int64>("size")],
                modifiedDate: row[Expression<Date>("modified_date")],
                hash: row[Expression<String?>("hash")],
                category: row[Expression<String>("category")]
            )
        }
    }

    /// Get files by category
    public func getFilesByCategory(_ category: String) async throws -> [IndexedFile] {
        let query = filesTable
            .filter(filesTable[Expression<String>("category")] == category)
            .order(filesTable[Expression<Int64>("size")].desc)

        return try db.prepare(query).map { row in
            IndexedFile(
                path: row[Expression<String>("path")],
                size: row[Expression<Int64>("size")],
                modifiedDate: row[Expression<Date>("modified_date")],
                hash: row[Expression<String?>("hash")],
                category: row[Expression<String>("category")]
            )
        }
    }

    /// Search files by name or path
    public func searchFiles(query: String, limit: Int = 100) async throws -> [IndexedFile] {
        let searchPattern = "%\(query.lowercased())%"

                let sqlQuery = filesTable
            .filter(Expression<String>("path").like(searchPattern) ||
                    Expression<String>("name").like(searchPattern))
            .order(Expression<Date>("modified_date").desc)
            .limit(limit)

        return try db.prepare(sqlQuery).map { row in
            IndexedFile(
                path: row[Expression<String>("path")],
                size: row[Expression<Int64>("size")],
                modifiedDate: row[Expression<Date>("modified_date")],
                hash: row[Expression<String?>("hash")],
                category: row[Expression<String>("category")]
            )
        }
    }

    /// Get storage statistics
    public func getStorageStats() async throws -> StorageStats {
        let totalFiles = try db.scalar(filesTable.count)
        let totalSize = try db.scalar(filesTable.select(filesTable[Expression<Int64>("size")].sum))

        // Get stats by category
        var categoryStats: [String: CategoryStats] = [:]

        let categoryQuery = filesTable
            .select(filesTable[Expression<String>("category")],
                   filesTable[Expression<Int64>("size")].sum,
                   filesTable[Expression<String>("category")].count)
            .group(Expression<String>("category"))

        for row in try db.prepare(categoryQuery) {
            let category = row[Expression<String>("category")]
            let size = row[Expression<Int64>("size").sum] ?? 0
            let count = row[Expression<String>("category").count]

            categoryStats[category] = CategoryStats(
                fileCount: count,
                totalSize: size,
                averageSize: count > 0 ? size / Int64(count) : 0
            )
        }

        return StorageStats(
            totalFiles: totalFiles,
            totalSize: totalSize ?? 0,
            categoryStats: categoryStats,
            lastUpdated: lastScanTime ?? Date()
        )
    }

    /// Clear index (for full rebuild)
    public func clearIndex() async throws {
        try db.run(filesTable.delete())
        try db.run(changesTable.delete())
        indexedPaths.removeAll()
        print("Index cleared")
    }

    // MARK: - Private Methods

    private func setupDatabase() async throws {
        // Create tables
        try db.run(filesTable.create(ifNotExists: true) { table in
            table.column(Expression<String>("path"), primaryKey: true)
            table.column(Expression<String>("name"))
            table.column(Expression<String>("category"))
            table.column(Expression<Int64>("size"))
            table.column(Expression<Date>("modified_date"))
            table.column(Expression<Date>("created_date"))
            table.column(Expression<String?>("hash"))
            table.column(Expression<Date>("indexed_at"))
        })

        try db.run(scansTable.create(ifNotExists: true) { table in
            table.column(Expression<Int64>("id"), primaryKey: .autoincrement)
            table.column(Expression<Date>("start_time"))
            table.column(Expression<Date>("end_time"))
            table.column(Expression<Int>("files_added"))
            table.column(Expression<Int>("files_deleted"))
            table.column(Expression<Int64>("bytes_processed"))
        })

        try db.run(changesTable.create(ifNotExists: true) { table in
            table.column(Expression<Int64>("id"), primaryKey: .autoincrement)
            table.column(Expression<String>("path"))
            table.column(Expression<String>("change_type")) // "added", "modified", "deleted"
            table.column(Expression<Date>("detected_at"))
            table.column(Expression<Bool>("processed"), defaultValue: false)
        })

        // Create indexes for performance
        try db.run(filesTable.createIndex(filesTable[Expression<String>("category")], ifNotExists: true))
        try db.run(filesTable.createIndex(filesTable[Expression<Date>("modified_date")], ifNotExists: true))
        try db.run(filesTable.createIndex(filesTable[Expression<String>("name")], ifNotExists: true))
    }

    private func loadIndexState() async {
        // Load indexed paths
        let paths = try? db.prepare(filesTable.select(filesTable[Expression<String>("path")]))
        indexedPaths = Set(paths?.map { $0[Expression<String>("path")] } ?? [])

        // Load last scan time
        if let lastScan = try? db.scalar(scansTable.select(scansTable[Expression<Date>("end_time")]).order(scansTable[Expression<Date>("end_time")].desc).limit(1)) {
            lastScanTime = lastScan
        }

        print("Loaded index state: \(indexedPaths.count) files indexed")
    }

    private func getPathsToMonitor() -> [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path

        return [
            "\(home)/Documents",
            "\(home)/Desktop",
            "\(home)/Downloads",
            "\(home)/Library/Caches",
            "\(home)/Library/Application Support",
            "/tmp",
            "/var/tmp"
        ].filter { FileManager.default.fileExists(atPath: $0) }
    }



    private func recordChange(_ path: String, type: FileChangeType) async throws {
        let insert = changesTable.insert(
            Expression<String>("path") <- path,
            Expression<String>("change_type") <- type.rawValue,
            Expression<Date>("detected_at") <- Date(),
            Expression<Bool>("processed") <- false
        )

        try db.run(insert)
    }

    private func findChangedFiles() async throws -> [FileChange] {
        // Get unprocessed changes
        let unprocessedQuery = changesTable
            .filter(changesTable[Expression<Bool>("processed")] == false)
            .order(changesTable[Expression<Date>("detected_at")].asc)

        var changes: [FileChange] = []

        for row in try db.prepare(unprocessedQuery) {
            let path = row[Expression<String>("path")]
            let changeTypeString = row[Expression<String>("change_type")]

            if let changeType = FileChangeType(rawValue: changeTypeString) {
                changes.append(FileChange(
                    path: path,
                    type: changeType,
                    detectedAt: Date()
                ))
            }
        }

        // Also check for files that may have changed without events
        if let lastScan = lastScanTime {
            let modifiedFiles = try await findModifiedFiles(since: lastScan)
            changes.append(contentsOf: modifiedFiles)
        }

        return changes
    }

    private func findModifiedFiles(since timestamp: Date) async throws -> [FileChange] {
        var changes: [FileChange] = []

        // Check a sample of indexed files for modifications
        let sampleSize = 1000
        let sampleQuery = filesTable
            .order(filesTable[Expression<Date>("modified_date")].desc)
            .limit(sampleSize)

        for row in try db.prepare(sampleQuery) {
            let path = row[Expression<String>("path")]
            let indexedModified = row[Expression<Date>("modified_date")]

            if let currentModified = try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date,
               currentModified > indexedModified {
                changes.append(FileChange(
                    path: path,
                    type: .modified,
                    detectedAt: Date()
                ))
            }
        }

        return changes
    }

    private func indexFile(at path: String) async throws -> IndexedFile? {
        let url = URL(fileURLWithPath: path)
        let attributes = try FileManager.default.attributesOfItem(atPath: path)

        guard let size = attributes[.size] as? Int64,
              let modifiedDate = attributes[.modificationDate] as? Date else {
            return nil
        }

        // Generate hash for duplicate detection
        let hash = try? await generateFileHash(at: path)

        // Determine category
        let category = determineCategory(for: path)

        let fileInfo = IndexedFile(
            path: path,
            size: size,
            modifiedDate: modifiedDate,
            hash: hash,
            category: category
        )

        // Store in database
        let insert = filesTable.insert(or: .replace,
            Expression<String>("path") <- path,
            Expression<String>("name") <- url.lastPathComponent,
            Expression<String>("category") <- category,
            Expression<Int64>("size") <- size,
            Expression<Date>("modified_date") <- modifiedDate,
            Expression<Date>("created_date") <- (attributes[.creationDate] as? Date ?? modifiedDate),
            Expression<String?>("hash") <- hash,
            Expression<Date>("indexed_at") <- Date()
        )

        try db.run(insert)
        indexedPaths.insert(path)

        return fileInfo
    }

    private func removeFromIndex(_ path: String) async throws {
        try db.run(filesTable.filter(filesTable[Expression<String>("path")] == path).delete())
        indexedPaths.remove(path)
    }

    private func recordScan(startTime: Date, delta: ScanDelta) async throws {
        let insert = scansTable.insert(
            Expression<Date>("start_time") <- startTime,
            Expression<Date>("end_time") <- Date(),
            Expression<Int>("files_added") <- delta.added.count,
            Expression<Int>("files_deleted") <- delta.deleted.count,
            Expression<Int64>("bytes_processed") <- delta.added.reduce(0) { $0 + $1.size }
        )

        try db.run(insert)

        // Mark changes as processed
        try db.run(changesTable.filter(changesTable[Expression<Bool>("processed")] == false)
            .update(Expression<Bool>("processed") <- true))
    }

    private func generateFileHash(at path: String) async throws -> String {
        // Use SHA256 for file hashing
        let task = Process()
        task.launchPath = "/usr/bin/shasum"
        task.arguments = ["-a", "256", path]

        let pipe = Pipe()
        task.standardOutput = pipe

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.components(separatedBy: .whitespaces)[0]
            }
        }

        throw NSError(domain: "IncrementalIndexer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate file hash"])
    }

    private func determineCategory(for path: String) -> String {
        let url = URL(fileURLWithPath: path)

        // Check for common patterns
        if path.contains("/node_modules/") || path.contains("/.npm/") {
            return "node_modules"
        } else if path.contains("/.next/") || path.contains("/.nuxt/") {
            return "build_cache"
        } else if path.contains("/Library/Caches/") {
            return "system_cache"
        } else if path.contains(".log") {
            return "logs"
        } else if path.contains("/tmp/") || path.contains("/var/tmp/") {
            return "temporary"
        } else if ["jpg", "png", "gif", "mp4", "mov"].contains(url.pathExtension) {
            return "media"
        } else if ["pdf", "doc", "docx", "txt"].contains(url.pathExtension) {
            return "documents"
        } else {
            return "other"
        }
    }
}

// MARK: - Supporting Types

public struct ScanDelta {
    public var added: [IndexedFile] = []
    public var deleted: [String] = []
    public var modified: [IndexedFile] = []

    public var totalChanges: Int {
        added.count + deleted.count + modified.count
    }
}

public struct IndexedFile {
    public let path: String
    public let size: Int64
    public let modifiedDate: Date
    public let hash: String?
    public let category: String
}

public struct FileChange {
    public let path: String
    public let type: FileChangeType
    public let detectedAt: Date
}

public enum FileChangeType: String {
    case added, modified, deleted
}

public struct StorageStats {
    public let totalFiles: Int
    public let totalSize: Int64
    public let categoryStats: [String: CategoryStats]
    public let lastUpdated: Date
}

public struct CategoryStats {
    public let fileCount: Int
    public let totalSize: Int64
    public let averageSize: Int64
}

// MARK: - Simplified File Monitoring
// Note: In production, implement FSEvents or DispatchSource for proper file monitoring

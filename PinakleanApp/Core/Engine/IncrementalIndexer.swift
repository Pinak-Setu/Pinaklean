//
//  Enhanced IncrementalIndexer.swift
//  PinakleanApp
//
//  Advanced incremental file indexer with FSEvents monitoring,
//  bloom filters, and efficient metadata caching
//

import Foundation
import CoreServices
import os.log

/// Advanced incremental indexer for efficient file system scanning
/// Provides real-time monitoring, change detection, and optimized indexing
public actor IncrementalIndexer {

    // MARK: - Types

    public enum IndexState {
        case idle, scanning, monitoring, updating, error
    }

    public struct FileIndexEntry: Codable, Hashable {
        public let path: String
        public let size: Int64
        public let modificationDate: Date
        public let creationDate: Date
        public let isDirectory: Bool
        public let fileType: String?
        public let inode: UInt64?
        public var lastIndexed: Date
        public var changeFlags: ChangeFlags

        public init(path: String, size: Int64, modificationDate: Date,
                   creationDate: Date, isDirectory: Bool, fileType: String? = nil,
                   inode: UInt64? = nil) {
            self.path = path
            self.size = size
            self.modificationDate = modificationDate
            self.creationDate = creationDate
            self.isDirectory = isDirectory
            self.fileType = fileType
            self.inode = inode
            self.lastIndexed = Date()
            self.changeFlags = []
        }
    }

    public struct ChangeFlags: OptionSet, Codable, Hashable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let created = ChangeFlags(rawValue: 1 << 0)
        public static let modified = ChangeFlags(rawValue: 1 << 1)
        public static let deleted = ChangeFlags(rawValue: 1 << 2)
        public static let renamed = ChangeFlags(rawValue: 1 << 3)
        public static let metadataChanged = ChangeFlags(rawValue: 1 << 4)
        public static let sizeChanged = ChangeFlags(rawValue: 1 << 5)
    }

    public struct IndexStatistics {
        public var totalFiles: Int = 0
        public var totalSize: Int64 = 0
        public var indexedDirectories: Int = 0
        public var lastFullScan: Date?
        public var averageScanTime: TimeInterval = 0
        public var cacheHitRate: Double = 0
    }

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.pinaklean", category: "IncrementalIndexer")
    private let fileManager = FileManager.default
    private let indexQueue = DispatchQueue(label: "com.pinaklean.indexer", qos: .background)

    // Core data structures
    private var fileIndex: [String: FileIndexEntry] = [:]
    private var directoryIndex: [String: DirectoryInfo] = [:]
    private var bloomFilter: BloomFilter<String>
    private var statistics = IndexStatistics()

    // FSEvents monitoring
    private var fsEventStream: FSEventStreamRef?
    private var isMonitoring = false
    private var monitoredPaths: Set<String> = []

    // Configuration
    private let maxCacheSize = 100_000
    private let indexSaveInterval: TimeInterval = 300 // 5 minutes
    private let fullScanInterval: TimeInterval = 86400 // 24 hours

    // State management
    private var lastFullScan: Date?
    private var lastIncrementalUpdate: Date?
    private var isIndexing = false
    private var pendingChanges: [(path: String, flags: ChangeFlags)] = []

    // Persistence
    private let indexDirectory: URL
    private let indexFileURL: URL
    private let bloomFilterFileURL: URL

    // MARK: - Initialization

    public init() async throws {
        // Initialize bloom filter with optimal size
        bloomFilter = BloomFilter<String>(expectedElements: maxCacheSize, falsePositiveRate: 0.01)

        // Set up persistence directory
        let appSupport = try fileManager.url(for: .applicationSupportDirectory,
                                           in: .userDomainMask,
                                           appropriateFor: nil,
                                           create: true)
        indexDirectory = appSupport.appendingPathComponent("Pinaklean/Index")
        indexFileURL = indexDirectory.appendingPathComponent("fileIndex.json")
        bloomFilterFileURL = indexDirectory.appendingPathComponent("bloomFilter.data")

        try fileManager.createDirectory(at: indexDirectory, withIntermediateDirectories: true)

        // Load existing index
        await loadIndexState()

        logger.info("IncrementalIndexer initialized with \(self.fileIndex.count) cached entries")
    }

    // MARK: - Public API

    /// Start monitoring file system changes
    public func startMonitoring() async {
        guard !isMonitoring else { return }

        logger.info("Starting file system monitoring")

        // Start FSEvents stream
        await setupFSEventsMonitoring()

        isMonitoring = true
        lastIncrementalUpdate = Date()

        // Schedule periodic index saves
        scheduleIndexSave()
    }

    /// Stop monitoring file system changes
    public func stopMonitoring() async {
        guard isMonitoring else { return }

        logger.info("Stopping file system monitoring")

        // Stop FSEvents stream
        if let stream = fsEventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            fsEventStream = nil
        }

        isMonitoring = false

        // Final index save
        await saveIndexState()
    }

    /// Perform full index scan
    public func performFullScan(paths: [String]) async throws -> IndexStatistics {
        guard !isIndexing else {
            throw IndexerError.scanInProgress
        }

        isIndexing = true
        let startTime = Date()
        defer { isIndexing = false }

        logger.info("Starting full index scan for \(paths.count) paths")

        var scanStats = IndexStatistics()

        for path in paths {
            let pathStats = try await scanDirectory(at: path)
            scanStats.totalFiles += pathStats.totalFiles
            scanStats.totalSize += pathStats.totalSize
            scanStats.indexedDirectories += pathStats.indexedDirectories
        }

        // Update statistics
        scanStats.lastFullScan = Date()
        scanStats.averageScanTime = Date().timeIntervalSince(startTime)
        statistics = scanStats
        lastFullScan = Date()

        // Save updated index
        await saveIndexState()

        logger.info("Full scan completed: \(scanStats.totalFiles) files, \(scanStats.totalSize) bytes")

        return scanStats
    }

    /// Perform incremental update
    public func performIncrementalUpdate() async throws -> [String] {
        let startTime = Date()
        var updatedPaths: [String] = []

        logger.info("Starting incremental update")

        // Process pending changes
        for (path, flags) in pendingChanges {
            if flags.contains(.deleted) {
                fileIndex.removeValue(forKey: path)
                bloomFilter.remove(path)
            } else {
                // Re-index the changed file
                if let entry = try? await createIndexEntry(for: path) {
                    fileIndex[path] = entry
                    bloomFilter.add(path)
                    updatedPaths.append(path)
                }
            }
        }

        pendingChanges.removeAll()
        lastIncrementalUpdate = Date()

        let duration = Date().timeIntervalSince(startTime)
        logger.info("Incremental update completed in \(duration)s: \(updatedPaths.count) paths updated")

        return updatedPaths
    }

    /// Check if path is in index
    public func isPathIndexed(_ path: String) -> Bool {
        return bloomFilter.contains(path) && fileIndex[path] != nil
    }

    /// Get index entry for path
    public func getIndexEntry(for path: String) -> FileIndexEntry? {
        return fileIndex[path]
    }

    /// Get all indexed paths
    public func getIndexedPaths() -> [String] {
        return Array(fileIndex.keys)
    }

    /// Get index statistics
    public func getStatistics() -> IndexStatistics {
        return statistics
    }

    /// Clear index (for testing or reset)
    public func clearIndex() async {
        fileIndex.removeAll()
        directoryIndex.removeAll()
        bloomFilter.clear()
        statistics = IndexStatistics()

        // Remove persisted files
        try? fileManager.removeItem(at: indexFileURL)
        try? fileManager.removeItem(at: bloomFilterFileURL)

        logger.info("Index cleared")
    }

    // MARK: - Private Methods

    private func setupFSEventsMonitoring() async {
        let paths = ["/Users", "/Applications", "/Library"] // Monitor key directories

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        fsEventStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            fsEventCallback,
            &context,
            paths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0, // 1 second latency
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents)
        )

        if let stream = fsEventStream {
            FSEventStreamSetDispatchQueue(stream, indexQueue)
            FSEventStreamStart(stream)
            logger.info("FSEvents monitoring started for \(paths.count) paths")
        }
    }

    private func scanDirectory(at path: String) async throws -> IndexStatistics {
        guard fileManager.fileExists(atPath: path) else {
            throw IndexerError.pathNotFound(path)
        }

        var stats = IndexStatistics()
        let url = URL(fileURLWithPath: path)

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [
                .fileSizeKey,
                .creationDateKey,
                .contentModificationDateKey,
                .isDirectoryKey,
                .typeIdentifierKey
            ],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw IndexerError.enumerationFailed(path)
        }

        for case let fileURL as URL in enumerator {
            do {
                let entry = try await createIndexEntry(for: fileURL.path)
                fileIndex[fileURL.path] = entry
                bloomFilter.add(fileURL.path)

                stats.totalFiles += 1
                stats.totalSize += entry.size

                if entry.isDirectory {
                    stats.indexedDirectories += 1
                }

                // Yield control periodically to prevent blocking
                if stats.totalFiles % 1000 == 0 {
                    await Task.yield()
                }
            } catch {
                logger.warning("Failed to index \(fileURL.path): \(error)")
            }
        }

        return stats
    }

    private func createIndexEntry(for path: String) async throws -> FileIndexEntry {
        let attributes = try fileManager.attributesOfItem(atPath: path)

        let size = (attributes[.size] as? Int64) ?? 0
        let modificationDate = (attributes[.modificationDate] as? Date) ?? Date()
        let creationDate = (attributes[.creationDate] as? Date) ?? Date()
        let isDirectory = (attributes[.type] as? FileAttributeType) == .typeDirectory

        // Get file type identifier
        var fileType: String?
        if let url = URL(string: path) {
            fileType = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier
        }

        // Get inode for change detection
        var inode: UInt64?
        if let inodeNumber = attributes[.systemFileNumber] as? UInt64 {
            inode = inodeNumber
        }

        return FileIndexEntry(
            path: path,
            size: size,
            modificationDate: modificationDate,
            creationDate: creationDate,
            isDirectory: isDirectory,
            fileType: fileType,
            inode: inode
        )
    }

    private func loadIndexState() async {
        do {
            // Load file index
            if fileManager.fileExists(atPath: indexFileURL.path) {
                let data = try Data(contentsOf: indexFileURL)
                let decoder = JSONDecoder()
                fileIndex = try decoder.decode([String: FileIndexEntry].self, from: data)
            }

            // Load bloom filter
            if fileManager.fileExists(atPath: bloomFilterFileURL.path) {
                let data = try Data(contentsOf: bloomFilterFileURL)
                bloomFilter = try BloomFilter<String>.fromData(data)
            }

            // Update statistics
            statistics.totalFiles = fileIndex.count
            statistics.totalSize = fileIndex.values.reduce(0) { $0 + $1.size }

            logger.info("Loaded index with \(self.fileIndex.count) entries")

        } catch {
            logger.error("Failed to load index state: \(error)")
            // Reset to empty state on error
            fileIndex.removeAll()
            bloomFilter.clear()
        }
    }

    private func saveIndexState() async {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(fileIndex)
            try data.write(to: indexFileURL, options: .atomic)

            let bloomData = try bloomFilter.toData()
            try bloomData.write(to: bloomFilterFileURL, options: .atomic)

            logger.debug("Index state saved: \(self.fileIndex.count) entries")

        } catch {
            logger.error("Failed to save index state: \(error)")
        }
    }

    private func scheduleIndexSave() {
        indexQueue.asyncAfter(deadline: .now() + indexSaveInterval) { [weak self] in
            Task {
                await self?.saveIndexState()
                await self?.scheduleIndexSave() // Reschedule
            }
        }
    }
}

// MARK: - FSEvents Callback

private func fsEventCallback(
    streamRef: ConstFSEventStreamRef,
    clientCallbackInfo: UnsafeMutableRawPointer?,
    numEvents: Int,
    eventPaths: UnsafeMutableRawPointer,
    eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    eventIds: UnsafePointer<FSEventStreamEventId>
) {
    guard let indexerPtr = clientCallbackInfo else { return }
    let indexer = Unmanaged<IncrementalIndexer>.fromOpaque(indexerPtr).takeUnretainedValue()

    let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]

    Task {
        for i in 0..<numEvents {
            let path = paths[i]
            let flags = eventFlags[i]

            var changeFlags: IncrementalIndexer.ChangeFlags = []

            if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated)) != 0 {
                changeFlags.insert(.created)
            }
            if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified)) != 0 {
                changeFlags.insert(.modified)
            }
            if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved)) != 0 {
                changeFlags.insert(.deleted)
            }
            if (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed)) != 0 {
                changeFlags.insert(.renamed)
            }

            // Queue change for processing
            await indexer.queuePathChange(path, flags: changeFlags)
        }
    }
}

// MARK: - Supporting Types

public struct DirectoryInfo: Codable {
    public let path: String
    public let lastScanned: Date
    public let fileCount: Int
    public let totalSize: Int64
    public var needsRescan: Bool = false
}

// MARK: - Bloom Filter Implementation

public class BloomFilter<T: Hashable> {
    private var bitArray: [Bool]
    private let hashFunctions: [(T) -> Int]
    private let size: Int

    public init(expectedElements: Int, falsePositiveRate: Double) {
        let optimalSize = Int(-Double(expectedElements) * log(falsePositiveRate) / pow(log(2), 2))
        let optimalHashes = Int(log(2) * Double(optimalSize) / Double(expectedElements))

        self.size = optimalSize
        self.bitArray = Array(repeating: false, count: size)
        self.hashFunctions = (0..<optimalHashes).map { i in
            return { element in
                var hasher = Hasher()
                hasher.combine(element)
                hasher.combine(i)
                return abs(hasher.finalize()) % optimalSize
            }
        }
    }

    public func add(_ element: T) {
        for hashFunction in hashFunctions {
            let index = hashFunction(element)
            if index < size {
                bitArray[index] = true
            }
        }
    }

    public func contains(_ element: T) -> Bool {
        return hashFunctions.allSatisfy { hashFunction in
            let index = hashFunction(element)
            return index < size && bitArray[index]
        }
    }

    public func remove(_ element: T) {
        for hashFunction in hashFunctions {
            let index = hashFunction(element)
            if index < size {
                bitArray[index] = false
            }
        }
    }

    public func clear() {
        bitArray = Array(repeating: false, count: size)
    }

    public func toData() throws -> Data {
        return try JSONEncoder().encode(bitArray)
    }

    public static func fromData(_ data: Data) throws -> BloomFilter {
        let decoded = try JSONDecoder().decode([Bool].self, from: data)
        let filter = BloomFilter(expectedElements: 1000, falsePositiveRate: 0.01)
        filter.bitArray = decoded
        return filter
    }
}

// MARK: - Errors

public enum IndexerError: LocalizedError {
    case scanInProgress
    case pathNotFound(String)
    case enumerationFailed(String)
    case indexingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .scanInProgress:
            return "File scan is already in progress"
        case .pathNotFound(let path):
            return "Path not found: \(path)"
        case .enumerationFailed(let path):
            return "Failed to enumerate directory: \(path)"
        case .indexingFailed(let reason):
            return "Indexing failed: \(reason)"
        }
    }
}

// MARK: - Extension for queueing changes

extension IncrementalIndexer {
    fileprivate func queuePathChange(_ path: String, flags: ChangeFlags) {
        pendingChanges.append((path: path, flags: flags))
    }
}

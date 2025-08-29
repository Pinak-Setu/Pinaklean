import Foundation
import AsyncAlgorithms

/// High-performance parallel file processor using Swift Concurrency
public actor ParallelProcessor {
    private let maxConcurrency: Int
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.pinaklean.parallel", qos: .userInitiated)

    // Performance metrics
    private var processedItems = 0
    private var totalBytesProcessed: Int64 = 0
    private var startTime = Date()

    public init(maxConcurrency: Int = ProcessInfo.processInfo.activeProcessorCount) {
        self.maxConcurrency = maxConcurrency
    }

    /// Find files matching a pattern in a directory with parallel processing
    public func findFiles(in directory: URL, matching pattern: String) async throws -> [URL] {
        guard fileManager.fileExists(atPath: directory.path) else {
            return []
        }

        return try await withThrowingTaskGroup(of: [URL].self) { group in
            var allFiles: [URL] = []

            // Add main directory scanning task
            group.addTask {
                try await self.scanDirectory(directory, pattern: pattern)
            }

            // Collect results
            for try await files in group {
                allFiles.append(contentsOf: files)
            }

            return allFiles
        }
    }

    private func scanDirectory(_ directory: URL, pattern: String) async throws -> [URL] {
        var matchingFiles: [URL] = []

        // Use FileManager's directory enumerator for better performance
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        // Process files in batches for better performance
        var batch: [URL] = []
        let batchSize = 100

        while let fileURL = enumerator.nextObject() as? URL {
            batch.append(fileURL)

            if batch.count >= batchSize {
                let matches = await processBatch(batch, pattern: pattern)
                matchingFiles.append(contentsOf: matches)
                batch.removeAll()
            }
        }

        // Process remaining files
        if !batch.isEmpty {
            let matches = await processBatch(batch, pattern: pattern)
            matchingFiles.append(contentsOf: matches)
        }

        return matchingFiles
    }

    private func processBatch(_ urls: [URL], pattern: String) async -> [URL] {
        await withTaskGroup(of: [URL].self) { group in
            var batchResults: [URL] = []

            for url in urls {
                group.addTask {
                    if await self.matchesPattern(url, pattern: pattern) {
                        return [url]
                    }
                    return []
                }
            }

            for await result in group {
                batchResults.append(contentsOf: result)
            }

            return batchResults
        }
    }

    private func matchesPattern(_ url: URL, pattern: String) async -> Bool {
        let fileName = url.lastPathComponent

        // Handle different pattern types
        if pattern == "*" {
            return true
        }

        // Exact match
        if fileName == pattern {
            return true
        }

        // Extension match (e.g., "*.log")
        if pattern.hasPrefix("*.") {
            let fileExtension = pattern.dropFirst(2)
            return url.pathExtension == fileExtension
        }

        // Directory name match
        if pattern.hasSuffix("/") {
            return fileName == pattern.dropLast()
        }

        // Glob pattern matching
        return fileName.matches(glob: pattern)
    }

    /// Delete items in parallel with progress tracking
    public func deleteItems(_ items: [CleanableItem]) async throws -> [CleanableItem] {
        guard !items.isEmpty else { return [] }

        startTime = Date()
        processedItems = 0
        totalBytesProcessed = 0

        let semaphore = AsyncSemaphore(value: maxConcurrency)
        var successfulDeletions: [CleanableItem] = []
        var failedItems: [CleanableItem] = []

        try await withThrowingTaskGroup(of: DeletionResult.self) { group in
            for item in items {
                group.addTask {
                    await semaphore.wait()
                    defer { semaphore.signal() }

                    do {
                        try await self.deleteItem(item)
                        return DeletionResult(item: item, success: true)
                    } catch {
                        return DeletionResult(item: item, success: false, error: error)
                    }
                }
            }

            for try await result in group {
                if result.success {
                    successfulDeletions.append(result.item)
                    totalBytesProcessed += result.item.size
                } else {
                    failedItems.append(result.item)
                }
                processedItems += 1
            }
        }

        // Log performance metrics
        let duration = Date().timeIntervalSince(startTime)
        let throughput = Double(totalBytesProcessed) / duration / 1024 / 1024 // MB/s

        print("Parallel deletion completed: \(successfulDeletions.count)/\(items.count) items, \(String(format: "%.2f", throughput)) MB/s")

        return successfulDeletions
    }

    private func deleteItem(_ item: CleanableItem) async throws {
        let url = URL(fileURLWithPath: item.path)

        // Check if item still exists
        guard fileManager.fileExists(atPath: url.path) else {
            return // Already deleted
        }

        // Get attributes before deletion for verification
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let expectedSize = attributes[.size] as? Int64 ?? 0

        // Perform deletion
        try fileManager.removeItem(at: url)

        // Verify deletion
        if fileManager.fileExists(atPath: url.path) {
            throw DeletionError.verificationFailed(url)
        }

        // Update metrics
        totalBytesProcessed += expectedSize
    }

    /// Calculate directory sizes in parallel
    public func calculateDirectorySizes(_ directories: [URL]) async throws -> [URL: Int64] {
        var results: [URL: Int64] = [:]

        try await withThrowingTaskGroup(of: (URL, Int64).self) { group in
            for directory in directories {
                group.addTask {
                    let size = try await self.calculateDirectorySize(directory)
                    return (directory, size)
                }
            }

            for try await (url, size) in group {
                results[url] = size
            }
        }

        return results
    }

    private func calculateDirectorySize(_ directory: URL) async throws -> Int64 {
        guard fileManager.fileExists(atPath: directory.path) else {
            return 0
        }

        var totalSize: Int64 = 0

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)

                // Only count regular files, not directories
                if let fileType = attributes[.type] as? FileAttributeType,
                   fileType == .typeRegular {
                    if let fileSize = attributes[.size] as? Int64 {
                        totalSize += fileSize
                    }
                }
            } catch {
                // Skip files we can't access
                continue
            }
        }

        return totalSize
    }

    /// Get file metadata in parallel
    public func getFileMetadata(_ urls: [URL]) async throws -> [URL: FileMetadata] {
        var results: [URL: FileMetadata] = [:]

        try await withThrowingTaskGroup(of: (URL, FileMetadata).self) { group in
            for url in urls {
                group.addTask {
                    let metadata = try await self.getMetadata(for: url)
                    return (url, metadata)
                }
            }

            for try await (url, metadata) in group {
                results[url] = metadata
            }
        }

        return results
    }

    private func getMetadata(for url: URL) async throws -> FileMetadata {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)

        return FileMetadata(
            size: attributes[.size] as? Int64 ?? 0,
            modificationDate: attributes[.modificationDate] as? Date,
            creationDate: attributes[.creationDate] as? Date,
            isDirectory: (attributes[.type] as? FileAttributeType) == .typeDirectory
        )
    }

    /// Performance metrics
    public var performanceMetrics: PerformanceMetrics {
        let duration = Date().timeIntervalSince(startTime)
        return PerformanceMetrics(
            processedItems: processedItems,
            totalBytesProcessed: totalBytesProcessed,
            duration: duration,
            throughputMBps: duration > 0 ? Double(totalBytesProcessed) / duration / 1024 / 1024 : 0
        )
    }
}

// MARK: - Supporting Types

public struct DeletionResult {
    let item: CleanableItem
    let success: Bool
    let error: Error?

    init(item: CleanableItem, success: Bool, error: Error? = nil) {
        self.item = item
        self.success = success
        self.error = error
    }
}

public struct FileMetadata {
    public let size: Int64
    public let modificationDate: Date?
    public let creationDate: Date?
    public let isDirectory: Bool
}

public struct PerformanceMetrics {
    public let processedItems: Int
    public let totalBytesProcessed: Int64
    public let duration: TimeInterval
    public let throughputMBps: Double
}

enum DeletionError: LocalizedError {
    case verificationFailed(URL)

    var errorDescription: String? {
        switch self {
        case .verificationFailed(let url):
            return "Failed to verify deletion of \(url.path)"
        }
    }
}

class AsyncSemaphore {
    private var value: Int
    private var waiters: [UnsafeContinuation<Void, Never>] = []
    private let lock = NSLock()

    init(value: Int) {
        self.value = value
    }

    func wait() async {
        lock.lock()
        if value > 0 {
            value -= 1
            lock.unlock()
            return
        }

        await withUnsafeContinuation { continuation in
            waiters.append(continuation)
            lock.unlock()
        }
    }

    func signal() {
        lock.lock()
        value += 1
        if let waiter = waiters.first {
            waiters.removeFirst()
            lock.unlock()
            waiter.resume()
        } else {
            lock.unlock()
        }
    }
}

// MARK: - Extensions

extension String {
    func matches(glob pattern: String) -> Bool {
        // Simple glob matching implementation
        // For more complex patterns, consider using NSRegularExpression
        if pattern == "*" {
            return true
        }

        let regexPattern = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: "?", with: ".")

        return self.range(of: regexPattern, options: .regularExpression) != nil
    }
}

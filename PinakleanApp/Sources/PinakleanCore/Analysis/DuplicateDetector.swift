import Foundation
import CryptoKit
import os.log

/// Advanced duplicate detection system using SHA256 hashing and multiple detection strategies
/// Provides comprehensive duplicate detection by content, name, and size with performance optimization
public struct DuplicateDetector {
    
    private static let logger = Logger(subsystem: "com.pinaklean", category: "DuplicateDetector")
    private let chunkSize: Int
    private let maxFileSize: Int64
    
    // MARK: - Initialization
    
    /// Initialize duplicate detector with performance settings
    /// - Parameters:
    ///   - chunkSize: Size of chunks for large file processing (default: 1MB)
    ///   - maxFileSize: Maximum file size to process (default: 1GB)
    public init(chunkSize: Int = 1024 * 1024, maxFileSize: Int64 = 1024 * 1024 * 1024) {
        self.chunkSize = chunkSize
        self.maxFileSize = maxFileSize
    }
    
    // MARK: - Content-Based Duplicate Detection
    
    /// Find duplicate files by content using SHA256 hashing
    /// - Parameter files: Array of file URLs to analyze
    /// - Returns: Array of duplicate groups
    public func findDuplicatesByContent(in files: [URL]) throws -> [DuplicateGroup] {
        logger.info("Starting content-based duplicate detection for \(files.count) files")
        
        var hashToFiles: [String: [URL]] = [:]
        var processedCount = 0
        
        // Process files in parallel for better performance
        let semaphore = DispatchSemaphore(value: 4) // Limit concurrent operations
        let queue = DispatchQueue(label: "duplicate.detection", attributes: .concurrent)
        let group = DispatchGroup()
        
        for file in files {
            group.enter()
            queue.async {
                defer { group.leave() }
                semaphore.wait()
                defer { semaphore.signal() }
                
                do {
                    let hash = try self.calculateFileHash(file)
                    DispatchQueue.main.async {
                        hashToFiles[hash, default: []].append(file)
                        processedCount += 1
                        
                        if processedCount % 100 == 0 {
                            self.logger.debug("Processed \(processedCount)/\(files.count) files")
                        }
                    }
                } catch {
                    self.logger.error("Failed to calculate hash for \(file.path): \(error.localizedDescription)")
                }
            }
        }
        
        group.wait()
        
        // Filter groups with more than one file
        let duplicateGroups = hashToFiles.compactMap { (hash, files) -> DuplicateGroup? in
            guard files.count > 1 else { return nil }
            return DuplicateGroup(
                type: .content,
                files: files,
                hash: hash,
                totalSize: files.compactMap { try? self.getFileSize($0) }.reduce(0, +)
            )
        }
        
        logger.info("Found \(duplicateGroups.count) content duplicate groups")
        return duplicateGroups
    }
    
    // MARK: - Name-Based Duplicate Detection
    
    /// Find duplicate files by name (case-insensitive)
    /// - Parameter files: Array of file URLs to analyze
    /// - Returns: Array of duplicate groups
    public func findDuplicatesByName(in files: [URL]) throws -> [DuplicateGroup] {
        logger.info("Starting name-based duplicate detection for \(files.count) files")
        
        var nameToFiles: [String: [URL]] = [:]
        
        for file in files {
            let fileName = file.lastPathComponent.lowercased()
            nameToFiles[fileName, default: []].append(file)
        }
        
        // Filter groups with more than one file
        let duplicateGroups = nameToFiles.compactMap { (name, files) -> DuplicateGroup? in
            guard files.count > 1 else { return nil }
            return DuplicateGroup(
                type: .name,
                files: files,
                hash: name,
                totalSize: files.compactMap { try? self.getFileSize($0) }.reduce(0, +)
            )
        }
        
        logger.info("Found \(duplicateGroups.count) name duplicate groups")
        return duplicateGroups
    }
    
    // MARK: - Size-Based Duplicate Detection
    
    /// Find duplicate files by size
    /// - Parameter files: Array of file URLs to analyze
    /// - Returns: Array of duplicate groups
    public func findDuplicatesBySize(in files: [URL]) throws -> [DuplicateGroup] {
        logger.info("Starting size-based duplicate detection for \(files.count) files")
        
        var sizeToFiles: [Int64: [URL]] = [:]
        
        for file in files {
            do {
                let size = try getFileSize(file)
                sizeToFiles[size, default: []].append(file)
            } catch {
                logger.error("Failed to get size for \(file.path): \(error.localizedDescription)")
            }
        }
        
        // Filter groups with more than one file
        let duplicateGroups = sizeToFiles.compactMap { (size, files) -> DuplicateGroup? in
            guard files.count > 1 else { return nil }
            return DuplicateGroup(
                type: .size,
                files: files,
                hash: String(size),
                totalSize: size * Int64(files.count)
            )
        }
        
        logger.info("Found \(duplicateGroups.count) size duplicate groups")
        return duplicateGroups
    }
    
    // MARK: - Comprehensive Duplicate Detection
    
    /// Find all types of duplicates in a comprehensive analysis
    /// - Parameter files: Array of file URLs to analyze
    /// - Returns: Comprehensive duplicate detection results
    public func findAllDuplicates(in files: [URL]) throws -> DuplicateDetectionResults {
        logger.info("Starting comprehensive duplicate detection for \(files.count) files")
        
        let startTime = Date()
        
        // Run all detection methods in parallel
        let group = DispatchGroup()
        var contentDuplicates: [DuplicateGroup] = []
        var nameDuplicates: [DuplicateGroup] = []
        var sizeDuplicates: [DuplicateGroup] = []
        
        // Content-based detection
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                contentDuplicates = try self.findDuplicatesByContent(in: files)
            } catch {
                self.logger.error("Content detection failed: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        // Name-based detection
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                nameDuplicates = try self.findDuplicatesByName(in: files)
            } catch {
                self.logger.error("Name detection failed: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        // Size-based detection
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                sizeDuplicates = try self.findDuplicatesBySize(in: files)
            } catch {
                self.logger.error("Size detection failed: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.wait()
        
        let duration = Date().timeIntervalSince(startTime)
        logger.info("Comprehensive duplicate detection completed in \(String(format: "%.2f", duration))s")
        
        return DuplicateDetectionResults(
            contentDuplicates: contentDuplicates,
            nameDuplicates: nameDuplicates,
            sizeDuplicates: sizeDuplicates,
            totalFiles: files.count,
            processingTime: duration
        )
    }
    
    // MARK: - Hash Calculation
    
    /// Calculate SHA256 hash of a file
    /// - Parameter file: File URL to hash
    /// - Returns: SHA256 hash as hex string
    public func calculateFileHash(_ file: URL) throws -> String {
        // Validate file exists and is not a directory
        guard FileManager.default.fileExists(atPath: file.path) else {
            throw DuplicateDetectionError.fileNotFound(file)
        }
        
        var isDirectory: ObjCBool = false
        guard !FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory) || !isDirectory.boolValue else {
            throw DuplicateDetectionError.notAFile(file)
        }
        
        // Check file size
        let fileSize = try getFileSize(file)
        guard fileSize <= maxFileSize else {
            throw DuplicateDetectionError.fileTooLarge(file, size: fileSize, maxSize: maxFileSize)
        }
        
        // Calculate hash
        let fileHandle = try FileHandle(forReadingFrom: file)
        defer { fileHandle.closeFile() }
        
        var hasher = SHA256()
        
        if fileSize <= Int64(chunkSize) {
            // Small file - read all at once
            let data = fileHandle.readDataToEndOfFile()
            hasher.update(data: data)
        } else {
            // Large file - read in chunks
            while true {
                let data = fileHandle.readData(ofLength: chunkSize)
                guard !data.isEmpty else { break }
                hasher.update(data: data)
            }
        }
        
        let hash = hasher.finalize()
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Helper Methods
    
    /// Get file size in bytes
    /// - Parameter file: File URL
    /// - Returns: File size in bytes
    private func getFileSize(_ file: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        guard let size = attributes[.size] as? Int64 else {
            throw DuplicateDetectionError.cannotGetFileSize(file)
        }
        return size
    }
    
    /// Check if file is accessible for reading
    /// - Parameter file: File URL
    /// - Returns: True if accessible, false otherwise
    private func isFileAccessible(_ file: URL) -> Bool {
        return FileManager.default.isReadableFile(atPath: file.path)
    }
}

// MARK: - Supporting Types

/// Types of duplicate detection
public enum DuplicateType: String, CaseIterable {
    case content = "content"
    case name = "name"
    case size = "size"
}

/// Group of duplicate files
public struct DuplicateGroup: Identifiable, Codable {
    public let id = UUID()
    public let type: DuplicateType
    public let files: [URL]
    public let hash: String
    public let totalSize: Int64
    
    /// Calculate space that could be freed by removing duplicates
    public var spaceWasted: Int64 {
        guard files.count > 1 else { return 0 }
        let fileSize = totalSize / Int64(files.count)
        return fileSize * Int64(files.count - 1)
    }
    
    /// Get the file to keep (usually the first one)
    public var fileToKeep: URL {
        return files.first!
    }
    
    /// Get files that can be safely deleted
    public var filesToDelete: [URL] {
        return Array(files.dropFirst())
    }
}

/// Comprehensive duplicate detection results
public struct DuplicateDetectionResults: Codable {
    public let contentDuplicates: [DuplicateGroup]
    public let nameDuplicates: [DuplicateGroup]
    public let sizeDuplicates: [DuplicateGroup]
    public let totalFiles: Int
    public let processingTime: TimeInterval
    
    /// Generate statistics from the results
    public func generateStatistics() -> DuplicateStatistics {
        let allDuplicates = contentDuplicates + nameDuplicates + sizeDuplicates
        let duplicateFiles = Set(allDuplicates.flatMap { $0.files }).count
        let uniqueFiles = totalFiles - duplicateFiles
        let totalSpaceWasted = allDuplicates.reduce(0) { $0 + $1.spaceWasted }
        
        return DuplicateStatistics(
            totalFiles: totalFiles,
            duplicateFiles: duplicateFiles,
            uniqueFiles: uniqueFiles,
            spaceWasted: totalSpaceWasted,
            processingTime: processingTime,
            contentDuplicateGroups: contentDuplicates.count,
            nameDuplicateGroups: nameDuplicates.count,
            sizeDuplicateGroups: sizeDuplicates.count
        )
    }
}

/// Statistics about duplicate detection results
public struct DuplicateStatistics: Codable {
    public let totalFiles: Int
    public let duplicateFiles: Int
    public let uniqueFiles: Int
    public let spaceWasted: Int64
    public let processingTime: TimeInterval
    public let contentDuplicateGroups: Int
    public let nameDuplicateGroups: Int
    public let sizeDuplicateGroups: Int
    
    /// Formatted space wasted string
    public var formattedSpaceWasted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: spaceWasted)
    }
    
    /// Duplicate percentage
    public var duplicatePercentage: Double {
        guard totalFiles > 0 else { return 0 }
        return Double(duplicateFiles) / Double(totalFiles) * 100
    }
}

// MARK: - Error Types

/// Errors that can occur during duplicate detection
public enum DuplicateDetectionError: LocalizedError {
    case fileNotFound(URL)
    case notAFile(URL)
    case permissionDenied(URL)
    case fileTooLarge(URL, size: Int64, maxSize: Int64)
    case cannotGetFileSize(URL)
    case hashCalculationFailed(URL)
    case invalidFileFormat(URL)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "File not found: \(url.path)"
        case .notAFile(let url):
            return "Path is not a file: \(url.path)"
        case .permissionDenied(let url):
            return "Permission denied accessing file: \(url.path)"
        case .fileTooLarge(let url, let size, let maxSize):
            return "File too large: \(url.path) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)) > \(ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file)))"
        case .cannotGetFileSize(let url):
            return "Cannot get file size: \(url.path)"
        case .hashCalculationFailed(let url):
            return "Failed to calculate hash for file: \(url.path)"
        case .invalidFileFormat(let url):
            return "Invalid file format: \(url.path)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "Check if the file exists and the path is correct."
        case .notAFile:
            return "Ensure the path points to a file, not a directory."
        case .permissionDenied:
            return "Check file permissions and ensure you have read access."
        case .fileTooLarge:
            return "The file exceeds the maximum size limit. Consider increasing the limit or excluding large files."
        case .cannotGetFileSize:
            return "Check file permissions and ensure the file is accessible."
        case .hashCalculationFailed:
            return "Check file permissions and ensure the file is not corrupted."
        case .invalidFileFormat:
            return "Ensure the file is in a supported format."
        }
    }
}

// MARK: - Extensions

extension URL: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self.init(fileURLWithPath: string)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.path)
    }
}

// MARK: - Performance Optimizations

extension DuplicateDetector {
    
    /// Optimized duplicate detection for large file sets
    /// - Parameters:
    ///   - files: Array of file URLs
    ///   - batchSize: Number of files to process in each batch
    /// - Returns: Duplicate detection results
    public func findDuplicatesOptimized(in files: [URL], batchSize: Int = 1000) throws -> DuplicateDetectionResults {
        logger.info("Starting optimized duplicate detection for \(files.count) files in batches of \(batchSize)")
        
        let startTime = Date()
        var allContentDuplicates: [DuplicateGroup] = []
        var allNameDuplicates: [DuplicateGroup] = []
        var allSizeDuplicates: [DuplicateGroup] = []
        
        // Process files in batches
        for i in stride(from: 0, to: files.count, by: batchSize) {
            let endIndex = min(i + batchSize, files.count)
            let batch = Array(files[i..<endIndex])
            
            logger.debug("Processing batch \(i/batchSize + 1)/\((files.count + batchSize - 1)/batchSize)")
            
            let batchResults = try findAllDuplicates(in: batch)
            allContentDuplicates.append(contentsOf: batchResults.contentDuplicates)
            allNameDuplicates.append(contentsOf: batchResults.nameDuplicates)
            allSizeDuplicates.append(contentsOf: batchResults.sizeDuplicates)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        logger.info("Optimized duplicate detection completed in \(String(format: "%.2f", duration))s")
        
        return DuplicateDetectionResults(
            contentDuplicates: allContentDuplicates,
            nameDuplicates: allNameDuplicates,
            sizeDuplicates: allSizeDuplicates,
            totalFiles: files.count,
            processingTime: duration
        )
    }
}
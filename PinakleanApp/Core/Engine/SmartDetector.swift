import Foundation
import CryptoKit

/// Smart Detection Actor for Pinaklean
/// Uses ML heuristics and patterns to intelligently identify safe-to-delete files
/// Enhanced integration of CLI smart detection capabilities
public actor SmartDetector {
    // MARK: - Types

    public struct FileAnalysis: Sendable {
        public let path: String
        public let importanceScore: Int
        public let accessScore: Int
        public let combinedScore: Int
        public let sizeBytes: Int64
        public let recommendation: Recommendation
        public let ageCategory: AgeCategory
        public let patternMatch: String?

        public enum Recommendation: String, Sendable {
            case safeToDelete = "safe_to_delete"
            case reviewRecommended = "review_recommended"
            case keep = "keep"
        }

        public enum AgeCategory: String, Sendable {
            case veryOld = "very_old"      // >365 days
            case old = "old"              // >180 days
            case medium = "medium"        // >90 days
            case recent = "recent"        // >30 days
            case new = "new"              // <=30 days
        }
    }

    public struct DuplicateGroup: Sendable {
        public let checksum: String
        public let items: [CleanableItem]
        public let totalSize: Int64
        public let spaceSavings: Int64
    }

    public struct RecommendationResult: Sendable {
        public let timestamp: Date
        public let analyses: [FileAnalysis]
        public let summary: Summary

        public struct Summary: Sendable {
            public let totalFiles: Int
            public let safeToDelete: Int
            public let riskyFiles: Int
            public let totalSizeMB: Int
        }
    }

    public enum SmartDetectionError: Error, Sendable {
        case fileNotFound(String)
        case analysisFailed(String)
        case duplicateDetectionFailed(String)
    }

    // MARK: - Properties

    private let mlDataDir: URL
    private let usagePatternsFile: URL
    private let feedbackFile: URL

    // File pattern database with safety scores (0-100, higher = safer to delete)
    private let safePatterns: [String: Int] = [
        // Build artifacts - very safe
        "*.o": 95,
        "*.pyc": 95,
        "*.pyo": 95,
        "*.class": 95,
        "*.dSYM": 90,
        "*.xcworkspace": 85,
        "*.xcodeproj": 85,

        // Cache files - safe
        "*.cache": 90,
        "*.tmp": 90,
        "*.temp": 90,
        "*.swp": 85,
        "*.swo": 85,
        "*~": 85,
        ".DS_Store": 95,
        "Thumbs.db": 95,

        // Log files - generally safe
        "*.log": 80,
        "*.log.*": 85,
        "*.out": 75,
        "*.err": 75,

        // Package manager artifacts
        "node_modules": 90,
        ".npm": 85,
        ".yarn": 85,
        ".pnpm-store": 85,
        "vendor": 70,
        "bower_components": 85,

        // Build directories
        "dist": 85,
        "build": 85,
        "target": 85,
        "out": 80,
        ".next": 90,
        ".nuxt": 90,
        ".turbo": 90,
        ".parcel-cache": 95,

        // IDE artifacts
        ".idea": 75,
        ".vscode": 70,
        "*.sublime-workspace": 75
    ]

    // Directory importance scores (lower = less important)
    private let directoryImportance: [String: Int] = [
        "/Users/\(NSUserName())/Documents": 100,
        "/Users/\(NSUserName())/Desktop": 95,
        "/Users/\(NSUserName())/Pictures": 100,
        "/Users/\(NSUserName())/Movies": 95,
        "/Users/\(NSUserName())/Music": 95,
        "/Users/\(NSUserName())/Downloads": 60,
        "/Users/\(NSUserName())/Library/Caches": 20,
        "/Users/\(NSUserName())/.Trash": 10,
        "/tmp": 5,
        "/var/tmp": 5
    ]

    // File age thresholds (days)
    private let ageThresholds: [FileAnalysis.AgeCategory: Int] = [
        .veryOld: 365,
        .old: 180,
        .medium: 90,
        .recent: 30,
        .new: 7
    ]

    // MARK: - Initialization

    public init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        self.mlDataDir = homeDir.appendingPathComponent(".pinaklean/ml_data")
        self.usagePatternsFile = mlDataDir.appendingPathComponent("usage_patterns.json")
        self.feedbackFile = mlDataDir.appendingPathComponent("feedback.log")

        Task { await initializeSmartDetection() }
    }

    private func initializeSmartDetection() async {
        do {
            try FileManager.default.createDirectory(at: mlDataDir, withIntermediateDirectories: true)

            // Load or create usage patterns file
            if !FileManager.default.fileExists(atPath: usagePatternsFile.path) {
                let initialData: [String: Any] = [
                    "patterns": [],
                    "last_updated": ISO8601DateFormatter().string(from: Date())
                ]
                let data = try JSONSerialization.data(withJSONObject: initialData)
                try data.write(to: usagePatternsFile)
            }

            print("Smart detection initialized successfully")
        } catch {
            print("Failed to initialize smart detection: \(error)")
        }
    }

    // MARK: - Public API

    /// Calculate safety score using heuristic analysis (legacy compatibility)
    public func calculateSafetyScore(for url: URL) async -> Int {
        let path = url.path
        var score = 50 // Base neutral score

        // Simple heuristic-based scoring
        if path.contains("/Library/") || path.contains("/System/") {
            score += 20 // System files are riskier
        }

        if path.contains("/Downloads/") || path.contains("/tmp/") {
            score -= 15 // Downloads and temp are less risky
        }

        if path.contains(".log") || path.contains(".cache") {
            score -= 10 // Log and cache files are safe to clean
        }

        return min(max(score, 0), 100)
    }

    /// Analyze a single file for deletion safety (enhanced CLI integration)
    public func analyzeFile(at path: String) async throws -> FileAnalysis {
        guard FileManager.default.fileExists(atPath: path) else {
            throw SmartDetectionError.fileNotFound(path)
        }

        let importanceScore = try await calculateImportance(forFileAt: path)
        let accessScore = try await analyzeAccessPatterns(forFileAt: path)
        let combinedScore = (importanceScore + accessScore) / 2
        let size = try await getFileSize(at: path)
        let ageCategory = try await getAgeCategory(forFileAt: path)
        let patternMatch = try await getPatternMatch(forFileAt: path)

        let recommendation: FileAnalysis.Recommendation
        if combinedScore > 70 {
            recommendation = .safeToDelete
        } else if combinedScore > 50 {
            recommendation = .reviewRecommended
        } else {
            recommendation = .keep
        }

        return FileAnalysis(
            path: path,
            importanceScore: importanceScore,
            accessScore: accessScore,
            combinedScore: combinedScore,
            sizeBytes: size,
            recommendation: recommendation,
            ageCategory: ageCategory,
            patternMatch: patternMatch
        )
    }

    /// Analyze multiple files and generate recommendations
    public func generateRecommendations(for paths: [String]) async throws -> RecommendationResult {
        var analyses: [FileAnalysis] = []
        var safeToDelete = 0
        var riskyFiles = 0
        var totalSize: Int64 = 0

        for path in paths {
            do {
                let analysis = try await analyzeFile(at: path)
                analyses.append(analysis)
                totalSize += analysis.sizeBytes

                switch analysis.recommendation {
                case .safeToDelete:
                    safeToDelete += 1
                case .keep:
                    riskyFiles += 1
                case .reviewRecommended:
                    break // Not counted in safe/risky totals
                }
            } catch {
                print("Failed to analyze \(path): \(error)")
            }
        }

        let summary = RecommendationResult.Summary(
            totalFiles: analyses.count,
            safeToDelete: safeToDelete,
            riskyFiles: riskyFiles,
            totalSizeMB: Int(totalSize / 1_048_576)
        )

        return RecommendationResult(
            timestamp: Date(),
            analyses: analyses,
            summary: summary
        )
    }

    /// Enhanced safety scoring (legacy compatibility)
    public func enhanceSafetyScore(for item: CleanableItem) async throws -> Int {
        let url = URL(fileURLWithPath: item.path)
        return await calculateSafetyScore(for: url)
    }

    /// Find duplicate files using checksums (enhanced from CLI)
    public func findDuplicates(in items: [CleanableItem]) async throws -> [DuplicateGroup] {
        return try await detectDuplicates(from: items, minSizeMB: 1)
    }

    /// Detect duplicates with advanced checksum-based detection
    public func detectDuplicates(from items: [CleanableItem], minSizeMB: Int = 1) async throws -> [DuplicateGroup] {
        var checksumGroups: [String: [CleanableItem]] = [:]
        var checksumSizes: [String: Int64] = [:]

        for item in items {
            let sizeMB = Double(item.size) / 1_048_576.0
            guard sizeMB >= Double(minSizeMB) else { continue }

            do {
                let checksum = try await calculateSHA256(at: item.path)
                let size = item.size

                if var existingItems = checksumGroups[checksum] {
                    existingItems.append(item)
                    checksumGroups[checksum] = existingItems
                    checksumSizes[checksum] = (checksumSizes[checksum] ?? 0) + size
                } else {
                    checksumGroups[checksum] = [item]
                    checksumSizes[checksum] = size
                }
            } catch {
                print("Failed to process \(item.path): \(error)")
            }
        }

        // Filter groups with duplicates and calculate space savings
        var duplicateGroups: [DuplicateGroup] = []
        for (checksum, items) in checksumGroups where items.count > 1 {
            let totalSize = checksumSizes[checksum] ?? 0
            let spaceSavings = totalSize - (totalSize / Int64(items.count))

            duplicateGroups.append(DuplicateGroup(
                checksum: checksum,
                items: items,
                totalSize: totalSize,
                spaceSavings: spaceSavings
            ))
        }

        return duplicateGroups.sorted { $0.spaceSavings > $1.spaceSavings }
    }

    /// Analyze file content (enhanced)
    public func analyzeContent(_ item: CleanableItem) async -> ContentAnalysis {
        let url = URL(fileURLWithPath: item.path)
        let contentType = determineContentType(for: url)

        return ContentAnalysis(
            fileType: url.pathExtension,
            contentType: contentType,
            textContent: "" // Placeholder for now
        )
    }

    /// Learn from user feedback to improve recommendations
    public func learnFromFeedback(action: String, filePath: String) async {
        let feedbackEntry = "\(ISO8601DateFormatter().string(from: Date()))|\(action)|\(filePath)|\(URL(fileURLWithPath: filePath).lastPathComponent)\n"

        do {
            let data = feedbackEntry.data(using: .utf8) ?? Data()
            let fileHandle = try FileHandle(forWritingTo: feedbackFile)
            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: data)
            try fileHandle.close()

            print("Learned from feedback: \(action) - \(filePath)")
        } catch {
            print("Failed to record feedback: \(error)")
        }
    }

    // MARK: - Private Methods

    private func calculateImportance(forFileAt path: String) async throws -> Int {
        var score = 50 // Start with neutral score

        // Check file extension safety
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        for (pattern, patternScore) in safePatterns {
            if matchesPattern(fileName, pattern: pattern) {
                score = patternScore
                break
            }
        }

        // Adjust based on directory importance
        for (dir, dirScore) in directoryImportance {
            if path.hasPrefix(dir) {
                score = (score * dirScore) / 100
                break
            }
        }

        // Adjust based on file age
        let ageCategory = try await getAgeCategory(forFileAt: path)
        switch ageCategory {
        case .veryOld:
            score += 20 // Very old files are safer to delete
        case .old:
            score += 10
        case .new:
            score -= 20 // New files are riskier to delete
        default:
            break
        }

        // Adjust based on file size
        let sizeMB = Double(try await getFileSize(at: path)) / 1_048_576.0
        if sizeMB > 1000 {
            score -= 15 // Large files need more consideration
        } else if sizeMB < 1 {
            score += 5 // Small files are generally safer
        }

        return max(0, min(100, score))
    }

    private func analyzeAccessPatterns(forFileAt path: String) async throws -> Int {
        var score = 50

        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        guard let lastAccessDate = attributes[.modificationDate] as? Date else {
            return score
        }

        let daysSinceAccess = Calendar.current.dateComponents([.day], from: lastAccessDate, to: Date()).day ?? 0

        if daysSinceAccess > 365 {
            score += 30 // Not accessed in a year
        } else if daysSinceAccess > 180 {
            score += 20 // Not accessed in 6 months
        } else if daysSinceAccess > 90 {
            score += 10 // Not accessed in 3 months
        } else if daysSinceAccess < 7 {
            score -= 30 // Recently accessed
        }

        // Check if file is in active git repository
        let parentDir = URL(fileURLWithPath: path).deletingLastPathComponent().path
        if isGitRepository(at: parentDir) {
            if isGitTracked(at: path, in: parentDir) {
                score -= 20 // Tracked files are important
            } else {
                score += 10 // Untracked files in git repos
            }
        }

        return max(0, min(100, score))
    }

    private func getAgeCategory(forFileAt path: String) async throws -> FileAnalysis.AgeCategory {
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        guard let lastAccessDate = attributes[.modificationDate] as? Date else {
            return .medium
        }

        let daysSinceAccess = Calendar.current.dateComponents([.day], from: lastAccessDate, to: Date()).day ?? 0

        if daysSinceAccess > ageThresholds[.veryOld]! {
            return .veryOld
        } else if daysSinceAccess > ageThresholds[.old]! {
            return .old
        } else if daysSinceAccess > ageThresholds[.medium]! {
            return .medium
        } else if daysSinceAccess > ageThresholds[.recent]! {
            return .recent
        } else {
            return .new
        }
    }

    private func getFileSize(at path: String) async throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        return attributes[.size] as? Int64 ?? 0
    }

    private func getPatternMatch(forFileAt path: String) async throws -> String? {
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        for pattern in safePatterns.keys {
            if matchesPattern(fileName, pattern: pattern) {
                return pattern
            }
        }
        return nil
    }

    private func calculateSHA256(at path: String) async throws -> String {
        let fileURL = URL(fileURLWithPath: path)
        let fileData = try Data(contentsOf: fileURL)
        let hash = SHA256.hash(data: fileData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func matchesPattern(_ fileName: String, pattern: String) -> Bool {
        // Simple pattern matching - could be enhanced with regex
        if pattern.hasPrefix("*.") {
            let fileExtension = String(pattern.dropFirst(2))
            return fileName.hasSuffix(".\(fileExtension)")
        } else if pattern.hasPrefix(".") {
            return fileName.hasPrefix(pattern)
        } else {
            return fileName == pattern
        }
    }

    private func isGitRepository(at path: String) -> Bool {
        let gitDir = (path as NSString).appendingPathComponent(".git")
        return FileManager.default.fileExists(atPath: gitDir)
    }

    private func isGitTracked(at filePath: String, in repoPath: String) -> Bool {
        // This is a simplified check - in practice you'd run git commands
        // For now, we'll assume files in git repos are tracked if they're not in .gitignore
        let gitignorePath = (repoPath as NSString).appendingPathComponent(".gitignore")
        if FileManager.default.fileExists(atPath: gitignorePath) {
            do {
                let gitignore = try String(contentsOfFile: gitignorePath, encoding: .utf8)
                let relativePath = String(filePath.dropFirst(repoPath.count + 1))
                for line in gitignore.components(separatedBy: .newlines) {
                    if matchesPattern(relativePath, pattern: line.trimmingCharacters(in: .whitespaces)) {
                        return false // Ignored files are not tracked
                    }
                }
            } catch {
                // If we can't read .gitignore, assume it's tracked
            }
        }
        return true
    }

    /// Determine content type based on file extension
    private func determineContentType(for url: URL) -> ContentType {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff":
            return .image
        case "mp4", "avi", "mov", "mkv", "wmv":
            return .video
        case "mp3", "wav", "flac", "aac", "ogg":
            return .audio
        case "pdf", "doc", "docx", "txt", "rtf":
            return .document
        case "zip", "rar", "7z", "tar", "gz":
            return .archive
        case "app", "exe", "dmg", "pkg":
            return .application
        default:
            return .other
        }
    }
}

// MARK: - Supporting Types

public enum ContentType: Sendable {
    case document, image, video, audio, archive, application, data, other, unknown
}

public enum SizeCategory: Sendable {
    case small, medium, large, huge, unknown
}

public struct SafetyFeatures: Sendable {
    var fileSize: Int64 = 0
    var modificationDate: Date?
    var creationDate: Date?
    var daysSinceModified: Double = 0
    var isRecent: Bool = false
    var isOld: Bool = false
    var sizeCategory: SizeCategory = .unknown
    var pathDepth: Double = 0
    var isInSystemDir: Bool = false
    var isInUserDir: Bool = false
    var hasCommonExtensions: Bool = false
}

public struct ContentAnalysis: Sendable {
    public let fileType: String
    public let contentType: ContentType
    public let textContent: String
}

public struct FileUsagePattern: Sendable {
    let pattern: String
    var totalEncounters: Int = 0
    var lastEncounter: Date?
    var averageScore: Double = 0
}

public struct FileLearningData: Codable, Sendable {
    let path: String
    let pattern: String
    let score: Int
    let timestamp: Date
}

// DuplicateGroup is defined in PinakleanEngine.swift
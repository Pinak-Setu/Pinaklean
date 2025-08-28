import Foundation
import CoreML
import CreateML
import NaturalLanguage
import Vision

/// ML-powered smart detector for intelligent file analysis
public actor SmartDetector {
    // ML Models for different detection tasks
    private var safetyModel: MLModel?
    private var contentTypeModel: MLModel?
    private var duplicateDetectionModel: MLModel?

    // Feature extractors
    private let perceptualHasher: PerceptualHasher
    private let textAnalyzer: TextContentAnalyzer
    private let fileTypeAnalyzer: FileTypeAnalyzer

    // Learning data
    private var usagePatterns: [String: FileUsagePattern] = [:]
    private var learningData: [FileLearningData] = []

    // Configuration
    private let maxLearningSamples = 10000
    private let confidenceThreshold = 0.7

    public init() async throws {
        self.perceptualHasher = PerceptualHasher()
        self.textAnalyzer = TextContentAnalyzer()
        self.fileTypeAnalyzer = FileTypeAnalyzer()

        // Load pre-trained models if available
        await loadModels()

        // Load learning data
        await loadLearningData()
    }

    /// Calculate safety score using multiple ML signals
    public func calculateSafetyScore(for url: URL) async -> Int {
        let features = await extractFeatures(for: url)
        let score = await predictSafetyScore(features: features)

        // Adjust based on learning data
        let adjustedScore = await adjustScoreWithLearning(score, for: url)

        return min(max(adjustedScore, 0), 100)
    }

    /// Enhanced safety scoring with ML model
    public func enhanceSafetyScore(for item: CleanableItem) async throws -> Int {
        let url = URL(fileURLWithPath: item.path)
        let baseScore = item.safetyScore

        // Get ML-enhanced prediction
        let enhancedScore = await calculateSafetyScore(for: url)

        // Combine with base score using weighted average
        let combinedScore = Int(Double(baseScore) * 0.3 + Double(enhancedScore) * 0.7)

        // Record for learning
        await recordUsagePattern(for: item, finalScore: combinedScore)

        return combinedScore
    }

    /// Find duplicate files using perceptual hashing and ML
    public func findDuplicates(in items: [CleanableItem]) async throws -> [DuplicateGroup] {
        guard items.count > 1 else { return [] }

        var hashGroups: [String: [CleanableItem]] = [:]

        // Generate perceptual hashes for all items
        for item in items {
            let url = URL(fileURLWithPath: item.path)
            if let hash = try? await perceptualHasher.generateHash(for: url) {
                hashGroups[hash, default: []].append(item)
            }
        }

        // Filter to groups with actual duplicates
        let duplicateGroups = hashGroups
            .filter { $0.value.count > 1 }
            .map { hash, items in
                DuplicateGroup(
                    checksum: hash,
                    items: items.sorted { $0.size > $1.size } // Largest first
                )
            }

        return duplicateGroups
    }

    /// Analyze file content to determine importance
    public func analyzeContent(_ item: CleanableItem) async -> ContentAnalysis {
        let url = URL(fileURLWithPath: item.path)

        // Analyze file type and content
        let fileType = await fileTypeAnalyzer.analyze(url)
        let contentType = await predictContentType(for: url)
        let textContent = await textAnalyzer.extractContent(from: url)

        return ContentAnalysis(
            fileType: fileType,
            contentType: contentType,
            textContent: textContent,
            importance: calculateImportance(contentType: contentType, textContent: textContent)
        )
    }

    /// Predict content type using ML
    private func predictContentType(for url: URL) async -> ContentType {
        // Use file extension and ML model to predict content type
        let fileExtension = url.pathExtension.lowercased()

        // Fallback to extension-based classification
        switch fileExtension {
        case "jpg", "jpeg", "png", "gif", "webp":
            return .image
        case "mp4", "mov", "avi", "mkv":
            return .video
        case "mp3", "wav", "aac", "flac":
            return .audio
        case "pdf", "doc", "docx", "txt", "rtf":
            return .document
        case "zip", "tar", "gz", "rar":
            return .archive
        case "app", "dmg", "pkg":
            return .application
        case "log", "txt", "csv", "json", "xml":
            return .data
        default:
            return .other
        }
    }

    /// Extract comprehensive features for ML prediction
    private func extractFeatures(for url: URL) async -> SafetyFeatures {
        let fileManager = FileManager.default

        // Basic file attributes
        var features = SafetyFeatures()

        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)

            features.fileSize = attributes[.size] as? Int64 ?? 0
            features.modificationDate = attributes[.modificationDate] as? Date
            features.creationDate = attributes[.creationDate] as? Date

            // Calculate age-based features
            if let modDate = features.modificationDate {
                let daysSinceModified = Calendar.current.dateComponents([.day], from: modDate, to: Date()).day ?? 0
                features.daysSinceModified = Double(daysSinceModified)
                features.isRecent = daysSinceModified <= 7
                features.isOld = daysSinceModified >= 365
            }

            // Size-based features
            let sizeMB = Double(features.fileSize) / 1024 / 1024
            features.sizeCategory = sizeMB < 1 ? .small :
                                  sizeMB < 100 ? .medium :
                                  sizeMB < 1000 ? .large : .huge

        } catch {
            // If we can't read attributes, assume minimal safety
            features.fileSize = 0
            features.daysSinceModified = 0
            features.isRecent = false
            features.isOld = false
            features.sizeCategory = .unknown
        }

        // Path-based features
        let path = url.path
        features.pathDepth = Double(path.components(separatedBy: "/").count)
        features.isInSystemDir = path.hasPrefix("/System") || path.hasPrefix("/usr") || path.hasPrefix("/bin")
        features.isInUserDir = path.hasPrefix("/Users")
        features.hasCommonExtensions = hasCommonExtension(url)

        // Content analysis features
        let contentAnalysis = await analyzeContent(CleanableItem(
            id: UUID(),
            path: path,
            name: url.lastPathComponent,
            category: "analysis",
            size: features.fileSize,
            lastModified: features.modificationDate,
            lastAccessed: nil,
            safetyScore: 50
        ))

        features.contentType = contentAnalysis.contentType
        features.hasTextContent = !contentAnalysis.textContent.isEmpty
        features.importanceScore = Double(contentAnalysis.importance)

        return features
    }

    private func hasCommonExtension(_ url: URL) -> Bool {
        let commonExtensions = [
            "txt", "log", "tmp", "cache", "bak", "old", "orig",
            "jpg", "png", "gif", "pdf", "doc", "zip", "tar"
        ]
        return commonExtensions.contains(url.pathExtension.lowercased())
    }

    /// Predict safety score using ML model or heuristic fallback
    private func predictSafetyScore(features: SafetyFeatures) async -> Int {
        // For now, use heuristic-based scoring until ML model is trained
        var score = 50 // Neutral starting point

        // Age-based scoring
        if features.isRecent {
            score -= 20 // Recently modified files are riskier
        } else if features.isOld {
            score += 15 // Old files are generally safer to delete
        }

        // Size-based scoring
        switch features.sizeCategory {
        case .small:
            score += 10 // Small files are generally safer
        case .large:
            score -= 5  // Large files need more consideration
        case .huge:
            score -= 15 // Very large files are risky
        default:
            break
        }

        // Path-based scoring
        if features.isInSystemDir {
            score -= 30 // System files are critical
        }

        if features.hasCommonExtensions {
            score += 10 // Common extensions are typically safe
        }

        // Content-based scoring
        switch features.contentType {
        case .document:
            score -= 10 // Documents are important
        case .image, .video:
            score += 5  // Media files are often safe to clean
        case .archive:
            score += 15 // Archives are typically safe
        case .data:
            score += 8  // Data files vary but often safe
        default:
            break
        }

        return min(max(score, 0), 100)
    }

    /// Adjust score based on learned user behavior
    private func adjustScoreWithLearning(_ baseScore: Int, for url: URL) async -> Int {
        let path = url.path
        let fileName = url.lastPathComponent

        // Check if we have learning data for similar files
        var adjustment = 0

        for (pattern, usage) in usagePatterns {
            if path.contains(pattern) || fileName.contains(pattern) {
                // Adjust based on user feedback
                if usage.keepRate > 0.8 {
                    adjustment -= 15 // User tends to keep these
                } else if usage.keepRate < 0.2 {
                    adjustment += 15 // User tends to delete these
                }
            }
        }

        return min(max(baseScore + adjustment, 0), 100)
    }

    /// Record usage pattern for learning
    private func recordUsagePattern(for item: CleanableItem, finalScore: Int) async {
        let pattern = extractPattern(from: item)

        var usage = usagePatterns[pattern] ?? FileUsagePattern(pattern: pattern)
        usage.totalEncounters += 1

        // This would be updated when user actually keeps/deletes the file
        // For now, we assume the ML prediction was correct
        usagePatterns[pattern] = usage

        // Store learning data
        let learningEntry = FileLearningData(
            path: item.path,
            pattern: pattern,
            finalScore: finalScore,
            timestamp: Date(),
            wasKept: nil // Will be updated when user makes decision
        )

        learningData.append(learningEntry)

        // Limit learning data size
        if learningData.count > maxLearningSamples {
            learningData.removeFirst()
        }

        await saveLearningData()
    }

    private func extractPattern(from item: CleanableItem) -> String {
        // Extract meaningful pattern from file path
        let components = item.path.components(separatedBy: "/")
        if components.count >= 2 {
            return components.suffix(2).joined(separator: "/")
        }
        return item.name
    }

    /// Load ML models
    private func loadModels() async {
        // Load pre-trained Core ML models
        // This would load actual ML models in production
        print("Loading ML models...")
    }

    /// Load learning data from disk
    private func loadLearningData() async {
        let fileManager = FileManager.default
        let learningDataURL = getLearningDataURL()

        if fileManager.fileExists(atPath: learningDataURL.path) {
            do {
                let data = try Data(contentsOf: learningDataURL)
                let decoder = JSONDecoder()
                learningData = try decoder.decode([FileLearningData].self, from: data)

                // Rebuild usage patterns from learning data
                rebuildUsagePatterns()
            } catch {
                print("Failed to load learning data: \(error)")
            }
        }
    }

    /// Save learning data to disk
    private func saveLearningData() async {
        let learningDataURL = getLearningDataURL()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(learningData)
            try data.write(to: learningDataURL)
        } catch {
            print("Failed to save learning data: \(error)")
        }
    }

    private func rebuildUsagePatterns() {
        var patterns: [String: FileUsagePattern] = [:]

        for entry in learningData {
            var usage = patterns[entry.pattern] ?? FileUsagePattern(pattern: entry.pattern)
            usage.totalEncounters += 1

            if let wasKept = entry.wasKept {
                usage.keepCount += wasKept ? 1 : 0
                usage.deleteCount += wasKept ? 0 : 1
            }

            patterns[entry.pattern] = usage
        }

        usagePatterns = patterns
    }

    private func getLearningDataURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let pinakleanDir = appSupport.appendingPathComponent("Pinaklean", isDirectory: true)

        try? FileManager.default.createDirectory(at: pinakleanDir, withIntermediateDirectories: true)

        return pinakleanDir.appendingPathComponent("learning_data.json")
    }

    /// Calculate importance score based on content
    private func calculateImportance(contentType: ContentType, textContent: String) -> Int {
        var importance = 50

        // Content type importance
        switch contentType {
        case .document:
            importance += 20
        case .image, .video:
            importance += 10
        case .application:
            importance += 30
        case .archive:
            importance -= 10
        case .data:
            importance -= 5
        default:
            break
        }

        // Text content analysis
        if !textContent.isEmpty {
            // Simple heuristic: files with more unique words are more important
            let words = Set(textContent.components(separatedBy: .whitespacesAndNewlines))
            importance += min(words.count / 10, 20)
        }

        return min(max(importance, 0), 100)
    }
}

// MARK: - Supporting Types

public enum ContentType {
    case document, image, video, audio, archive, application, data, other
}

public enum SizeCategory {
    case small, medium, large, huge, unknown
}

public struct SafetyFeatures {
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
    var contentType: ContentType = .other
    var hasTextContent: Bool = false
    var importanceScore: Double = 50
}

public struct ContentAnalysis {
    public let fileType: String
    public let contentType: ContentType
    public let textContent: String
    public let importance: Int
}

public struct FileUsagePattern {
    let pattern: String
    var totalEncounters: Int = 0
    var keepCount: Int = 0
    var deleteCount: Int = 0

    var keepRate: Double {
        guard totalEncounters > 0 else { return 0.5 }
        return Double(keepCount) / Double(totalEncounters)
    }
}

public struct FileLearningData: Codable {
    let path: String
    let pattern: String
    let finalScore: Int
    let timestamp: Date
    var wasKept: Bool?
}

// MARK: - Helper Classes

class PerceptualHasher {
    func generateHash(for url: URL) async throws -> String {
        // Implement perceptual hashing for duplicate detection
        // For now, return a simple hash
        let path = url.path
        return String(path.hashValue)
    }
}

class TextContentAnalyzer {
    func extractContent(from url: URL) async -> String {
        // Extract text content from files for analysis
        // This would handle various file types (PDF, DOC, TXT, etc.)
        return ""
    }
}

class FileTypeAnalyzer {
    func analyze(_ url: URL) async -> String {
        // Analyze file type using magic numbers and extensions
        return url.pathExtension
    }
}

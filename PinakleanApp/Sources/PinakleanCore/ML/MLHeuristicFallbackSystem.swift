import Foundation
import os.log

/// Advanced ML Heuristic Fallback System for Pinaklean
/// Provides sophisticated rule-based analysis when ML models are unavailable
/// Implements comprehensive file analysis with safety scoring and content detection
public struct MLHeuristicFallbackSystem {
    
    private static let logger = Logger(subsystem: "com.pinaklean", category: "MLHeuristicFallbackSystem")
    
    // MARK: - Safety Score Calculation
    
    /// Calculate safety score for a file using heuristic rules
    /// - Parameter fileInfo: File analysis information
    /// - Returns: Safety score between 0.0 (unsafe) and 1.0 (safe)
    public func calculateSafetyScore(for fileInfo: FileAnalysisInfo) -> Double {
        var score: Double = 1.0
        
        // System files are always unsafe to delete
        if fileInfo.isSystemFile {
            score *= 0.1
            logger.debug("System file penalty applied: \(fileInfo.path)")
        }
        
        // Hidden files are less safe
        if fileInfo.isHidden {
            score *= 0.6
            logger.debug("Hidden file penalty applied: \(fileInfo.path)")
        }
        
        // Apply extension-based scoring
        score *= getExtensionSafetyScore(fileInfo.extension)
        
        // Apply path-based scoring
        score *= getPathSafetyScore(fileInfo.path)
        
        // Apply size-based scoring
        score *= getSizeSafetyScore(fileInfo.size)
        
        // Apply age-based scoring
        score *= getAgeSafetyScore(fileInfo.modified, isRecent: fileInfo.isRecent, isOld: fileInfo.isOld)
        
        // Ensure score is within bounds
        return max(0.0, min(1.0, score))
    }
    
    // MARK: - Content Type Detection
    
    /// Detect content type from filename
    /// - Parameter filename: File name with extension
    /// - Returns: MIME content type
    public func detectContentType(filename: String) -> String {
        let fileExtension = (filename as NSString).pathExtension.lowercased()
        
        return contentTypes[fileExtension] ?? "application/octet-stream"
    }
    
    // MARK: - File Pattern Analysis
    
    /// Check if file is temporary
    /// - Parameter path: File path
    /// - Returns: True if file appears to be temporary
    public func isTemporaryFile(path: String) -> Bool {
        let tempPatterns = [
            "/tmp/",
            "/var/tmp/",
            "/Library/Caches/",
            "~",
            ".tmp",
            ".temp",
            ".cache"
        ]
        
        return tempPatterns.contains { pattern in
            path.lowercased().contains(pattern.lowercased())
        }
    }
    
    /// Check if file is cache
    /// - Parameter path: File path
    /// - Returns: True if file appears to be cache
    public func isCacheFile(path: String) -> Bool {
        let cachePatterns = [
            "/Library/Caches/",
            "/System/Library/Caches/",
            "/var/cache/",
            ".cache"
        ]
        
        return cachePatterns.contains { pattern in
            path.lowercased().contains(pattern.lowercased())
        }
    }
    
    /// Check if file is log
    /// - Parameter path: File path
    /// - Returns: True if file appears to be log
    public func isLogFile(path: String) -> Bool {
        let logPatterns = [
            "/var/log/",
            "/Library/Logs/",
            ".log"
        ]
        
        return logPatterns.contains { pattern in
            path.lowercased().contains(pattern.lowercased())
        }
    }
    
    // MARK: - Cleanup Recommendations
    
    /// Generate cleanup recommendation for a file
    /// - Parameter fileInfo: File analysis information
    /// - Returns: Cleanup recommendation with confidence score
    public func generateCleanupRecommendation(for fileInfo: FileAnalysisInfo) -> CleanupRecommendation {
        let safetyScore = calculateSafetyScore(for: fileInfo)
        
        // Determine action based on safety score and file characteristics
        let action: CleanupAction
        let confidence: Double
        let reason: String
        
        if safetyScore < 0.2 {
            // Very unsafe - keep
            action = .keep
            confidence = 0.9
            reason = "Critical system file - must keep"
        } else if safetyScore < 0.4 {
            // Unsafe - keep with warning
            action = .keep
            confidence = 0.7
            reason = "Important file - recommend keeping"
        } else if isTemporaryFile(path: fileInfo.path) || isCacheFile(path: fileInfo.path) {
            // Temporary or cache files - delete
            action = .delete
            confidence = 0.8
            reason = "Temporary/cache file - safe to delete"
        } else if fileInfo.isOld && fileInfo.size > 100 * 1024 * 1024 { // 100MB
            // Large old files - archive
            action = .archive
            confidence = 0.7
            reason = "Large old file - recommend archiving"
        } else if fileInfo.isOld && safetyScore > 0.6 {
            // Old but safe files - archive
            action = .archive
            confidence = 0.6
            reason = "Old file - consider archiving"
        } else if safetyScore > 0.8 {
            // Very safe files - can delete if needed
            action = .delete
            confidence = 0.6
            reason = "Safe file - can be deleted if needed"
        } else {
            // Default - keep
            action = .keep
            confidence = 0.5
            reason = "Uncertain - recommend keeping"
        }
        
        return CleanupRecommendation(
            action: action,
            confidence: confidence,
            reason: reason,
            safetyScore: safetyScore
        )
    }
    
    // MARK: - Duplicate File Analysis
    
    /// Analyze duplicate files and provide recommendations
    /// - Parameter files: Array of duplicate files
    /// - Returns: Array of recommendations for each file
    public func analyzeDuplicateFiles(_ files: [FileAnalysisInfo]) -> [CleanupRecommendation] {
        guard files.count > 1 else {
            return files.map { generateCleanupRecommendation(for: $0) }
        }
        
        // Sort by safety score (highest first)
        let sortedFiles = files.sorted { file1, file2 in
            calculateSafetyScore(for: file1) > calculateSafetyScore(for: file2)
        }
        
        var recommendations: [CleanupRecommendation] = []
        
        for (index, file) in sortedFiles.enumerated() {
            if index == 0 {
                // Keep the first (safest) file
                recommendations.append(CleanupRecommendation(
                    action: .keep,
                    confidence: 0.8,
                    reason: "Keep original file (highest safety score)",
                    safetyScore: calculateSafetyScore(for: file)
                ))
            } else {
                // Delete duplicates
                recommendations.append(CleanupRecommendation(
                    action: .delete,
                    confidence: 0.7,
                    reason: "Duplicate file - safe to delete",
                    safetyScore: calculateSafetyScore(for: file)
                ))
            }
        }
        
        return recommendations
    }
    
    // MARK: - File Analysis
    
    /// Analyze file with optional ML model usage
    /// - Parameters:
    ///   - fileInfo: File analysis information
    ///   - useMLModel: Whether to attempt ML model usage
    /// - Returns: Complete file analysis result
    public func analyzeFile(_ fileInfo: FileAnalysisInfo, useMLModel: Bool = false) -> FileAnalysisResult {
        let contentType = detectContentType(filename: fileInfo.path)
        let safetyScore = calculateSafetyScore(for: fileInfo)
        let recommendation = generateCleanupRecommendation(for: fileInfo)
        
        // Try ML model if requested, fallback to heuristic
        let method: AnalysisMethod
        if useMLModel {
            // In a real implementation, this would attempt to use the ML model
            // For now, we'll use heuristic as fallback
            method = .heuristic
            logger.debug("ML model requested but using heuristic fallback for: \(fileInfo.path)")
        } else {
            method = .heuristic
        }
        
        return FileAnalysisResult(
            fileInfo: fileInfo,
            safetyScore: safetyScore,
            contentType: contentType,
            recommendation: recommendation,
            method: method,
            timestamp: Date()
        )
    }
    
    // MARK: - Analysis Reports
    
    /// Generate comprehensive analysis report for multiple files
    /// - Parameter files: Array of files to analyze
    /// - Returns: Comprehensive analysis report
    public func generateAnalysisReport(for files: [FileAnalysisInfo]) -> AnalysisReport {
        let analysisResults = files.map { analyzeFile($0) }
        
        let totalSize = files.reduce(0) { $0 + $1.size }
        let averageSafetyScore = analysisResults.reduce(0.0) { $0 + $1.safetyScore } / Double(analysisResults.count)
        
        let actionCounts = analysisResults.reduce(into: [CleanupAction: Int]()) { counts, result in
            counts[result.recommendation.action, default: 0] += 1
        }
        
        let spaceSavings = analysisResults
            .filter { $0.recommendation.action == .delete }
            .reduce(0) { $0 + $1.fileInfo.size }
        
        let summary = generateSummary(
            totalFiles: files.count,
            totalSize: totalSize,
            averageSafetyScore: averageSafetyScore,
            actionCounts: actionCounts,
            spaceSavings: spaceSavings
        )
        
        let recommendations = generateRecommendations(analysisResults: analysisResults)
        
        return AnalysisReport(
            totalFiles: files.count,
            totalSize: totalSize,
            averageSafetyScore: averageSafetyScore,
            analysisResults: analysisResults,
            actionCounts: actionCounts,
            spaceSavings: spaceSavings,
            summary: summary,
            recommendations: recommendations,
            generatedAt: Date()
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func getExtensionSafetyScore(_ extension: String) -> Double {
        let safeExtensions = ["pdf", "doc", "docx", "txt", "rtf", "pages", "jpg", "jpeg", "png", "gif", "mp4", "mov", "mp3", "wav"]
        let unsafeExtensions = ["app", "exe", "dmg", "pkg", "command", "sh", "bat", "com"]
        let neutralExtensions = ["zip", "rar", "7z", "tar", "gz"]
        
        let ext = `extension`.lowercased()
        
        if safeExtensions.contains(ext) {
            return 0.9
        } else if unsafeExtensions.contains(ext) {
            return 0.3
        } else if neutralExtensions.contains(ext) {
            return 0.7
        } else {
            return 0.6 // Unknown extension
        }
    }
    
    private func getPathSafetyScore(_ path: String) -> Double {
        let unsafePaths = ["/System/", "/usr/", "/bin/", "/sbin/", "/etc/", "/var/"]
        let safePaths = ["/Users/", "/Documents/", "/Desktop/", "/Downloads/"]
        
        let lowerPath = path.lowercased()
        
        if unsafePaths.contains(where: { lowerPath.hasPrefix($0) }) {
            return 0.2
        } else if safePaths.contains(where: { lowerPath.contains($0) }) {
            return 0.9
        } else {
            return 0.7
        }
    }
    
    private func getSizeSafetyScore(_ size: Int64) -> Double {
        let oneGB = Int64(1024 * 1024 * 1024)
        let oneMB = Int64(1024 * 1024)
        
        if size > oneGB {
            return 0.6 // Large files are less safe to delete
        } else if size < oneMB {
            return 0.8 // Small files are safer to delete
        } else {
            return 0.7 // Medium files
        }
    }
    
    private func getAgeSafetyScore(_ modified: Date, isRecent: Bool, isOld: Bool) -> Double {
        if isRecent {
            return 0.9 // Recent files are safer to keep
        } else if isOld {
            return 0.6 // Old files are less safe to keep
        } else {
            return 0.7 // Medium age
        }
    }
    
    private func generateSummary(
        totalFiles: Int,
        totalSize: Int64,
        averageSafetyScore: Double,
        actionCounts: [CleanupAction: Int],
        spaceSavings: Int64
    ) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        
        return """
        Analysis Summary:
        • Total files: \(totalFiles)
        • Total size: \(formatter.string(fromByteCount: totalSize))
        • Average safety score: \(String(format: "%.2f", averageSafetyScore))
        • Files to keep: \(actionCounts[.keep] ?? 0)
        • Files to delete: \(actionCounts[.delete] ?? 0)
        • Files to archive: \(actionCounts[.archive] ?? 0)
        • Potential space savings: \(formatter.string(fromByteCount: spaceSavings))
        """
    }
    
    private func generateRecommendations(analysisResults: [FileAnalysisResult]) -> [String] {
        var recommendations: [String] = []
        
        let highConfidenceDeletes = analysisResults.filter { 
            $0.recommendation.action == .delete && $0.recommendation.confidence > 0.7 
        }
        
        if !highConfidenceDeletes.isEmpty {
            recommendations.append("\(highConfidenceDeletes.count) files can be safely deleted with high confidence")
        }
        
        let largeFiles = analysisResults.filter { $0.fileInfo.size > 100 * 1024 * 1024 }
        if !largeFiles.isEmpty {
            recommendations.append("Consider archiving \(largeFiles.count) large files to save space")
        }
        
        let oldFiles = analysisResults.filter { $0.fileInfo.isOld }
        if !oldFiles.isEmpty {
            recommendations.append("\(oldFiles.count) old files could be archived or deleted")
        }
        
        return recommendations
    }
    
    // MARK: - Content Types Mapping
    
    private let contentTypes: [String: String] = [
        // Documents
        "pdf": "application/pdf",
        "doc": "application/msword",
        "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "txt": "text/plain",
        "rtf": "application/rtf",
        "pages": "application/vnd.apple.pages",
        "odt": "application/vnd.oasis.opendocument.text",
        
        // Spreadsheets
        "xls": "application/vnd.ms-excel",
        "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "numbers": "application/vnd.apple.numbers",
        "ods": "application/vnd.oasis.opendocument.spreadsheet",
        
        // Presentations
        "ppt": "application/vnd.ms-powerpoint",
        "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        "key": "application/vnd.apple.keynote",
        "odp": "application/vnd.oasis.opendocument.presentation",
        
        // Images
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "gif": "image/gif",
        "bmp": "image/bmp",
        "tiff": "image/tiff",
        "svg": "image/svg+xml",
        "webp": "image/webp",
        
        // Videos
        "mp4": "video/mp4",
        "avi": "video/x-msvideo",
        "mov": "video/quicktime",
        "wmv": "video/x-ms-wmv",
        "flv": "video/x-flv",
        "webm": "video/webm",
        "mkv": "video/x-matroska",
        
        // Audio
        "mp3": "audio/mpeg",
        "wav": "audio/wav",
        "aac": "audio/aac",
        "flac": "audio/flac",
        "ogg": "audio/ogg",
        "m4a": "audio/mp4",
        
        // Archives
        "zip": "application/zip",
        "rar": "application/x-rar-compressed",
        "7z": "application/x-7z-compressed",
        "tar": "application/x-tar",
        "gz": "application/gzip",
        "bz2": "application/x-bzip2",
        
        // Code
        "html": "text/html",
        "css": "text/css",
        "js": "application/javascript",
        "json": "application/json",
        "xml": "application/xml",
        "py": "text/x-python",
        "java": "text/x-java-source",
        "cpp": "text/x-c++src",
        "c": "text/x-csrc",
        "swift": "text/x-swift",
        
        // Executables
        "app": "application/x-executable",
        "exe": "application/x-msdownload",
        "dmg": "application/x-apple-diskimage",
        "pkg": "application/x-newton-compatible-pkg",
        "deb": "application/vnd.debian.binary-package",
        "rpm": "application/x-rpm"
    ]
}

// MARK: - Supporting Types

/// File analysis information
public struct FileAnalysisInfo: Codable {
    public let path: String
    public let size: Int64
    public let modified: Date
    public let isHidden: Bool
    public let isSystemFile: Bool
    public let extension: String
    public let isRecent: Bool
    public let isOld: Bool
    
    public init(
        path: String,
        size: Int64,
        modified: Date,
        isHidden: Bool,
        isSystemFile: Bool,
        extension: String,
        isRecent: Bool,
        isOld: Bool
    ) {
        self.path = path
        self.size = size
        self.modified = modified
        self.isHidden = isHidden
        self.isSystemFile = isSystemFile
        self.extension = extension
        self.isRecent = isRecent
        self.isOld = isOld
    }
}

/// Cleanup action types
public enum CleanupAction: String, Codable, CaseIterable {
    case keep = "keep"
    case delete = "delete"
    case archive = "archive"
}

/// Cleanup recommendation
public struct CleanupRecommendation: Codable {
    public let action: CleanupAction
    public let confidence: Double
    public let reason: String
    public let safetyScore: Double
    
    public init(action: CleanupAction, confidence: Double, reason: String, safetyScore: Double) {
        self.action = action
        self.confidence = confidence
        self.reason = reason
        self.safetyScore = safetyScore
    }
}

/// Analysis method
public enum AnalysisMethod: String, Codable {
    case mlModel = "ml_model"
    case heuristic = "heuristic"
}

/// File analysis result
public struct FileAnalysisResult: Codable {
    public let fileInfo: FileAnalysisInfo
    public let safetyScore: Double
    public let contentType: String
    public let recommendation: CleanupRecommendation
    public let method: AnalysisMethod
    public let timestamp: Date
    
    public init(
        fileInfo: FileAnalysisInfo,
        safetyScore: Double,
        contentType: String,
        recommendation: CleanupRecommendation,
        method: AnalysisMethod,
        timestamp: Date
    ) {
        self.fileInfo = fileInfo
        self.safetyScore = safetyScore
        self.contentType = contentType
        self.recommendation = recommendation
        self.method = method
        self.timestamp = timestamp
    }
}

/// Comprehensive analysis report
public struct AnalysisReport: Codable {
    public let totalFiles: Int
    public let totalSize: Int64
    public let averageSafetyScore: Double
    public let analysisResults: [FileAnalysisResult]
    public let actionCounts: [CleanupAction: Int]
    public let spaceSavings: Int64
    public let summary: String
    public let recommendations: [String]
    public let generatedAt: Date
    
    public init(
        totalFiles: Int,
        totalSize: Int64,
        averageSafetyScore: Double,
        analysisResults: [FileAnalysisResult],
        actionCounts: [CleanupAction: Int],
        spaceSavings: Int64,
        summary: String,
        recommendations: [String],
        generatedAt: Date
    ) {
        self.totalFiles = totalFiles
        self.totalSize = totalSize
        self.averageSafetyScore = averageSafetyScore
        self.analysisResults = analysisResults
        self.actionCounts = actionCounts
        self.spaceSavings = spaceSavings
        self.summary = summary
        self.recommendations = recommendations
        self.generatedAt = generatedAt
    }
}
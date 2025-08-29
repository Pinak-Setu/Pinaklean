import Foundation
import Combine
import os.log

/// Core Pinaklean Engine - Unified cleaning engine for both CLI and GUI
/// This is the heart of Pinaklean, providing all cleaning operations
@MainActor
public class PinakleanEngine: ObservableObject {

    // MARK: - Published Properties
    @Published public var isScanning = false
    @Published public var isCleaning = false
    @Published public var scanProgress: Double = 0
    @Published public var cleanProgress: Double = 0
    @Published public var currentOperation = ""
    @Published public var lastError: Error?
    @Published public var scanResults: ScanResults?
    @Published public var cleanResults: CleanResults?

    // MARK: - Core Components
    private let securityAuditor: SecurityAuditor
    private let parallelProcessor: ParallelProcessor
    private let smartDetector: SmartDetector
    private let incrementalIndexer: IncrementalIndexer
    private let backupManager: CloudBackupManager
    private let ragManager: RAGManager
    private let logger = Logger(subsystem: "com.pinaklean", category: "Engine")

    // MARK: - Configuration
    public struct Configuration {
        public var dryRun: Bool = false
        public var safeMode: Bool = true
        public var aggressiveMode: Bool = false
        public var parallelWorkers: Int = ProcessInfo.processInfo.processorCount
        public var enableSmartDetection: Bool = true
        public var enableSecurityAudit: Bool = true
        public var autoBackup: Bool = true
        public var verboseLogging: Bool = false

        public static let `default` = Configuration()
        public static let aggressive = Configuration(
            safeMode: false,
            aggressiveMode: true,
            enableSecurityAudit: false
        )
        public static let paranoid = Configuration(
            dryRun: true,
            safeMode: true,
            enableSecurityAudit: true,
            autoBackup: true
        )
    }

    public var configuration = Configuration.default

    /// Configure the engine (for CLI usage)
    public func configure(_ newConfiguration: Configuration) {
        configuration = newConfiguration
    }

    // MARK: - Scan Categories
    public struct ScanCategories: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let userCaches = ScanCategories(rawValue: 1 << 0)
        public static let systemCaches = ScanCategories(rawValue: 1 << 1)
        public static let developerJunk = ScanCategories(rawValue: 1 << 2)
        public static let appCaches = ScanCategories(rawValue: 1 << 3)
        public static let logs = ScanCategories(rawValue: 1 << 4)
        public static let downloads = ScanCategories(rawValue: 1 << 5)
        public static let trash = ScanCategories(rawValue: 1 << 6)
        public static let duplicates = ScanCategories(rawValue: 1 << 7)
        public static let largeFiles = ScanCategories(rawValue: 1 << 8)
        public static let oldFiles = ScanCategories(rawValue: 1 << 9)
        public static let brokenSymlinks = ScanCategories(rawValue: 1 << 10)
        public static let nodeModules = ScanCategories(rawValue: 1 << 11)
        public static let xcodeJunk = ScanCategories(rawValue: 1 << 12)
        public static let dockerJunk = ScanCategories(rawValue: 1 << 13)
        public static let brewCache = ScanCategories(rawValue: 1 << 14)
        public static let pipCache = ScanCategories(rawValue: 1 << 15)

        public static let all: ScanCategories = [
            .userCaches, .systemCaches, .developerJunk, .appCaches,
            .logs, .downloads, .trash, .duplicates, .largeFiles,
            .oldFiles, .brokenSymlinks, .nodeModules, .xcodeJunk,
            .dockerJunk, .brewCache, .pipCache
        ]

        public static let safe: ScanCategories = [
            .userCaches, .appCaches, .logs, .trash,
            .nodeModules, .brewCache, .pipCache
        ]

        public static let developer: ScanCategories = [
            .nodeModules, .xcodeJunk, .dockerJunk,
            .brewCache, .pipCache, .developerJunk
        ]
    }

    // MARK: - Initialization
    public init() async throws {
        self.securityAuditor = try await SecurityAuditor()
        self.parallelProcessor = ParallelProcessor()
        self.smartDetector = try await SmartDetector()
        self.incrementalIndexer = try await IncrementalIndexer()
        self.backupManager = CloudBackupManager()
        self.ragManager = try await RAGManager()

        logger.info("Pinaklean Engine initialized")

        // Start incremental indexer
        Task {
            await incrementalIndexer.startMonitoring()
        }
    }

    // MARK: - Public API

    /// Perform a scan for cleanable items
    public func scan(categories: ScanCategories = .safe) async throws -> ScanResults {
        guard !isScanning else {
            throw EngineError.operationInProgress
        }

        isScanning = true
        scanProgress = 0
        currentOperation = "Initializing scan..."
        defer { isScanning = false }

        logger.info("Starting scan with categories: \(categories.rawValue)")

        var results = ScanResults()
        let scanTasks = createScanTasks(for: categories)
        let totalTasks = Double(scanTasks.count)
        var completedTasks = 0.0

        // Execute scans in parallel
        try await withThrowingTaskGroup(of: [CleanableItem].self) { group in
            for task in scanTasks {
                group.addTask {
                    try await self.executeScanTask(task)
                }
            }

            for try await items in group {
                completedTasks += 1
                scanProgress = completedTasks / totalTasks
                results.items.append(contentsOf: items)
                results.totalSize += items.reduce(0) { $0 + $1.size }
            }
        }

        // Apply smart detection if enabled
        if configuration.enableSmartDetection {
            currentOperation = "Analyzing with ML..."
            results = try await applySmartDetection(to: results)
        }

        // Perform security audit if enabled
        if configuration.enableSecurityAudit {
            currentOperation = "Running security audit..."
            results = try await performSecurityAudit(on: results)
        }

        // Generate explanations
        currentOperation = "Generating explanations..."
        results = await addExplanations(to: results)

        self.scanResults = results
        logger.info("Scan completed: \(results.items.count) items, \(results.totalSize) bytes")

        return results
    }

    /// Clean selected items
    public func clean(_ items: [CleanableItem]) async throws -> CleanResults {
        guard !isCleaning else {
            throw EngineError.operationInProgress
        }

        isCleaning = true
        cleanProgress = 0
        currentOperation = "Preparing cleanup..."
        defer { isCleaning = false }

        logger.info("Starting cleanup of \(items.count) items")

        // Create backup if enabled
        if configuration.autoBackup && !configuration.dryRun {
            currentOperation = "Creating backup..."
            try await createBackup(for: items)
        }

        var results = CleanResults()
        let totalItems = Double(items.count)
        var processedItems = 0.0

        // Group items by type for efficient cleaning
        let groupedItems = Dictionary(grouping: items) { $0.category }

        for (category, categoryItems) in groupedItems {
            currentOperation = "Cleaning \(category)..."

            if configuration.dryRun {
                // Dry run - just simulate
                results.deletedItems.append(contentsOf: categoryItems)
                results.freedSpace += categoryItems.reduce(0) { $0 + $1.size }
            } else {
                // Actual deletion with parallel processing
                let deleted = try await parallelProcessor.deleteItems(categoryItems)
                results.deletedItems.append(contentsOf: deleted)
                results.freedSpace += deleted.reduce(0) { $0 + $1.size }
            }

            processedItems += Double(categoryItems.count)
            cleanProgress = processedItems / totalItems
        }

        // Record results
        results.timestamp = Date()
        results.isDryRun = configuration.dryRun
        self.cleanResults = results

        logger.info("Cleanup completed: \(results.deletedItems.count) items, \(results.freedSpace) bytes freed")

        return results
    }

    /// Get smart recommendations
    public func getRecommendations() async throws -> [CleaningRecommendation] {
        guard let scanResults = scanResults else {
            throw EngineError.noScanResults
        }

        currentOperation = "Generating recommendations..."

        var recommendations: [CleaningRecommendation] = []

        // Safe to delete items
        let safeItems = scanResults.items.filter { $0.safetyScore > 70 }
        if !safeItems.isEmpty {
            recommendations.append(CleaningRecommendation(
                id: UUID(),
                title: "Safe to Delete",
                description: "\(safeItems.count) items identified as safe to delete",
                items: safeItems,
                potentialSpace: safeItems.reduce(0) { $0 + $1.size },
                confidence: 0.95
            ))
        }

        // Large old files
        let largeOldFiles = scanResults.items.filter {
            $0.size > 100_000_000 && // > 100MB
            $0.lastAccessed.map { Date().timeIntervalSince($0) > 90 * 24 * 3600 } ?? false
        }
        if !largeOldFiles.isEmpty {
            recommendations.append(CleaningRecommendation(
                id: UUID(),
                title: "Large Unused Files",
                description: "Files over 100MB not accessed in 90+ days",
                items: largeOldFiles,
                potentialSpace: largeOldFiles.reduce(0) { $0 + $1.size },
                confidence: 0.85
            ))
        }

        // Developer junk
        let devJunk = scanResults.items.filter {
            [".nodeModules", ".xcodeJunk", ".dockerJunk"].contains($0.category)
        }
        if !devJunk.isEmpty {
            recommendations.append(CleaningRecommendation(
                id: UUID(),
                title: "Developer Cache",
                description: "Build artifacts and package caches",
                items: devJunk,
                potentialSpace: devJunk.reduce(0) { $0 + $1.size },
                confidence: 0.90
            ))
        }

        return recommendations
    }

    // MARK: - Private Methods

    private func createScanTasks(for categories: ScanCategories) -> [ScanTask] {
        var tasks: [ScanTask] = []

        if categories.contains(.userCaches) {
            tasks.append(ScanTask(
                category: ".userCaches",
                paths: [
                    URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Caches"),
                    URL(fileURLWithPath: NSHomeDirectory())
                        .appendingPathComponent("Library/Application Support")
                        .appendingPathComponent("Google/Chrome/Default/Cache")
                ],
                patterns: ["*", "Cache.db", "*.cache"]
            ))
        }

        if categories.contains(.nodeModules) {
            tasks.append(ScanTask(
                category: ".nodeModules",
                paths: [
                    URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents"),
                    URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Developer")
                ],
                patterns: ["node_modules", ".npm", ".yarn", ".pnpm-store"]
            ))
        }

        if categories.contains(.xcodeJunk) {
            tasks.append(ScanTask(
                category: ".xcodeJunk",
                paths: [
                    URL(fileURLWithPath: NSHomeDirectory())
                        .appendingPathComponent("Library/Developer/Xcode/DerivedData"),
                    URL(fileURLWithPath: NSHomeDirectory())
                        .appendingPathComponent("Library/Developer/Xcode/Archives")
                ],
                patterns: ["*"]
            ))
        }

        if categories.contains(.trash) {
            tasks.append(ScanTask(
                category: ".trash",
                paths: [
                    URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".Trash")
                ],
                patterns: ["*"]
            ))
        }

        // Add more categories...

        return tasks
    }

    private func executeScanTask(_ task: ScanTask) async throws -> [CleanableItem] {
        var items: [CleanableItem] = []

        for basePath in task.paths {
            guard FileManager.default.fileExists(atPath: basePath.path) else { continue }

            for pattern in task.patterns {
                let foundPaths = try await findPaths(in: basePath, matching: pattern)

                for path in foundPaths {
                    if let item = try? await createCleanableItem(from: path, category: task.category) {
                        items.append(item)
                    }
                }
            }
        }

        return items
    }

    private func findPaths(in directory: URL, matching pattern: String) async throws -> [URL] {
        // Use parallel file enumeration
        return try await parallelProcessor.findFiles(in: directory, matching: pattern)
    }

    private func createCleanableItem(from url: URL, category: String) async throws -> CleanableItem {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attributes[.size] as? Int64) ?? 0
        let modified = attributes[.modificationDate] as? Date
        let accessed = attributes[.creationDate] as? Date // Note: macOS doesn't reliably track access time

        // Calculate safety score
        let safetyScore = await smartDetector.calculateSafetyScore(for: url)

        return CleanableItem(
            id: UUID(),
            path: url.path,
            name: url.lastPathComponent,
            category: category,
            size: size,
            lastModified: modified,
            lastAccessed: accessed,
            safetyScore: safetyScore,
            explanation: nil
        )
    }

    private func applySmartDetection(to results: ScanResults) async throws -> ScanResults {
        var enhancedResults = results

        // Find duplicates
        let duplicates = try await smartDetector.findDuplicates(in: results.items)
        enhancedResults.duplicates = duplicates

        // Apply ML-based safety scoring
        for (index, item) in enhancedResults.items.enumerated() {
            let enhancedScore = try await smartDetector.enhanceSafetyScore(for: item)
            enhancedResults.items[index].safetyScore = enhancedScore
        }

        return enhancedResults
    }

    private func performSecurityAudit(on results: ScanResults) async throws -> ScanResults {
        var auditedResults = results

        for (index, item) in auditedResults.items.enumerated() {
            let auditResult = try await securityAuditor.audit(URL(fileURLWithPath: item.path))

            // Update safety score based on audit
            if auditResult.risk == .critical || auditResult.risk == .high {
                auditedResults.items[index].safetyScore = min(auditedResults.items[index].safetyScore, 25)
                auditedResults.items[index].warning = auditResult.message
            }
        }

        return auditedResults
    }

    private func addExplanations(to results: ScanResults) async -> ScanResults {
        var explainedResults = results

        for (index, item) in explainedResults.items.enumerated() {
            let explanation = await ragManager.generateExplanation(for: item)
            explainedResults.items[index].explanation = explanation
        }

        return explainedResults
    }

    private func createBackup(for items: [CleanableItem]) async throws {
        let snapshot = DiskSnapshot(
            id: UUID(),
            timestamp: Date(),
            totalSize: items.reduce(0) { $0 + $1.size },
            fileCount: items.count,
            metadata: [
                "type": "pre-cleanup",
                "categories": items.map { $0.category }.unique().joined(separator: ",")
            ]
        )

        _ = try await backupManager.smartBackup(snapshot)
    }
}

// MARK: - Supporting Types

public struct ScanResults: Codable {
    public var items: [CleanableItem] = []
    public var duplicates: [DuplicateGroup] = []
    public var totalSize: Int64 = 0
    public var timestamp = Date()

    public var itemsByCategory: [String: [CleanableItem]] {
        Dictionary(grouping: items) { $0.category }
    }

    public var safeTotalSize: Int64 {
        items.filter { $0.safetyScore > 70 }.reduce(0) { $0 + $1.size }
    }
}

public struct CleanResults {
    public var deletedItems: [CleanableItem] = []
    public var failedItems: [CleanableItem] = []
    public var freedSpace: Int64 = 0
    public var timestamp = Date()
    public var isDryRun = false
}

public struct CleanableItem: Identifiable, Codable {
    public let id: UUID
    public let path: String
    public let name: String
    public let category: String
    public let size: Int64
    public let lastModified: Date?
    public let lastAccessed: Date?
    public var safetyScore: Int
    public var explanation: String?
    public var warning: String?

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    public var isRecommended: Bool {
        safetyScore > 70 && warning == nil
    }
}

public struct DuplicateGroup: Identifiable, Codable {
    public let id = UUID()
    public let checksum: String
    public let items: [CleanableItem]
    public var wastedSpace: Int64 {
        guard items.count > 1 else { return 0 }
        return items.dropFirst().reduce(0) { $0 + $1.size }
    }
}

public struct CleaningRecommendation: Identifiable {
    public let id: UUID
    public let title: String
    public let description: String
    public let items: [CleanableItem]
    public let potentialSpace: Int64
    public let confidence: Double

    public var formattedSpace: String {
        ByteCountFormatter.string(fromByteCount: potentialSpace, countStyle: .file)
    }
}

struct ScanTask {
    let category: String
    let paths: [URL]
    let patterns: [String]
}

public enum EngineError: LocalizedError {
    case operationInProgress
    case noScanResults
    case securityAuditFailed(String)
    case backupFailed(String)

    public var errorDescription: String? {
        switch self {
        case .operationInProgress:
            return "An operation is already in progress"
        case .noScanResults:
            return "No scan results available. Please run a scan first."
        case .securityAuditFailed(let message):
            return "Security audit failed: \(message)"
        case .backupFailed(let message):
            return "Backup failed: \(message)"
        }
    }
}

// MARK: - Real Component Initializations

// MARK: - Extensions

extension Array where Element: Hashable {
    func unique() -> [Element] {
        Array(Set(self))
    }
}

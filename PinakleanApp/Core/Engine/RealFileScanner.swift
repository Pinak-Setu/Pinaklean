import Foundation
import os.log

/// Real file system scanner that performs actual file system operations
/// Replaces simulation with production-grade file scanning
public class RealFileScanner {
    private let fileManager = FileManager.default
    private let securityAuditor: SecurityAuditor
    private let parallelProcessor: ParallelProcessor
    private let logger = Logger(subsystem: "com.pinaklean", category: "FileScanner")
    
    public init(securityAuditor: SecurityAuditor, parallelProcessor: ParallelProcessor) {
        self.securityAuditor = securityAuditor
        self.parallelProcessor = parallelProcessor
    }
    
    /// Scan the system for cleanable files
    public func scanSystem(categories: PinakleanEngine.ScanCategories, progressCallback: @escaping (Double) -> Void) async throws -> [CleanableItem] {
        logger.info("Starting real file system scan with categories: \(categories.rawValue)")
        
        var allItems: [CleanableItem] = []
        let scanPaths = getScanPaths(for: categories)
        let totalPaths = Double(scanPaths.count)
        var completedPaths = 0.0
        
        // Scan each path in parallel
        try await withThrowingTaskGroup(of: [CleanableItem].self) { group in
            for path in scanPaths {
                group.addTask {
                    try await self.scanDirectory(path, categories: categories)
                }
            }
            
            // Collect results
            for try await items in group {
                allItems.append(contentsOf: items)
                completedPaths += 1
                progressCallback(completedPaths / totalPaths)
            }
        }
        
        logger.info("Real scan completed: \(allItems.count) items found")
        return allItems
    }
    
    /// Scan a specific directory
    private func scanDirectory(_ path: String, categories: PinakleanEngine.ScanCategories) async throws -> [CleanableItem] {
        guard fileManager.fileExists(atPath: path) else {
            logger.warning("Directory does not exist: \(path)")
            return []
        }
        
        var items: [CleanableItem] = []
        
        // Get directory contents
        let contents = try fileManager.contentsOfDirectory(atPath: path)
        
        for content in contents {
            let fullPath = (path as NSString).appendingPathComponent(content)
            var isDirectory: ObjCBool = false
            
            guard fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory) else {
                continue
            }
            
            if isDirectory.boolValue {
                // Recursively scan subdirectories
                let subItems = try await scanDirectory(fullPath, categories: categories)
                items.append(contentsOf: subItems)
            } else {
                // Analyze file
                if let item = try await analyzeFile(at: fullPath, categories: categories) {
                    items.append(item)
                }
            }
        }
        
        return items
    }
    
    /// Analyze a single file
    private func analyzeFile(at path: String, categories: PinakleanEngine.ScanCategories) async throws -> CleanableItem? {
        // Get file attributes
        let attributes = try fileManager.attributesOfItem(atPath: path)
        guard let fileSize = attributes[.size] as? Int64 else {
            return nil
        }
        
        // Determine file category
        let category = determineFileCategory(path: path, categories: categories)
        guard category != nil else {
            return nil // File doesn't match any requested categories
        }
        
        // Perform security audit
        let securityResult = try await securityAuditor.audit(URL(fileURLWithPath: path))
        let safetyScore = calculateSafetyScore(from: securityResult)
        
        // Create cleanable item
        let item = CleanableItem(
            id: UUID(),
            path: path,
            name: (path as NSString).lastPathComponent,
            category: category ?? "unknown",
            size: fileSize,
            safetyScore: safetyScore
        )
        
        return item
    }
    
    /// Determine file category based on path and requested categories
    private func determineFileCategory(path: String, categories: PinakleanEngine.ScanCategories) -> String? {
        let pathLower = path.lowercased()
        
        // Check each category
        if categories.contains(.userCaches) && isUserCache(path: pathLower) {
            return "cache"
        }
        
        if categories.contains(.systemCaches) && isSystemCache(path: pathLower) {
            return "cache"
        }
        
        if categories.contains(.appCaches) && isAppCache(path: pathLower) {
            return "cache"
        }
        
        if categories.contains(.logs) && isLogFile(path: pathLower) {
            return "logs"
        }
        
        if categories.contains(.developerJunk) && isDeveloperJunk(path: pathLower) {
            return "developer"
        }
        
        if categories.contains(.nodeModules) && isNodeModules(path: pathLower) {
            return "node_modules"
        }
        
        if categories.contains(.xcodeJunk) && isXcodeJunk(path: pathLower) {
            return "xcode"
        }
        
        if categories.contains(.brewCache) && isBrewCache(path: pathLower) {
            return "brew"
        }
        
        if categories.contains(.pipCache) && isPipCache(path: pathLower) {
            return "pip"
        }
        
        if categories.contains(.trash) && isTrash(path: pathLower) {
            return "trash"
        }
        
        if categories.contains(.downloads) && isDownloads(path: pathLower) {
            return "downloads"
        }
        
        if categories.contains(.duplicates) && isDuplicate(path: pathLower) {
            return "duplicates"
        }
        
        return nil
    }
    
    /// Calculate safety score from security audit result
    private func calculateSafetyScore(from result: SecurityAuditor.AuditResult) -> Int {
        switch result.risk {
        case .critical:
            return 0
        case .high:
            return 25
        case .medium:
            return 50
        case .low:
            return 75
        case .minimal:
            return 90
        }
    }
    
    /// Get scan paths based on categories
    private func getScanPaths(for categories: PinakleanEngine.ScanCategories) -> [String] {
        var paths: [String] = []
        
        if categories.contains(.userCaches) {
            paths.append(NSHomeDirectory() + "/Library/Caches")
        }
        
        if categories.contains(.systemCaches) {
            paths.append("/Library/Caches")
            paths.append("/System/Library/Caches")
        }
        
        if categories.contains(.appCaches) {
            paths.append(NSHomeDirectory() + "/Library/Application Support")
        }
        
        if categories.contains(.logs) {
            paths.append(NSHomeDirectory() + "/Library/Logs")
            paths.append("/var/log")
        }
        
        if categories.contains(.developerJunk) {
            paths.append(NSHomeDirectory() + "/.cache")
            paths.append(NSHomeDirectory() + "/.npm")
            paths.append(NSHomeDirectory() + "/.cargo")
        }
        
        if categories.contains(.nodeModules) {
            paths.append(NSHomeDirectory() + "/node_modules")
        }
        
        if categories.contains(.xcodeJunk) {
            paths.append(NSHomeDirectory() + "/Library/Developer/Xcode/DerivedData")
            paths.append(NSHomeDirectory() + "/Library/Developer/Xcode/Archives")
        }
        
        if categories.contains(.brewCache) {
            paths.append("/opt/homebrew/var/cache")
            paths.append("/usr/local/var/cache")
        }
        
        if categories.contains(.pipCache) {
            paths.append(NSHomeDirectory() + "/Library/Caches/pip")
        }
        
        if categories.contains(.trash) {
            paths.append(NSHomeDirectory() + "/.Trash")
        }
        
        if categories.contains(.downloads) {
            paths.append(NSHomeDirectory() + "/Downloads")
        }
        
        return paths
    }
    
    // MARK: - File Type Detection
    
    private func isUserCache(path: String) -> Bool {
        return path.contains("/library/caches/") || 
               path.contains("/.cache/") ||
               path.hasSuffix(".cache") ||
               path.hasSuffix(".tmp")
    }
    
    private func isSystemCache(path: String) -> Bool {
        return path.contains("/system/library/caches/") ||
               path.contains("/library/caches/") ||
               path.hasSuffix(".cache")
    }
    
    private func isAppCache(path: String) -> Bool {
        return path.contains("/application support/") ||
               path.contains("/caches/") ||
               path.hasSuffix(".cache")
    }
    
    private func isLogFile(path: String) -> Bool {
        return path.hasSuffix(".log") ||
               path.hasSuffix(".log.1") ||
               path.hasSuffix(".log.2") ||
               path.contains("/logs/")
    }
    
    private func isDeveloperJunk(path: String) -> Bool {
        return path.contains("/.cache/") ||
               path.contains("/.npm/") ||
               path.contains("/.cargo/") ||
               path.contains("/.gradle/") ||
               path.contains("/.m2/")
    }
    
    private func isNodeModules(path: String) -> Bool {
        return path.contains("/node_modules/") ||
               path.hasSuffix("/node_modules")
    }
    
    private func isXcodeJunk(path: String) -> Bool {
        return path.contains("/deriveddata/") ||
               path.contains("/archives/") ||
               path.contains("/xcode/")
    }
    
    private func isBrewCache(path: String) -> Bool {
        return path.contains("/homebrew/var/cache/") ||
               path.contains("/brew/cache/")
    }
    
    private func isPipCache(path: String) -> Bool {
        return path.contains("/pip/cache/") ||
               path.contains("/.cache/pip/")
    }
    
    private func isTrash(path: String) -> Bool {
        return path.contains("/.trash/") ||
               path.contains("/trash/")
    }
    
    private func isDownloads(path: String) -> Bool {
        return path.contains("/downloads/") ||
               path.hasSuffix("/downloads")
    }
    
    private func isDuplicate(path: String) -> Bool {
        // This would require content analysis - simplified for now
        return path.contains(" copy") ||
               path.contains(" (1)") ||
               path.contains(" (2)")
    }
}
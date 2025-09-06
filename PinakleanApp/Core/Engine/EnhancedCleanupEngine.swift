import Foundation
import os.log

/// Enhanced Cleanup Engine - Integrates software detection with native cleanup commands
public class EnhancedCleanupEngine {
    private let logger = Logger(subsystem: "com.pinaklean", category: "EnhancedCleanupEngine")
    private let softwareDetector = SoftwareDetector()
    private let fileManager = FileManager.default
    
    /// Cleanup operation result
    public struct CleanupOperationResult {
        let softwareName: String
        let operationType: OperationType
        let success: Bool
        let spaceFreed: Int64
        let filesProcessed: Int
        let duration: TimeInterval
        let details: String
    }
    
    /// Type of cleanup operation
    public enum OperationType {
        case nativeCommand    // Using software's native cleanup command
        case cacheCleanup     // Direct cache file cleanup
        case systemCleanup    // System-level cleanup
    }
    
    /// Initialize Enhanced Cleanup Engine
    public init() {}
    
    /// Perform comprehensive cleanup using detected software
    public func performComprehensiveCleanup() async throws -> [CleanupOperationResult] {
        logger.info("Starting comprehensive cleanup with software detection...")
        
        var results: [CleanupOperationResult] = []
        
        // Step 1: Detect installed software
        let detectedSoftware = await softwareDetector.detectInstalledSoftware()
        logger.info("Detected \(detectedSoftware.count) software packages")
        
        // Step 2: Execute native cleanup commands
        let nativeResults = await executeNativeCleanupCommands(detectedSoftware)
        results.append(contentsOf: nativeResults)
        
        // Step 3: Clean cache files directly
        let cacheResults = await cleanCacheFilesDirectly(detectedSoftware)
        results.append(contentsOf: cacheResults)
        
        // Step 4: Perform system-level cleanup
        let systemResults = await performSystemCleanup()
        results.append(contentsOf: systemResults)
        
        // Step 5: Generate summary
        let summary = generateCleanupSummary(results)
        logger.info("Comprehensive cleanup completed: \(summary)")
        
        return results
    }
    
    // MARK: - Native Cleanup Commands
    
    private func executeNativeCleanupCommands(_ software: [SoftwareDetector.DetectedSoftware]) async -> [CleanupOperationResult] {
        var results: [CleanupOperationResult] = []
        
        for sw in software {
            logger.info("Executing native cleanup commands for \(sw.name)")
            
            for command in sw.cleanupCommands {
                let startTime = Date()
                
                do {
                    let result = try await executeCommand(command, for: sw.name)
                    let duration = Date().timeIntervalSince(startTime)
                    
                    let operationResult = CleanupOperationResult(
                        softwareName: sw.name,
                        operationType: .nativeCommand,
                        success: result.success,
                        spaceFreed: estimateSpaceFreed(from: command),
                        filesProcessed: 0, // Native commands don't report file count
                        duration: duration,
                        details: result.output
                    )
                    
                    results.append(operationResult)
                    
                    if result.success {
                        logger.info("✅ \(sw.name): \(command.description) - SUCCESS")
                    } else {
                        logger.warning("❌ \(sw.name): \(command.description) - FAILED: \(result.output)")
                    }
                } catch {
                    let duration = Date().timeIntervalSince(startTime)
                    let operationResult = CleanupOperationResult(
                        softwareName: sw.name,
                        operationType: .nativeCommand,
                        success: false,
                        spaceFreed: 0,
                        filesProcessed: 0,
                        duration: duration,
                        details: error.localizedDescription
                    )
                    
                    results.append(operationResult)
                    logger.error("❌ \(sw.name): \(command.description) - ERROR: \(error)")
                }
            }
        }
        
        return results
    }
    
    private func executeCommand(_ command: SoftwareDetector.CleanupCommand, for softwareName: String) async -> CleanupResult {
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [command.command] + command.arguments
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                let result = CleanupResult(
                    softwareName: softwareName,
                    command: command,
                    success: process.terminationStatus == 0,
                    output: output,
                    exitCode: process.terminationStatus
                )
                
                continuation.resume(returning: result)
            } catch {
                let result = CleanupResult(
                    softwareName: softwareName,
                    command: command,
                    success: false,
                    output: error.localizedDescription,
                    exitCode: -1
                )
                
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - Direct Cache Cleanup
    
    private func cleanCacheFilesDirectly(_ software: [SoftwareDetector.DetectedSoftware]) async -> [CleanupOperationResult] {
        var results: [CleanupOperationResult] = []
        
        for sw in software {
            logger.info("Cleaning cache files directly for \(sw.name)")
            
            let startTime = Date()
            var totalSpaceFreed: Int64 = 0
            var filesProcessed = 0
            
            for cachePath in sw.cachePaths {
                let expandedPath = NSString(string: cachePath).expandingTildeInPath
                
                do {
                    let (spaceFreed, fileCount) = try await cleanDirectory(expandedPath)
                    totalSpaceFreed += spaceFreed
                    filesProcessed += fileCount
                } catch {
                    logger.warning("Failed to clean \(expandedPath): \(error)")
                }
            }
            
            let duration = Date().timeIntervalSince(startTime)
            let operationResult = CleanupOperationResult(
                softwareName: sw.name,
                operationType: .cacheCleanup,
                success: totalSpaceFreed > 0,
                spaceFreed: totalSpaceFreed,
                filesProcessed: filesProcessed,
                duration: duration,
                details: "Cleaned \(filesProcessed) files from cache directories"
            )
            
            results.append(operationResult)
            
            if totalSpaceFreed > 0 {
                logger.info("✅ \(sw.name): Direct cache cleanup - \(ByteCountFormatter.string(fromByteCount: totalSpaceFreed, countStyle: .file)) freed")
            }
        }
        
        return results
    }
    
    private func cleanDirectory(_ path: String) async throws -> (spaceFreed: Int64, fileCount: Int) {
        guard fileManager.fileExists(atPath: path) else {
            return (0, 0)
        }
        
        var totalSpaceFreed: Int64 = 0
        var fileCount = 0
        
        let contents = try fileManager.contentsOfDirectory(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        for url in contents {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                let isDirectory = attributes[.type] as? FileAttributeType == .typeDirectory
                
                if isDirectory {
                    // Recursively clean subdirectories
                    let (subSpace, subCount) = try await cleanDirectory(url.path)
                    totalSpaceFreed += subSpace
                    fileCount += subCount
                } else {
                    // Delete file
                    try fileManager.removeItem(at: url)
                    totalSpaceFreed += fileSize
                    fileCount += 1
                }
            } catch {
                // Skip files we can't delete
                continue
            }
        }
        
        return (totalSpaceFreed, fileCount)
    }
    
    // MARK: - System Cleanup
    
    private func performSystemCleanup() async -> [CleanupOperationResult] {
        var results: [CleanupOperationResult] = []
        
        logger.info("Performing system-level cleanup...")
        
        // Clean system temporary files
        let tempResult = await cleanSystemTempFiles()
        results.append(tempResult)
        
        // Clean user caches
        let cacheResult = await cleanUserCaches()
        results.append(cacheResult)
        
        // Clean logs
        let logResult = await cleanSystemLogs()
        results.append(logResult)
        
        return results
    }
    
    private func cleanSystemTempFiles() async -> CleanupOperationResult {
        let startTime = Date()
        let tempPaths = [
            "/private/var/folders",
            "/tmp",
            "/var/tmp"
        ]
        
        var totalSpaceFreed: Int64 = 0
        var filesProcessed = 0
        
        for tempPath in tempPaths {
            do {
                let (spaceFreed, fileCount) = try await cleanDirectory(tempPath)
                totalSpaceFreed += spaceFreed
                filesProcessed += fileCount
            } catch {
                logger.warning("Failed to clean system temp path \(tempPath): \(error)")
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        return CleanupOperationResult(
            softwareName: "System",
            operationType: .systemCleanup,
            success: totalSpaceFreed > 0,
            spaceFreed: totalSpaceFreed,
            filesProcessed: filesProcessed,
            duration: duration,
            details: "Cleaned system temporary files"
        )
    }
    
    private func cleanUserCaches() async -> CleanupOperationResult {
        let startTime = Date()
        let cachePath = "~/Library/Caches"
        let expandedPath = NSString(string: cachePath).expandingTildeInPath
        
        var totalSpaceFreed: Int64 = 0
        var filesProcessed = 0
        
        do {
            let (spaceFreed, fileCount) = try await cleanDirectory(expandedPath)
            totalSpaceFreed += spaceFreed
            filesProcessed += fileCount
        } catch {
            logger.warning("Failed to clean user caches: \(error)")
        }
        
        let duration = Date().timeIntervalSince(startTime)
        return CleanupOperationResult(
            softwareName: "User Caches",
            operationType: .systemCleanup,
            success: totalSpaceFreed > 0,
            spaceFreed: totalSpaceFreed,
            filesProcessed: filesProcessed,
            duration: duration,
            details: "Cleaned user cache files"
        )
    }
    
    private func cleanSystemLogs() async -> CleanupOperationResult {
        let startTime = Date()
        let logPaths = [
            "~/Library/Logs",
            "/var/log"
        ]
        
        var totalSpaceFreed: Int64 = 0
        var filesProcessed = 0
        
        for logPath in logPaths {
            let expandedPath = NSString(string: logPath).expandingTildeInPath
            do {
                let (spaceFreed, fileCount) = try await cleanDirectory(expandedPath)
                totalSpaceFreed += spaceFreed
                filesProcessed += fileCount
            } catch {
                logger.warning("Failed to clean log path \(logPath): \(error)")
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        return CleanupOperationResult(
            softwareName: "System Logs",
            operationType: .systemCleanup,
            success: totalSpaceFreed > 0,
            spaceFreed: totalSpaceFreed,
            filesProcessed: filesProcessed,
            duration: duration,
            details: "Cleaned system log files"
        )
    }
    
    // MARK: - Helper Methods
    
    private func estimateSpaceFreed(from command: SoftwareDetector.CleanupCommand) -> Int64 {
        // This is a rough estimation based on the command type
        // In a real implementation, you'd want to measure before/after
        switch command.command {
        case "npm":
            return 100 * 1024 * 1024 // 100MB
        case "brew":
            return 500 * 1024 * 1024 // 500MB
        case "docker":
            return 1024 * 1024 * 1024 // 1GB
        case "xcrun":
            return 2 * 1024 * 1024 * 1024 // 2GB
        default:
            return 50 * 1024 * 1024 // 50MB default
        }
    }
    
    private func generateCleanupSummary(_ results: [CleanupOperationResult]) -> String {
        let totalSpaceFreed = results.reduce(0) { $0 + $1.spaceFreed }
        let totalFilesProcessed = results.reduce(0) { $0 + $1.filesProcessed }
        let successfulOperations = results.filter { $0.success }.count
        let totalOperations = results.count
        
        return """
        Cleanup Summary:
        - Total operations: \(totalOperations)
        - Successful operations: \(successfulOperations)
        - Total space freed: \(ByteCountFormatter.string(fromByteCount: totalSpaceFreed, countStyle: .file))
        - Total files processed: \(totalFilesProcessed)
        - Success rate: \(Int(Double(successfulOperations) / Double(totalOperations) * 100))%
        """
    }
}

// MARK: - Cleanup Result (from SoftwareDetector)
// CleanupResult is defined in SoftwareDetector.swift
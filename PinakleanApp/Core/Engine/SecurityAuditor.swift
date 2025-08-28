import Foundation
import SystemConfiguration
import Security

/// Comprehensive security auditor for file deletion safety
public actor SecurityAuditor {
    public enum Risk: Int, Comparable {
        case critical = 100  // Never delete
        case high = 75       // Require explicit confirmation
        case medium = 50     // Warn user
        case low = 25        // Safe with notification
        case minimal = 0     // Safe to auto-clean

        public static func < (lhs: Risk, rhs: Risk) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    public struct AuditResult {
        public let risk: Risk
        public let message: String?
        public let details: [String: Any]?
        public let timestamp = Date()
    }

    // Critical system paths that should never be deleted
    private let criticalPaths: Set<String> = [
        "/System",
        "/usr",
        "/bin",
        "/sbin",
        "/private",
        "/Library/Keychains",
        "/Library/Preferences",
        "/Library/LaunchDaemons",
        "/Library/LaunchAgents",
        "/System/Library"
    ]

    // Important user data paths
    private let importantUserPaths: Set<String> = [
        "/Users/*/Documents",
        "/Users/*/Desktop",
        "/Users/*/Pictures",
        "/Users/*/Movies",
        "/Users/*/Music",
        "/Users/*/Downloads",
        "/Users/*/Library/Mail",
        "/Users/*/Library/Safari",
        "/Users/*/Library/Application Support",
        "/Users/*/Library/Containers"
    ]

    // Active process patterns to check
    private let activeProcessPatterns: Set<String> = [
        "Safari", "Mail", "Photos", "Music", "iTunes", "Xcode",
        "Visual Studio Code", "IntelliJ IDEA", "WebStorm",
        "Docker", "VirtualBox", "VMware"
    ]

    public init() async throws {
        // Initialize security monitoring
    }

    /// Comprehensive security audit for a file path
    public func audit(_ url: URL) async throws -> AuditResult {
        let path = url.path

        // Check critical system paths
        if let risk = checkCriticalPaths(path) {
            return risk
        }

        // Check important user data
        if let risk = checkImportantUserData(path) {
            return risk
        }

        // Check file ownership and permissions
        if let risk = try await checkFileOwnership(url) {
            return risk
        }

        // Check for active processes using this path
        if let risk = try await checkActiveProcesses(path) {
            return risk
        }

        // Check file signatures for system files
        if let risk = try await checkFileSignatures(url) {
            return risk
        }

        // Check modification patterns
        if let risk = try await checkModificationPatterns(url) {
            return risk
        }

        // Check file size and type safety
        if let risk = try await checkFileSafety(url) {
            return risk
        }

        return AuditResult(
            risk: .minimal,
            message: "File appears safe to delete",
            details: ["confidence": 0.95]
        )
    }

    private func checkCriticalPaths(_ path: String) -> AuditResult? {
        for criticalPath in criticalPaths {
            if path.hasPrefix(criticalPath) {
                return AuditResult(
                    risk: .critical,
                    message: "Critical system path: \(criticalPath)",
                    details: ["blocked_by": "critical_path", "path": criticalPath]
                )
            }
        }
        return nil
    }

    private func checkImportantUserData(_ path: String) -> AuditResult? {
        for pattern in importantUserPaths {
            if path.matches(pattern: pattern) {
                // Additional checks for user data
                if isLikelyUserData(path) {
                    return AuditResult(
                        risk: .high,
                        message: "Contains important user data",
                        details: ["blocked_by": "user_data", "pattern": pattern]
                    )
                }
            }
        }
        return nil
    }

    private func isLikelyUserData(_ path: String) -> Bool {
        let userDataIndicators = [
            "Documents", "Desktop", "Pictures", "Movies", "Music",
            ".docx", ".pdf", ".jpg", ".png", ".mp4", ".mov"
        ]

        return userDataIndicators.contains { path.contains($0) }
    }

    private func checkFileOwnership(_ url: URL) async throws -> AuditResult? {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)

        // Check if file is owned by root or system
        if let ownerAccountID = attributes[.ownerAccountID] as? NSNumber,
           ownerAccountID.intValue == 0 {
            return AuditResult(
                risk: .high,
                message: "File owned by system/root",
                details: ["owner": "root"]
            )
        }

        // Check permissions
        if let posixPermissions = attributes[.posixPermissions] as? NSNumber {
            let permissions = posixPermissions.intValue

            // Check if file has system-level permissions
            if permissions & 0o4000 != 0 { // setuid
                return AuditResult(
                    risk: .critical,
                    message: "File has setuid bit set",
                    details: ["permissions": permissions]
                )
            }
        }

        return nil
    }

    private func checkActiveProcesses(_ path: String) async throws -> AuditResult? {
        // Check if any active processes are using files in this path
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "lsof \"\(path)\" 2>/dev/null | head -5"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return AuditResult(
                    risk: .high,
                    message: "Files in path are currently in use",
                    details: ["active_processes": output]
                )
            }
        }

        return nil
    }

    private func checkFileSignatures(_ url: URL) async throws -> AuditResult? {
        // Check if file has code signatures (indicates system/app files)
        let task = Process()
        task.launchPath = "/usr/bin/codesign"
        task.arguments = ["-d", "--verbose", url.path]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8),
               (output.contains("Authority=") || output.contains("Developer ID")) {
                return AuditResult(
                    risk: .high,
                    message: "File has valid code signature",
                    details: ["signature_info": output]
                )
            }
        }

        return nil
    }

    private func checkModificationPatterns(_ url: URL) async throws -> AuditResult? {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)

        guard let modificationDate = attributes[.modificationDate] as? Date else {
            return nil
        }

        let daysSinceModified = Calendar.current.dateComponents([.day], from: modificationDate, to: Date()).day ?? 0

        // Files modified very recently are likely important
        if daysSinceModified <= 1 {
            return AuditResult(
                risk: .medium,
                message: "File modified recently (\(daysSinceModified) days ago)",
                details: ["days_since_modified": daysSinceModified]
            )
        }

        return nil
    }

    private func checkFileSafety(_ url: URL) async throws -> AuditResult? {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)

        // Check file size
        if let fileSize = attributes[.size] as? NSNumber,
           fileSize.int64Value > 10 * 1024 * 1024 * 1024 { // > 10GB
            return AuditResult(
                risk: .medium,
                message: "Very large file (\(ByteCountFormatter.string(fromByteCount: fileSize.int64Value, countStyle: .file)))",
                details: ["size": fileSize.int64Value]
            )
        }

        // Check file type
        let fileExtension = url.pathExtension.lowercased()
        let riskyExtensions = ["app", "bundle", "framework", "kext", "dylib"]

        if riskyExtensions.contains(fileExtension) {
            return AuditResult(
                risk: .high,
                message: "Potentially system-critical file type",
                details: ["extension": fileExtension]
            )
        }

        return nil
    }

    /// Batch audit multiple paths for efficiency
    public func batchAudit(_ urls: [URL]) async throws -> [URL: AuditResult] {
        var results: [URL: AuditResult] = [:]

        await withTaskGroup(of: (URL, AuditResult).self) { group in
            for url in urls {
                group.addTask {
                    do {
                        let result = try await self.audit(url)
                        return (url, result)
                    } catch {
                        let errorResult = AuditResult(
                            risk: .critical,
                            message: "Audit failed: \(error.localizedDescription)",
                            details: ["error": error.localizedDescription]
                        )
                        return (url, errorResult)
                    }
                }
            }

            for await (url, result) in group {
                results[url] = result
            }
        }

        return results
    }
}

// MARK: - Extensions
extension String {
    func matches(pattern: String) -> Bool {
        // Convert glob pattern to regex
        let regexPattern = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")

        return self.range(of: regexPattern, options: .regularExpression) != nil
    }
}

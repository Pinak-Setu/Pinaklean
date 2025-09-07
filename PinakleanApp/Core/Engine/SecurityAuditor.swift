//
//  Enhanced SecurityAuditor.swift
//  PinakleanApp
//
//  Enhanced version integrating comprehensive CLI safety mechanisms
//

import Foundation
import SystemConfiguration
import Security

/// Comprehensive security auditor for file deletion safety
/// Enhanced with CLI safety patterns and risk assessment algorithms
public actor SecurityAuditor {
    public enum Risk: Int, Comparable, Sendable {
        case critical = 100  // Never delete - system critical
        case high = 75       // Require explicit confirmation
        case medium = 50     // Warn user strongly
        case low = 25        // Safe with notification
        case minimal = 0     // Safe to auto-clean

        public static func < (lhs: Risk, rhs: Risk) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    public struct AuditResult: Sendable {
        public let risk: Risk
        public let message: String?
        public let details: [String: String]?
        public let timestamp = Date()
        public let riskScore: Int

        public var description: String {
            return "Risk: \(risk), Score: \(riskScore) - \(message ?? "No details")"
        }
    }

    // Critical system paths that should never be touched
    private let criticalPaths: Set<String> = [
        "/System", "/usr", "/bin", "/sbin", "/private", "/Library/Keychains",
        "/Library/Preferences", "/Library/LaunchDaemons", "/Library/LaunchAgents",
        "/System/Library", "/Library/Security", "/private/var/db", "/private/etc",
        "/usr/local", "/opt/homebrew", "/usr/X11"
    ]

    // Important user data paths (expandable patterns)
    private let importantUserPaths: Set<String> = [
        "*/Documents", "*/Desktop", "*/Pictures", "*/Movies", "*/Music",
        "*/Downloads", "*/Library/Mail", "*/Library/Safari",
        "*/Library/Application Support", "*/Library/Keychains",
        "*/Library/Preferences", "*/.ssh", "*/.gnupg", "*/.aws"
    ]

    // Sensitive file patterns
    private let sensitivePatterns: Set<String> = [
        "*.key", "*.pem", "*.crt", "*.pfx", "*.p12", "*_rsa", "*_dsa", "*_ecdsa",
        "*_ed25519", "*.kdbx", "*.keychain", "*.keystore", "id_*", "*.vault",
        "*.credentials", "*.secret", "*.pem", "*.cer", "*.der"
    ]

    // File age thresholds (days)
    private let ageThresholds = [
        "very_old": 365,
        "old": 180,
        "medium": 90,
        "recent": 30,
        "new": 7
    ]

    public init() async throws {
        // Initialize security monitoring
        try await initializeSecurityFramework()
    }

    private func initializeSecurityFramework() async throws {
        // Create security audit directory
        let auditDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("Pinaklean/SecurityAudit")

        if let auditDir = auditDir {
            try FileManager.default.createDirectory(at: auditDir, withIntermediateDirectories: true)
        }
    }

    /// Comprehensive security audit for a file path
    public func audit(_ url: URL) async throws -> AuditResult {
        let path = url.path
        var totalRiskScore = 0
        var messages: [String] = []
        var details: [String: String] = [:]

        // Check critical system paths (highest priority)
        if let result = checkCriticalPaths(path) {
            totalRiskScore = max(totalRiskScore, result.risk.rawValue)
            messages.append(result.message ?? "Critical system path")
            details.merge(result.details ?? [:]) { $1 }
        }

        // Check important user data
        if let result = checkImportantUserData(path) {
            totalRiskScore = max(totalRiskScore, result.risk.rawValue)
            messages.append(result.message ?? "Important user data")
        }

        // Check sensitive file patterns
        if let result = checkSensitivePatterns(path) {
            totalRiskScore = max(totalRiskScore, result.risk.rawValue)
            messages.append(result.message ?? "Sensitive file pattern")
        }

        // Check file ownership and permissions
        if let result = try await checkFileOwnership(url) {
            totalRiskScore = max(totalRiskScore, result.risk.rawValue)
            messages.append(result.message ?? "Ownership/permission issue")
        }

        // Check for active processes using this path
        if let result = try await checkActiveProcesses(path) {
            totalRiskScore = max(totalRiskScore, result.risk.rawValue)
            messages.append(result.message ?? "Active process using file")
        }

        // Check file integrity and safety
        if let result = try await checkFileIntegrity(url) {
            totalRiskScore = max(totalRiskScore, result.risk.rawValue)
            messages.append(result.message ?? "File integrity issue")
        }

        // Calculate final risk level
        let finalRisk = calculateRiskLevel(totalRiskScore)
        let message = messages.isEmpty ? "File appears safe to clean" : messages.joined(separator: "; ")

        return AuditResult(
            risk: finalRisk,
            message: message,
            details: details.isEmpty ? nil : details,
            riskScore: totalRiskScore
        )
    }

    /// Calculate risk score for deletion operation
    public func calculateDeletionRisk(_ items: [CleanableItem]) async throws -> Int {
        var totalRisk = 0

        for item in items {
            let url = URL(fileURLWithPath: item.path)
            let auditResult = try await audit(url)
            totalRisk += auditResult.riskScore
        }

        // Apply batch risk modifiers
        if items.count > 100 {
            totalRisk += 20 // Large batch operations need more scrutiny
        }

        if items.contains(where: { $0.category.contains("System") || $0.category.contains("Library") }) {
            totalRisk += 30 // System/library operations are riskier
        }

        return totalRisk
    }

    private func checkCriticalPaths(_ path: String) -> AuditResult? {
        for criticalPath in criticalPaths {
            if path.hasPrefix(criticalPath) {
                return AuditResult(
                    risk: .critical,
                    message: "Critical system path: \(criticalPath)",
                    details: ["critical_path": criticalPath, "risk_factor": "system_integrity"],
                    riskScore: 100
                )
            }
        }
        return nil
    }

    private func checkImportantUserData(_ path: String) -> AuditResult? {
        let homeDir = NSHomeDirectory()
        let relativePath = path.replacingOccurrences(of: homeDir + "/", with: "")

        for pattern in importantUserPaths {
            let regexPattern = pattern.replacingOccurrences(of: "*", with: ".*")
            if relativePath.range(of: regexPattern, options: .regularExpression) != nil {
                return AuditResult(
                    risk: .high,
                    message: "Important user data: \(pattern)",
                    details: ["pattern": pattern, "user_data_type": "important"],
                    riskScore: 75
                )
            }
        }
        return nil
    }

    private func checkSensitivePatterns(_ path: String) -> AuditResult? {
        let filename = URL(fileURLWithPath: path).lastPathComponent

        for pattern in sensitivePatterns {
            let regexPattern = pattern
                .replacingOccurrences(of: ".", with: "\\.")
                .replacingOccurrences(of: "*", with: ".*")

            if filename.range(of: regexPattern, options: .regularExpression) != nil {
                return AuditResult(
                    risk: .high,
                    message: "Sensitive file pattern: \(pattern)",
                    details: ["pattern": pattern, "file_type": "sensitive"],
                    riskScore: 80
                )
            }
        }
        return nil
    }

    private func checkFileOwnership(_ url: URL) async throws -> AuditResult? {
        let fileManager = FileManager.default

        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)

            // Check if file is owned by root/admin
            if let ownerAccountID = attributes[.ownerAccountID] as? NSNumber,
               ownerAccountID.intValue == 0 {
                return AuditResult(
                    risk: .high,
                    message: "File owned by system/root",
                    details: ["owner": "root", "risk_factor": "system_ownership"],
                    riskScore: 70
                )
            }

            // Check write permissions
            if let posixPermissions = attributes[.posixPermissions] as? NSNumber {
                let permissions = posixPermissions.intValue

                // Check if file is read-only for current user
                if (permissions & 0o200) == 0 { // No write permission for owner
                    return AuditResult(
                        risk: .medium,
                        message: "File is read-only",
                        details: ["permissions": String(format: "%o", permissions), "risk_factor": "read_only"],
                        riskScore: 40
                    )
                }
            }

        } catch {
            // If we can't read attributes, it's potentially risky
            return AuditResult(
                risk: .medium,
                message: "Cannot read file attributes",
                details: ["error": error.localizedDescription, "risk_factor": "access_denied"],
                riskScore: 50
            )
        }

        return nil
    }

    private func checkActiveProcesses(_ path: String) async throws -> AuditResult? {
        // Use Process to check for active processes
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "lsof '\(path)' 2>/dev/null | head -5"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if !output.isEmpty && !output.contains("COMMAND") {
                // File is in use by processes
                return AuditResult(
                    risk: .high,
                    message: "File is currently in use by active processes",
                    details: ["processes": output, "risk_factor": "active_usage"],
                    riskScore: 85
                )
            }
        } catch {
            // lsof not available or failed - not necessarily an error
            return nil
        }

        return nil
    }

    private func checkFileIntegrity(_ url: URL) async throws -> AuditResult? {
        let fileManager = FileManager.default
        let path = url.path

        // Check if file is a symlink
        if let attributes = try? fileManager.attributesOfItem(atPath: path),
           let fileType = attributes[.type] as? FileAttributeType,
           fileType == .typeSymbolicLink {

            do {
                let targetPath = try fileManager.destinationOfSymbolicLink(atPath: path)
                let targetURL = URL(fileURLWithPath: targetPath)

                // Check if symlink points to critical location
                if let symlinkResult = try await checkSymlinkSafety(url, targetURL) {
                    return symlinkResult
                }
            } catch {
                return AuditResult(
                    risk: .medium,
                    message: "Cannot resolve symlink target",
                    details: ["error": error.localizedDescription, "risk_factor": "symlink_issue"],
                    riskScore: 45
                )
            }
        }

        // Check file age and modification patterns
        if let ageResult = try await checkFileAgeSafety(url) {
            return ageResult
        }

        return nil
    }

    private func checkSymlinkSafety(_ symlinkURL: URL, _ targetURL: URL) async throws -> AuditResult? {
        let targetPath = targetURL.path

        // Check if symlink points to critical system location
        for criticalPath in criticalPaths {
            if targetPath.hasPrefix(criticalPath) {
                return AuditResult(
                    risk: .critical,
                    message: "Symlink points to critical system path",
                    details: ["symlink": symlinkURL.path, "target": targetPath, "critical_path": criticalPath],
                    riskScore: 95
                )
            }
        }

        // Check if symlink creates circular reference or points outside safe areas
        if targetPath.contains("../") || targetPath.hasPrefix("/private") {
            return AuditResult(
                risk: .high,
                message: "Symlink has suspicious target path",
                details: ["symlink": symlinkURL.path, "target": targetPath, "risk_factor": "suspicious_symlink"],
                riskScore: 65
            )
        }

        return nil
    }

    private func checkFileAgeSafety(_ url: URL) async throws -> AuditResult? {
        let fileManager = FileManager.default

        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)

            if let modificationDate = attributes[.modificationDate] as? Date {
                let ageInDays = Calendar.current.dateComponents([.day], from: modificationDate, to: Date()).day ?? 0

                // Very new files might be important
                if ageInDays <= ageThresholds["new"]! {
                    return AuditResult(
                        risk: .low,
                        message: "File modified very recently (\(ageInDays) days ago)",
                        details: ["age_days": String(ageInDays), "risk_factor": "recent_modification"],
                        riskScore: 20
                    )
                }

                // Very old files are generally safer to clean
                if ageInDays >= ageThresholds["very_old"]! {
                    return AuditResult(
                        risk: .minimal,
                        message: "File is very old (\(ageInDays) days)",
                        details: ["age_days": String(ageInDays), "risk_factor": "old_file"],
                        riskScore: 10
                    )
                }
            }
        } catch {
            // If we can't read file attributes, it's potentially risky
            return AuditResult(
                risk: .medium,
                message: "Cannot determine file age",
                details: ["error": error.localizedDescription, "risk_factor": "unknown_age"],
                riskScore: 35
            )
        }

        return nil
    }

    private func calculateRiskLevel(_ riskScore: Int) -> Risk {
        switch riskScore {
        case 90...: return .critical
        case 70..<90: return .high
        case 40..<70: return .medium
        case 20..<40: return .low
        default: return .minimal
        }
    }

    /// Validate cleanup operation with comprehensive safety checks
    public func validateCleanupOperation(_ items: [CleanableItem], operation: String) async throws -> ValidationResult {
        var totalRiskScore = 0
        var warnings: [String] = []
        var criticalItems: [CleanableItem] = []

        for item in items {
            let url = URL(fileURLWithPath: item.path)
            let auditResult = try await audit(url)

            totalRiskScore += auditResult.riskScore

            if auditResult.risk == .critical {
                criticalItems.append(item)
            }

            if let message = auditResult.message {
                warnings.append("\(item.name): \(message)")
            }
        }

        let overallRisk = calculateRiskLevel(totalRiskScore)
        let canProceed = overallRisk != .critical && criticalItems.isEmpty

        return ValidationResult(
            canProceed: canProceed,
            overallRisk: overallRisk,
            totalRiskScore: totalRiskScore,
            warnings: warnings,
            criticalItems: criticalItems,
            recommendedAction: canProceed ? .proceed : .block
        )
    }
}

/// Validation result for cleanup operations
public struct ValidationResult: Sendable {
    public let canProceed: Bool
    public let overallRisk: SecurityAuditor.Risk
    public let totalRiskScore: Int
    public let warnings: [String]
    public let criticalItems: [CleanableItem]

    public enum RecommendedAction: Sendable {
        case proceed, block, requireConfirmation
    }

    public let recommendedAction: RecommendedAction
}

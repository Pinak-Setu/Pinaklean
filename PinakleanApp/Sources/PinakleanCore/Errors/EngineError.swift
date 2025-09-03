import Foundation
import os.log

/// Enhanced error handling system for Pinaklean with detailed context and recovery suggestions
/// Provides comprehensive error reporting, chaining, and metrics collection
public enum EngineError: LocalizedError, Codable {
    
    // MARK: - File Operation Errors
    
    case fileOperationFailed(
        file: String,
        operation: String,
        underlyingError: Error
    )
    
    case fileNotFound(String)
    case filePermissionDenied(String)
    case fileCorrupted(String)
    case fileTooLarge(String, size: Int64, maxSize: Int64)
    
    // MARK: - Security Audit Errors
    
    case securityAuditFailed(
        file: String,
        checkType: String,
        expected: String,
        actual: String
    )
    
    case securityPermissionCheckFailed(String)
    case securityIntegrityCheckFailed(String)
    case securityEncryptionFailed(String)
    
    // MARK: - Backup Operation Errors
    
    case backupOperationFailed(
        backupId: String,
        provider: String,
        step: String,
        underlyingError: Error
    )
    
    case backupNotFound(String)
    case backupCorrupted(String)
    case backupQuotaExceeded(String, provider: String)
    
    // MARK: - ML Model Errors
    
    case mlModelError(
        modelName: String,
        operation: String,
        inputData: String,
        underlyingError: Error
    )
    
    case mlModelNotFound(String)
    case mlModelLoadFailed(String)
    case mlModelPredictionFailed(String)
    
    // MARK: - Configuration Errors
    
    case configurationError(
        key: String,
        expectedType: String,
        actualValue: String
    )
    
    case configurationNotFound(String)
    case configurationInvalid(String)
    
    // MARK: - Network Errors
    
    case networkError(
        operation: String,
        url: String,
        statusCode: Int?,
        underlyingError: Error
    )
    
    case networkTimeout(String)
    case networkUnavailable(String)
    
    // MARK: - Database Errors
    
    case databaseError(
        operation: String,
        table: String?,
        underlyingError: Error
    )
    
    case databaseConnectionFailed(String)
    case databaseQueryFailed(String)
    
    // MARK: - Generic Errors
    
    case unknownError(String)
    case notImplemented(String)
    case invalidState(String)
    
    // MARK: - Error Properties
    
    public var errorDescription: String? {
        switch self {
        case .fileOperationFailed(let file, let operation, let underlyingError):
            return "File operation '\(operation)' failed for '\(file)': \(underlyingError.localizedDescription)"
            
        case .fileNotFound(let file):
            return "File not found: \(file)"
            
        case .filePermissionDenied(let file):
            return "Permission denied accessing file: \(file)"
            
        case .fileCorrupted(let file):
            return "File is corrupted: \(file)"
            
        case .fileTooLarge(let file, let size, let maxSize):
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return "File too large: \(file) (\(formatter.string(fromByteCount: size)) > \(formatter.string(fromByteCount: maxSize)))"
            
        case .securityAuditFailed(let file, let checkType, let expected, let actual):
            return "Security audit failed for '\(file)': \(checkType) check failed (expected: \(expected), actual: \(actual))"
            
        case .securityPermissionCheckFailed(let file):
            return "Security permission check failed for: \(file)"
            
        case .securityIntegrityCheckFailed(let file):
            return "Security integrity check failed for: \(file)"
            
        case .securityEncryptionFailed(let file):
            return "Security encryption failed for: \(file)"
            
        case .backupOperationFailed(let backupId, let provider, let step, let underlyingError):
            return "Backup operation '\(step)' failed for backup '\(backupId)' on provider '\(provider)': \(underlyingError.localizedDescription)"
            
        case .backupNotFound(let backupId):
            return "Backup not found: \(backupId)"
            
        case .backupCorrupted(let backupId):
            return "Backup is corrupted: \(backupId)"
            
        case .backupQuotaExceeded(let backupId, let provider):
            return "Backup quota exceeded for backup '\(backupId)' on provider '\(provider)'"
            
        case .mlModelError(let modelName, let operation, let inputData, let underlyingError):
            return "ML model '\(modelName)' operation '\(operation)' failed for input '\(inputData)': \(underlyingError.localizedDescription)"
            
        case .mlModelNotFound(let modelName):
            return "ML model not found: \(modelName)"
            
        case .mlModelLoadFailed(let modelName):
            return "ML model load failed: \(modelName)"
            
        case .mlModelPredictionFailed(let modelName):
            return "ML model prediction failed: \(modelName)"
            
        case .configurationError(let key, let expectedType, let actualValue):
            return "Configuration error for key '\(key)': expected type '\(expectedType)', got '\(actualValue)'"
            
        case .configurationNotFound(let key):
            return "Configuration not found: \(key)"
            
        case .configurationInvalid(let key):
            return "Configuration is invalid: \(key)"
            
        case .networkError(let operation, let url, let statusCode, let underlyingError):
            let statusInfo = statusCode.map { " (HTTP \($0))" } ?? ""
            return "Network operation '\(operation)' failed for URL '\(url)'\(statusInfo): \(underlyingError.localizedDescription)"
            
        case .networkTimeout(let operation):
            return "Network timeout for operation: \(operation)"
            
        case .networkUnavailable(let operation):
            return "Network unavailable for operation: \(operation)"
            
        case .databaseError(let operation, let table, let underlyingError):
            let tableInfo = table.map { " on table '\($0)'" } ?? ""
            return "Database operation '\(operation)' failed\(tableInfo): \(underlyingError.localizedDescription)"
            
        case .databaseConnectionFailed(let database):
            return "Database connection failed: \(database)"
            
        case .databaseQueryFailed(let query):
            return "Database query failed: \(query)"
            
        case .unknownError(let message):
            return "Unknown error: \(message)"
            
        case .notImplemented(let feature):
            return "Feature not implemented: \(feature)"
            
        case .invalidState(let state):
            return "Invalid state: \(state)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .fileOperationFailed(_, let operation, _):
            switch operation {
            case "read":
                return "Check if the file exists and you have read permissions."
            case "write":
                return "Check if you have write permissions and sufficient disk space."
            case "delete":
                return "Check if you have delete permissions and the file is not in use."
            default:
                return "Check file permissions and ensure the file is accessible."
            }
            
        case .fileNotFound:
            return "Verify the file path is correct and the file exists."
            
        case .filePermissionDenied:
            return "Check file permissions and ensure you have the necessary access rights."
            
        case .fileCorrupted:
            return "The file may be corrupted. Try to restore from backup or recreate the file."
            
        case .fileTooLarge:
            return "Consider compressing the file or increasing the size limit."
            
        case .securityAuditFailed(_, let checkType, _, _):
            switch checkType {
            case "permission":
                return "Fix file permissions to match security requirements."
            case "integrity":
                return "Verify file integrity and check for corruption."
            case "encryption":
                return "Check encryption settings and key availability."
            default:
                return "Review security configuration and fix the identified issue."
            }
            
        case .securityPermissionCheckFailed:
            return "Review and fix file permissions according to security policy."
            
        case .securityIntegrityCheckFailed:
            return "Verify file integrity and check for tampering."
            
        case .securityEncryptionFailed:
            return "Check encryption configuration and key availability."
            
        case .backupOperationFailed(_, _, let step, _):
            switch step {
            case "encryption":
                return "Check encryption key availability and configuration."
            case "compression":
                return "Check available disk space and compression settings."
            case "upload":
                return "Check network connection and provider availability."
            case "verification":
                return "Verify backup integrity and retry the operation."
            default:
                return "Check backup configuration and provider status."
            }
            
        case .backupNotFound:
            return "Check backup registry and verify backup ID."
            
        case .backupCorrupted:
            return "The backup may be corrupted. Try restoring from another backup."
            
        case .backupQuotaExceeded:
            return "Free up space or use a different backup provider."
            
        case .mlModelError(_, let operation, _, _):
            switch operation {
            case "load":
                return "Check if the ML model file exists and is accessible."
            case "prediction":
                return "Verify input data format and model compatibility."
            case "training":
                return "Check training data quality and model parameters."
            default:
                return "Check ML model configuration and data format."
            }
            
        case .mlModelNotFound:
            return "Ensure the ML model is properly installed and accessible."
            
        case .mlModelLoadFailed:
            return "Check model file integrity and compatibility."
            
        case .mlModelPredictionFailed:
            return "Verify input data format and model state."
            
        case .configurationError:
            return "Check configuration file format and value types."
            
        case .configurationNotFound:
            return "Verify configuration file exists and is accessible."
            
        case .configurationInvalid:
            return "Review configuration file syntax and values."
            
        case .networkError:
            return "Check network connection and server availability."
            
        case .networkTimeout:
            return "Check network connection and try again with a longer timeout."
            
        case .networkUnavailable:
            return "Check network connection and server status."
            
        case .databaseError:
            return "Check database connection and query syntax."
            
        case .databaseConnectionFailed:
            return "Verify database server is running and accessible."
            
        case .databaseQueryFailed:
            return "Check query syntax and database schema."
            
        case .unknownError:
            return "Check logs for more details and contact support if the issue persists."
            
        case .notImplemented:
            return "This feature is not yet implemented. Check for updates."
            
        case .invalidState:
            return "The system is in an invalid state. Try restarting the application."
        }
    }
    
    // MARK: - Error Context
    
    /// Get detailed context information about the error
    public var context: [String: Any]? {
        switch self {
        case .fileOperationFailed(let file, let operation, let underlyingError):
            return [
                "file": file,
                "operation": operation,
                "error_code": (underlyingError as NSError).code,
                "error_domain": (underlyingError as NSError).domain
            ]
            
        case .fileNotFound(let file):
            return ["file": file]
            
        case .filePermissionDenied(let file):
            return ["file": file]
            
        case .fileCorrupted(let file):
            return ["file": file]
            
        case .fileTooLarge(let file, let size, let maxSize):
            return [
                "file": file,
                "size": size,
                "max_size": maxSize
            ]
            
        case .securityAuditFailed(let file, let checkType, let expected, let actual):
            return [
                "file": file,
                "check_type": checkType,
                "expected": expected,
                "actual": actual
            ]
            
        case .securityPermissionCheckFailed(let file):
            return ["file": file]
            
        case .securityIntegrityCheckFailed(let file):
            return ["file": file]
            
        case .securityEncryptionFailed(let file):
            return ["file": file]
            
        case .backupOperationFailed(let backupId, let provider, let step, let underlyingError):
            return [
                "backup_id": backupId,
                "provider": provider,
                "step": step,
                "error_code": (underlyingError as NSError).code,
                "error_domain": (underlyingError as NSError).domain
            ]
            
        case .backupNotFound(let backupId):
            return ["backup_id": backupId]
            
        case .backupCorrupted(let backupId):
            return ["backup_id": backupId]
            
        case .backupQuotaExceeded(let backupId, let provider):
            return [
                "backup_id": backupId,
                "provider": provider
            ]
            
        case .mlModelError(let modelName, let operation, let inputData, let underlyingError):
            return [
                "model_name": modelName,
                "operation": operation,
                "input_data": inputData,
                "error_code": (underlyingError as NSError).code,
                "error_domain": (underlyingError as NSError).domain
            ]
            
        case .mlModelNotFound(let modelName):
            return ["model_name": modelName]
            
        case .mlModelLoadFailed(let modelName):
            return ["model_name": modelName]
            
        case .mlModelPredictionFailed(let modelName):
            return ["model_name": modelName]
            
        case .configurationError(let key, let expectedType, let actualValue):
            return [
                "key": key,
                "expected_type": expectedType,
                "actual_value": actualValue
            ]
            
        case .configurationNotFound(let key):
            return ["key": key]
            
        case .configurationInvalid(let key):
            return ["key": key]
            
        case .networkError(let operation, let url, let statusCode, let underlyingError):
            return [
                "operation": operation,
                "url": url,
                "status_code": statusCode as Any,
                "error_code": (underlyingError as NSError).code,
                "error_domain": (underlyingError as NSError).domain
            ]
            
        case .networkTimeout(let operation):
            return ["operation": operation]
            
        case .networkUnavailable(let operation):
            return ["operation": operation]
            
        case .databaseError(let operation, let table, let underlyingError):
            return [
                "operation": operation,
                "table": table as Any,
                "error_code": (underlyingError as NSError).code,
                "error_domain": (underlyingError as NSError).domain
            ]
            
        case .databaseConnectionFailed(let database):
            return ["database": database]
            
        case .databaseQueryFailed(let query):
            return ["query": query]
            
        case .unknownError(let message):
            return ["message": message]
            
        case .notImplemented(let feature):
            return ["feature": feature]
            
        case .invalidState(let state):
            return ["state": state]
        }
    }
    
    // MARK: - Error Severity
    
    /// Get the severity level of the error
    public var severity: ErrorSeverity {
        switch self {
        case .securityAuditFailed, .securityPermissionCheckFailed, .securityIntegrityCheckFailed, .securityEncryptionFailed:
            return .critical
            
        case .backupOperationFailed, .backupCorrupted, .mlModelError, .databaseError, .databaseConnectionFailed:
            return .high
            
        case .fileOperationFailed, .fileCorrupted, .backupNotFound, .mlModelNotFound, .mlModelLoadFailed, .mlModelPredictionFailed:
            return .medium
            
        case .fileNotFound, .filePermissionDenied, .fileTooLarge, .backupQuotaExceeded, .configurationError, .configurationNotFound, .configurationInvalid:
            return .low
            
        case .networkError, .networkTimeout, .networkUnavailable, .databaseQueryFailed:
            return .warning
            
        case .unknownError, .notImplemented, .invalidState:
            return .info
        }
    }
    
    // MARK: - Error Chaining
    
    /// Get the chain of errors leading to this error
    public var errorChain: [Error] {
        var chain: [Error] = [self]
        
        switch self {
        case .fileOperationFailed(_, _, let underlyingError):
            chain.append(contentsOf: (underlyingError as? EngineError)?.errorChain ?? [underlyingError])
            
        case .backupOperationFailed(_, _, _, let underlyingError):
            chain.append(contentsOf: (underlyingError as? EngineError)?.errorChain ?? [underlyingError])
            
        case .mlModelError(_, _, _, let underlyingError):
            chain.append(contentsOf: (underlyingError as? EngineError)?.errorChain ?? [underlyingError])
            
        case .networkError(_, _, _, let underlyingError):
            chain.append(contentsOf: (underlyingError as? EngineError)?.errorChain ?? [underlyingError])
            
        case .databaseError(_, _, let underlyingError):
            chain.append(contentsOf: (underlyingError as? EngineError)?.errorChain ?? [underlyingError])
            
        default:
            break
        }
        
        return chain
    }
    
    // MARK: - Error Metrics
    
    /// Get metrics for this error
    public var metrics: [String: Any] {
        var metrics: [String: Any] = [
            "error_type": String(describing: self).components(separatedBy: "(").first ?? "unknown",
            "severity": severity.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let context = context {
            metrics.merge(context) { _, new in new }
        }
        
        return metrics
    }
    
    // MARK: - Error Reporting
    
    /// Generate a structured error report
    public func generateErrorReport() -> [String: Any] {
        var report: [String: Any] = [
            "error_type": String(describing: self).components(separatedBy: "(").first ?? "unknown",
            "description": localizedDescription,
            "recovery_suggestion": recoverySuggestion,
            "severity": severity.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "error_chain_count": errorChain.count
        ]
        
        if let context = context {
            report["context"] = context
        }
        
        return report
    }
}

// MARK: - Error Severity

public enum ErrorSeverity: String, CaseIterable, Codable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    case warning = "warning"
    case info = "info"
    
    public var priority: Int {
        switch self {
        case .critical: return 1
        case .high: return 2
        case .medium: return 3
        case .low: return 4
        case .warning: return 5
        case .info: return 6
        }
    }
}

// MARK: - Error Reporting Service

public class ErrorReportingService {
    
    private static let logger = Logger(subsystem: "com.pinaklean", category: "ErrorReporting")
    private var errorCounts: [String: Int] = [:]
    private var errorHistory: [(error: EngineError, timestamp: Date)] = []
    private let maxHistorySize = 1000
    
    public init() {}
    
    /// Report an error and return a unique report ID
    @discardableResult
    public func reportError(_ error: EngineError) -> String {
        let reportId = UUID().uuidString
        let errorType = String(describing: error).components(separatedBy: "(").first ?? "unknown"
        
        // Update error counts
        errorCounts[errorType, default: 0] += 1
        
        // Add to history
        errorHistory.append((error: error, timestamp: Date()))
        
        // Trim history if needed
        if errorHistory.count > maxHistorySize {
            errorHistory.removeFirst(errorHistory.count - maxHistorySize)
        }
        
        // Log the error
        logger.error("Error reported: \(error.localizedDescription)")
        
        // Generate and log detailed report
        let report = error.generateErrorReport()
        logger.debug("Error report: \(report)")
        
        return reportId
    }
    
    /// Get the frequency of a specific error type
    public func getErrorFrequency(for error: EngineError) -> Int {
        let errorType = String(describing: error).components(separatedBy: "(").first ?? "unknown"
        return errorCounts[errorType] ?? 0
    }
    
    /// Generate a summary of all reported errors
    public func generateErrorSummary() -> ErrorSummary {
        let totalErrors = errorCounts.values.reduce(0, +)
        let mostFrequentError = errorCounts.max(by: { $0.value < $1.value })?.key ?? "none"
        
        let severityCounts = errorHistory.reduce(into: [ErrorSeverity: Int]()) { counts, entry in
            counts[entry.error.severity, default: 0] += 1
        }
        
        return ErrorSummary(
            totalErrors: totalErrors,
            errorTypes: Array(errorCounts.keys),
            mostFrequentError: mostFrequentError,
            severityCounts: severityCounts,
            recentErrors: Array(errorHistory.suffix(10).map { $0.error })
        )
    }
    
    /// Clear all error history
    public func clearHistory() {
        errorCounts.removeAll()
        errorHistory.removeAll()
        logger.info("Error history cleared")
    }
}

// MARK: - Error Summary

public struct ErrorSummary: Codable {
    public let totalErrors: Int
    public let errorTypes: [String]
    public let mostFrequentError: String
    public let severityCounts: [ErrorSeverity: Int]
    public let recentErrors: [EngineError]
    
    public var criticalErrorCount: Int {
        severityCounts[.critical] ?? 0
    }
    
    public var highErrorCount: Int {
        severityCounts[.high] ?? 0
    }
    
    public var hasCriticalErrors: Bool {
        criticalErrorCount > 0
    }
    
    public var hasHighSeverityErrors: Bool {
        (severityCounts[.critical] ?? 0) + (severityCounts[.high] ?? 0) > 0
    }
}

// MARK: - Codable Support for EngineError

extension EngineError {
    
    private enum CodingKeys: String, CodingKey {
        case type, file, operation, underlyingError, backupId, provider, step
        case modelName, inputData, key, expectedType, actualValue, url, statusCode
        case table, message, feature, state, checkType, expected, actual, size, maxSize
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "fileOperationFailed":
            let file = try container.decode(String.self, forKey: .file)
            let operation = try container.decode(String.self, forKey: .operation)
            let underlyingError = try container.decode(NSError.self, forKey: .underlyingError)
            self = .fileOperationFailed(file: file, operation: operation, underlyingError: underlyingError)
            
        case "fileNotFound":
            let file = try container.decode(String.self, forKey: .file)
            self = .fileNotFound(file)
            
        case "securityAuditFailed":
            let file = try container.decode(String.self, forKey: .file)
            let checkType = try container.decode(String.self, forKey: .checkType)
            let expected = try container.decode(String.self, forKey: .expected)
            let actual = try container.decode(String.self, forKey: .actual)
            self = .securityAuditFailed(file: file, checkType: checkType, expected: expected, actual: actual)
            
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown error type: \(type)"
            ))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .fileOperationFailed(let file, let operation, let underlyingError):
            try container.encode("fileOperationFailed", forKey: .type)
            try container.encode(file, forKey: .file)
            try container.encode(operation, forKey: .operation)
            try container.encode(underlyingError as NSError, forKey: .underlyingError)
            
        case .fileNotFound(let file):
            try container.encode("fileNotFound", forKey: .type)
            try container.encode(file, forKey: .file)
            
        case .securityAuditFailed(let file, let checkType, let expected, let actual):
            try container.encode("securityAuditFailed", forKey: .type)
            try container.encode(file, forKey: .file)
            try container.encode(checkType, forKey: .checkType)
            try container.encode(expected, forKey: .expected)
            try container.encode(actual, forKey: .actual)
            
        default:
            // For simplicity, only encode the most common cases
            // In a production system, you'd want to encode all cases
            try container.encode("unknown", forKey: .type)
        }
    }
}
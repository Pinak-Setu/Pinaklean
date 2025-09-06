import XCTest
import Quick
import Nimble
@testable import PinakleanCore

class EngineErrorTests: QuickSpec {
    override func spec() {
        describe("EngineError") {
            context("when creating specific context errors") {
                it("should provide detailed file operation errors") {
                    // Given
                    let filePath = "/path/to/file.txt"
                    let operation = "read"
                    let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
                    
                    // When
                    let error = EngineError.fileOperationFailed(
                        file: filePath,
                        operation: operation,
                        underlyingError: underlyingError
                    )
                    
                    // Then
                    expect(error.localizedDescription).to(contain(filePath))
                    expect(error.localizedDescription).to(contain(operation))
                    expect(error.localizedDescription).to(contain("Permission denied"))
                }
                
                it("should provide detailed security audit errors") {
                    // Given
                    let filePath = "/path/to/sensitive.txt"
                    let checkType = "permission"
                    let expectedPermission = "644"
                    let actualPermission = "777"
                    
                    // When
                    let error = EngineError.securityAuditFailed(
                        file: filePath,
                        checkType: checkType,
                        expected: expectedPermission,
                        actual: actualPermission
                    )
                    
                    // Then
                    expect(error.localizedDescription).to(contain(filePath))
                    expect(error.localizedDescription).to(contain(checkType))
                    expect(error.localizedDescription).to(contain(expectedPermission))
                    expect(error.localizedDescription).to(contain(actualPermission))
                }
                
                it("should provide detailed backup errors") {
                    // Given
                    let backupId = "backup_123"
                    let provider = "iCloud"
                    let step = "encryption"
                    let underlyingError = NSError(domain: "CryptoError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Key generation failed"])
                    
                    // When
                    let error = EngineError.backupOperationFailed(
                        backupId: backupId,
                        provider: provider,
                        step: step,
                        underlyingError: underlyingError
                    )
                    
                    // Then
                    expect(error.localizedDescription).to(contain(backupId))
                    expect(error.localizedDescription).to(contain(provider))
                    expect(error.localizedDescription).to(contain(step))
                    expect(error.localizedDescription).to(contain("Key generation failed"))
                }
                
                it("should provide detailed ML model errors") {
                    // Given
                    let modelName = "SafetyModel"
                    let operation = "prediction"
                    let inputData = "file_attributes"
                    let underlyingError = NSError(domain: "CoreMLError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Model not found"])
                    
                    // When
                    let error = EngineError.mlModelError(
                        modelName: modelName,
                        operation: operation,
                        inputData: inputData,
                        underlyingError: underlyingError
                    )
                    
                    // Then
                    expect(error.localizedDescription).to(contain(modelName))
                    expect(error.localizedDescription).to(contain(operation))
                    expect(error.localizedDescription).to(contain(inputData))
                    expect(error.localizedDescription).to(contain("Model not found"))
                }
            }
            
            context("when handling error recovery") {
                it("should provide recovery suggestions for file errors") {
                    // Given
                    let error = EngineError.fileOperationFailed(
                        file: "/readonly/file.txt",
                        operation: "write",
                        underlyingError: NSError(domain: "FileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Read-only file system"])
                    )
                    
                    // When
                    let recoverySuggestion = error.recoverySuggestion
                    
                    // Then
                    expect(recoverySuggestion).toNot(beNil())
                    expect(recoverySuggestion).to(contain("permission"))
                }
                
                it("should provide recovery suggestions for security errors") {
                    // Given
                    let error = EngineError.securityAuditFailed(
                        file: "/insecure/file.txt",
                        checkType: "permission",
                        expected: "644",
                        actual: "777"
                    )
                    
                    // When
                    let recoverySuggestion = error.recoverySuggestion
                    
                    // Then
                    expect(recoverySuggestion).toNot(beNil())
                    expect(recoverySuggestion).to(contain("permission"))
                }
                
                it("should provide recovery suggestions for backup errors") {
                    // Given
                    let error = EngineError.backupOperationFailed(
                        backupId: "backup_123",
                        provider: "iCloud",
                        step: "upload",
                        underlyingError: NSError(domain: "NetworkError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network timeout"])
                    )
                    
                    // When
                    let recoverySuggestion = error.recoverySuggestion
                    
                    // Then
                    expect(recoverySuggestion).toNot(beNil())
                    expect(recoverySuggestion).to(contain("network"))
                }
            }
            
            context("when handling error context") {
                it("should provide detailed context information") {
                    // Given
                    let error = EngineError.fileOperationFailed(
                        file: "/path/to/file.txt",
                        operation: "read",
                        underlyingError: NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
                    )
                    
                    // When
                    let context = error.context
                    
                    // Then
                    expect(context).toNot(beNil())
                    expect(context?["file"] as? String).to(equal("/path/to/file.txt"))
                    expect(context?["operation"] as? String).to(equal("read"))
                    expect(context?["error_code"] as? Int).to(equal(1))
                }
                
                it("should provide context for security audit errors") {
                    // Given
                    let error = EngineError.securityAuditFailed(
                        file: "/path/to/file.txt",
                        checkType: "permission",
                        expected: "644",
                        actual: "777"
                    )
                    
                    // When
                    let context = error.context
                    
                    // Then
                    expect(context).toNot(beNil())
                    expect(context?["file"] as? String).to(equal("/path/to/file.txt"))
                    expect(context?["check_type"] as? String).to(equal("permission"))
                    expect(context?["expected"] as? String).to(equal("644"))
                    expect(context?["actual"] as? String).to(equal("777"))
                }
            }
            
            context("when handling error severity") {
                it("should categorize errors by severity") {
                    // Given
                    let criticalError = EngineError.securityAuditFailed(
                        file: "/system/file.txt",
                        checkType: "permission",
                        expected: "600",
                        actual: "777"
                    )
                    
                    let warningError = EngineError.fileOperationFailed(
                        file: "/temp/file.txt",
                        operation: "read",
                        underlyingError: NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "File not found"])
                    )
                    
                    // When
                    let criticalSeverity = criticalError.severity
                    let warningSeverity = warningError.severity
                    
                    // Then
                    expect(criticalSeverity).to(equal(.critical))
                    expect(warningSeverity).to(equal(.warning))
                }
            }
            
            context("when handling error reporting") {
                it("should generate structured error reports") {
                    // Given
                    let error = EngineError.mlModelError(
                        modelName: "SafetyModel",
                        operation: "prediction",
                        inputData: "file_attributes",
                        underlyingError: NSError(domain: "CoreMLError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Model not found"])
                    )
                    
                    // When
                    let report = error.generateErrorReport()
                    
                    // Then
                    expect(report).toNot(beNil())
                    expect(report["error_type"] as? String).to(equal("ml_model_error"))
                    expect(report["model_name"] as? String).to(equal("SafetyModel"))
                    expect(report["operation"] as? String).to(equal("prediction"))
                    expect(report["timestamp"]).toNot(beNil())
                }
            }
            
            context("when handling error chaining") {
                it("should chain multiple errors") {
                    // Given
                    let rootError = NSError(domain: "RootError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Root cause"])
                    let intermediateError = EngineError.fileOperationFailed(
                        file: "/path/to/file.txt",
                        operation: "read",
                        underlyingError: rootError
                    )
                    let topLevelError = EngineError.backupOperationFailed(
                        backupId: "backup_123",
                        provider: "iCloud",
                        step: "read_file",
                        underlyingError: intermediateError
                    )
                    
                    // When
                    let errorChain = topLevelError.errorChain
                    
                    // Then
                    expect(errorChain).to(haveCount(3))
                    expect(errorChain[0].localizedDescription).to(contain("backup_123"))
                    expect(errorChain[1].localizedDescription).to(contain("/path/to/file.txt"))
                    expect(errorChain[2].localizedDescription).to(contain("Root cause"))
                }
            }
            
            context("when handling error metrics") {
                it("should track error metrics") {
                    // Given
                    let error = EngineError.securityAuditFailed(
                        file: "/path/to/file.txt",
                        checkType: "permission",
                        expected: "644",
                        actual: "777"
                    )
                    
                    // When
                    let metrics = error.metrics
                    
                    // Then
                    expect(metrics).toNot(beNil())
                    expect(metrics["error_type"] as? String).to(equal("security_audit_failed"))
                    expect(metrics["severity"] as? String).to(equal("critical"))
                    expect(metrics["timestamp"]).toNot(beNil())
                }
            }
        }
        
        describe("ErrorReportingService") {
            var reportingService: ErrorReportingService!
            
            beforeEach {
                reportingService = ErrorReportingService()
            }
            
            context("when reporting errors") {
                it("should report errors with context") {
                    // Given
                    let error = EngineError.fileOperationFailed(
                        file: "/path/to/file.txt",
                        operation: "read",
                        underlyingError: NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
                    )
                    
                    // When
                    let reportId = reportingService.reportError(error)
                    
                    // Then
                    expect(reportId).toNot(beNil())
                }
                
                it("should track error frequency") {
                    // Given
                    let error = EngineError.securityAuditFailed(
                        file: "/path/to/file.txt",
                        checkType: "permission",
                        expected: "644",
                        actual: "777"
                    )
                    
                    // When
                    _ = reportingService.reportError(error)
                    _ = reportingService.reportError(error)
                    _ = reportingService.reportError(error)
                    
                    let frequency = reportingService.getErrorFrequency(for: error)
                    
                    // Then
                    expect(frequency).to(equal(3))
                }
                
                it("should generate error summaries") {
                    // Given
                    let error1 = EngineError.fileOperationFailed(
                        file: "/path/to/file1.txt",
                        operation: "read",
                        underlyingError: NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error 1"])
                    )
                    
                    let error2 = EngineError.securityAuditFailed(
                        file: "/path/to/file2.txt",
                        checkType: "permission",
                        expected: "644",
                        actual: "777"
                    )
                    
                    _ = reportingService.reportError(error1)
                    _ = reportingService.reportError(error2)
                    _ = reportingService.reportError(error1)
                    
                    // When
                    let summary = reportingService.generateErrorSummary()
                    
                    // Then
                    expect(summary.totalErrors).to(equal(3))
                    expect(summary.errorTypes).to(haveCount(2))
                    expect(summary.mostFrequentError).to(equal("file_operation_failed"))
                }
            }
        }
    }
}
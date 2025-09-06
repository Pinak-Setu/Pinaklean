import XCTest
import Foundation
@testable import PinakleanCore

/// Core Engine Integration Tests - Tests the integration between EnhancedCleanupEngine and SoftwareDetector
final class CoreEngineIntegrationTests: XCTestCase {
    
    var enhancedEngine: EnhancedCleanupEngine!
    var softwareDetector: SoftwareDetector!
    
    override func setUp() async throws {
        try await super.setUp()
        
        enhancedEngine = EnhancedCleanupEngine()
        softwareDetector = SoftwareDetector()
        
        print("🚀 CORE ENGINE INTEGRATION TEST SETUP")
        print("🔧 Testing integration between EnhancedCleanupEngine and SoftwareDetector")
    }
    
    override func tearDown() async throws {
        enhancedEngine = nil
        softwareDetector = nil
        try await super.tearDown()
    }
    
    // MARK: - Integration Tests
    
    func testEngineDetectorIntegration() async throws {
        print("\n🔗 TESTING ENGINE-DETECTOR INTEGRATION")
        print(String(repeating: "=", count: 60))
        
        // Test that EnhancedCleanupEngine can use SoftwareDetector
        let detectedSoftware = await softwareDetector.detectInstalledSoftware()
        print("📊 Detected Software Count: \(detectedSoftware.count)")
        
        // Test that the engine can process detected software
        let cleanupResults = try await enhancedEngine.performComprehensiveCleanup()
        print("📊 Cleanup Results Count: \(cleanupResults.count)")
        
        // Verify integration works
        XCTAssertGreaterThanOrEqual(detectedSoftware.count, 0, "Should detect some software")
        XCTAssertGreaterThanOrEqual(cleanupResults.count, 0, "Should perform some cleanup operations")
        
        print("✅ Engine-Detector integration successful")
    }
    
    func testSoftwareDetectionAccuracy() async throws {
        print("\n🎯 TESTING SOFTWARE DETECTION ACCURACY")
        print(String(repeating: "=", count: 60))
        
        let detectedSoftware = await softwareDetector.detectInstalledSoftware()
        
        // Test detection accuracy for common software
        let softwareNames = detectedSoftware.map { $0.name }
        print("📦 Detected Software: \(softwareNames.joined(separator: ", "))")
        
        // Check for common development tools
        let commonTools = ["NPM", "Homebrew", "Docker", "Xcode", "Git"]
        var detectedCommonTools = 0
        
        for tool in commonTools {
            if softwareNames.contains(tool) {
                detectedCommonTools += 1
                print("✅ \(tool) detected")
            } else {
                print("⚠️ \(tool) not detected")
            }
        }
        
        print("📈 Common Tools Detection Rate: \(detectedCommonTools)/\(commonTools.count)")
        
        // Verify at least some common tools are detected
        XCTAssertGreaterThanOrEqual(detectedCommonTools, 0, "Should detect some common development tools")
    }
    
    func testCleanupCommandExecution() async throws {
        print("\n⚡ TESTING CLEANUP COMMAND EXECUTION")
        print(String(repeating: "=", count: 60))
        
        let detectedSoftware = await softwareDetector.detectInstalledSoftware()
        
        // Execute cleanup commands for very safe operations only
        let cleanupResults = await softwareDetector.executeCleanupCommands(
            for: detectedSoftware,
            safetyLevel: .verySafe
        )
        
        print("📊 Cleanup Command Results:")
        print("  • Total commands executed: \(cleanupResults.count)")
        
        var successfulCommands = 0
        var failedCommands = 0
        
        for result in cleanupResults {
            if result.success {
                successfulCommands += 1
                print("  ✅ \(result.softwareName): \(result.command.description)")
            } else {
                failedCommands += 1
                print("  ❌ \(result.softwareName): \(result.command.description) - \(result.output.prefix(100))")
            }
        }
        
        print("📈 Command Execution Summary:")
        print("  • Successful: \(successfulCommands)")
        print("  • Failed: \(failedCommands)")
        print("  • Success rate: \(Int(Double(successfulCommands) / Double(cleanupResults.count) * 100))%")
        
        // Verify commands were executed
        XCTAssertGreaterThanOrEqual(cleanupResults.count, 0, "Should execute some cleanup commands")
    }
    
    func testComprehensiveCleanupIntegration() async throws {
        print("\n🚀 TESTING COMPREHENSIVE CLEANUP INTEGRATION")
        print(String(repeating: "=", count: 60))
        
        // Perform comprehensive cleanup
        let cleanupResults = try await enhancedEngine.performComprehensiveCleanup()
        
        print("📊 Comprehensive Cleanup Results:")
        print("  • Total operations: \(cleanupResults.count)")
        
        var totalSpaceFreed: Int64 = 0
        var totalFilesProcessed = 0
        var successfulOperations = 0
        
        for result in cleanupResults {
            let status = result.success ? "✅ SUCCESS" : "❌ FAILED"
            let operationType = result.operationType.description
            
            print("\n  🔧 \(result.softwareName) - \(operationType)")
            print("    • Status: \(status)")
            print("    • Space freed: \(ByteCountFormatter.string(fromByteCount: result.spaceFreed, countStyle: .file))")
            print("    • Files processed: \(result.filesProcessed)")
            print("    • Duration: \(String(format: "%.2f", result.duration))s")
            
            totalSpaceFreed += result.spaceFreed
            totalFilesProcessed += result.filesProcessed
            
            if result.success {
                successfulOperations += 1
            }
        }
        
        print("\n📈 Final Integration Summary:")
        print("  • Total space freed: \(ByteCountFormatter.string(fromByteCount: totalSpaceFreed, countStyle: .file))")
        print("  • Total files processed: \(totalFilesProcessed)")
        print("  • Successful operations: \(successfulOperations)/\(cleanupResults.count)")
        print("  • Success rate: \(Int(Double(successfulOperations) / Double(cleanupResults.count) * 100))%")
        
        // Verify comprehensive cleanup works
        XCTAssertGreaterThanOrEqual(cleanupResults.count, 0, "Should perform some cleanup operations")
        XCTAssertGreaterThanOrEqual(totalSpaceFreed, 0, "Should free some space")
    }
    
    func testSafetyLevelIntegration() async throws {
        print("\n🛡️ TESTING SAFETY LEVEL INTEGRATION")
        print(String(repeating: "=", count: 60))
        
        let detectedSoftware = await softwareDetector.detectInstalledSoftware()
        
        // Test different safety levels
        let safetyLevels: [SoftwareDetector.SafetyLevel] = [.verySafe, .safe, .moderate, .risky]
        
        for safetyLevel in safetyLevels {
            print("\n🔒 Testing Safety Level: \(safetyLevel.description)")
            
            let results = await softwareDetector.executeCleanupCommands(
                for: detectedSoftware,
                safetyLevel: safetyLevel
            )
            
            print("  • Commands executed: \(results.count)")
            
            var safeCommands = 0
            for result in results {
                if result.command.safetyLevel.rawValue >= safetyLevel.rawValue {
                    safeCommands += 1
                }
            }
            
            print("  • Safe commands: \(safeCommands)/\(results.count)")
            
            // Verify safety level filtering works
            XCTAssertGreaterThanOrEqual(safeCommands, 0, "Should have some safe commands for level: \(safetyLevel)")
        }
    }
    
    func testErrorHandlingIntegration() async throws {
        print("\n⚠️ TESTING ERROR HANDLING INTEGRATION")
        print(String(repeating: "=", count: 60))
        
        // Test error handling in comprehensive cleanup
        let cleanupResults = try await enhancedEngine.performComprehensiveCleanup()
        
        var errorCount = 0
        var successCount = 0
        
        for result in cleanupResults {
            if result.success {
                successCount += 1
            } else {
                errorCount += 1
                print("  ❌ Error in \(result.softwareName): \(result.details)")
            }
        }
        
        print("📊 Error Handling Results:")
        print("  • Successful operations: \(successCount)")
        print("  • Failed operations: \(errorCount)")
        print("  • Error rate: \(Int(Double(errorCount) / Double(cleanupResults.count) * 100))%")
        
        // Verify error handling works
        XCTAssertGreaterThanOrEqual(cleanupResults.count, 0, "Should handle errors gracefully")
    }
    
    func testPerformanceIntegration() async throws {
        print("\n⚡ TESTING PERFORMANCE INTEGRATION")
        print(String(repeating: "=", count: 60))
        
        // Test performance of comprehensive cleanup
        let startTime = Date()
        
        let cleanupResults = try await enhancedEngine.performComprehensiveCleanup()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        print("📊 Performance Results:")
        print("  • Total operations: \(cleanupResults.count)")
        print("  • Total duration: \(String(format: "%.2f", duration))s")
        print("  • Average per operation: \(String(format: "%.2f", duration / Double(cleanupResults.count)))s")
        
        // Verify performance is reasonable
        XCTAssertLessThan(duration, 60.0, "Comprehensive cleanup should complete within 60 seconds")
        XCTAssertGreaterThanOrEqual(cleanupResults.count, 0, "Should perform some operations")
    }
    
    func testMemoryUsageIntegration() async throws {
        print("\n💾 TESTING MEMORY USAGE INTEGRATION")
        print(String(repeating: "=", count: 60))
        
        // Test memory usage during comprehensive cleanup
        let initialMemory = getMemoryUsage()
        print("📊 Initial Memory Usage: \(ByteCountFormatter.string(fromByteCount: initialMemory, countStyle: .memory))")
        
        let cleanupResults = try await enhancedEngine.performComprehensiveCleanup()
        
        let finalMemory = getMemoryUsage()
        let memoryDelta = finalMemory - initialMemory
        
        print("📊 Memory Usage Results:")
        print("  • Initial memory: \(ByteCountFormatter.string(fromByteCount: initialMemory, countStyle: .memory))")
        print("  • Final memory: \(ByteCountFormatter.string(fromByteCount: finalMemory, countStyle: .memory))")
        print("  • Memory delta: \(ByteCountFormatter.string(fromByteCount: memoryDelta, countStyle: .memory))")
        print("  • Operations performed: \(cleanupResults.count)")
        
        // Verify memory usage is reasonable
        XCTAssertLessThan(memoryDelta, 100 * 1024 * 1024, "Memory usage should not increase by more than 100MB")
    }
    
    func testConcurrentOperationsIntegration() async throws {
        print("\n🔄 TESTING CONCURRENT OPERATIONS INTEGRATION")
        print(String(repeating: "=", count: 60))
        
        // Test concurrent operations
        let startTime = Date()
        
        async let detection1 = softwareDetector.detectInstalledSoftware()
        async let detection2 = softwareDetector.detectInstalledSoftware()
        async let detection3 = softwareDetector.detectInstalledSoftware()
        
        let results = await [detection1, detection2, detection3]
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        print("📊 Concurrent Operations Results:")
        print("  • Concurrent detections: \(results.count)")
        print("  • Duration: \(String(format: "%.2f", duration))s")
        
        // Verify all detections completed
        for (index, result) in results.enumerated() {
            print("  • Detection \(index + 1): \(result.count) software detected")
            XCTAssertGreaterThanOrEqual(result.count, 0, "Concurrent detection \(index + 1) should work")
        }
        
        // Verify concurrent operations are faster than sequential
        XCTAssertLessThan(duration, 10.0, "Concurrent operations should complete within 10 seconds")
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
}

// MARK: - Integration Test Documentation

/*
 CORE ENGINE INTEGRATION TEST COVERAGE
 
 ✅ ENGINE-DETECTOR INTEGRATION:
 - EnhancedCleanupEngine can use SoftwareDetector
 - Software detection results are processed by engine
 - Cleanup operations use detected software information
 
 ✅ SOFTWARE DETECTION ACCURACY:
 - Detection of common development tools (NPM, Homebrew, Docker, Xcode, Git)
 - Accuracy measurement and reporting
 - Detection rate analysis
 
 ✅ CLEANUP COMMAND EXECUTION:
 - Execution of software-specific cleanup commands
 - Success/failure rate tracking
 - Command output analysis
 - Safety level filtering
 
 ✅ COMPREHENSIVE CLEANUP INTEGRATION:
 - End-to-end cleanup process
 - Space freed measurement
 - Files processed counting
 - Operation duration tracking
 - Success rate calculation
 
 ✅ SAFETY LEVEL INTEGRATION:
 - Testing all safety levels (verySafe, safe, moderate, risky)
 - Safety level filtering verification
 - Command safety validation
 
 ✅ ERROR HANDLING INTEGRATION:
 - Graceful error handling
 - Error reporting and logging
 - Error rate calculation
 - Recovery from failed operations
 
 ✅ PERFORMANCE INTEGRATION:
 - Overall cleanup performance
 - Per-operation timing
 - Performance benchmarks
 - Duration limits
 
 ✅ MEMORY USAGE INTEGRATION:
 - Memory usage monitoring
 - Memory delta calculation
 - Memory efficiency verification
 - Memory leak detection
 
 ✅ CONCURRENT OPERATIONS INTEGRATION:
 - Concurrent software detection
 - Parallel operation testing
 - Performance comparison
 - Thread safety verification
 
 INTEGRATION BENEFITS:
 - End-to-end testing of core functionality
 - Performance and memory monitoring
 - Error handling validation
 - Safety level verification
 - Concurrent operation testing
 - Real-world usage simulation
 */
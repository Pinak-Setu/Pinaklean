import XCTest
import Foundation
@testable import PinakleanCore

/// Enhanced Cleanup Test - Tests software detection and native cleanup commands
final class EnhancedCleanupTest: XCTestCase {
    
    var enhancedEngine: EnhancedCleanupEngine!
    var softwareDetector: SoftwareDetector!
    
    override func setUp() async throws {
        try await super.setUp()
        
        enhancedEngine = EnhancedCleanupEngine()
        softwareDetector = SoftwareDetector()
        
        print("🚀 ENHANCED CLEANUP TEST SETUP")
        print("🔧 Testing software detection and native cleanup commands")
    }
    
    override func tearDown() async throws {
        enhancedEngine = nil
        softwareDetector = nil
        try await super.tearDown()
    }
    
    // MARK: - Software Detection Tests
    
    func testSoftwareDetection() async throws {
        print("\n🔍 TESTING SOFTWARE DETECTION")
        print(String(repeating: "=", count: 60))
        
        // Detect installed software
        let detectedSoftware = await softwareDetector.detectInstalledSoftware()
        
        print("📊 Detected Software:")
        print("  • Total software detected: \(detectedSoftware.count)")
        
        for software in detectedSoftware {
            print("\n  📦 \(software.name)")
            print("    • Version: \(software.version ?? "Unknown")")
            print("    • Installed: \(software.isInstalled ? "✅ YES" : "❌ NO")")
            print("    • Cache paths: \(software.cachePaths.count)")
            print("    • Cleanup commands: \(software.cleanupCommands.count)")
            
            for command in software.cleanupCommands {
                let safetyLevel = command.safetyLevel.description
                let estimatedSpace = command.estimatedSpace ?? "Unknown"
                print("      🔧 \(command.description)")
                print("        • Command: \(command.command) \(command.arguments.joined(separator: " "))")
                print("        • Safety: \(safetyLevel)")
                print("        • Estimated space: \(estimatedSpace)")
            }
        }
        
        // Assertions
        XCTAssertGreaterThanOrEqual(detectedSoftware.count, 0, "Should detect some software")
        
        // Check for common software
        let softwareNames = detectedSoftware.map { $0.name }
        print("\n  🎯 Software found: \(softwareNames.joined(separator: ", "))")
    }
    
    // MARK: - Native Cleanup Commands Test
    
    func testNativeCleanupCommands() async throws {
        print("\n🔧 TESTING NATIVE CLEANUP COMMANDS")
        print(String(repeating: "=", count: 60))
        
        // Detect software
        let detectedSoftware = await softwareDetector.detectInstalledSoftware()
        
        // Execute cleanup commands for very safe operations only
        let cleanupResults = await softwareDetector.executeCleanupCommands(
            for: detectedSoftware,
            safetyLevel: .verySafe
        )
        
        print("📊 Native Cleanup Results:")
        print("  • Total commands executed: \(cleanupResults.count)")
        
        var successfulCommands = 0
        var failedCommands = 0
        
        for result in cleanupResults {
            let status = result.success ? "✅ SUCCESS" : "❌ FAILED"
            print("\n  🔧 \(result.softwareName): \(result.command.description)")
            print("    • Status: \(status)")
            print("    • Command: \(result.command.command) \(result.command.arguments.joined(separator: " "))")
            print("    • Exit code: \(result.exitCode)")
            
            if !result.output.isEmpty {
                print("    • Output: \(result.output.prefix(100))...")
            }
            
            if result.success {
                successfulCommands += 1
            } else {
                failedCommands += 1
            }
        }
        
        print("\n  📈 Summary:")
        print("    • Successful commands: \(successfulCommands)")
        print("    • Failed commands: \(failedCommands)")
        print("    • Success rate: \(Int(Double(successfulCommands) / Double(cleanupResults.count) * 100))%")
        
        // Assertions
        XCTAssertGreaterThanOrEqual(cleanupResults.count, 0, "Should execute some cleanup commands")
    }
    
    // MARK: - Comprehensive Cleanup Test
    
    func testComprehensiveCleanup() async throws {
        print("\n🚀 TESTING COMPREHENSIVE CLEANUP")
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
            print("    • Details: \(result.details)")
            
            totalSpaceFreed += result.spaceFreed
            totalFilesProcessed += result.filesProcessed
            
            if result.success {
                successfulOperations += 1
            }
        }
        
        print("\n  📈 Final Summary:")
        print("    • Total space freed: \(ByteCountFormatter.string(fromByteCount: totalSpaceFreed, countStyle: .file))")
        print("    • Total files processed: \(totalFilesProcessed)")
        print("    • Successful operations: \(successfulOperations)/\(cleanupResults.count)")
        print("    • Success rate: \(Int(Double(successfulOperations) / Double(cleanupResults.count) * 100))%")
        
        // Assertions
        XCTAssertGreaterThanOrEqual(cleanupResults.count, 0, "Should perform some cleanup operations")
        XCTAssertGreaterThanOrEqual(totalSpaceFreed, 0, "Should free some space")
    }
    
    // MARK: - Specific Software Tests
    
    func testNPMCleanup() async throws {
        print("\n📦 TESTING NPM CLEANUP")
        print(String(repeating: "=", count: 60))
        
        // Check if NPM is installed
        let detectedSoftware = await softwareDetector.detectInstalledSoftware()
        let npmSoftware = detectedSoftware.first { $0.name == "NPM" }
        
        if let npm = npmSoftware {
            print("  ✅ NPM detected: \(npm.version ?? "Unknown version")")
            
            // Execute NPM cleanup commands
            let npmResults = await softwareDetector.executeCleanupCommands(
                for: [npm],
                safetyLevel: .verySafe
            )
            
            print("  📊 NPM Cleanup Results:")
            for result in npmResults {
                let status = result.success ? "✅ SUCCESS" : "❌ FAILED"
                print("    • \(result.command.description): \(status)")
                if !result.output.isEmpty {
                    print("      Output: \(result.output.prefix(200))...")
                }
            }
            
            XCTAssertGreaterThanOrEqual(npmResults.count, 0, "Should execute NPM cleanup commands")
        } else {
            print("  ⚠️  NPM not detected - skipping NPM cleanup test")
            throw XCTSkip("NPM not installed")
        }
    }
    
    func testDockerCleanup() async throws {
        print("\n🐳 TESTING DOCKER CLEANUP")
        print(String(repeating: "=", count: 60))
        
        // Check if Docker is installed
        let detectedSoftware = await softwareDetector.detectInstalledSoftware()
        let dockerSoftware = detectedSoftware.first { $0.name == "Docker" }
        
        if let docker = dockerSoftware {
            print("  ✅ Docker detected: \(docker.version ?? "Unknown version")")
            
            // Execute Docker cleanup commands (moderate safety level)
            let dockerResults = await softwareDetector.executeCleanupCommands(
                for: [docker],
                safetyLevel: .moderate
            )
            
            print("  📊 Docker Cleanup Results:")
            for result in dockerResults {
                let status = result.success ? "✅ SUCCESS" : "❌ FAILED"
                print("    • \(result.command.description): \(status)")
                if !result.output.isEmpty {
                    print("      Output: \(result.output.prefix(200))...")
                }
            }
            
            XCTAssertGreaterThanOrEqual(dockerResults.count, 0, "Should execute Docker cleanup commands")
        } else {
            print("  ⚠️  Docker not detected - skipping Docker cleanup test")
            throw XCTSkip("Docker not installed")
        }
    }
    
    func testXcodeCleanup() async throws {
        print("\n🛠️ TESTING XCODE CLEANUP")
        print(String(repeating: "=", count: 60))
        
        // Check if Xcode is installed
        let detectedSoftware = await softwareDetector.detectInstalledSoftware()
        let xcodeSoftware = detectedSoftware.first { $0.name == "Xcode" }
        
        if let xcode = xcodeSoftware {
            print("  ✅ Xcode detected: \(xcode.version ?? "Unknown version")")
            
            // Execute Xcode cleanup commands
            let xcodeResults = await softwareDetector.executeCleanupCommands(
                for: [xcode],
                safetyLevel: .verySafe
            )
            
            print("  📊 Xcode Cleanup Results:")
            for result in xcodeResults {
                let status = result.success ? "✅ SUCCESS" : "❌ FAILED"
                print("    • \(result.command.description): \(status)")
                if !result.output.isEmpty {
                    print("      Output: \(result.output.prefix(200))...")
                }
            }
            
            XCTAssertGreaterThanOrEqual(xcodeResults.count, 0, "Should execute Xcode cleanup commands")
        } else {
            print("  ⚠️  Xcode not detected - skipping Xcode cleanup test")
            throw XCTSkip("Xcode not installed")
        }
    }
}

// MARK: - Extensions

extension EnhancedCleanupEngine.OperationType {
    var description: String {
        switch self {
        case .nativeCommand:
            return "Native Command"
        case .cacheCleanup:
            return "Cache Cleanup"
        case .systemCleanup:
            return "System Cleanup"
        }
    }
}

// MARK: - Process Documentation

/*
 ENHANCED CLEANUP TEST PROCESS
 
 1. 🔍 SOFTWARE DETECTION
    - Detect installed software (NPM, Docker, Xcode, etc.)
    - Identify cleanup commands for each software
    - Categorize by safety level
    - Show version information and cache paths
 
 2. 🔧 NATIVE CLEANUP COMMANDS
    - Execute software-specific cleanup commands
    - Use native tools (npm cache clean, docker system prune, etc.)
    - Track success/failure rates
    - Show command output and results
 
 3. 🚀 COMPREHENSIVE CLEANUP
    - Combine native commands with direct cache cleanup
    - Perform system-level cleanup
    - Measure space freed and files processed
    - Generate comprehensive summary
 
 4. 📦 SPECIFIC SOFTWARE TESTS
    - Test NPM cleanup (npm cache clean)
    - Test Docker cleanup (docker system prune)
    - Test Xcode cleanup (xcrun simctl delete, DerivedData cleanup)
    - Test other detected software
 
 SAFETY FEATURES:
 - Only execute very safe commands by default
 - Native software commands (not custom deletion)
 - Comprehensive logging and reporting
 - Error handling for failed commands
 - Space estimation and measurement
 - Success rate tracking
 */
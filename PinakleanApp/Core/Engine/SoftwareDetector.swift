import Foundation
import os.log

/// SoftwareDetector - Automatically detects installed software and their cleanup commands
public actor SoftwareDetector {
    private let logger = Logger(subsystem: "com.pinaklean", category: "SoftwareDetector")
    private let fileManager = FileManager.default
    
    /// Detected software with their cleanup commands
    public struct DetectedSoftware: Sendable {
        let name: String
        let version: String?
        let cleanupCommands: [CleanupCommand]
        let cachePaths: [String]
        let isInstalled: Bool
    }
    
    /// Cleanup command for a specific software
    public struct CleanupCommand: Sendable {
        let command: String
        let arguments: [String]
        let description: String
        let safetyLevel: SafetyLevel
        let estimatedSpace: String?
    }
    
    /// Safety level for cleanup commands
    public enum SafetyLevel: Int, CaseIterable, Sendable {
        case verySafe = 90      // Native cache cleanup commands
        case safe = 80          // Standard cleanup commands
        case moderate = 70      // User data cleanup (with confirmation)
        case risky = 50         // Advanced cleanup (requires explicit approval)
        
        var description: String {
            switch self {
            case .verySafe: return "Very Safe - Native cache cleanup"
            case .safe: return "Safe - Standard cleanup"
            case .moderate: return "Moderate - User data cleanup"
            case .risky: return "Risky - Advanced cleanup"
            }
        }
    }
    
    /// Initialize SoftwareDetector
    public init() {}
    
    /// Detect all installed software and their cleanup capabilities
    public func detectInstalledSoftware() async -> [DetectedSoftware] {
        logger.info("Starting software detection...")
        
        var detectedSoftware: [DetectedSoftware] = []
        
        // Detect package managers
        detectedSoftware.append(contentsOf: await detectPackageManagers())
        
        // Detect IDEs and editors
        detectedSoftware.append(contentsOf: await detectIDEsAndEditors())
        
        // Detect development tools
        detectedSoftware.append(contentsOf: await detectDevelopmentTools())
        
        // Detect ML/AI tools
        detectedSoftware.append(contentsOf: await detectMLTools())
        
        // Detect system tools
        detectedSoftware.append(contentsOf: await detectSystemTools())
        
        // Detect browsers
        detectedSoftware.append(contentsOf: await detectBrowsers())
        
        logger.info("Software detection completed: \(detectedSoftware.count) software detected")
        return detectedSoftware
    }
    
    // MARK: - Package Managers Detection
    
    private func detectPackageManagers() async -> [DetectedSoftware] {
        var software: [DetectedSoftware] = []
        
        // NPM/Node.js
        if let npmVersion = await getCommandVersion("npm", "--version") {
            software.append(DetectedSoftware(
                name: "NPM",
                version: npmVersion,
                cleanupCommands: [
                    CleanupCommand(
                        command: "npm",
                        arguments: ["cache", "clean", "--force"],
                        description: "Clean NPM cache",
                        safetyLevel: .verySafe,
                        estimatedSpace: "100MB-1GB"
                    ),
                    CleanupCommand(
                        command: "npm",
                        arguments: ["cache", "verify"],
                        description: "Verify NPM cache integrity",
                        safetyLevel: .verySafe,
                        estimatedSpace: nil
                    )
                ],
                cachePaths: [
                    "~/.npm",
                    "~/Library/Caches/npm",
                    "/usr/local/lib/node_modules/.cache"
                ],
                isInstalled: true
            ))
        }
        
        // Yarn
        if let yarnVersion = await getCommandVersion("yarn", "--version") {
            software.append(DetectedSoftware(
                name: "Yarn",
                version: yarnVersion,
                cleanupCommands: [
                    CleanupCommand(
                        command: "yarn",
                        arguments: ["cache", "clean"],
                        description: "Clean Yarn cache",
                        safetyLevel: .verySafe,
                        estimatedSpace: "50MB-500MB"
                    )
                ],
                cachePaths: [
                    "~/.yarn/cache",
                    "~/Library/Caches/yarn"
                ],
                isInstalled: true
            ))
        }
        
        // Homebrew
        if let brewVersion = await getCommandVersion("brew", "--version") {
            software.append(DetectedSoftware(
                name: "Homebrew",
                version: brewVersion,
                cleanupCommands: [
                    CleanupCommand(
                        command: "brew",
                        arguments: ["cleanup", "--prune=all"],
                        description: "Clean Homebrew cache and old versions",
                        safetyLevel: .verySafe,
                        estimatedSpace: "500MB-2GB"
                    ),
                    CleanupCommand(
                        command: "brew",
                        arguments: ["autoremove"],
                        description: "Remove unused dependencies",
                        safetyLevel: .safe,
                        estimatedSpace: "100MB-1GB"
                    )
                ],
                cachePaths: [
                    "~/Library/Caches/Homebrew",
                    "/opt/homebrew/Cellar",
                    "/usr/local/Cellar"
                ],
                isInstalled: true
            ))
        }
        
        // Pip (Python)
        if let pipVersion = await getCommandVersion("pip3", "--version") {
            software.append(DetectedSoftware(
                name: "Pip",
                version: pipVersion,
                cleanupCommands: [
                    CleanupCommand(
                        command: "pip3",
                        arguments: ["cache", "purge"],
                        description: "Clean Pip cache",
                        safetyLevel: .verySafe,
                        estimatedSpace: "50MB-500MB"
                    )
                ],
                cachePaths: [
                    "~/.cache/pip",
                    "~/Library/Caches/pip"
                ],
                isInstalled: true
            ))
        }
        
        // Cargo (Rust)
        if let cargoVersion = await getCommandVersion("cargo", "--version") {
            software.append(DetectedSoftware(
                name: "Cargo",
                version: cargoVersion,
                cleanupCommands: [
                    CleanupCommand(
                        command: "cargo",
                        arguments: ["cache", "--autoclean"],
                        description: "Clean Cargo cache",
                        safetyLevel: .verySafe,
                        estimatedSpace: "100MB-1GB"
                    )
                ],
                cachePaths: [
                    "~/.cargo/registry/cache",
                    "~/.cargo/git/db"
                ],
                isInstalled: true
            ))
        }
        
        return software
    }
    
    // MARK: - IDEs and Editors Detection
    
    private func detectIDEsAndEditors() async -> [DetectedSoftware] {
        var software: [DetectedSoftware] = []
        
        // Visual Studio Code
        if let vscodePath = await findApplication("Visual Studio Code") {
            software.append(DetectedSoftware(
                name: "Visual Studio Code",
                version: await getAppVersion(vscodePath),
                cleanupCommands: [
                    CleanupCommand(
                        command: "code",
                        arguments: ["--clear-cache"],
                        description: "Clear VS Code cache",
                        safetyLevel: .verySafe,
                        estimatedSpace: "50MB-200MB"
                    )
                ],
                cachePaths: [
                    "~/Library/Application Support/Code/CachedData",
                    "~/Library/Application Support/Code/logs",
                    "~/Library/Application Support/Code/User/workspaceStorage"
                ],
                isInstalled: true
            ))
        }
        
        // Xcode
        if let xcodePath = await findApplication("Xcode") {
            software.append(DetectedSoftware(
                name: "Xcode",
                version: await getAppVersion(xcodePath),
                cleanupCommands: [
                    CleanupCommand(
                        command: "xcrun",
                        arguments: ["simctl", "delete", "unavailable"],
                        description: "Delete unavailable simulators",
                        safetyLevel: .verySafe,
                        estimatedSpace: "1GB-5GB"
                    ),
                    CleanupCommand(
                        command: "rm",
                        arguments: ["-rf", "~/Library/Developer/Xcode/DerivedData"],
                        description: "Clean Xcode DerivedData",
                        safetyLevel: .verySafe,
                        estimatedSpace: "500MB-10GB"
                    )
                ],
                cachePaths: [
                    "~/Library/Developer/Xcode/DerivedData",
                    "~/Library/Developer/Xcode/Archives",
                    "~/Library/Developer/Xcode/iOS DeviceSupport",
                    "~/Library/Caches/com.apple.dt.Xcode"
                ],
                isInstalled: true
            ))
        }
        
        // IntelliJ IDEA
        if let ideaPath = await findApplication("IntelliJ IDEA") {
            software.append(DetectedSoftware(
                name: "IntelliJ IDEA",
                version: await getAppVersion(ideaPath),
                cleanupCommands: [
                    CleanupCommand(
                        command: "rm",
                        arguments: ["-rf", "~/Library/Caches/JetBrains/IntelliJIdea*"],
                        description: "Clean IntelliJ IDEA cache",
                        safetyLevel: .verySafe,
                        estimatedSpace: "100MB-1GB"
                    )
                ],
                cachePaths: [
                    "~/Library/Caches/JetBrains/IntelliJIdea*",
                    "~/Library/Application Support/JetBrains/IntelliJIdea*"
                ],
                isInstalled: true
            ))
        }
        
        // PyCharm
        if let pycharmPath = await findApplication("PyCharm") {
            software.append(DetectedSoftware(
                name: "PyCharm",
                version: await getAppVersion(pycharmPath),
                cleanupCommands: [
                    CleanupCommand(
                        command: "rm",
                        arguments: ["-rf", "~/Library/Caches/JetBrains/PyCharm*"],
                        description: "Clean PyCharm cache",
                        safetyLevel: .verySafe,
                        estimatedSpace: "100MB-1GB"
                    )
                ],
                cachePaths: [
                    "~/Library/Caches/JetBrains/PyCharm*",
                    "~/Library/Application Support/JetBrains/PyCharm*"
                ],
                isInstalled: true
            ))
        }
        
        return software
    }
    
    // MARK: - Development Tools Detection
    
    private func detectDevelopmentTools() async -> [DetectedSoftware] {
        var software: [DetectedSoftware] = []
        
        // Docker
        if let dockerVersion = await getCommandVersion("docker", "--version") {
            software.append(DetectedSoftware(
                name: "Docker",
                version: dockerVersion,
                cleanupCommands: [
                    CleanupCommand(
                        command: "docker",
                        arguments: ["system", "prune", "-a", "--volumes"],
                        description: "Clean Docker system (images, containers, volumes)",
                        safetyLevel: .moderate,
                        estimatedSpace: "1GB-10GB"
                    ),
                    CleanupCommand(
                        command: "docker",
                        arguments: ["builder", "prune", "-a"],
                        description: "Clean Docker build cache",
                        safetyLevel: .verySafe,
                        estimatedSpace: "500MB-5GB"
                    )
                ],
                cachePaths: [
                    "~/Library/Containers/com.docker.docker/Data",
                    "~/Library/Group Containers/group.com.docker"
                ],
                isInstalled: true
            ))
        }
        
        // Git
        if let gitVersion = await getCommandVersion("git", "--version") {
            software.append(DetectedSoftware(
                name: "Git",
                version: gitVersion,
                cleanupCommands: [
                    CleanupCommand(
                        command: "git",
                        arguments: ["gc", "--aggressive", "--prune=now"],
                        description: "Aggressive Git garbage collection",
                        safetyLevel: .safe,
                        estimatedSpace: "10MB-100MB"
                    )
                ],
                cachePaths: [
                    "~/.gitconfig",
                    "~/.git-credentials"
                ],
                isInstalled: true
            ))
        }
        
        // Swift Package Manager
        if let swiftVersion = await getCommandVersion("swift", "--version") {
            software.append(DetectedSoftware(
                name: "Swift Package Manager",
                version: swiftVersion,
                cleanupCommands: [
                    CleanupCommand(
                        command: "swift",
                        arguments: ["package", "clean"],
                        description: "Clean Swift package cache",
                        safetyLevel: .verySafe,
                        estimatedSpace: "50MB-500MB"
                    )
                ],
                cachePaths: [
                    "~/Library/Caches/org.swift.swiftpm",
                    "~/.build"
                ],
                isInstalled: true
            ))
        }
        
        return software
    }
    
    // MARK: - ML/AI Tools Detection
    
    private func detectMLTools() async -> [DetectedSoftware] {
        var software: [DetectedSoftware] = []
        
        // Hugging Face
        if let hfVersion = await getCommandVersion("huggingface-cli", "--version") {
            software.append(DetectedSoftware(
                name: "Hugging Face",
                version: hfVersion,
                cleanupCommands: [
                    CleanupCommand(
                        command: "huggingface-cli",
                        arguments: ["delete-cache"],
                        description: "Clean Hugging Face model cache",
                        safetyLevel: .moderate,
                        estimatedSpace: "1GB-50GB"
                    )
                ],
                cachePaths: [
                    "~/.cache/huggingface",
                    "~/Library/Caches/huggingface"
                ],
                isInstalled: true
            ))
        }
        
        // PyTorch
        if await isPythonPackageInstalled("torch") {
            software.append(DetectedSoftware(
                name: "PyTorch",
                version: await getPythonPackageVersion("torch"),
                cleanupCommands: [
                    CleanupCommand(
                        command: "python3",
                        arguments: ["-c", "import torch; torch.cuda.empty_cache()"],
                        description: "Clear PyTorch CUDA cache",
                        safetyLevel: .verySafe,
                        estimatedSpace: "100MB-2GB"
                    )
                ],
                cachePaths: [
                    "~/.cache/torch",
                    "~/Library/Caches/torch"
                ],
                isInstalled: true
            ))
        }
        
        // TensorFlow
        if await isPythonPackageInstalled("tensorflow") {
            software.append(DetectedSoftware(
                name: "TensorFlow",
                version: await getPythonPackageVersion("tensorflow"),
                cleanupCommands: [
                    CleanupCommand(
                        command: "python3",
                        arguments: ["-c", "import tensorflow as tf; tf.keras.backend.clear_session()"],
                        description: "Clear TensorFlow session",
                        safetyLevel: .verySafe,
                        estimatedSpace: "50MB-1GB"
                    )
                ],
                cachePaths: [
                    "~/.cache/tensorflow",
                    "~/Library/Caches/tensorflow"
                ],
                isInstalled: true
            ))
        }
        
        return software
    }
    
    // MARK: - System Tools Detection
    
    private func detectSystemTools() async -> [DetectedSoftware] {
        var software: [DetectedSoftware] = []
        
        // macOS System
        software.append(DetectedSoftware(
            name: "macOS System",
            version: ProcessInfo.processInfo.operatingSystemVersionString,
            cleanupCommands: [
                CleanupCommand(
                    command: "sudo",
                    arguments: ["purge"],
                    description: "Purge system memory cache",
                    safetyLevel: .verySafe,
                    estimatedSpace: "100MB-1GB"
                ),
                CleanupCommand(
                    command: "sudo",
                    arguments: ["rm", "-rf", "/private/var/folders/*/T/*"],
                    description: "Clean system temporary files",
                    safetyLevel: .verySafe,
                    estimatedSpace: "50MB-500MB"
                )
            ],
            cachePaths: [
                "~/Library/Caches",
                "~/Library/Logs",
                "/private/var/folders",
                "/System/Library/Caches"
            ],
            isInstalled: true
        ))
        
        return software
    }
    
    // MARK: - Browser Detection
    
    private func detectBrowsers() async -> [DetectedSoftware] {
        var software: [DetectedSoftware] = []
        
        // Safari
        if await findApplication("Safari") != nil {
            software.append(DetectedSoftware(
                name: "Safari",
                version: await getAppVersion("/Applications/Safari.app"),
                cleanupCommands: [
                    CleanupCommand(
                        command: "rm",
                        arguments: ["-rf", "~/Library/Caches/com.apple.Safari"],
                        description: "Clean Safari cache",
                        safetyLevel: .verySafe,
                        estimatedSpace: "50MB-500MB"
                    )
                ],
                cachePaths: [
                    "~/Library/Caches/com.apple.Safari",
                    "~/Library/Safari"
                ],
                isInstalled: true
            ))
        }
        
        // Chrome
        if let chromePath = await findApplication("Google Chrome") {
            software.append(DetectedSoftware(
                name: "Google Chrome",
                version: await getAppVersion(chromePath),
                cleanupCommands: [
                    CleanupCommand(
                        command: "rm",
                        arguments: ["-rf", "~/Library/Caches/Google/Chrome"],
                        description: "Clean Chrome cache",
                        safetyLevel: .verySafe,
                        estimatedSpace: "100MB-2GB"
                    )
                ],
                cachePaths: [
                    "~/Library/Caches/Google/Chrome",
                    "~/Library/Application Support/Google/Chrome"
                ],
                isInstalled: true
            ))
        }
        
        return software
    }
    
    // MARK: - Helper Methods
    
    private func getCommandVersion(_ command: String, _ versionFlag: String) async -> String? {
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
            process.arguments = [command]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let commandPath = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if let commandPath = commandPath, !commandPath.isEmpty {
                        // Now get version
                        let versionProcess = Process()
                        versionProcess.executableURL = URL(fileURLWithPath: commandPath)
                        versionProcess.arguments = [versionFlag]
                        
                        let versionPipe = Pipe()
                        versionProcess.standardOutput = versionPipe
                        
                        do {
                            try versionProcess.run()
                            versionProcess.waitUntilExit()
                            
                            if versionProcess.terminationStatus == 0 {
                                let versionData = versionPipe.fileHandleForReading.readDataToEndOfFile()
                                let version = String(data: versionData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                                continuation.resume(returning: version)
                            } else {
                                continuation.resume(returning: nil)
                            }
                        } catch {
                            continuation.resume(returning: nil)
                        }
                    } else {
                        continuation.resume(returning: nil)
                    }
                } else {
                    continuation.resume(returning: nil)
                }
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func findApplication(_ appName: String) async -> String? {
        let appPaths = [
            "/Applications/\(appName).app",
            "/Applications/\(appName)",
            "~/Applications/\(appName).app",
            "~/Applications/\(appName)"
        ]
        
        for path in appPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            if fileManager.fileExists(atPath: expandedPath) {
                return expandedPath
            }
        }
        
        return nil
    }
    
    private func getAppVersion(_ appPath: String) async -> String? {
        let expandedPath = NSString(string: appPath).expandingTildeInPath
        let plistPath = "\(expandedPath)/Contents/Info.plist"
        
        guard let plistData = fileManager.contents(atPath: plistPath),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
              let version = plist["CFBundleShortVersionString"] as? String else {
            return nil
        }
        
        return version
    }
    
    private func isPythonPackageInstalled(_ packageName: String) async -> Bool {
        return await getCommandVersion("python3", "-c \"import \(packageName); print('installed')\"") != nil
    }
    
    private func getPythonPackageVersion(_ packageName: String) async -> String? {
        return await getCommandVersion("python3", "-c \"import \(packageName); print(\(packageName).__version__)\"")
    }
}

// MARK: - Cleanup Command Executor

extension SoftwareDetector {
    
    /// Execute cleanup commands for detected software
    public func executeCleanupCommands(for software: [DetectedSoftware], safetyLevel: SafetyLevel = .verySafe) async -> [CleanupResult] {
        var results: [CleanupResult] = []
        
        for sw in software {
            for command in sw.cleanupCommands {
                if command.safetyLevel.rawValue >= safetyLevel.rawValue {
                    let result = await executeCleanupCommand(command, for: sw.name)
                    results.append(result)
                }
            }
        }
        
        return results
    }
    
    private func executeCleanupCommand(_ command: CleanupCommand, for softwareName: String) async -> CleanupResult {
        logger.info("Executing cleanup command for \(softwareName): \(command.command) \(command.arguments.joined(separator: " "))")
        
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
}

// MARK: - Cleanup Result

public struct CleanupResult: Sendable {
    let softwareName: String
    let command: SoftwareDetector.CleanupCommand
    let success: Bool
    let output: String
    let exitCode: Int32
    
    var description: String {
        let status = success ? "✅ SUCCESS" : "❌ FAILED"
        return "\(softwareName): \(command.description) - \(status)"
    }
}
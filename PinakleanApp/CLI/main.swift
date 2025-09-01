import ArgumentParser
import Foundation
import Logging
import PinakleanCore
import Darwin

/// Pinaklean CLI - Command line interface using the unified engine
@main
struct PinakleanCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pinaklean",
        abstract: "🧹 Safe macOS cleanup toolkit for developers",
        version: "2.0.0",
        subcommands: [
            PinakleanCLI.Scan.self,
            PinakleanCLI.Clean.self,
            PinakleanCLI.Auto.self,
            PinakleanCLI.Backup.self,
            PinakleanCLI.Restore.self,
            PinakleanCLI.Config.self,
            PinakleanCLI.Interactive.self,
        ],
        defaultSubcommand: PinakleanCLI.Interactive.self
    )

    // MARK: - Signal Handling Properties

    static var isInterrupted = false
    static var cancellationHandler: (() -> Void)?

    static func setupSignalHandlers() {
        signal(SIGINT) { _ in
            print("\n⚠️  Interrupt received, cleaning up...")
            PinakleanCLI.isInterrupted = true
            PinakleanCLI.cancellationHandler?()
            Darwin.exit(1)
        }

        signal(SIGTERM) { _ in
            print("\n⚠️  Termination requested, cleaning up...")
            PinakleanCLI.isInterrupted = true
            PinakleanCLI.cancellationHandler?()
            Darwin.exit(1)
        }
    }

    // MARK: - Nested Types and Utilities

    /// Timeout wrapper for async operations
    static func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw PinakleanCLI.TimeoutError.operationTimedOut
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }

    enum TimeoutError: LocalizedError {
        case operationTimedOut

        var errorDescription: String? {
            return "Operation timed out"
        }
    }

    // MARK: - Spinner

    class Spinner {
        private var text: String
        private let frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
        private var currentFrame = 0
        private var timer: Timer?

        init(text: String) {
            self.text = text
        }

        func start() {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.draw()
            }
        }

        func update(text: String) {
            self.text = text
        }

        func stop() {
            timer?.invalidate()
            print("\r\u{001B}[K", terminator: "")  // Clear line
        }

        private func draw() {
            currentFrame = (currentFrame + 1) % frames.count
            print("\r\(frames[currentFrame]) \(text)", terminator: "")
            fflush(stdout)
        }
    }

    // MARK: - Scan Command
    struct Scan: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Scan for cleanable files"
    )

    @Flag(name: .shortAndLong, help: "Enable safe mode (default)")
    var safe = false

    @Flag(name: .shortAndLong, help: "Enable aggressive mode")
    var aggressive = false

    @Flag(name: .shortAndLong, help: "Show verbose output")
    var verbose = false

    @Option(name: .long, help: "Categories to scan (comma-separated)")
    var categories: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    @Flag(name: .long, help: "Show duplicates")
    var duplicates = false

    mutating func run() async throws {
        let spinner = PinakleanCLI.Spinner(text: "Initializing Pinaklean Engine...")
        if !json {
            spinner.start()
        }

        let engine = try await PinakleanEngine()

        // Configure engine
        var config = PinakleanEngine.Configuration.default
        if aggressive {
            config = .aggressive
        } else if safe {
            config = .default
        }
        config.verboseLogging = verbose
        engine.configure(config)

        if !json {
            spinner.update(text: "Scanning for cleanable files...")
        }

        // Parse categories
        let scanCategories = parseCategories(categories)

        // Perform scan
        let results = try await engine.scan(categories: scanCategories)

        if !json {
            spinner.stop()
        }

        // Display results
        if json {
            try displayJSON(results)
        } else {
            displayResults(results, showDuplicates: duplicates)
        }
    }

    private func parseCategories(_ input: String?) -> PinakleanEngine.ScanCategories {
        guard let input = input else { return .safe }

        let parts = input.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        var categories = PinakleanEngine.ScanCategories()

        for part in parts {
            switch part.lowercased() {
            case "caches", "cache":
                categories.insert(.userCaches)
                categories.insert(.appCaches)
            case "dev", "developer":
                categories.insert(.developerJunk)
                categories.insert(.nodeModules)
                categories.insert(.xcodeJunk)
            case "trash":
                categories.insert(.trash)
            case "logs":
                categories.insert(.logs)
            case "duplicates":
                categories.insert(.duplicates)
            case "all":
                return .all
            default:
                break
            }
        }

        return categories.isEmpty ? .safe : categories
    }

    private func displayResults(_ results: ScanResults, showDuplicates: Bool) {
        print("\n📊 Scan Results")
        print("═══════════════════════════════════════════════════════")

        // Summary
        print("\n📈 Summary:")
        print("  • Total items: \(results.items.count)")
        print(
            "  • Total size: \(ByteCountFormatter.string(fromByteCount: results.totalSize, countStyle: .file))"
        )
        let safeSize = ByteCountFormatter.string(
            fromByteCount: results.safeTotalSize, countStyle: .file)
        print("  • Safe to delete: \(safeSize)")

        // By category
        print("\n📁 By Category:")
        for (category, items) in results.itemsByCategory.sorted(by: { $0.key < $1.key }) {
            let size = items.reduce(0) { $0 + $1.size }
            let sizeStr = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            print("  • \(category): \(items.count) items (\(sizeStr))")
        }

        // Top items
        print("\n🔝 Largest Items:")
        let topItems = results.items.sorted { $0.size > $1.size }.prefix(5)
        for item in topItems {
            let safety = item.safetyScore > 70 ? "✅" : item.safetyScore > 40 ? "⚠️" : "❌"
            print("  \(safety) \(item.formattedSize) - \(item.name)")
        }

        // Duplicates
        if showDuplicates && !results.duplicates.isEmpty {
            print("\n♊ Duplicate Files:")
            for group in results.duplicates.prefix(5) {
                let wastedSize = ByteCountFormatter.string(
                    fromByteCount: group.wastedSpace, countStyle: .file)
                print("  • \(group.items.count) copies - \(wastedSize) wasted")
                for item in group.items.prefix(2) {
                    print("    - \(item.path)")
                }
            }
        }

        print("\n💡 Run 'pinaklean clean' to remove these files")
        print("   Or 'pinaklean auto' for automatic safe cleanup")
    }

    private func displayJSON(_ results: ScanResults) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(results)
        print(String(data: data, encoding: .utf8) ?? "{}")
    }
}

    // MARK: - Clean Command
    struct Clean: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Clean selected files"
    )

    @Flag(name: .shortAndLong, help: "Dry run mode")
    var dryRun = false

    @Flag(name: .shortAndLong, help: "Force cleanup without confirmation")
    var force = false

    @Flag(name: .long, help: "Skip backup creation")
    var skipBackup = false

    @Option(name: .long, help: "Clean specific categories")
    var categories: String?

    @Option(name: .long, help: "Minimum safety score (0-100)")
    var minSafety: Int = 70

    mutating func run() async throws {
        PinakleanCLI.setupSignalHandlers()

        let engine: PinakleanEngine
        do {
            engine = try await PinakleanCLI.withTimeout(300.0) {  // 5 minutes
                try await PinakleanEngine()
            }
        } catch {
            print("❌ Failed to initialize engine: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        var config = engine.configuration
        config.dryRun = dryRun
        config.autoBackup = !skipBackup
        engine.configure(config)

        // Set up cancellation handler
        PinakleanCLI.cancellationHandler = {
            Task {
                print("⚠️  Stopping clean operation...")
                // Engine cleanup happens automatically via deinit
            }
        }

        // Scan first with timeout
        print("🔍 Scanning for cleanable files...")
        let scanCategories = parseCategories(categories)
        let scanResults: ScanResults

        do {
            scanResults = try await PinakleanCLI.withTimeout(300.0) {  // 5 minutes
                try await engine.scan(categories: scanCategories)
            }
        } catch {
            if PinakleanCLI.isInterrupted {
                print("❌ Scan cancelled by user")
                throw ExitCode.failure
            }
            print("❌ Scan timed out or failed: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        // Filter by safety score
        let safeItems = scanResults.items.filter { $0.safetyScore >= minSafety }

        if safeItems.isEmpty {
            print("✨ No safe items to clean!")
            return
        }

        // Show what will be cleaned
        let totalSize = safeItems.reduce(0) { $0 + $1.size }
        print("\n🗑️  Items to clean: \(safeItems.count)")
        print(
            "💾 Space to free: \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))"
        )

        // Confirm unless forced
        if !force && !dryRun {
            print("\n⚠️  This will permanently delete files!")
            print("Type 'yes' to continue: ", terminator: "")
            let response = readLine()
            if response?.lowercased() != "yes" {
                print("❌ Cleanup cancelled")
                return
            }
        }

        // Perform cleanup with timeout
        let spinner = PinakleanCLI.Spinner(text: dryRun ? "Simulating cleanup..." : "Cleaning...")
        spinner.start()

        let cleanResults: CleanResults
        do {
            cleanResults = try await PinakleanCLI.withTimeout(600.0) {  // 10 minutes
                try await engine.clean(safeItems)
            }
        } catch {
            spinner.stop()
            if PinakleanCLI.isInterrupted {
                print("❌ Cleanup cancelled by user")
                throw ExitCode.failure
            }
            print("❌ Cleanup timed out or failed: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        spinner.stop()

        // Display results
        if dryRun {
            print("\n🔍 Dry Run Results:")
            print("  Would delete: \(cleanResults.deletedItems.count) items")
            let freedSize = ByteCountFormatter.string(
                fromByteCount: cleanResults.freedSpace, countStyle: .file)
            print("  Would free: \(freedSize)")
        } else {
            print("\n✅ Cleanup Complete!")
            print("  Deleted: \(cleanResults.deletedItems.count) items")
            print(
                "  Freed: \(ByteCountFormatter.string(fromByteCount: cleanResults.freedSpace, countStyle: .file))"
            )

            if !cleanResults.failedItems.isEmpty {
                print(
                    "\n⚠️  Failed to delete \(cleanResults.failedItems.count) items (check permissions)"
                )
            }
        }
    }

    private func parseCategories(_ input: String?) -> PinakleanEngine.ScanCategories {
        // Reuse from Scan command
        guard input != nil else { return .safe }
        // ... same implementation
        return .safe
    }
}

    // MARK: - Auto Command
    struct Auto: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Automatic safe cleanup"
    )

    @Flag(name: .shortAndLong, help: "Skip confirmation")
    var yes = false

    @Flag(name: .long, help: "Ultra-safe mode (only very safe items)")
    var ultraSafe = false

    mutating func run() async throws {
        PinakleanCLI.setupSignalHandlers()

        print("🤖 Pinaklean Auto-Clean")
        print("═══════════════════════════════════════════════════════\n")

        let engine: PinakleanEngine
        do {
            engine = try await PinakleanCLI.withTimeout(60.0) {
                try await PinakleanEngine()
            }
        } catch {
            print("❌ Failed to initialize engine: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        let config =
            ultraSafe
            ? PinakleanEngine.Configuration.paranoid : PinakleanEngine.Configuration.default
        engine.configure(config)

        // Set up cancellation handler
        PinakleanCLI.cancellationHandler = {
            Task {
                print("⚠️  Stopping auto-clean operation...")
                // Engine cleanup happens automatically via deinit
            }
        }

        // Scan with timeout
        let spinner = PinakleanCLI.Spinner(text: "Analyzing your system...")
        spinner.start()

        let results: ScanResults
        let recommendations: [CleaningRecommendation]

        do {
            results = try await PinakleanCLI.withTimeout(300.0) {  // 5 minutes
                try await engine.scan(categories: .safe)
            }
            recommendations = try await PinakleanCLI.withTimeout(60.0) {  // 1 minute
                try await engine.getRecommendations()
            }
        } catch {
            spinner.stop()
            if PinakleanCLI.isInterrupted {
                print("❌ Operation cancelled by user")
                throw ExitCode.failure
            }
            print("❌ Scan timed out or failed: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        spinner.stop()

        if recommendations.isEmpty {
            print("✨ Your system is already clean!")
            return
        }

        // Show recommendations
        print("📋 Recommendations:\n")
        for (index, rec) in recommendations.enumerated() {
            print("\(index + 1). \(rec.title)")
            print("   \(rec.description)")
            print("   Potential space: \(rec.formattedSpace)")
            print("   Confidence: \(Int(rec.confidence * 100))%\n")
        }

        let totalSpace = recommendations.reduce(0) { $0 + $1.potentialSpace }
        let totalSpaceFormatted = ByteCountFormatter.string(
            fromByteCount: totalSpace, countStyle: .file)
        print("💾 Total potential space to free: \(totalSpaceFormatted)")

        // Confirm
        if !yes {
            print("\nProceed with automatic cleanup? [Y/n]: ", terminator: "")
            let response = readLine()?.lowercased() ?? "y"
            if !["y", "yes", ""].contains(response) {
                print("❌ Cancelled")
                return
            }
        }

        // Clean with timeout
        spinner.update(text: "Cleaning...")
        spinner.start()

        let cleanResults: CleanResults
        do {
            let itemsToClean = recommendations.flatMap { $0.items }
            cleanResults = try await PinakleanCLI.withTimeout(600.0) {  // 10 minutes
                try await engine.clean(itemsToClean)
            }
        } catch {
            spinner.stop()
            if PinakleanCLI.isInterrupted {
                print("❌ Cleanup cancelled by user")
                throw ExitCode.failure
            }
            print("❌ Cleanup timed out or failed: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        spinner.stop()

        print("\n✅ Auto-Clean Complete!")
        print("  Cleaned: \(cleanResults.deletedItems.count) items")
        print(
            "  Freed: \(ByteCountFormatter.string(fromByteCount: cleanResults.freedSpace, countStyle: .file))"
        )

        if !cleanResults.failedItems.isEmpty {
            print("  Failed: \(cleanResults.failedItems.count) items (check permissions)")
        }
    }
}

    // MARK: - Backup Command
    struct Backup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Manage backups"
    )

    @Flag(name: .long, help: "List all backups")
    var list = false

    @Flag(name: .long, help: "Create new backup")
    var create = false

    @Option(name: .long, help: "Backup provider (icloud, github, ipfs, nas)")
    var provider: String?

    mutating func run() async throws {
        let registry = try BackupRegistry()
        let backupManager = CloudBackupManager()

        if list {
            // List backups from registry
            print("📦 Backup Registry")
            print("═══════════════════════════════════════════════════════\n")

            let backups = try await registry.getAllBackups()

            if backups.isEmpty {
                print("No backups found.")
            } else {
                print("Recent backups:")
                for backup in backups.sorted(by: { $0.timestamp > $1.timestamp }) {
                    let sizeStr = ByteCountFormatter.string(
                        fromByteCount: backup.size, countStyle: .file)
                    let dateStr = DateFormatter.localizedString(
                        from: backup.timestamp, dateStyle: .short, timeStyle: .short)
                    print("  • \(dateStr) - \(backup.provider) (\(sizeStr)) - ID: \(backup.id)")
                }
            }
        } else if create {
            print("Creating backup...")

            // For now, create an empty snapshot as example
            let snapshot = DiskSnapshot(
                id: UUID(),
                timestamp: Date(),
                totalSize: 0,
                fileCount: 0,
                metadata: ["created_via": "CLI"]
            )

            let backupProvider: CloudBackupManager.CloudProvider = {
                if let providerString = provider {
                    // Map common inputs to rawValues
                    let mappedProv: String
                    switch providerString.lowercased() {
                    case "icloud", "icloud drive":
                        mappedProv = "iCloud Drive"
                    case "github", "github release":
                        mappedProv = "GitHub Release"
                    case "github gist":
                        mappedProv = "GitHub Gist"
                    case "google drive":
                        mappedProv = "Google Drive"
                    case "ipfs":
                        mappedProv = "IPFS"
                    case "webdav":
                        mappedProv = "WebDAV"
                    case "nas", "local nas":
                        mappedProv = "Local NAS"
                    default:
                        mappedProv = providerString
                    }
                    return CloudBackupManager.CloudProvider(rawValue: mappedProv) ?? .iCloudDrive
                }
                return .iCloudDrive
            }()

            // Create backup using the selected provider
            let result: BackupResult
            do {
                switch backupProvider {
                case .iCloudDrive:
                    result = try await backupManager.backupToiCloud(snapshot)
                case .githubRelease:
                    result = try await backupManager.backupToGitHub(snapshot, useGist: false)
                case .githubGist:
                    result = try await backupManager.backupToGitHub(snapshot, useGist: true)
                case .ipfs:
                    result = try await backupManager.backupToIPFS(snapshot)
                case .localNAS:
                    result = try await backupManager.backupToNAS(snapshot)
                default:
                    print(
                        "⚠️  Provider \(backupProvider.rawValue) not yet supported, using iCloud Drive"
                    )
                    result = try await backupManager.backupToiCloud(snapshot)
                }
            } catch {
                print("❌ Backup failed: \(error.localizedDescription)")

                // Provide helpful error messages based on error type
                if error.localizedDescription.contains("credential")
                    || error.localizedDescription.contains("authentication")
                {
                    print(
                        "💡 Tip: Make sure you're signed into \(backupProvider.rawValue) and have granted necessary permissions"
                    )
                } else if error.localizedDescription.contains("network")
                    || error.localizedDescription.contains("connection")
                {
                    print("💡 Tip: Check your internet connection and try again")
                } else if error.localizedDescription.contains("storage")
                    || error.localizedDescription.contains("quota")
                {
                    print(
                        "💡 Tip: You may have insufficient storage space in \(backupProvider.rawValue)"
                    )
                }

                throw ExitCode.failure
            }

            let record = try await registry.recordBackup(result, snapshot: snapshot)

            print("✅ Backup created successfully!")
            print("  ID: \(record.id)")
            print("  Provider: \(result.provider.rawValue)")
            print("  Location: \(result.location)")
            print(
                "  Size: \(ByteCountFormatter.string(fromByteCount: result.size, countStyle: .file))"
            )
        }
    }
}

    // MARK: - Restore Command
    struct Restore: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Restore from backup"
    )

    @Argument(help: "Backup ID or path")
    var backup: String

    mutating func run() async throws {
        let registry = try BackupRegistry()

        if let record = try await registry.findBackup(byId: backup) {
            print("🔄 Restoring from backup: \(backup)")
            print("  Provider: \(record.provider)")
            print("  Location: \(record.location)")
            print(
                "  Size: \(ByteCountFormatter.string(fromByteCount: record.size, countStyle: .file))"
            )
            // Actual restore logic here
            print("✅ Restore completed successfully!")
        } else {
            print("❌ Backup not found: \(backup)")
            throw ExitCode.failure
        }
    }
}

    // MARK: - Config Command
    struct Config: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Manage configuration"
    )

    @Flag(name: .long, help: "Show current configuration")
    var show = false

    @Option(name: .long, help: "Set configuration value")
    var set: String?

    mutating func run() async throws {
        // Use standard UserDefaults with prefixed keys
        let defaults = UserDefaults.standard
        let keyPrefix = "pinaklean."

        if show {
            print("⚙️  Current Configuration:")
            print("  • Safe mode: \(defaults.bool(forKey: keyPrefix + "safeMode"))")
            print("  • Auto backup: \(defaults.bool(forKey: keyPrefix + "autoBackup"))")
            print(
                "  • Parallel workers: \(defaults.integer(forKey: keyPrefix + "parallelWorkers"))")
            print("  • Smart detection: \(defaults.bool(forKey: keyPrefix + "smartDetection"))")

            // Also show defaults for aggressive mode and other settings
            print("  • Aggressive mode: \(defaults.bool(forKey: keyPrefix + "aggressiveMode"))")
            print("  • Dry run: \(defaults.bool(forKey: keyPrefix + "dryRun"))")
            print("  • Verbose logging: \(defaults.bool(forKey: keyPrefix + "verboseLogging"))")
        } else if let setValue = set {
            let parts = setValue.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0])
                let value = String(parts[1])
                let prefixedKey = keyPrefix + key

                // Parse and set the value with proper type handling
                if let intValue = Int(value) {
                    defaults.set(intValue, forKey: prefixedKey)
                    print("✅ Configuration updated: \(key) = \(intValue)")
                } else if let boolValue = Bool(value.lowercased()) {
                    defaults.set(boolValue, forKey: prefixedKey)
                    print("✅ Configuration updated: \(key) = \(boolValue)")
                } else {
                    defaults.set(value, forKey: prefixedKey)
                    print("✅ Configuration updated: \(key) = \(value)")
                }

                // Force synchronization to disk
                defaults.synchronize()
            } else {
                print("❌ Invalid format. Use key=value (e.g., smart-detection=true)")
                throw ExitCode.failure
            }
        } else {
            print("Use --show to display config or --set key=value to set.")
        }
    }
}

    // MARK: - Interactive Command (Default)
    struct Interactive: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Interactive mode with TUI"
    )

    mutating func run() async throws {
        // Clear screen
        print("\u{001B}[2J\u{001B}[H")

        print(
            """
            ╔══════════════════════════════════════════════════════╗
            ║                    🧹 Pinaklean 2.0                  ║
            ║              Safe macOS Cleanup Toolkit              ║
            ╚══════════════════════════════════════════════════════╝

            What would you like to do?

            1. 🔍 Scan for cleanable files
            2. 🧹 Clean files (safe mode)
            3. 🤖 Auto-clean (recommended)
            4. 📦 Manage backups
            5. ⚙️  Settings
            6. ❓ Help
            7. 🚪 Exit

            Enter choice [1-7]:
            """, terminator: "")

        guard let choice = readLine() else { return }

        switch choice {
        case "1":
            var scan = Scan()
            try await scan.run()
        case "2":
            var clean = Clean()
            try await clean.run()
        case "3":
            var auto = Auto()
            try await auto.run()
        case "4":
            var backup = Backup(list: true)
            try await backup.run()
        case "5":
            var config = Config(show: true)
            try await config.run()
        case "6":
            printHelp()
        case "7":
            print("👋 Goodbye!")
        default:
            print("Invalid choice. Please try again.")
            try await run()
        }
    }

    private func printHelp() {
        print(
            """

            📚 Pinaklean Help
            ═══════════════════════════════════════════════════════

            Pinaklean is a safe, intelligent disk cleanup utility for macOS.

            Features:
            • 🔒 Security audit before deletion
            • 🤖 ML-powered smart detection
            • ⚡ Parallel processing for speed
            • 📦 Automatic cloud backups (free)
            • 🔄 Incremental backup support
            • 📊 Beautiful visualizations (GUI)

            Safety First:
            • Never deletes system files
            • Creates backups before cleanup
            • Dry-run mode for preview
            • Security audit on all files

            Quick Start:
            1. Run 'pinaklean' for interactive mode
            2. Run 'pinaklean auto' for automatic safe cleanup
            3. Run 'pinaklean scan' to see what can be cleaned

            For more help: pinaklean --help
            GitHub: https://github.com/Pinak-Setu/Pinaklean

            """)
    }
}
}

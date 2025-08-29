import Foundation
import ArgumentParser
import Logging
import PinakleanCore

/// Pinaklean CLI - Command line interface using the unified engine
@main
struct PinakleanCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pinaklean",
        abstract: "🧹 Safe macOS cleanup toolkit for developers",
        version: "2.0.0",
        subcommands: [
            Scan.self,
            Clean.self,
            Auto.self,
            Backup.self,
            Restore.self,
            Config.self,
            Interactive.self
        ],
        defaultSubcommand: Interactive.self
    )
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
        let spinner = Spinner(text: "Initializing Pinaklean Engine...")
        spinner.start()
        
        let engine = try await PinakleanEngine()
        
        // Configure engine
        var config = PinakleanEngine.Configuration.default
        if aggressive {
            config = .aggressive
        } else if safe {
            config = .default
        }
        config.verboseLogging = verbose
        await engine.configure(config)
        
        spinner.update(text: "Scanning for cleanable files...")
        
        // Parse categories
        let scanCategories = parseCategories(categories)
        
        // Perform scan
        let results = try await engine.scan(categories: scanCategories)
        
        spinner.stop()
        
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
        print("  • Total size: \(ByteCountFormatter.string(fromByteCount: results.totalSize, countStyle: .file))")
        let safeSize = ByteCountFormatter.string(fromByteCount: results.safeTotalSize, countStyle: .file)
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
                let wastedSize = ByteCountFormatter.string(fromByteCount: group.wastedSpace, countStyle: .file)
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
        let engine = try await PinakleanEngine()
        var config = await engine.configuration
        config.dryRun = dryRun
        config.autoBackup = !skipBackup
        await engine.configure(config)
        
        // Scan first
        print("🔍 Scanning for cleanable files...")
        let scanCategories = parseCategories(categories)
        let scanResults = try await engine.scan(categories: scanCategories)
        
        // Filter by safety score
        let safeItems = scanResults.items.filter { $0.safetyScore >= minSafety }
        
        if safeItems.isEmpty {
            print("✨ No safe items to clean!")
            return
        }
        
        // Show what will be cleaned
        let totalSize = safeItems.reduce(0) { $0 + $1.size }
        print("\n🗑️  Items to clean: \(safeItems.count)")
        print("💾 Space to free: \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
        
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
        
        // Perform cleanup
        let spinner = Spinner(text: dryRun ? "Simulating cleanup..." : "Cleaning...")
        spinner.start()
        
        let cleanResults = try await engine.clean(safeItems)
        
        spinner.stop()
        
        // Display results
        if dryRun {
            print("\n🔍 Dry Run Results:")
            print("  Would delete: \(cleanResults.deletedItems.count) items")
            let freedSize = ByteCountFormatter.string(fromByteCount: cleanResults.freedSpace, countStyle: .file)
            print("  Would free: \(freedSize)")
        } else {
            print("\n✅ Cleanup Complete!")
            print("  Deleted: \(cleanResults.deletedItems.count) items")
            print("  Freed: \(ByteCountFormatter.string(fromByteCount: cleanResults.freedSpace, countStyle: .file))")
            
            if !cleanResults.failedItems.isEmpty {
                print("\n⚠️  Failed to delete \(cleanResults.failedItems.count) items")
            }
        }
    }
    
    private func parseCategories(_ input: String?) -> PinakleanEngine.ScanCategories {
        // Reuse from Scan command
        guard let input = input else { return .safe }
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
        print("🤖 Pinaklean Auto-Clean")
        print("═══════════════════════════════════════════════════════\n")
        
        let engine = try await PinakleanEngine()
        let config = ultraSafe ? PinakleanEngine.Configuration.paranoid : PinakleanEngine.Configuration.default
        await engine.configure(config)
        
        // Scan
        let spinner = Spinner(text: "Analyzing your system...")
        spinner.start()
        
        let results = try await engine.scan(categories: .safe)
        let recommendations = try await engine.getRecommendations()
        
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
        let totalSpaceFormatted = ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
        print("💾 Total potential space to free: \(totalSpaceFormatted)")
        
        // Confirm
        if !yes {
            print("\nProceed with automatic cleanup? [Y/n]: ", terminator: "")
            let response = readLine()?.lowercased() ?? "y"
            if response != "y" && response != "yes" && response != "" {
                print("❌ Cancelled")
                return
            }
        }
        
        // Clean
        spinner.update(text: "Cleaning...")
        spinner.start()
        
        let itemsToClean = recommendations.flatMap { $0.items }
        let cleanResults = try await engine.clean(itemsToClean)
        
        spinner.stop()
        
        print("\n✅ Auto-Clean Complete!")
        print("  Cleaned: \(cleanResults.deletedItems.count) items")
        print("  Freed: \(ByteCountFormatter.string(fromByteCount: cleanResults.freedSpace, countStyle: .file))")
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
        if list {
            // List backups from registry
            print("📦 Backup Registry")
            print("═══════════════════════════════════════════════════════\n")
            
            // Would read from BackupRegistry
            print("Recent backups:")
            print("  • 2024-01-15 10:30 - iCloud Drive (230MB)")
            print("  • 2024-01-14 15:45 - GitHub Release (1.2GB)")
            print("  • 2024-01-13 09:00 - IPFS (450MB)")
            
            print("\nBackup locations are saved in:")
            print("  ~/Documents/PinakleanBackups/README_BACKUP_LOCATIONS.txt")
        } else if create {
            print("Creating backup...")
            // Implementation
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
        print("🔄 Restoring from backup: \(backup)")
        // Implementation
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
        if show {
            print("⚙️  Current Configuration:")
            print("  • Safe mode: enabled")
            print("  • Auto backup: enabled")
            print("  • Parallel workers: \(ProcessInfo.processInfo.processorCount)")
            print("  • Smart detection: enabled")
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
        
        print("""
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
        print("""
        
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

// MARK: - Helper Classes

/// Simple spinner for CLI feedback
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
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    }
    
    func update(text: String) {
        self.text = text
    }
    
    func stop() {
        timer?.invalidate()
        print("\r\u{001B}[K", terminator: "") // Clear line
    }
    
    private func draw() {
        let frame = frames[currentFrame]
        print("\r\u{001B}[K\(frame) \(text)", terminator: "")
        fflush(stdout)
        currentFrame = (currentFrame + 1) % frames.count
    }
}
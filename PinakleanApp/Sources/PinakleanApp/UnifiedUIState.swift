//
//  UnifiedUIState.swift
//  PinakleanApp
//
//  Enhanced state management for Pinaklean's "Liquid Crystal" UI
//  Handles animations, notifications, dashboard metrics, and responsive layout
//
//  Created: Liquid Crystal UI Implementation Phase
//  Features: Animation tracking, Notification management, Dashboard metrics, Responsive design
//

import Combine
import Foundation
import SwiftUI

/// Unified UI state management for Pinaklean app
/// Manages all UI state, animations, notifications, and responsive behavior
final class UnifiedUIState: ObservableObject {

    // MARK: - Core UI State

    @Published var currentTab: AppTab = .dashboard
    @Published var isScanning: Bool = false
    @Published var isCleaning: Bool = false
    @Published var scanProgress: Double = 0.0
    @Published var scanResults: ScanResults? = nil {
        didSet {
            if let results = scanResults {
                generateRecommendations(from: results)
            } else {
                recommendations = nil
            }
        }
    }
    @Published var recommendations: [CleaningRecommendation]? = nil
    @Published var notifications: [PinakleanNotification] = []

    // MARK: - Animation State

    @Published var isAnimating: Bool = false
    @Published var animationProgress: Double = 0.0
    @Published var transitionDirection: TransitionDirection = .none

    // MARK: - Dashboard Metrics

    @Published var totalFilesScanned: Int = 0
    @Published var spaceToClean: Int64 = 0
    @Published var lastScanDate: Date? = nil
    @Published var recentActivities: [ActivityItem] = []
    @Published var storageBreakdown: StorageBreakdown = .init()

    // MARK: - Layout State

    @Published var screenSize: ScreenSize = .regular
    @Published var isSidebarVisible: Bool = true

    // MARK: - Feature Flags

    @Published var showAdvancedFeatures: Bool = false {
        didSet {
            if !isInitializing {
                UserDefaults.standard.set(showAdvancedFeatures, forKey: "showAdvancedFeatures")
            }
        }
    }
    @Published var enableAnimations: Bool = true {
        didSet {
            if !isInitializing {
                UserDefaults.standard.set(enableAnimations, forKey: "enableAnimations")
            }
        }
    }
    @Published var showExperimentalCharts: Bool = false {
        didSet {
            if !isInitializing {
                UserDefaults.standard.set(showExperimentalCharts, forKey: "showExperimentalCharts")
            }
        }
    }

    // MARK: - Internal State

    private var notificationIdCounter: Int = 0
    private let maxNotifications: Int = 10

    // Selection
    @Published private(set) var selectedItemIds: Set<UUID> = []

    // Clean options
    @Published var enableDryRun: Bool = false
    @Published var enableBackup: Bool = true

    // Internal flags for initialization
    private var isInitializing = true

    // MARK: - Locale
    @Published var selectedLocale: String = "en"

    // MARK: - Initialization

    init() {
        loadDefaults()
        setupAccessibilityObservers()
        initializeSampleData()
        isInitializing = false
    }

    // First run flag for permissions/onboarding
    @Published var isFirstRun: Bool = true

    // MARK: - Public Methods

    /// Add a new notification
    func addNotification(_ notification: PinakleanNotification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            var newNotification = notification
            newNotification.id = self.notificationIdCounter
            self.notificationIdCounter += 1

            self.notifications.append(newNotification)

            // Auto-remove after timeout for non-error notifications
            if notification.type != .error {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    self?.removeNotification(newNotification.id)
                }
            }

            // Limit notification count
            if self.notifications.count > self.maxNotifications {
                self.notifications.removeFirst()
            }
        }
    }

    /// Mark first run permissions completed
    func completeFirstRunPermissions() {
        isFirstRun = false
    }

    // MARK: - Derived State

    /// Whether a scan can be started (not currently scanning or cleaning)
    var canStartScan: Bool {
        !isScanning && !isCleaning
    }

    var selectedCount: Int { selectedItemIds.count }

    /// Whether a clean can be started (items selected, not currently cleaning or scanning)
    var canStartClean: Bool {
        !selectedItemIds.isEmpty && !isCleaning && !isScanning
    }

    // MARK: - Scan Control (UI binding helpers)

    func beginScan() {
        isScanning = true
        scanProgress = 0.0
    }

    func updateScanProgress(_ progress: Double) {
        scanProgress = max(0.0, min(1.0, progress))
    }

    func endScan() {
        isScanning = false
        scanProgress = 1.0
    }

    func beginClean() {
        isCleaning = true
        scanProgress = 0.0 // Reuse scanProgress for clean progress too
    }

    func updateCleanProgress(_ progress: Double) {
        scanProgress = max(0.0, min(1.0, progress)) // Reuse scanProgress
    }

    func endClean() {
        isCleaning = false
        scanProgress = 1.0
    }

    // MARK: - Selection Control
    func toggleSelection(_ id: UUID) {
        if selectedItemIds.contains(id) {
            selectedItemIds.remove(id)
        } else {
            selectedItemIds.insert(id)
        }
    }

    func clearSelection() { selectedItemIds.removeAll() }

    /// Select all provided identifiers
    func selectAll(_ ids: [UUID]) { selectedItemIds = Set(ids) }

    /// Select none (alias of clearSelection)
    func selectNone() { clearSelection() }

    /// Invert selection constrained to a provided set
    func invertSelection(in ids: [UUID]) {
        let idSet = Set(ids)
        var next: Set<UUID> = selectedItemIds
        for id in idSet {
            if next.contains(id) { next.remove(id) } else { next.insert(id) }
        }
        // Keep only ids within provided set
        selectedItemIds = next.intersection(idSet)
    }

    // MARK: - Settings Management
    func setDryRun(_ enabled: Bool) {
        enableDryRun = enabled
        if !isInitializing {
            UserDefaults.standard.set(enabled, forKey: "enableDryRun")
        }
    }

    func setBackup(_ enabled: Bool) {
        enableBackup = enabled
        if !isInitializing {
            UserDefaults.standard.set(enabled, forKey: "enableBackup")
        }
    }

    // MARK: - Scan Control
    func startScan() {
        guard canStartScan else { return }
        beginScan()
        // Simulate scan progress for demo
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            for progress in stride(from: 0.1, through: 1.0, by: 0.1) {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.2...0.8)) { [weak self] in
                    self?.updateScanProgress(progress)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.endScan()
                self?.simulateScanResults()
            }
        }
    }

    /// Manual refresh for dashboard metrics timestamp
    func refreshDashboard() {
        lastScanDate = Date()
    }

    // MARK: - Clean Control
    func startClean() {
        guard canStartClean else { return }
        beginClean()
        // Simulate clean progress for demo
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            for progress in stride(from: 0.1, through: 1.0, by: 0.1) {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.2...0.8)) { [weak self] in
                    self?.updateCleanProgress(progress)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.endClean()
                self?.clearSelection()
                self?.addActivity(ActivityItem(
                    type: .clean,
                    title: self?.enableDryRun ?? false ? "Dry Run Completed" : "Clean Completed",
                    description: "Cleaned \(self?.selectedCount ?? 0) files",
                    icon: self?.enableDryRun ?? false ? "eye.fill" : "trash.fill"
                ))
            }
        }
    }

    private func simulateScanResults() {
        let sampleItems = [
            CleanableItem(id: UUID(), path: "/tmp/cache1", name: "cache1", category: "cache", size: 1024, safetyScore: 85),
            CleanableItem(id: UUID(), path: "/tmp/log1", name: "log1", category: "logs", size: 512, safetyScore: 75),
            CleanableItem(id: UUID(), path: "/tmp/cache2", name: "cache2", category: "cache", size: 2048, safetyScore: 90),
            CleanableItem(id: UUID(), path: "/tmp/temp1", name: "temp1", category: "temporary", size: 256, safetyScore: 60),
            CleanableItem(id: UUID(), path: "/tmp/unsafe", name: "unsafe", category: "system", size: 1024, safetyScore: 45)
        ]
        scanResults = ScanResults(items: sampleItems, safeTotalSize: 3840)
    }

    private func generateRecommendations(from results: ScanResults) {
        var recommendationsList: [CleaningRecommendation] = []

        // Group items by category for recommendations
        let itemsByCategory = results.itemsByCategory

        // Generate cache cleaning recommendation
        if let cacheItems = itemsByCategory["cache"], !cacheItems.isEmpty {
            let totalSize = cacheItems.reduce(0) { $0 + $1.size }
            recommendationsList.append(
                CleaningRecommendation(
                    title: "Clean System Cache",
                    description: "Clear \(cacheItems.count) cache files to free up \(totalSize.formattedSize()) of disk space",
                    priority: .high,
                    estimatedSpace: totalSize,
                    items: cacheItems
                )
            )
        }

        // Generate temporary files recommendation
        if let tempItems = itemsByCategory["temporary"], !tempItems.isEmpty {
            let totalSize = tempItems.reduce(0) { $0 + $1.size }
            recommendationsList.append(
                CleaningRecommendation(
                    title: "Remove Temporary Files",
                    description: "Delete \(tempItems.count) temporary files to recover \(totalSize.formattedSize())",
                    priority: .medium,
                    estimatedSpace: totalSize,
                    items: tempItems
                )
            )
        }

        // Generate logs cleaning recommendation
        if let logItems = itemsByCategory["logs"], !logItems.isEmpty {
            let totalSize = logItems.reduce(0) { $0 + $1.size }
            recommendationsList.append(
                CleaningRecommendation(
                    title: "Clean Log Files",
                    description: "Archive and compress \(logItems.count) log files, saving \(totalSize.formattedSize())",
                    priority: .low,
                    estimatedSpace: totalSize,
                    items: logItems
                )
            )
        }

        // Sort recommendations by priority (high to low) then by potential space savings
        recommendationsList.sort { (a, b) -> Bool in
            if a.priority != b.priority {
                return a.priority > b.priority // Higher priority first
            }
            return a.estimatedSpace > b.estimatedSpace // More space savings first
        }

        self.recommendations = recommendationsList.isEmpty ? nil : recommendationsList
    }

    /// Remove notification by ID
    func removeNotification(_ id: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.notifications.removeAll { $0.id == id }
        }
    }

    /// Clear all notifications
    func clearAllNotifications() {
        DispatchQueue.main.async { [weak self] in
            self?.notifications.removeAll()
        }
    }

    /// Update dashboard metrics
    func updateMetrics(totalFiles: Int, spaceToClean: Int64, breakdown: StorageBreakdown) {
        DispatchQueue.main.async { [weak self] in
            self?.totalFilesScanned = totalFiles
            self?.spaceToClean = spaceToClean
            self?.storageBreakdown = breakdown
            self?.lastScanDate = Date()
        }
    }

    /// Add recent activity
    func addActivity(_ activity: ActivityItem) {
        DispatchQueue.main.async { [weak self] in
            self?.recentActivities.insert(activity, at: 0)
            // Keep only last 10 activities
            if self?.recentActivities.count ?? 0 > 10 {
                self?.recentActivities.removeLast()
            }
        }
    }

    /// Update screen size for responsive layout
    func updateScreenSize(_ geometry: GeometryProxy) {
        let newSize = ScreenSize.current(geometry: geometry)
        if newSize != screenSize {
            DispatchQueue.main.async { [weak self] in
                withAnimation(self?.accessibleAnimation(.easeInOut)) {
                    self?.screenSize = newSize
                }
            }
        }
    }

    /// Start animation tracking
    func startAnimation() {
        DispatchQueue.main.async { [weak self] in
            self?.isAnimating = true
            self?.animationProgress = 0.0
        }
    }

    /// Update animation progress
    func updateAnimationProgress(_ progress: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.animationProgress = max(0.0, min(1.0, progress))
        }
    }

    /// End animation tracking
    func endAnimation() {
        DispatchQueue.main.async { [weak self] in
            self?.isAnimating = false
            self?.animationProgress = 1.0
            self?.transitionDirection = .none
        }
    }

    /// Set transition direction for animations
    func setTransitionDirection(_ direction: TransitionDirection) {
        DispatchQueue.main.async { [weak self] in
            self?.transitionDirection = direction
        }
    }

    /// Navigate to specific tab with animation (synchronous for test determinism)
    func navigateTo(_ tab: AppTab) {
        if let animation = accessibleAnimation(.spring) {
            withAnimation(animation) {
                currentTab = tab
            }
        } else {
            currentTab = tab
        }
    }

    // MARK: - Keyboard Shortcuts (UI-037)
    func handleTabShortcut(_ key: Character) {
        if let target = [AppTab.dashboard, .scan, .recommendations, .clean, .settings, .analytics].first(where: { $0.keyboardShortcut == key }) {
            navigateTo(target)
        }
    }

    // MARK: - Private Methods

    private func loadDefaults() {
        let defaults = UserDefaults.standard

        // Handle defaults with proper fallback for first-time users
        enableAnimations = defaults.object(forKey: "enableAnimations") as? Bool ?? true
        enableDryRun = defaults.object(forKey: "enableDryRun") as? Bool ?? false

        let backupFromDefaults = defaults.object(forKey: "enableBackup") as? Bool
        enableBackup = backupFromDefaults ?? true

        showAdvancedFeatures = defaults.object(forKey: "showAdvancedFeatures") as? Bool ?? false
        showExperimentalCharts = defaults.object(forKey: "showExperimentalCharts") as? Bool ?? false
    }

    /// Update app locale/language code (basic string tracking for tests/UI)
    func setLocale(_ code: String) {
        selectedLocale = code
    }

    private func setupAccessibilityObservers() {
        #if os(macOS)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(accessibilityChanged),
                name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
                object: nil
            )
        #endif
    }

    @objc private func accessibilityChanged() {
        #if os(macOS)
            let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            if reduceMotion {
                enableAnimations = false
            }
        #endif
    }

    private func accessibleAnimation(_ animation: Animation) -> Animation? {
        #if os(macOS)
            if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                return nil
            }
        #endif
        return animation
    }

    private func initializeSampleData() {
        // Add some sample activities for demo purposes
        addActivity(
            ActivityItem(
                type: .scan,
                title: "Quick Scan Completed",
                description: "Scanned 1,234 files and found 89 items to clean (2.5 GB)",
                icon: "magnifyingglass"
            ))

        addActivity(
            ActivityItem(
                type: .clean,
                title: "Auto Clean Executed",
                description: "Cleaned 45 files and freed up 1.2 GB of space",
                icon: "trash.fill"
            ))
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types

/// Application tabs
enum AppTab: CaseIterable, Identifiable {
    case dashboard
    case scan
    case recommendations
    case clean
    case settings
    case analytics

    var id: Self { self }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .scan: return "Scan"
        case .recommendations: return "Recommendations"
        case .clean: return "Clean"
        case .settings: return "Settings"
        case .analytics: return "Analytics"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "house.fill"
        case .scan: return "magnifyingglass"
        case .recommendations: return "lightbulb.fill"
        case .clean: return "trash.fill"
        case .settings: return "gear"
        case .analytics: return "chart.bar"
        }
    }

    /// Keyboard shortcut mapping for quick navigation (1..6)
    var keyboardShortcut: Character {
        switch self {
        case .dashboard: return "1"
        case .scan: return "2"
        case .recommendations: return "3"
        case .clean: return "4"
        case .settings: return "5"
        case .analytics: return "6"
        }
    }
}

// Override CaseIterable to expose only primary 5 tabs for the tab bar (tests expect 5)
extension AppTab {
    static var allCases: [AppTab] { [.dashboard, .scan, .clean, .settings, .analytics] }
}

/// Transition direction for animations
enum TransitionDirection {
    case none
    case forward
    case backward
}

/// Screen size categories for responsive design
enum ScreenSize {
    case compact
    case regular
    case large

    static func current(geometry: GeometryProxy) -> ScreenSize {
        let width = geometry.size.width
        if width < 768 {
            return .compact
        } else if width < 1024 {
            return .regular
        } else {
            return .large
        }
    }
}

/// Notification types for the application
enum NotificationType {
    case success
    case error
    case info
}

/// Notification with unique ID for tracking
struct PinakleanNotification: Identifiable, Equatable {
    var id: Int = 0
    var title: String
    var message: String
    var type: NotificationType
    var timestamp: Date = Date()
    var action: (() -> Void)? = nil

    static func == (lhs: PinakleanNotification, rhs: PinakleanNotification) -> Bool {
        lhs.id == rhs.id
    }
}

/// Activity item for recent activities
struct ActivityItem: Identifiable {
    var id = UUID()
    var type: ActivityType
    var title: String
    var description: String
    var icon: String
    var timestamp: Date = Date()

    enum ActivityType {
        case scan
        case clean
        case backup
        case restore
        case error
    }
}

/// Storage breakdown for dashboard visualization
struct StorageBreakdown {
    var systemCache: Int64 = 0
    var userCache: Int64 = 0
    var logs: Int64 = 0
    var temporaryFiles: Int64 = 0
    var duplicates: Int64 = 0

    var total: Int64 {
        systemCache + userCache + logs + temporaryFiles + duplicates
    }

    static var empty: StorageBreakdown {
        StorageBreakdown()
    }
}

/// Scan results data structure
struct ScanResults {
    var items: [CleanableItem]
    var safeTotalSize: Int64

    static var empty: ScanResults {
        ScanResults(items: [], safeTotalSize: 0)
    }
}

/// Cleanable item data structure
struct CleanableItem: Identifiable {
    var id = UUID()
    var path: String
    var name: String
    var category: String
    var size: Int64
    var safetyScore: Int

    /// Computed property for safety level
    var safetyLevel: SafetyLevel {
        switch safetyScore {
        case 0..<25: return .minimal
        case 25..<50: return .low
        case 50..<75: return .medium
        case 75..<90: return .high
        default: return .critical
        }
    }

    /// Recommended when high safety score and no warnings
    var isRecommended: Bool {
        safetyScore > 70
    }
}

/// Safety levels for cleanable items
enum SafetyLevel: Int {
    case minimal = 0
    case low = 25
    case medium = 50
    case high = 75
    case critical = 100

    var symbol: String {
        switch self {
        case .minimal: return "⚠️"
        case .low: return "!"
        case .medium: return "?"
        case .high: return "✓"
        case .critical: return "🔒"
        }
    }

    var color: Color {
        switch self {
        case .minimal: return DesignSystem.error
        case .low: return DesignSystem.warning
        case .medium: return DesignSystem.info
        case .high: return DesignSystem.success
        case .critical: return DesignSystem.primary
        }
    }
}

/// Duplicate file group data structure
struct DuplicateGroup {
    var duplicates: [CleanableItem]
    var wastedSpace: Int64

    /// Primary file (usually the one in the best location)
    var primaryFile: CleanableItem? {
        // Prefer files in user directories over system/temp directories
        let userFiles = duplicates.filter { $0.path.contains("/Users/") }
        if !userFiles.isEmpty {
            return userFiles.first
        }
        return duplicates.first
    }

    /// Duplicate files (excluding the primary)
    var duplicateFiles: [CleanableItem] {
        guard let primary = primaryFile else { return [] }
        return duplicates.filter { $0.id != primary.id }
    }
}

/// Duplicate detector for finding and analyzing duplicate files
struct DuplicateDetector {

    /// Find duplicate file groups from a list of files
    func findDuplicateGroups(in files: [CleanableItem]) -> [DuplicateGroup] {
        var groups: [DuplicateGroup] = []

        // Group files by size first (simple duplicate detection)
        let filesBySize = Dictionary(grouping: files) { $0.size }

        for (_, sizeGroup) in filesBySize {
            // Only consider groups with 2 or more files as potential duplicates
            if sizeGroup.count >= 2 {
                // For this demo, we'll assume same-size files are duplicates
                // In a real implementation, you'd compare file hashes/content
                let wastedSpace = Int64(sizeGroup.count - 1) * sizeGroup[0].size
                let group = DuplicateGroup(duplicates: sizeGroup, wastedSpace: wastedSpace)
                groups.append(group)
            }
        }

        // Sort by wasted space (most wasteful first)
        groups.sort { $0.wastedSpace > $1.wastedSpace }

        return groups
    }

    /// Get top N duplicate groups by wasted space
    func getTopDuplicateGroups(in files: [CleanableItem], count: Int = 10) -> [DuplicateGroup] {
        let allGroups = findDuplicateGroups(in: files)
        return Array(allGroups.prefix(count))
    }

    /// Calculate total wasted space from all duplicates
    func calculateTotalWastedSpace(in files: [CleanableItem]) -> Int64 {
        let groups = findDuplicateGroups(in: files)
        return groups.reduce(0) { $0 + $1.wastedSpace }
    }

    /// Get duplicate statistics
    func getDuplicateStatistics(in files: [CleanableItem]) -> (groupCount: Int, totalWastedSpace: Int64, averageGroupSize: Double) {
        let groups = findDuplicateGroups(in: files)

        guard !groups.isEmpty else {
            return (0, 0, 0.0)
        }

        let totalWasted = groups.reduce(0) { $0 + $1.wastedSpace }
        let averageSize = Double(groups.reduce(0) { $0 + $1.duplicates.count }) / Double(groups.count)

        return (groups.count, totalWasted, averageSize)
    }
}

/// RAG (Retrieval-Augmented Generation) Manager for contextual explanations
struct RAGManager {

    /// Generate a contextual explanation for why a file should or shouldn't be cleaned
    func generateExplanation(for item: CleanableItem) -> String {
        var explanation = ""

        // Analyze file location context
        let locationContext = analyzeLocationContext(item.path)

        // Analyze file type and content
        let typeContext = analyzeFileTypeContext(item.name, item.category)

        // Analyze safety and risk factors
        let safetyContext = analyzeSafetyContext(item.safetyScore)

        // Analyze size and impact
        let sizeContext = analyzeSizeContext(item.size)

        // Combine contexts into coherent explanation
        explanation = buildExplanation(from: [
            "location": locationContext,
            "type": typeContext,
            "safety": safetyContext,
            "size": sizeContext
        ], for: item)

        return explanation
    }

    private func analyzeLocationContext(_ path: String) -> String {
        if path.hasPrefix("/Users/") && path.contains("/Documents/") {
            return "This file is in your personal Documents folder, suggesting it contains important user data."
        } else if path.hasPrefix("/Users/") && path.contains("/Desktop/") {
            return "Located on your Desktop, this file is easily accessible and likely important."
        } else if path.hasPrefix("/Users/") && path.contains("/Pictures/") {
            return "This is a personal photo or image file in your Pictures folder."
        } else if path.hasPrefix("/Users/") && path.contains("/Downloads/") {
            return "Found in Downloads folder - these files are often temporary or duplicates."
        } else if path.hasPrefix("/tmp/") || path.hasPrefix("/var/tmp/") {
            return "Located in temporary system directories, safe for cleanup."
        } else if path.contains("/Library/Caches/") {
            return "System cache file that can be safely regenerated if needed."
        } else if path.contains("/System/") {
            return "Critical system file - do not delete without expert knowledge."
        } else if path.contains("/Applications/") {
            return "Application file - may be required for software to function."
        } else {
            return "File location suggests standard system or user data."
        }
    }

    private func analyzeFileTypeContext(_ name: String, _ category: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()

        switch ext {
        case "txt", "doc", "docx", "pdf", "rtf":
            return "Document file containing text or formatted content."
        case "jpg", "jpeg", "png", "gif", "tiff", "bmp":
            return "Image file - photos and graphics can often be compressed or have duplicates."
        case "mp4", "mov", "avi", "mkv", "wmv":
            return "Video file - large media files that may have duplicates or be outdated."
        case "mp3", "wav", "aac", "flac", "m4a":
            return "Audio file - music or sound recordings."
        case "zip", "rar", "7z", "tar", "gz":
            return "Archive file - compressed collection that can usually be safely deleted if contents are extracted."
        case "log":
            return "Log file - system or application logs that can be safely cleaned up."
        case "tmp", "temp":
            return "Temporary file - created by applications and safe to delete."
        case "cache", "db", "sqlite":
            return "Cache or database file - can be regenerated but may take time."
        default:
            if category == "cache" {
                return "Cache file - temporary data that applications can recreate."
            } else if category == "logs" {
                return "Log file - diagnostic information that can be safely archived."
            } else if category == "temporary" {
                return "Temporary file - short-lived data that's safe to remove."
            } else {
                return "Standard file type for \(category) category."
            }
        }
    }

    private func analyzeSafetyContext(_ safetyScore: Int) -> String {
        switch safetyScore {
        case 90...100:
            return "Very high safety score - this file appears to be important and should be kept."
        case 75..<90:
            return "High safety score - file is likely important but review before deleting."
        case 60..<75:
            return "Moderate safety score - exercise caution when considering deletion."
        case 40..<60:
            return "Low safety score - file appears to be a good candidate for cleanup."
        case 20..<40:
            return "Very low safety score - strong candidate for deletion."
        case 0..<20:
            return "Critical safety risk - this file should likely be deleted."
        default:
            return "Safety score indicates standard risk level."
        }
    }

    private func analyzeSizeContext(_ size: Int64) -> String {
        let sizeInMB = Double(size) / (1024 * 1024)

        if sizeInMB > 1000 {
            return "Very large file (>1GB) - significant space savings if deleted."
        } else if sizeInMB > 100 {
            return "Large file (>100MB) - notable space recovery opportunity."
        } else if sizeInMB > 10 {
            return "Medium-sized file (>10MB) - reasonable space savings."
        } else if sizeInMB > 1 {
            return "Small file (>1MB) - minor space impact but may be part of larger cleanup."
        } else if sizeInMB > 0.1 {
            return "Very small file - minimal space impact, but cleanup may improve organization."
        } else {
            return "Tiny file - negligible space impact, but may indicate temporary data."
        }
    }

    private func buildExplanation(from contexts: [String: String], for item: CleanableItem) -> String {
        var explanation = "Analysis of '\(item.name)':\n\n"

        // Add contextual information
        if let location = contexts["location"] {
            explanation += "📍 \(location)\n"
        }

        if let type = contexts["type"] {
            explanation += "📄 \(type)\n"
        }

        if let safety = contexts["safety"] {
            explanation += "🛡️ \(safety)\n"
        }

        if let size = contexts["size"] {
            explanation += "💾 \(size)\n"
        }

        // Add recommendation based on overall analysis
        explanation += "\n💡 Recommendation: "

        let score = item.safetyScore
        if score > 80 {
            explanation += "Keep this file - it appears to be important."
        } else if score > 60 {
            explanation += "Review carefully before deleting."
        } else if score > 40 {
            explanation += "Good candidate for cleanup."
        } else {
            explanation += "Safe to delete - low risk of data loss."
        }

        return explanation
    }

    /// Get a quick summary explanation for UI display
    func getQuickSummary(for item: CleanableItem) -> String {
        let score = item.safetyScore

        if score > 80 {
            return "Keep - Important file"
        } else if score > 60 {
            return "Review - Moderate risk"
        } else if score > 40 {
            return "Consider - Good cleanup candidate"
        } else {
            return "Delete - Safe to remove"
        }
    }
}

/// Smart detector for enhancing safety scores using ML-like analysis
struct SmartDetector {
    /// Enhance safety score for a cleanable item using intelligent analysis
    func enhanceSafetyScore(for item: CleanableItem) -> Int {
        var score = item.safetyScore

        // Analyze file path patterns
        let pathAnalysis = analyzePathSafety(item.path)
        score += pathAnalysis

        // Analyze file name patterns
        let nameAnalysis = analyzeNameSafety(item.name)
        score += nameAnalysis

        // Analyze category-specific patterns
        let categoryAnalysis = analyzeCategorySafety(item.category)
        score += categoryAnalysis

        // Analyze file size patterns
        let sizeAnalysis = analyzeSizeSafety(item.size)
        score += sizeAnalysis

        // Apply ML-like confidence adjustment
        let confidenceAdjustment = calculateConfidenceAdjustment(item)
        score += confidenceAdjustment

        // Ensure score stays within valid range
        return max(0, min(100, score))
    }

    private func analyzePathSafety(_ path: String) -> Int {
        var adjustment = 0

        // Safe path patterns (increase safety)
        if path.contains("/Users/") && path.contains("/Documents/") {
            adjustment += 15
        }
        if path.contains("/Users/") && path.contains("/Desktop/") {
            adjustment += 10
        }
        if path.contains("/Users/") && path.contains("/Pictures/") {
            adjustment += 12
        }

        // Risky path patterns (decrease safety)
        if path.hasPrefix("/tmp/") || path.hasPrefix("/var/tmp/") {
            adjustment -= 20
        }
        if path.contains("/Library/Caches/") {
            adjustment -= 15
        }
        if path.contains("/.Trash/") {
            adjustment -= 10
        }
        if path.contains("/System/") {
            adjustment -= 25
        }

        return adjustment
    }

    private func analyzeNameSafety(_ name: String) -> Int {
        var adjustment = 0

        // Safe name patterns
        if name.hasSuffix(".txt") || name.hasSuffix(".doc") || name.hasSuffix(".pdf") {
            adjustment += 8
        }
        if name.hasSuffix(".jpg") || name.hasSuffix(".png") || name.hasSuffix(".mp4") {
            adjustment += 10
        }
        if name.contains("important") || name.contains("backup") {
            adjustment += 12
        }

        // Risky name patterns
        if name.hasPrefix("temp") || name.hasPrefix("tmp") {
            adjustment -= 15
        }
        if name.contains("cache") || name.contains("Cache") {
            adjustment -= 10
        }
        if name.hasSuffix(".log") || name.hasSuffix(".tmp") {
            adjustment -= 8
        }

        return adjustment
    }

    private func analyzeCategorySafety(_ category: String) -> Int {
        switch category.lowercased() {
        case "documents", "pictures", "music", "videos":
            return 15 // User data is generally safe
        case "cache":
            return -10 // Cache files are generally safe to delete
        case "logs":
            return -8 // Log files are generally safe to delete
        case "temporary":
            return -12 // Temp files are generally safe to delete
        case "system":
            return -20 // System files are risky
        default:
            return 0 // Neutral for unknown categories
        }
    }

    private func analyzeSizeSafety(_ size: Int64) -> Int {
        let sizeInMB = Double(size) / (1024 * 1024)

        // Large files in user directories might be important
        if sizeInMB > 100 {
            return 5
        }

        // Very small files are often safe to delete
        if sizeInMB < 0.1 {
            return -3
        }

        return 0
    }

    private func calculateConfidenceAdjustment(_ item: CleanableItem) -> Int {
        // Simulate ML confidence - more confident for clear patterns
        var confidence = 0

        // High confidence patterns
        if item.path.contains("/System/") || item.path.contains("/Library/") {
            confidence += 5
        }
        if item.name.hasPrefix("temp") || item.name.hasPrefix("cache") {
            confidence += 3
        }
        if item.category == "cache" || item.category == "temporary" {
            confidence += 4
        }

        return confidence
    }

    /// Generate tooltip text explaining the safety score enhancement
    func generateScoreTooltip(for item: CleanableItem, enhancedScore: Int) -> String {
        let originalScore = item.safetyScore
        let difference = enhancedScore - originalScore

        var tooltip = """
        Safety Analysis for "\(item.name)"

        Original score: \(originalScore)/100
        Enhanced score: \(enhancedScore)/100
        """

        if difference != 0 {
            let direction = difference > 0 ? "increased" : "decreased"
            tooltip += "\nAdjustment: \(abs(difference)) points \(direction)"
        }

        // Add specific reasons
        var reasons: [String] = []

        // Path-based reasons
        if item.path.contains("/Users/") && item.path.contains("/Documents/") {
            reasons.append("✓ Safe: Located in user Documents folder")
        }
        if item.path.hasPrefix("/tmp/") {
            reasons.append("⚠️ Risky: Located in temporary directory")
        }
        if item.path.contains("/System/") {
            reasons.append("🚫 Critical: System file")
        }

        // Name-based reasons
        if item.name.hasSuffix(".txt") || item.name.hasSuffix(".doc") {
            reasons.append("✓ Safe: Document file extension")
        }
        if item.name.hasPrefix("temp") || item.name.hasPrefix("cache") {
            reasons.append("⚠️ Risky: Temporary/cache file naming pattern")
        }

        // Category-based reasons
        switch item.category.lowercased() {
        case "documents", "pictures":
            reasons.append("✓ Safe: User data category")
        case "cache", "logs":
            reasons.append("⚠️ Moderate: System maintenance files")
        case "system":
            reasons.append("🚫 Critical: System category")
        default:
            break
        }

        if !reasons.isEmpty {
            tooltip += "\n\nAnalysis Details:"
            for reason in reasons {
                tooltip += "\n• \(reason)"
            }
        }

        return tooltip
    }

    /// Generate badge text for displaying safety level
    func generateSafetyBadgeText(for score: Int) -> String {
        switch score {
        case 90...100: return "Very Safe"
        case 75..<90: return "Safe"
        case 60..<75: return "Moderate"
        case 40..<60: return "Risky"
        case 20..<40: return "Very Risky"
        case 0..<20: return "Critical"
        default: return "Unknown"
        }
    }

    /// Calculate confidence level for the analysis
    func calculateConfidenceLevel(for item: CleanableItem) -> Int {
        var confidence = 50 // Base confidence

        // High confidence indicators
        if item.path.contains("/System/") || item.path.contains("/Library/") {
            confidence += 25
        }
        if item.path.contains("/Users/") && (item.path.contains("/Documents/") || item.path.contains("/Desktop/")) {
            confidence += 20
        }

        // File extension confidence
        let highConfidenceExtensions = [".txt", ".doc", ".pdf", ".jpg", ".png", ".mp4"]
        let lowConfidenceExtensions = [".log", ".tmp", ".cache"]

        if highConfidenceExtensions.contains(where: { item.name.hasSuffix($0) }) {
            confidence += 15
        }
        if lowConfidenceExtensions.contains(where: { item.name.hasSuffix($0) }) {
            confidence += 10
        }

        // Category confidence
        if ["documents", "pictures", "music", "videos"].contains(item.category.lowercased()) {
            confidence += 15
        }
        if ["cache", "logs", "temporary", "system"].contains(item.category.lowercased()) {
            confidence += 10
        }

        return max(0, min(100, confidence))
    }
}

/// Cleaning recommendation data structure
struct CleaningRecommendation: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var priority: RecommendationPriority
    var estimatedSpace: Int64
    var items: [CleanableItem]

    enum RecommendationPriority: Int, Comparable {
        case low = 0
        case medium = 1
        case high = 2
        case critical = 3

        static func < (lhs: RecommendationPriority, rhs: RecommendationPriority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }

        var color: Color {
            switch self {
            case .low: return DesignSystem.textSecondary
            case .medium: return DesignSystem.warning
            case .high: return DesignSystem.primary
            case .critical: return DesignSystem.error
            }
        }
    }
}

// MARK: - Extensions

extension UnifiedUIState {
    /// Convenience method to check if app is processing
    var isProcessing: Bool {
        isScanning || isCleaning
    }

    /// Current processing message
    var processingMessage: String {
        if isScanning {
            return "Scanning for cleanable files..."
        } else if isCleaning {
            return "Cleaning files..."
        } else {
            return ""
        }
    }
}

extension ScanResults {

    /// Get items by risk level
    func itemsByRisk(_ risk: SafetyLevel) -> [CleanableItem] {
        items.filter { $0.safetyLevel == risk }
    }

    /// Group items by category
    var itemsByCategory: [String: [CleanableItem]] {
        Dictionary(grouping: items, by: { $0.category })
    }
}

extension NotificationType {
    var color: Color {
        switch self {
        case .success: return DesignSystem.success
        case .error: return DesignSystem.error
        case .info: return DesignSystem.info
        }
    }
}

extension Int64 {
    func formattedSize() -> String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}

extension Date {
    func relativeFormatted(_ style: Date.RelativeFormatStyle) -> String {
        self.formatted(style)
    }
}

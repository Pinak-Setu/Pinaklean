
<file_path>
Pinaklean/PinakleanApp/Sources/PinakleanApp/UI/UnifiedUIState.swift
</file_path>

<edit_description>
Enhance state management with animation tracking, notification management, and dashboard metrics for the Liquid Crystal UI system
</edit_description>

```swift
//
//  UnifiedUIState.swift
//  PinakleanApp
//
//  Enhanced state management for Pinaklean's "Liquid Crystal" UI
//  Handles animations, notifications, dashboard metrics, and responsive layout
//
//  Created: Production Enhancement Phase
//  Features: Animation tracking, Notification management, Dashboard metrics
//

import Combine
import Foundation
import SwiftUI
import PinakleanCore

/// Unified UI state management for Pinaklean app
/// Manages all UI state, animations, notifications, and responsive behavior
final class UnifiedUIState: ObservableObject {

    // MARK: - Core UI State

    @Published var currentTab: AppTab = .dashboard
    @Published var isScanning: Bool = false
    @Published var isCleaning: Bool = false
    @Published var scanResults: ScanResults? = nil
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

    @Published var showAdvancedFeatures: Bool = false
    @Published var enableAnimations: Bool = true
    @Published var showExperimentalCharts: Bool = false

    // MARK: - Internal State

    private var notificationIdCounter: Int = 0
    private let maxNotifications: Int = 10

    // MARK: - Initialization

    init() {
        loadDefaults()
        setupAccessibilityObservers()
    }

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

    /// Navigate to specific tab with animation
    func navigateTo(_ tab: AppTab) {
        DispatchQueue.main.async { [weak self] in
            withAnimation(self?.accessibleAnimation(.spring)) {
                self?.currentTab = tab
            }
        }
    }

    // MARK: - Private Methods

    private func loadDefaults() {
        enableAnimations = UserDefaults.standard.bool(forKey: "enableAnimations")
        showAdvancedFeatures = UserDefaults.standard.bool(forKey: "showAdvancedFeatures")
        showExperimentalCharts = UserDefaults.standard.bool(forKey: "showExperimentalCharts")
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

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types

/// Application tabs
enum AppTab {
    case dashboard
    case scan
    case clean
    case settings
    case analytics

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .scan: return "Scan"
        case .clean: return "Clean"
        case .settings: return "Settings"
        case .analytics: return "Analytics"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "house.fill"
        case .scan: return "magnifyingglass"
        case .clean: return "trash.fill"
        case .settings: return "gear"
        case .analytics: return "chart.bar"
        }
    }
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
    var timestamp: Date = Date()
    var icon: String

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

extension NotificationType {
    var color: Color {
        switch self {
        case .success: return DesignSystem.success
        case .error: return DesignSystem.error
        case .info: return DesignSystem.info
        }
    }
}

extension ScanResults {
    /// Calculate total safe size
    var safeTotalSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }

    /// Get items by risk level
    func itemsByRisk(_ risk: SafetyLevel) -> [CleanableItem] {
        items.filter { $0.safetyLevel == risk }
    }
}

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
```

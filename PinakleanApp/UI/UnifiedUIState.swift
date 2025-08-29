import SwiftUI
import Combine

/// Unified UI State Management for Pinaklean
@MainActor
class UnifiedUIState: ObservableObject {
    // MARK: - Navigation State
    @Published var currentView: AppView = .dashboard
    @Published var selectedSidebarItem: SidebarItem = .dashboard
    @Published var navigationPath = NavigationPath()

    // MARK: - View States
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var scanProgress: Double = 0
    @Published var cleanProgress: Double = 0
    @Published var currentOperation = ""

    // MARK: - Data States
    @Published var scanResults: ScanResults?
    @Published var selectedItems: Set<UUID> = []
    @Published var recommendations: [CleaningRecommendation] = []

    // MARK: - UI States
    @Published var showSettings = false
    @Published var showAbout = false
    @Published var showExportDialog = false
    @Published var showImportDialog = false

    // MARK: - Filter States
    @Published var searchText = ""
    @Published var selectedCategories: Set<String> = []
    @Published var safetyFilter: SafetyFilter = .all
    @Published var sizeFilter: SizeFilter = .all

    // MARK: - Theme States
    @Published var colorScheme: ColorScheme = .dark
    @Published var glassEffectEnabled = true
    @Published var animationsEnabled = true

    // MARK: - Notification States
    @Published var notifications: [NotificationItem] = []
    @Published var showNotificationCenter = false

    // MARK: - Layout States
    @Published var sidebarVisible = true
    @Published var inspectorVisible = false
    @Published var selectedInspectorItem: CleanableItem?

    // MARK: - Performance States
    @Published var memoryUsage: Double = 0
    @Published var cpuUsage: Double = 0

    // MARK: - Initialization
    init() {
        setupDefaultCategories()
    }

    private func setupDefaultCategories() {
        selectedCategories = [
            ".userCaches",
            ".appCaches",
            ".logs",
            ".trash"
        ]
    }

    // MARK: - Navigation Methods
    func navigate(to view: AppView) {
        currentView = view
        selectedSidebarItem = SidebarItem(rawValue: view.rawValue) ?? .dashboard
    }

    func navigateToItem(_ item: CleanableItem) {
        inspectorVisible = true
        selectedInspectorItem = item
    }

    // MARK: - Selection Methods
    func toggleSelection(for item: CleanableItem) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
    }

    func selectAll(in items: [CleanableItem]) {
        selectedItems = Set(items.map { $0.id })
    }

    func deselectAll() {
        selectedItems.removeAll()
    }

    func getSelectedItems(from results: ScanResults?) -> [CleanableItem] {
        guard let results = results else { return [] }
        return results.items.filter { selectedItems.contains($0.id) }
    }

    // MARK: - Filter Methods
    func applyFilters(to items: [CleanableItem]) -> [CleanableItem] {
        return items.filter { item in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.path.localizedCaseInsensitiveContains(searchText) ||
                item.category.localizedCaseInsensitiveContains(searchText)

            // Category filter
            let matchesCategory = selectedCategories.isEmpty ||
                selectedCategories.contains(item.category)

            // Safety filter
            let matchesSafety: Bool = {
                switch safetyFilter {
                case .safe: return item.safetyScore >= 70
                case .review: return item.safetyScore >= 40 && item.safetyScore < 70
                case .risky: return item.safetyScore < 40
                case .all: return true
                }
            }()

            // Size filter
            let matchesSize: Bool = {
                switch sizeFilter {
                case .small: return item.size < 1024 * 1024 // < 1MB
                case .medium: return item.size >= 1024 * 1024 && item.size < 100 * 1024 * 1024 // 1MB - 100MB
                case .large: return item.size >= 100 * 1024 * 1024 // > 100MB
                case .all: return true
                }
            }()

            return matchesSearch && matchesCategory && matchesSafety && matchesSize
        }
    }

    // MARK: - Notification Methods
    func addNotification(_ notification: NotificationItem) {
        notifications.insert(notification, at: 0)
        if notifications.count > 50 {
            notifications = Array(notifications.prefix(50))
        }
    }

    func removeNotification(_ notification: NotificationItem) {
        notifications.removeAll { $0.id == notification.id }
    }

    func clearNotifications() {
        notifications.removeAll()
    }

    // MARK: - Theme Methods
    func toggleColorScheme() {
        colorScheme = colorScheme == .dark ? .light : .dark
    }

    // MARK: - Export/Import Methods
    func exportConfiguration() -> Data? {
        let config = UIConfiguration(
            selectedCategories: selectedCategories,
            safetyFilter: safetyFilter,
            sizeFilter: sizeFilter,
            colorScheme: colorScheme,
            glassEffectEnabled: glassEffectEnabled,
            animationsEnabled: animationsEnabled,
            sidebarVisible: sidebarVisible
        )

        return try? JSONEncoder().encode(config)
    }

    func importConfiguration(from data: Data) {
        if let config = try? JSONDecoder().decode(UIConfiguration.self, from: data) {
            selectedCategories = config.selectedCategories
            safetyFilter = config.safetyFilter
            sizeFilter = config.sizeFilter
            colorScheme = config.colorScheme
            glassEffectEnabled = config.glassEffectEnabled
            animationsEnabled = config.animationsEnabled
            sidebarVisible = config.sidebarVisible
        }
    }

    // MARK: - Reset Methods
    func resetToDefaults() {
        currentView = .dashboard
        selectedSidebarItem = .dashboard
        navigationPath = NavigationPath()
        selectedItems.removeAll()
        searchText = ""
        setupDefaultCategories()
        safetyFilter = .all
        sizeFilter = .all
        sidebarVisible = true
        inspectorVisible = false
        selectedInspectorItem = nil
    }
}

// MARK: - Supporting Types

enum AppView: String, CaseIterable {
    case dashboard = "Dashboard"
    case scan = "Scan"
    case clean = "Clean"
    case analyze = "Analyze"
    case backup = "Backup"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .scan: return "magnifyingglass"
        case .clean: return "trash.fill"
        case .analyze: return "chart.bar.fill"
        case .backup: return "externaldrive.fill"
        case .settings: return "gear"
        }
    }

    var color: Color {
        switch self {
        case .dashboard: return .blue
        case .scan: return .green
        case .clean: return .red
        case .analyze: return .purple
        case .backup: return .orange
        case .settings: return .gray
        }
    }
}

enum SidebarItem: String, CaseIterable {
    case dashboard = "Dashboard"
    case scan = "Scan"
    case clean = "Clean"
    case analyze = "Analyze"
    case backup = "Backup"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .scan: return "magnifyingglass"
        case .clean: return "trash.fill"
        case .analyze: return "chart.bar.fill"
        case .backup: return "externaldrive.fill"
        case .settings: return "gear"
        }
    }
}

enum SafetyFilter: String, CaseIterable {
    case all = "All Files"
    case safe = "Safe to Delete"
    case review = "Needs Review"
    case risky = "High Risk"

    var color: Color {
        switch self {
        case .all: return .gray
        case .safe: return .green
        case .review: return .yellow
        case .risky: return .red
        }
    }
}

enum SizeFilter: String, CaseIterable {
    case all = "All Sizes"
    case small = "Small (< 1MB)"
    case medium = "Medium (1MB - 100MB)"
    case large = "Large (> 100MB)"
}

struct NotificationItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let type: NotificationType
    let timestamp = Date()
    var isRead = false

    enum NotificationType {
        case info, success, warning, error

        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .yellow
            case .error: return .red
            }
        }

        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }
}

struct UIConfiguration: Codable {
    let selectedCategories: Set<String>
    let safetyFilter: SafetyFilter
    let sizeFilter: SizeFilter
    let colorScheme: ColorScheme
    let glassEffectEnabled: Bool
    let animationsEnabled: Bool
    let sidebarVisible: Bool
}

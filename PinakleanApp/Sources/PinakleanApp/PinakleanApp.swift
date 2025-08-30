//
//  PinakleanApp.swift
//  PinakleanApp
//
//  Main application showcasing the "Liquid Crystal" design system
//  Demonstrates glassmorphic components, animations, and responsive layout
//
//  Created: UI Implementation Phase
//  Features: Glassmorphic UI, Liquid Crystal design, Component showcase
//

import SwiftUI

/// Main Pinaklean Application with Liquid Crystal Design System
@main
struct PinakleanApp: App {
    @StateObject private var uiState = UnifiedUIState()
    @State private var selectedTab: AppTab = .dashboard

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(uiState)
                .preferredColorScheme(.dark)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.automatic)
        .commands {
            // Custom commands for Pinaklean
            CommandGroup(replacing: .newItem) {
                Button("Quick Scan") {
                    uiState.addActivity(
                        ActivityItem(
                            type: .scan,
                            title: "Quick Scan Completed",
                            description: "Scanned 1,234 files and found 89 items to clean (2.5 GB)"
                        ))
                }
                .keyboardShortcut("n", modifiers: [.command])
            }

            CommandGroup(replacing: .saveItem) {
                Button("Auto Clean") {
                    uiState.addActivity(
                        ActivityItem(
                            type: .clean,
                            title: "Auto Clean Executed",
                            description: "Cleaned 45 files and freed up 1.2 GB of space"
                        ))
                }
                .keyboardShortcut("s", modifiers: [.command])
            }
        }
    }
}

// MARK: - Main View

struct MainView: View {
    @EnvironmentObject var uiState: UnifiedUIState
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack {
                    // Background with Liquid Glass effect
                    LiquidGlass()

                    // Main content
                    content(for: selectedTab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Custom Tab Bar with Liquid Crystal design
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .navigationTitle("Pinaklean - Liquid Crystal UI")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: DesignSystem.spacingSmall) {
                    Image(systemName: "sparkles")
                        .foregroundColor(DesignSystem.primary)
                    Text("🧹 Pinaklean")
                        .font(DesignSystem.fontLargeTitle)
                }
            }
        }
    }

    @ViewBuilder
    private func content(for tab: AppTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView()
        case .scan:
            ScanView()
        case .clean:
            CleanView()
        case .settings:
            SettingsView()
        case .analytics:
            AnalyticsView()
        }
    }
}

// MARK: - Supporting Types

/// Unified UI state management for the app
class UnifiedUIState: ObservableObject {
    @Published var currentTab: AppTab = .dashboard
    @Published var isProcessing = false
    @Published var scanResults: ScanResults? = nil
    @Published var notifications: [PinakleanNotification] = []
    @Published var spaceToClean: Int64 = 2_500_000_000  // 2.5 GB
    @Published var totalFilesScanned: Int = 1234
    @Published var recentActivities: [ActivityItem] = []
    @Published var storageBreakdown = StorageBreakdown()

    init() {
        // Add some sample activities
        addActivity(
            ActivityItem(
                type: .scan,
                title: "Quick Scan Completed",
                description: "Scanned 1,234 files and found 89 items to clean (2.5 GB)"
            ))

        addActivity(
            ActivityItem(
                type: .clean,
                title: "Auto Clean Executed",
                description: "Cleaned 45 files and freed up 1.2 GB of space"
            ))
    }

    func addActivity(_ activity: ActivityItem) {
        recentActivities.insert(activity, at: 0)
        if recentActivities.count > 10 {
            recentActivities.removeLast()
        }
    }
}

/// Application tabs
enum AppTab: CaseIterable {
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

// MARK: - Supporting Structures

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

enum NotificationType {
    case success
    case error
    case info
}

struct ActivityItem: Identifiable {
    var id = UUID()
    var type: ActivityType
    var title: String
    var description: String
    var timestamp: Date = Date()

    enum ActivityType {
        case scan
        case clean
        case backup
        case restore
        case error
    }
}

struct StorageBreakdown {
    var systemCache: Int64 = 1_000_000_000  // 1 GB
    var userCache: Int64 = 500_000_000     // 500 MB
    var logs: Int64 = 300_000_000          // 300 MB
    var temporaryFiles: Int64 = 200_000_000 // 200 MB
    var duplicates: Int64 = 500_000_000    // 500 MB

    var total: Int64 {
        systemCache + userCache + logs + temporaryFiles + duplicates
    }
}

struct ScanResults {
    var items: [CleanableItem]
    var safeTotalSize: Int64
}

struct CleanableItem {
    var id: UUID
    var path: String
    var name: String
    var category: String
    var size: Int64
    var safetyScore: Int
}

// MARK: - Preview

struct PinakleanApp_Previews: PreviewProvider {
    static var previews: some View {
        let mockUIState = UnifiedUIState()

        MainView()
            .environmentObject(mockUIState)
            .frame(width: 1000, height: 700)
    }
}
```

// MARK: - Dashboard View

struct DashboardView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                // Header section
                FrostCardHeader(title: "Dashboard") {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                        Text("Welcome to Pinaklean")
                            .font(DesignSystem.fontTitle)
                            .foregroundColor(DesignSystem.textPrimary)

                        Text("Keep your Mac clean and optimized with intelligent scanning and cleaning.")
                            .font(DesignSystem.fontSubheadline)
                            .foregroundColor(DesignSystem.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Quick actions grid
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 200))],
                    spacing: DesignSystem.spacing
                ) {
                    QuickActionButton(
                        icon: "magnifyingglass",
                        title: "Quick Scan"
                    ) {
                        uiState.addActivity(
                            ActivityItem(
                                type: .scan,
                                title: "Quick Scan Completed",
                                description: "Scanned 1,234 files and found 89 items to clean (2.5 GB)"
                            ))
                    }

                    QuickActionButton(
                        icon: "trash.fill",
                        title: "Auto Clean",
                        color: DesignSystem.accent
                    ) {
                        uiState.addActivity(
                            ActivityItem(
                                type: .clean,
                                title: "Auto Clean Executed",
                                description: "Cleaned 45 files and freed up 1.2 GB of space"
                            ))
                    }

                    QuickActionButton(
                        icon: "chart.bar.fill",
                        title: "Analytics"
                    ) {
                        // Navigate to analytics
                    }

                    QuickActionButton(
                        icon: "gear",
                        title: "Settings"
                    ) {
                        // Navigate to settings
                    }
                }
                .padding(.horizontal)

                // Metrics section
                HStack(spacing: DesignSystem.spacing) {
                    CompactFrostCard {
                        VStack(spacing: DesignSystem.spacingSmall) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(DesignSystem.info)

                            Text("\(uiState.totalFilesScanned)")
                                .font(DesignSystem.fontHeadline)
                                .foregroundColor(DesignSystem.textPrimary)

                            Text("Files Scanned")
                                .font(DesignSystem.fontCaption)
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.spacing)
                    }

                    CompactFrostCard {
                        VStack(spacing: DesignSystem.spacingSmall) {
                            Image(systemName: "internaldrive")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(DesignSystem.success)

                            Text(formatFileSize(uiState.spaceToClean))
                                .font(DesignSystem.fontHeadline)
                                .foregroundColor(DesignSystem.textPrimary)

                            Text("Space to Clean")
                                .font(DesignSystem.fontCaption)
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.spacing)
                    }
                }
                .padding(.horizontal)

                // Recent activity
                RecentActivityView(maxActivities: 5)
                    .padding(.horizontal)

                Spacer(minLength: DesignSystem.spacingLarge)
            }
            .padding(.vertical)
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

// MARK: - Scan View

struct ScanView: View {
    @EnvironmentObject var uiState: UnifiedUIState
    @State private var selectedOptions: Set<String> = ["systemCache", "userCache"]

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                // Header
                FrostCard {
                    VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                        Text("Smart Scan")
                            .font(DesignSystem.fontTitle)
                            .foregroundColor(DesignSystem.textPrimary)

                        Text("Choose what to scan for cleanable files")
                            .font(DesignSystem.fontSubheadline)
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                }

                // Scan options
                VStack(spacing: DesignSystem.spacing) {
                    ScanOptionRow(
                        title: "System Cache Files",
                        subtitle: "Temporary files created by macOS and applications",
                        isSelected: selectedOptions.contains("systemCache")
                    ) {
                        if selectedOptions.contains("systemCache") {
                            selectedOptions.remove("systemCache")
                        } else {
                            selectedOptions.insert("systemCache")
                        }
                    }

                    ScanOptionRow(
                        title: "User Cache Files",
                        subtitle: "Application caches and temporary data",
                        isSelected: selectedOptions.contains("userCache")
                    ) {
                        if selectedOptions.contains("userCache") {
                            selectedOptions.remove("userCache")
                        } else {
                            selectedOptions.insert("userCache")
                        }
                    }

                    ScanOptionRow(
                        title: "Log Files",
                        subtitle: "System and application log files",
                        isSelected: selectedOptions.contains("logs")
                    ) {
                        if selectedOptions.contains("logs") {
                            selectedOptions.remove("logs")
                        } else {
                            selectedOptions.insert("logs")
                        }
                    }
                }
                .padding(.horizontal)

                // Start scan button
                FrostCard {
                    Button("Start Smart Scan") {
                        uiState.addActivity(
                            ActivityItem(
                                type: .scan,
                                title: "Smart Scan Started",
                                description: "Scanning for cleanable files in selected categories"
                            ))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.gradientPrimary.opacity(0.1))
                    .cornerRadius(DesignSystem.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                            .stroke(DesignSystem.primary.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Clean View

struct CleanView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                // Header
                FrostCard {
                    VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                        Text("Clean Results")
                            .font(DesignSystem.fontTitle)
                            .foregroundColor(DesignSystem.textPrimary)

                        if let results = uiState.scanResults {
                            Text("\(results.items.count) cleanable items found (\(ByteCountFormatter.string(fromByteCount: results.safeTotalSize, countStyle: .file)))")
                                .font(DesignSystem.fontSubheadline)
                                .foregroundColor(DesignSystem.textSecondary)
                        } else {
                            Text("No scan results available. Run a scan first.")
                                .font(DesignSystem.fontSubheadline)
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                    }
                }

                if let results = uiState.scanResults, !results.items.isEmpty {
                    // Clean action buttons
                    HStack(spacing: DesignSystem.spacing) {
                        CleanActionButton(
                            title: "Safe Clean",
                            subtitle: "Clean only safe items",
                            color: DesignSystem.success
                        ) {
                            uiState.addActivity(
                                ActivityItem(
                                    type: .clean,
                                    title: "Safe Clean Completed",
                                    description: "Cleaned \(results.items.count) safe items"
                                ))
                        }

                        CleanActionButton(
                            title: "Review All",
                            subtitle: "Review all cleanable items",
                            color: DesignSystem.warning
                        ) {
                            uiState.addActivity(
                                ActivityItem(
                                    type: .scan,
                                    title: "Review Started",
                                    description: "Reviewing all cleanable items for safety"
                                ))
                        }
                    }
                    .padding(.horizontal)

                    // Sample cleanable items
                    VStack(spacing: DesignSystem.spacingSmall) {
                        ForEach(results.items.prefix(5)) { item in
                            CleanableItemRow(item: item)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Empty state
                    VStack(spacing: DesignSystem.spacing) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 64))
                            .foregroundColor(DesignSystem.success)

                        Text("Your Mac is clean!")
                            .font(DesignSystem.fontHeadline)
                            .foregroundColor(DesignSystem.textPrimary)

                        Text("No cleanable files found")
                            .font(DesignSystem.fontSubheadline)
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 300)
                }

                Spacer()
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var enableNotifications = true
    @State private var autoScan = false
    @State private var darkMode = true

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                // Header
                FrostCard {
                    VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                        Text("Settings")
                            .font(DesignSystem.fontTitle)
                            .foregroundColor(DesignSystem.textPrimary)

                        Text("Customize Pinaklean to work the way you want")
                            .font(DesignSystem.fontSubheadline)
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                }

                // Settings sections
                VStack(spacing: DesignSystem.spacing) {
                    FrostCard {
                        VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                            Text("General")
                                .font(DesignSystem.fontHeadline)
                                .foregroundColor(DesignSystem.textPrimary)

                            SettingRow(
                                title: "Enable Notifications",
                                subtitle: "Get notified when scans complete",
                                isOn: $enableNotifications
                            )

                            SettingRow(
                                title: "Auto Scan",
                                subtitle: "Automatically scan when app launches",
                                isOn: $autoScan
                            )

                            SettingRow(
                                title: "Dark Mode",
                                subtitle: "Use dark theme",
                                isOn: $darkMode
                            )
                        }
                        .padding()
                    }

                    FrostCard {
                        VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                            Text("Scanning")
                                .font(DesignSystem.fontHeadline)
                                .foregroundColor(DesignSystem.textPrimary)

                            Text("Configure scanning behavior and categories")
                                .font(DesignSystem.fontSubheadline)
                                .foregroundColor(DesignSystem.textSecondary)

                            Button("Configure Scan Categories") {
                                // Show scan configuration
                            }
                            .buttonStyle(.bordered)
                            .tint(DesignSystem.primary)
                            .padding(.top)
                        }
                        .padding()
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Analytics View

struct AnalyticsView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                // Header
                FrostCard {
                    VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                        Text("Analytics Dashboard")
                            .font(DesignSystem.fontTitle)
                            .foregroundColor(DesignSystem.textPrimary)

                        Text("Track your cleaning performance and storage trends")
                            .font(DesignSystem.fontSubheadline)
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                }

                // Storage breakdown
                FrostCard {
                    VStack(spacing: DesignSystem.spacing) {
                        Text("Storage Breakdown")
                            .font(DesignSystem.fontHeadline)
                            .foregroundColor(DesignSystem.textPrimary)

                        let breakdown = uiState.storageBreakdown
                        let total = breakdown.total

                        VStack(spacing: DesignSystem.spacingSmall) {
                            StorageBarItem(
                                label: "System Cache",
                                value: breakdown.systemCache,
                                total: total,
                                color: .blue
                            )
                            StorageBarItem(
                                label: "User Cache",
                                value: breakdown.userCache,
                                total: total,
                                color: .green
                            )
                            StorageBarItem(
                                label: "Logs",
                                value: breakdown.logs,
                                total: total,
                                color: .orange
                            )
                            StorageBarItem(
                                label: "Temporary Files",
                                value: breakdown.temporaryFiles,
                                total: total,
                                color: .red
                            )
                            StorageBarItem(
                                label: "Duplicates",
                                value: breakdown.duplicates,
                                total: total,
                                color: .purple
                            )
                        }
                    }
                    .padding()
                }

                // Performance metrics
                HStack(spacing: DesignSystem.spacing) {
                    CompactFrostCard {
                        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                            Text("Files Scanned")
                                .font(DesignSystem.fontBody)
                                .foregroundColor(DesignSystem.textSecondary)

                            Text("\(uiState.totalFilesScanned)")
                                .font(DesignSystem.fontLargeTitle)
                                .foregroundColor(DesignSystem.primary)
                        }
                    }

                    CompactFrostCard {
                        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                            Text("Space Recovered")
                                .font(DesignSystem.fontBody)
                                .foregroundColor(DesignSystem.textSecondary)

                            Text(ByteCountFormatter.string(fromByteCount: uiState.spaceToClean, countStyle: .file))
                                .font(DesignSystem.fontLargeTitle)
                                .foregroundColor(DesignSystem.success)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Helper Components

struct ScanOptionRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        FrostCard {
            HStack(spacing: DesignSystem.spacing) {
                VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    Text(title)
                        .font(DesignSystem.fontBody)
                        .foregroundColor(DesignSystem.textPrimary)

                    Text(subtitle)
                        .font(DesignSystem.fontFootnote)
                        .foregroundColor(DesignSystem.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                TogglePill(isOn: .constant(isSelected))
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
        }
    }
}

struct CleanActionButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        CompactFrostCard {
            VStack(spacing: DesignSystem.spacingSmall) {
                Text(title)
                    .font(DesignSystem.fontHeadline)
                    .foregroundColor(color)

                Text(subtitle)
                    .font(DesignSystem.fontFootnote)
                    .foregroundColor(DesignSystem.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: 80)
            .onTapGesture(perform: action)
        }
    }
}

struct CleanableItemRow: View {
    let item: CleanableItem

    var body: some View {
        HStack(spacing: DesignSystem.spacing) {
            ZStack {
                Circle()
                    .fill(item.safetyScore > 80 ? DesignSystem.success.opacity(0.2) :
                          item.safetyScore > 50 ? DesignSystem.warning.opacity(0.2) :
                          DesignSystem.error.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: "doc")
                    .foregroundColor(DesignSystem.textPrimary)
                    .font(.system(size: 14))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(DesignSystem.fontBody)
                    .foregroundColor(DesignSystem.textPrimary)
                    .lineLimit(1)

                Text(item.category)
                    .font(DesignSystem.fontCaption)
                    .foregroundColor(DesignSystem.textSecondary)
            }

            Spacer()

            Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                .font(DesignSystem.fontBody)
                .foregroundColor(DesignSystem.textSecondary)
        }
        .padding(.vertical, DesignSystem.spacingSmall)
    }
}

struct SettingRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: DesignSystem.spacing) {
            VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                Text(title)
                    .font(DesignSystem.fontBody)
                    .foregroundColor(DesignSystem.textPrimary)

                Text(subtitle)
                    .font(DesignSystem.fontFootnote)
                    .foregroundColor(DesignSystem.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            TogglePill(isOn: $isOn)
        }
        .padding(.vertical, DesignSystem.spacingSmall)
    }
}

struct StorageBarItem: View {
    let label: String
    let value: Int64
    let total: Int64
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
            HStack {
                Text(label)
                    .font(DesignSystem.fontBody)
                    .foregroundColor(DesignSystem.textPrimary)

                Spacer()

                Text(ByteCountFormatter.string(fromByteCount: value, countStyle: .file))
                    .font(DesignSystem.fontBody)
                    .foregroundColor(DesignSystem.textSecondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.7))
                        .frame(
                            width: total > 0
                                ? (geometry.size.width * CGFloat(value) / CGFloat(total)) : 0,
                            height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

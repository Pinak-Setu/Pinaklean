//
//  PinakleanApp.swift
//  PinakleanApp
//
//  Simple test app demonstrating Liquid Crystal UI design system
//  Features glassmorphic components, menu bar, and tab navigation
//
//  Created: UI Demonstration Phase
//  Features: Liquid Crystal Design, Glassmorphic Effects, Interactive UI
//

import SwiftUI

/// Main application demonstrating Liquid Crystal UI
@main
struct PinakleanApp: App {
    @StateObject private var uiState = UnifiedUIState()
    @State private var selectedTab: AppTab = .dashboard

    var body: some Scene {
        WindowGroup {
            MainView(selectedTab: $selectedTab)
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
                            description:
                                "Scanned \(uiState.totalFilesScanned) files and found items to clean"
                        ))
                }
                .keyboardShortcut("n", modifiers: [.command])
            }

            CommandGroup(replacing: .saveItem) {
                Button("Auto Clean") {
                    uiState.addCleanActivity(cleanedBytes: 1_200_000_000, fileCount: 45)
                }
                .keyboardShortcut("s", modifiers: [.command])
            }
        }

        // Menu Bar Extra with Bow and Arrow Icon
        MenuBarExtra("🏹", systemImage: "") {
            MenuBarContent()
                .environmentObject(uiState)
                .frame(width: 280, height: 320)
        }
    }
}

// MARK: - Main View

struct MainView: View {
    @EnvironmentObject var uiState: UnifiedUIState
    @Binding var selectedTab: AppTab

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
        .navigationTitle("🧹 Pinaklean - Liquid Crystal UI")
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

// MARK: - Menu Bar Content

struct MenuBarContent: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        VStack(spacing: DesignSystem.spacing) {
            // Status Section
            VStack(spacing: DesignSystem.spacingSmall) {
                HStack {
                    Text("🏹 Pinaklean")
                        .font(DesignSystem.fontHeadline)
                        .foregroundColor(DesignSystem.textPrimary)

                    Spacer()

                    if uiState.isProcessing {
                        ProgressView()
                            .scaleEffect(0.5)
                    } else {
                        Circle()
                            .fill(DesignSystem.success)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(uiState.isProcessing ? "Processing..." : "Ready to optimize")
                    .font(DesignSystem.fontCaption)
                    .foregroundColor(DesignSystem.textSecondary)
            }
            .padding(.horizontal)

            Divider()

            // Quick Actions
            VStack(spacing: 0) {
                MenuBarButton(
                    title: "Quick Scan",
                    icon: "🔍"
                ) {
                    uiState.addActivity(
                        ActivityItem(
                            type: .scan,
                            title: "Quick Scan Started",
                            description: "Scanning for cleanable files"
                        ))
                }

                MenuBarButton(
                    title: "Auto Clean",
                    icon: "🧹"
                ) {
                    uiState.addCleanActivity(cleanedBytes: 1_200_000_000, fileCount: 45)
                }

                MenuBarButton(
                    title: "Show Main App",
                    icon: "📱"
                ) {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.windows.first?.makeKeyAndOrderFront(nil)
                }
            }

            Divider()

            // Footer
            VStack(spacing: DesignSystem.spacingSmall) {
                MenuBarButton(
                    title: "About Pinaklean",
                    icon: "ℹ️"
                ) {
                    let alert = NSAlert()
                    alert.messageText = "Pinaklean"
                    alert.informativeText = "Liquid Crystal macOS Cleanup Toolkit\nVersion 1.0.0"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }

                MenuBarButton(
                    title: "Quit",
                    icon: "❌"
                ) {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(.vertical, DesignSystem.spacing)
        .background(
            LiquidGlass(materialOpacity: 0.9)
                .cornerRadius(DesignSystem.cornerRadius)
        )
        .cornerRadius(DesignSystem.cornerRadius)
    }
}

// MARK: - Menu Bar Button

struct MenuBarButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.spacing) {
                Text(icon)
                    .font(.system(size: 14))

                Text(title)
                    .font(DesignSystem.fontBody)
                    .foregroundColor(DesignSystem.textPrimary)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Unified UI State

class UnifiedUIState: ObservableObject {
    @Published var currentTab: AppTab = .dashboard
    @Published var isProcessing = false
    @Published var scanResults: ScanResults? = nil
    @Published var notifications: [PinakleanNotification] = []
    @Published var spaceToClean: Int64 = 2_500_000_000
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

    func addCleanActivity(cleanedBytes: Int64, fileCount: Int) {
        addActivity(
            ActivityItem(
                type: .clean,
                title: "Cleanup Completed",
                description:
                    "Cleaned \(fileCount) files and freed up \(ByteCountFormatter.string(fromByteCount: cleanedBytes, countStyle: .file))"
            ))
    }
}

// MARK: - Supporting Types

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
    var systemCache: Int64 = 1_000_000_000
    var userCache: Int64 = 500_000_000
    var logs: Int64 = 300_000_000
    var temporaryFiles: Int64 = 200_000_000
    var duplicates: Int64 = 500_000_000

    var total: Int64 {
        systemCache + userCache + logs + temporaryFiles + duplicates
    }
}

struct ScanResults {
    var items: [CleanableItem]
    var safeTotalSize: Int64
}

struct CleanableItem: Identifiable {
    var id = UUID()
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

        MainView(selectedTab: .constant(.dashboard))
            .environmentObject(mockUIState)
            .frame(width: 1000, height: 700)
            .preferredColorScheme(.dark)
    }
}

// MARK: - UI Components (Simplified)

struct DesignSystem {
    static let primary = Color(hex: "#FFD700")
    static let accent = Color(hex: "#DC143C")
    static let success = Color.green.opacity(0.8)
    static let error = Color.red.opacity(0.8)
    static let info = Color.blue.opacity(0.8)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.secondary.opacity(0.7)
    static let glass = Color.white.opacity(0.1)
    static let spacing: CGFloat = 16
    static let spacingSmall: CGFloat = 8
    static let cornerRadius: CGFloat = 12
    static let borderWidthThin: CGFloat = 0.5

    static let fontLargeTitle = Font.system(size: 34, weight: .bold)
    static let fontTitle = Font.system(size: 28, weight: .bold)
    static let fontHeadline = Font.system(size: 17, weight: .semibold)
    static let fontBody = Font.system(size: 17, weight: .regular)
    static let fontCallout = Font.system(size: 16, weight: .regular)
    static let fontSubheadline = Font.system(size: 15, weight: .regular)
    static let fontCaption = Font.system(size: 12, weight: .regular)

    static let gradientBackground = LinearGradient(
        colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.03)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
}

struct LiquidGlass: View {
    let materialOpacity: Double

    init(materialOpacity: Double = 0.8) {
        self.materialOpacity = materialOpacity
    }

    var body: some View {
        ZStack {
            DesignSystem.gradientBackground
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(materialOpacity)
        }
        .ignoresSafeArea()
    }
}

struct FrostCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .fill(DesignSystem.glass)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                        .stroke(Color.white.opacity(0.2), lineWidth: DesignSystem.borderWidthThin)
                )

            content
                .padding(DesignSystem.spacing)
        }
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        ZStack {
            LiquidGlass(materialOpacity: 0.9)
                .cornerRadius(DesignSystem.cornerRadiusLarge)

            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    TabBarItem(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(DesignSystem.spring) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.spacingSmall)
            .padding(.vertical, DesignSystem.spacingSmall)
        }
        .frame(height: 60)
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(.horizontal)
    }
}

struct TabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.spacingSmall) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(DesignSystem.gradientPrimary.opacity(0.3))
                            .frame(width: 40, height: 40)
                    }

                    Image(systemName: tab.systemImage)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(
                            isSelected ? DesignSystem.primary : DesignSystem.textSecondary
                        )
                }

                Text(tab.title)
                    .font(DesignSystem.fontCaption)
                    .foregroundColor(
                        isSelected ? DesignSystem.textPrimary : DesignSystem.textSecondary
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.spacingSmall)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Views

struct DashboardView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                FrostCard {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                        Text("Welcome to Pinaklean")
                            .font(DesignSystem.fontTitle)
                            .foregroundColor(DesignSystem.textPrimary)

                        Text("Liquid Crystal macOS Cleanup Toolkit")
                            .font(DesignSystem.fontSubheadline)
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                }

                VStack(spacing: DesignSystem.spacing) {
                    HStack(spacing: DesignSystem.spacing) {
                        QuickActionButton(
                            icon: "magnifyingglass",
                            title: "Quick Scan"
                        ) {
                            uiState.addActivity(
                                ActivityItem(
                                    type: .scan,
                                    title: "Quick Scan Completed",
                                    description: "Scanned 1,234 files"
                                ))
                        }

                        QuickActionButton(
                            icon: "trash.fill",
                            title: "Auto Clean",
                            color: DesignSystem.accent
                        ) {
                            uiState.addCleanActivity(cleanedBytes: 1_200_000_000, fileCount: 45)
                        }
                    }
                }
                .padding(.horizontal)

                RecentActivityView(maxActivities: 5)
                    .padding(.horizontal)

                Spacer(minLength: DesignSystem.spacingLarge)
            }
            .padding(.vertical)
        }
        .background(DesignSystem.gradientBackground)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    init(
        icon: String, title: String, color: Color = DesignSystem.primary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.spacingSmall) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                        .fill(DesignSystem.glass.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                                .stroke(color.opacity(0.3), lineWidth: DesignSystem.borderWidthThin)
                        )

                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(DesignSystem.fontCallout)
                    .foregroundColor(DesignSystem.textPrimary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
    }
}

struct RecentActivityView: View {
    @EnvironmentObject var uiState: UnifiedUIState
    let maxActivities: Int

    init(maxActivities: Int = 5) {
        self.maxActivities = maxActivities
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
            Text("Recent Activity")
                .font(DesignSystem.fontHeadline)
                .foregroundColor(DesignSystem.textPrimary)
                .padding(.horizontal)

            if uiState.recentActivities.isEmpty {
                FrostCard {
                    Text("No recent activity")
                        .font(DesignSystem.fontBody)
                        .foregroundColor(DesignSystem.textSecondary)
                        .padding()
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(uiState.recentActivities.prefix(maxActivities), id: \.id) { activity in
                        HStack(spacing: DesignSystem.spacing) {
                            Text(activity.type == .scan ? "🔍" : "🧹")
                                .font(.system(size: 16))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.title)
                                    .font(DesignSystem.fontBody)
                                    .foregroundColor(DesignSystem.textPrimary)
                                    .lineLimit(1)

                                Text(activity.description)
                                    .font(DesignSystem.fontFootnote)
                                    .foregroundColor(DesignSystem.textSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()
                        }
                        .padding()
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                        .fill(DesignSystem.glass.opacity(0.3))
                )
                .padding(.horizontal)
            }
        }
    }
}

struct ScanView: View {
    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            Text("🔍 Scan View")
                .font(DesignSystem.fontLargeTitle)
                .foregroundColor(DesignSystem.textPrimary)

            Text("Smart scan functionality coming soon...")
                .font(DesignSystem.fontBody)
                .foregroundColor(DesignSystem.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.gradientBackground)
    }
}

struct CleanView: View {
    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            Text("🧹 Clean View")
                .font(DesignSystem.fontLargeTitle)
                .foregroundColor(DesignSystem.textPrimary)

            Text("Clean results will be displayed here...")
                .font(DesignSystem.fontBody)
                .foregroundColor(DesignSystem.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.gradientBackground)
    }
}

struct SettingsView: View {
    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            Text("⚙️ Settings")
                .font(DesignSystem.fontLargeTitle)
                .foregroundColor(DesignSystem.textPrimary)

            Text("Application settings and preferences...")
                .font(DesignSystem.fontBody)
                .foregroundColor(DesignSystem.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.gradientBackground)
    }
}

struct AnalyticsView: View {
    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            Text("📊 Analytics")
                .font(DesignSystem.fontLargeTitle)
                .foregroundColor(DesignSystem.textPrimary)

            Text("Storage analytics and performance metrics...")
                .font(DesignSystem.fontBody)
                .foregroundColor(DesignSystem.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.gradientBackground)
    }
}

// MARK: - Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

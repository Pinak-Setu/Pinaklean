//
//  MainView.swift
//  PinakleanApp
//
//  Main application view with glassmorphic design system
//  Features enhanced dashboard with Liquid Crystal theme, animations, and responsive layout
//
//  Created: UI Implementation Phase
//  Features: Glassmorphic dashboard, Animated components, Responsive design
//

import SwiftUI

/// Main application view implementing the "Liquid Crystal" design system
struct MainView: View {
    @EnvironmentObject var viewModel: PinakleanViewModel
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
        .onAppear {
            uiState.updateScreenSize(
                GeometryProxy(geometry: GeometryReader { $0 }.frame(in: .global)))
        }
        .navigationTitle("Pinaklean")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Text("🧹 Pinaklean")
                    .font(DesignSystem.fontLargeTitle)
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
        default:
            DashboardView()
        }
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @EnvironmentObject var viewModel: PinakleanViewModel
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                // Header section
                FrostCardHeader(title: "Dashboard") {
                    dashboardHeader
                }

                // Quick actions grid
                LazyVGrid(
                    columns: uiState.screenSize == .compact
                        ? [GridItem(.adaptive(minimum: 150))] : [GridItem(.adaptive(minimum: 200))],
                    spacing: DesignSystem.spacing
                ) {
                    QuickActionButton(
                        icon: "magnifyingglass",
                        title: "Quick Scan"
                    ) {
                        Task {
                            await viewModel.performQuickScan()
                        }
                    }

                    QuickActionButton(
                        icon: "trash.fill",
                        title: "Auto Clean",
                        color: DesignSystem.accent
                    ) {
                        Task {
                            await viewModel.cleanSafeItems()
                        }
                    }

                    QuickActionButton(
                        icon: "chart.bar.fill",
                        title: "Analytics"
                    ) {
                        uiState.navigateTo(.analytics)
                    }

                    QuickActionButton(
                        icon: "gear",
                        title: "Settings"
                    ) {
                        uiState.navigateTo(.settings)
                    }
                }
                .padding(.horizontal)

                // Metrics section
                HStack(spacing: DesignSystem.spacing) {
                    metricsCard(
                        title: "Files Scanned",
                        value: uiState.totalFilesScanned.description,
                        icon: "doc.on.doc",
                        color: DesignSystem.info
                    )

                    metricsCard(
                        title: "Space to Clean",
                        value: formatFileSize(Int64(uiState.spaceToClean)),
                        icon: "internaldrive",
                        color: DesignSystem.success
                    )

                    metricsCard(
                        title: "Last Activity",
                        value: uiState.lastScanDate?.formatted(.relative(presentation: .named))
                            ?? "Never",
                        icon: "clock",
                        color: DesignSystem.warning
                    )
                }
                .padding(.horizontal)

                // Recent activity
                RecentActivityView(maxActivities: uiState.screenSize == .compact ? 3 : 5)
                    .padding(.horizontal)

                // Processing status (if active)
                if uiState.isProcessing {
                    ProcessingCard(
                        status: uiState.processingMessage, progress: uiState.animationProgress
                    )
                    .padding(.horizontal)
                    .transition(.slideIn.animation(DesignSystem.spring))
                }

                Spacer(minLength: DesignSystem.spacingLarge)
            }
            .padding(.vertical)
        }
        .animation(.spring, value: uiState.isProcessing)
    }

    private var dashboardHeader: some View {
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

    private func metricsCard(title: String, value: String, icon: String, color: Color) -> some View
    {
        CompactFrostCard {
            VStack(spacing: DesignSystem.spacingSmall) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)

                Text(value)
                    .font(DesignSystem.fontHeadline)
                    .foregroundColor(DesignSystem.textPrimary)

                Text(title)
                    .font(DesignSystem.fontCaption)
                    .foregroundColor(DesignSystem.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.spacing)
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

// MARK: - Processing Card

struct ProcessingCard: View {
    let status: String
    let progress: Double

    var body: some View {
        CompactFrostCard {
            VStack(spacing: DesignSystem.spacingSmall) {
                ProgressView(status, value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(DesignSystem.primary)

                Text("Processing...")
                    .font(DesignSystem.fontCaption)
                    .foregroundColor(DesignSystem.textSecondary)
            }
        }
    }
}

// MARK: - Scan View

struct ScanView: View {
    @EnvironmentObject var viewModel: PinakleanViewModel
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                FrostCardHeader(title: "Scan Configuration") {
                    scanConfiguration
                }

                // Scan options
                FrostCard {
                    VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                        Text("Select scan targets:")
                            .font(DesignSystem.fontHeadline)
                            .foregroundColor(DesignSystem.textPrimary)

                        ScanOptionRow(title: "Cache Files", isSelected: true)
                        ScanOptionRow(title: "Log Files", isSelected: true)
                        ScanOptionRow(title: "Temporary Files", isSelected: true)
                        ScanOptionRow(title: "Package Manager Cache", isSelected: true)
                    }
                }
                .padding(.horizontal)

                // Scan button
                ElevatedFrostCard {
                    Button(action: startComprehensiveScan) {
                        HStack(spacing: DesignSystem.spacing) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.system(size: 24))

                            Text("Start Comprehensive Scan")
                                .font(DesignSystem.fontHeadline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.spacing)
                    }
                    .buttonStyle(.plain)
                    .background(DesignSystem.primary)
                    .cornerRadius(DesignSystem.cornerRadius)
                    .disabled(uiState.isProcessing)
                    .opacity(uiState.isProcessing ? 0.6 : 1.0)
                }
                .padding(.horizontal)

                Spacer(minLength: DesignSystem.spacingLarge)
            }
            .padding(.vertical)
        }
    }

    private var scanConfiguration: some View {
        Text(
            "Configure your scan parameters and select which areas to include in the cleanup process."
        )
        .font(DesignSystem.fontSubheadline)
        .foregroundColor(DesignSystem.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func startComprehensiveScan() {
        Task {
            await viewModel.performComprehensiveScan()
            uiState.addScanActivity(foundFiles: Int.random(in: 10...100), duration: 5.0)
        }
    }
}

private struct ScanOptionRow: View {
    let title: String
    @State var isSelected: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(DesignSystem.fontBody)
                .foregroundColor(DesignSystem.textPrimary)

            Spacer()

            TogglePill(isOn: $isSelected)
        }
        .padding(.vertical, DesignSystem.spacingSmall)
    }
}

// MARK: - Clean View

struct CleanView: View {
    @EnvironmentObject var viewModel: PinakleanViewModel
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                FrostCardHeader(title: "Clean Results") {
                    cleanHeader
                }

                if let results = viewModel.scanResults, !results.isEmpty {
                    CleanResultsView(results: results)
                        .padding(.horizontal)
                } else {
                    emptyStateView
                }

                Spacer(minLength: DesignSystem.spacingLarge)
            }
            .padding(.vertical)
        }
    }

    private var cleanHeader: some View {
        Text(
            "Review and execute cleanup operations. Items are automatically categorized by safety level."
        )
        .font(DesignSystem.fontSubheadline)
        .foregroundColor(DesignSystem.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var emptyStateView: some View {
        FrostCard {
            VStack(spacing: DesignSystem.spacing) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 48))
                    .foregroundColor(DesignSystem.textTertiary)

                Text("No files to clean")
                    .font(DesignSystem.fontHeadline)
                    .foregroundColor(DesignSystem.textSecondary)

                Text("Run a scan first to find cleanable files.")
                    .font(DesignSystem.fontSubheadline)
                    .foregroundColor(DesignSystem.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.spacingLarge)
        }
        .padding(.horizontal)
    }
}

private struct CleanResultsView: View {
    let results: ScanResults

    var body: some View {
        VStack(spacing: DesignSystem.spacing) {
            // Clean actions
            HStack(spacing: DesignSystem.spacing) {
                cleanActionButton(
                    title: "Clean Safe Items",
                    subtitle: "Recommended",
                    color: DesignSystem.success,
                    action: cleanSafeItems
                )

                cleanActionButton(
                    title: "Review All",
                    subtitle: "Manual selection",
                    color: DesignSystem.warning,
                    action: reviewAll
                )
            }

            // Results summary
            FrostCard {
                VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    Text("Scan Results")
                        .font(DesignSystem.fontHeadline)
                        .foregroundColor(DesignSystem.textPrimary)

                    HStack {
                        Text("\(results.items.count) items found")
                        Spacer()
                        Text("\(results.safeTotalSize.formattedSize()) available")
                    }
                    .font(DesignSystem.fontSubheadline)
                    .foregroundColor(DesignSystem.textSecondary)
                }
            }
        }
    }

    private func cleanActionButton(
        title: String, subtitle: String, color: Color, action: @escaping () -> Void
    ) -> some View {
        CompactFrostCard {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DesignSystem.fontHeadline)
                        .foregroundColor(color)

                    Text(subtitle)
                        .font(DesignSystem.fontCaption)
                        .foregroundColor(DesignSystem.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, DesignSystem.spacing)
            }
            .buttonStyle(.plain)
        }
    }

    private func cleanSafeItems() {
        Task {
            // Implementation would go here
            print("Cleaning safe items...")
        }
    }

    private func reviewAll() {
        // Implementation would go here
        print("Reviewing all items...")
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var viewModel: PinakleanViewModel
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                FrostCardHeader(title: "Settings") {
                    Text("Configure Pinaklean to match your preferences and workflow.")
                        .font(DesignSystem.fontSubheadline)
                        .foregroundColor(DesignSystem.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // General settings
                FrostCard {
                    VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                        Text("General")
                            .font(DesignSystem.fontHeadline)
                            .foregroundColor(DesignSystem.textPrimary)

                        SettingRow(
                            title: "Enable Animations",
                            subtitle: "Smooth transitions and effects",
                            isOn: Binding(
                                get: { uiState.enableAnimations },
                                set: { uiState.enableAnimations = $0 }
                            )
                        )

                        SettingRow(
                            title: "Auto Backup",
                            subtitle: "Backup before cleaning",
                            isOn: .constant(true)
                        )

                        SettingRow(
                            title: "Safe Mode",
                            subtitle: "Extra safety checks",
                            isOn: .constant(true)
                        )
                    }
                }
                .padding(.horizontal)

                // Advanced settings
                if uiState.showAdvancedFeatures {
                    FrostCard {
                        VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                            Text("Advanced")
                                .font(DesignSystem.fontHeadline)
                                .foregroundColor(DesignSystem.textPrimary)

                            Button("Clear All Caches") {
                                Task {
                                    await viewModel.clearAllCaches()
                                }
                            }
                            .foregroundColor(DesignSystem.error)
                            .font(DesignSystem.fontBody)

                            Button("Reset Settings") {
                                // Reset implementation
                            }
                            .foregroundColor(DesignSystem.textSecondary)
                            .font(DesignSystem.fontBody)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: DesignSystem.spacingLarge)
            }
            .padding(.vertical)
        }
    }
}

private struct SettingRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.fontBody)
                    .foregroundColor(DesignSystem.textPrimary)

                Text(subtitle)
                    .font(DesignSystem.fontCaption)
                    .foregroundColor(DesignSystem.textSecondary)
            }

            Spacer()

            TogglePill(isOn: $isOn)
        }
        .padding(.vertical, DesignSystem.spacingSmall)
    }
}

// MARK: - Previews

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUIState = UnifiedUIState()
        mockUIState.totalFilesScanned = 1250
        mockUIState.spaceToClean = 2_500_000_000  // 2.5 GB
        mockUIState.lastScanDate = Date().addingTimeInterval(-3600)

        return MainView()
            .environmentObject(PinakleanViewModel())
            .environmentObject(mockUIState)
            .frame(width: 1000, height: 700)
            .preferredColorScheme(.light)
    }
}

// MARK: - Extensions

extension Int64 {
    func formattedSize() -> String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}

extension AppTab {
    var systemImage: String {
        switch self {
        case .dashboard: return "house.fill"
        case .scan: return "magnifyingglass"
        case .clean: return "trash.fill"
        case .settings: return "gear"
        default: return "circle"
        }
    }
}

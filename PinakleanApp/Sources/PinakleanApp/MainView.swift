//
//  MainView.swift
//  PinakleanApp
//
//  Main application interface with Liquid Crystal design system
//  Provides navigation between dashboard, scan, clean, settings, and analytics
//
//  Created: UI Implementation Phase
//  Features: Tab-based navigation, Glassmorphic design, Responsive layout
//

import SwiftUI

/// Main application view implementing the "Liquid Crystal" design system
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
        .navigationTitle("🧹 Pinaklean")
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

                        Text(
                            "Keep your Mac clean and optimized with intelligent scanning and cleaning."
                        )
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
                                description:
                                    "Scanned (uiState.totalFilesScanned) files and found items to clean" ,
                                icon: "magnifyingglass"
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
                                description: "Cleaned files and freed up space",
                                icon: "trash.fill"
                            ))
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
}

// MARK: - Scan View

struct ScanView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            Text("Scan View")
                .font(DesignSystem.fontLargeTitle)
                .foregroundColor(DesignSystem.textPrimary)

            Text("Smart scan functionality coming soon...")
                .font(DesignSystem.fontBody)
                .foregroundColor(DesignSystem.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Clean View

struct CleanView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            Text("Clean View")
                .font(DesignSystem.fontLargeTitle)
                .foregroundColor(DesignSystem.textPrimary)

            Text("Clean results will be displayed here...")
                .font(DesignSystem.fontBody)
                .foregroundColor(DesignSystem.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            Text("Settings")
                .font(DesignSystem.fontLargeTitle)
                .foregroundColor(DesignSystem.textPrimary)

            Text("Application settings and preferences...")
                .font(DesignSystem.fontBody)
                .foregroundColor(DesignSystem.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Analytics View

struct AnalyticsView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            Text("Analytics")
                .font(DesignSystem.fontLargeTitle)
                .foregroundColor(DesignSystem.textPrimary)

            Text("Storage analytics and performance metrics...")
                .font(DesignSystem.fontBody)
                .foregroundColor(DesignSystem.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUIState = UnifiedUIState()

        MainView()
            .environmentObject(mockUIState)
            .frame(width: 1000, height: 700)
            .preferredColorScheme(.dark)
    }
}

//
//  AnalyticsDashboard.swift
//  PinakleanApp
//
//  Analytics dashboard for visualizing cleanup data, trends, and storage metrics
//  Features storage breakdown, performance metrics, and activity insights
//
//  Created: Analytics Implementation Phase
//  Features: Data visualization, Interactive charts, Trend analysis
//

import SwiftUI

/// Main analytics dashboard view
struct AnalyticsDashboard: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                // Header section
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

                // Storage breakdown section
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

                // Performance metrics section
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

                            Text(formatFileSize(uiState.spaceToClean))
                                .font(DesignSystem.fontLargeTitle)
                                .foregroundColor(DesignSystem.success)
                        }
                    }
                }
                .padding(.horizontal)

                // Experimental Charts Section
                if Self.isChartsEnabled(state: uiState) {
                    FrostCardHeader(title: "Experimental Visualizations") {
                        VStack {
                            SunburstChart()
                                .frame(height: 300)
                            SankeyDiagram()
                                .frame(height: 300)
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical)
        }
        .background(DesignSystem.gradientBackground)
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

// MARK: - Layout Helpers
extension AnalyticsDashboard {
    static func gridColumns(for size: ScreenSize) -> Int {
        switch size {
        case .compact: return 1
        case .regular: return 2
        case .large: return 3
        }
    }

    /// UI-043: Feature flag to enable/disable charts rendering
    static func isChartsEnabled(state: UnifiedUIState) -> Bool {
        state.showExperimentalCharts
    }
}

// MARK: - Supporting Views

/// Storage bar item component
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
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Preview

struct AnalyticsDashboard_Previews: PreviewProvider {
    static var previews: some View {
        let mockUIState = UnifiedUIState()
        mockUIState.totalFilesScanned = 150
        mockUIState.spaceToClean = 2_500_000_000
        mockUIState.storageBreakdown = StorageBreakdown(
            systemCache: 1_000_000_000,
            userCache: 500_000_000,
            logs: 300_000_000,
            temporaryFiles: 200_000_000,
            duplicates: 500_000_000
        )

        return AnalyticsDashboard()
            .environmentObject(mockUIState)
            .frame(width: 900, height: 700)
            .preferredColorScheme(.light)
    }
}

//
//  AnalyticsDashboard.swift
//  PinakleanApp
//
//  Analytics dashboard for visualizing cleanup data, trends, and storage metrics
//  Features interactive charts, storage breakdown, and performance metrics
//
//  Created: Analytics Implementation Phase
//  Features: Data visualization, Interactive charts, Trend analysis
//

import SwiftUI

/// Main analytics dashboard view
struct AnalyticsDashboard: View {
    @EnvironmentObject var uiState: UnifiedUIState
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedChartType: ChartType = .bar

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                // Header section
                FrostCard {
                    VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                        Text("Analytics Dashboard")
                            .font(DesignSystem.fontTitle)
                            .foregroundColor(DesignSystem.textPrimary)

                        Text("Track your cleaning performance and storage trends over time.")
                            .font(DesignSystem.fontSubheadline)
                            .foregroundColor(DesignSystem.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Controls section
                FrostCard {
                    VStack(spacing: DesignSystem.spacing) {
                        HStack {
                            Text("Time Range")
                                .font(DesignSystem.fontBody)
                                .foregroundColor(DesignSystem.textPrimary)

                            Picker("Time Range", selection: $selectedTimeRange) {
                                ForEach(TimeRange.allCases) { range in
                                    Text(range.displayName).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)

                            Spacer()

                            Text("Chart Type")
                                .font(DesignSystem.fontBody)
                                .foregroundColor(DesignSystem.textPrimary)

                            Picker("Chart Type", selection: $selectedChartType) {
                                ForEach(ChartType.allCases) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(.vertical)
                }

                // Charts section
                chartSection

                // Storage breakdown section
                storageBreakdownSection

                // Performance metrics section
                performanceMetricsSection
            }
            .padding()
        }
        .background(DesignSystem.gradientBackground)
    }

    private var chartSection: some View {
        FrostCard {
            VStack(spacing: DesignSystem.spacing) {
                Text("Cleanup Trends")
                    .font(DesignSystem.fontHeadline)
                    .foregroundColor(DesignSystem.textPrimary)

                // Chart view
                if let chartData = generateChartData() {
                    // Simple bar chart representation
                    VStack(spacing: DesignSystem.spacing) {
                        ForEach(Array(chartData.prefix(5)), id: \.date) { dataPoint in
                            HStack {
                                Text(dataPoint.date.formatted(.dateTime.month().day()))
                                    .font(DesignSystem.fontCaption)
                                    .foregroundColor(DesignSystem.textSecondary)
                                    .frame(width: 60, alignment: .leading)

                                GeometryReader { geometry in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(DesignSystem.primary.opacity(0.7))
                                        .frame(
                                            width: (dataPoint.size / 10_000_000)
                                                * geometry.size.width, height: 20)
                                }
                                .frame(height: 20)

                                Text(
                                    ByteCountFormatter.string(
                                        fromByteCount: Int64(dataPoint.size), countStyle: .file)

                                .font(DesignSystem.fontCaption)
                                .foregroundColor(DesignSystem.textPrimary)
                                .frame(width: 80, alignment: .trailing)
                            }
                        }
                    }
                    .frame(height: 200)
                } else {
                    Text("No data available")
                        .font(DesignSystem.fontBody)
                        .foregroundColor(DesignSystem.textSecondary)
                        .frame(height: 200)
                }
            }
        }
    }

    private var storageBreakdownSection: some View {
        FrostCard {
            VStack(spacing: DesignSystem.spacing) {
                Text("Storage Breakdown")
                    .font(DesignSystem.fontHeadline)
                    .foregroundColor(DesignSystem.textPrimary)

                let total = uiState.storageBreakdown.total
                let breakdown = uiState.storageBreakdown

                VStack(spacing: DesignSystem.spacing) {
                    StorageBarItem(
                        label: "System Cache",
                        value: breakdown.systemCache,
                        total: total,
                        color: .blue

                    StorageBarItem(
                        label: "User Cache",
                        value: breakdown.userCache,
                        total: total,
                        color: .green

                    StorageBarItem(
                        label: "Logs",
                        value: breakdown.logs,
                        total: total,
                        color: .orange

                    StorageBarItem(
                        label: "Temporary Files",
                        value: breakdown.temporaryFiles,
                        total: total,
                        color: .red

                    StorageBarItem(
                        label: "Duplicates",
                        value: breakdown.duplicates,
                        total: total,
                        color: .purple

                }
            }
        }
    }

    private var performanceMetricsSection: some View {
        HStack(spacing: DesignSystem.spacing) {
            CompactFrostCard {
                VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    Text("Average Clean Time")
                        .font(DesignSystem.fontBody)
                        .foregroundColor(DesignSystem.textSecondary)

                    Text("2.3 minutes")
                        .font(DesignSystem.fontLargeTitle)
                        .foregroundColor(DesignSystem.primary)
                }
            }

            CompactFrostCard {
                VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    Text("Files Cleaned Today")
                        .font(DesignSystem.fontBody)
                        .foregroundColor(DesignSystem.textSecondary)

                    Text("\(uiState.totalFilesScanned)")
                        .font(DesignSystem.fontLargeTitle)
                        .foregroundColor(DesignSystem.success)
                }
            }

            CompactFrostCard {
                VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    Text("Space Recovered")
                        .font(DesignSystem.fontBody)
                        .foregroundColor(DesignSystem.textSecondary)

                    Text(
                        ByteCountFormatter.string(
                            fromByteCount: uiState.spaceToClean, countStyle: .file)

                    .font(DesignSystem.fontLargeTitle)
                    .foregroundColor(DesignSystem.accent)
                }
            }
        }
    }

    private func generateChartData() -> [ChartDataPoint]? {
        // Generate sample chart data based on selected time range
        let calendar = Calendar.current
        let now = Date()
        let range: Int

        switch selectedTimeRange {
        case .week:
            range = 7
        case .month:
            range = 30
        case .year:
            range = 365
        }

        return (0..<range).map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: now) ?? now
            let size = Double.random(in: 1_000_000...50_000_000)  // Sample data in bytes
            return ChartDataPoint(date: date, size: size)
        }
    }
}

// MARK: - Supporting Views

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

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

enum ChartType: String, CaseIterable, Identifiable {
    case bar = "Bar"
    case line = "Line"
    case area = "Area"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

struct ChartDataPoint: Identifiable {
    var id = UUID()
    let date: Date
    let size: Double
}

// MARK: - Previews

private func createMockUIState() -> UnifiedUIState {
    let state = UnifiedUIState()
    state.totalFilesScanned = 150
    state.spaceToClean = 2_500_000_000
    state.storageBreakdown =
        systemCache: 1_000_000_000,
        userCache: 500_000_000,
        logs: 300_000_000,
        temporaryFiles: 200_000_000)
        duplicates: 500_000_000
    )
    return state
}

struct AnalyticsDashboard_Previews: PreviewProvider {
    static var previews: some View {
        let mockUIState = createMockUIState()










        AnalyticsDashboard()
            .environmentObject(mockUIState)
            .frame(width: 900, height: 700)
            .preferredColorScheme(.light)
    }
}

// MARK: - Extensions

extension AnalyticsDashboard {
    /// Analytics dashboard with custom title
    func title(_ title: String) -> some View {
        self.navigationTitle(title)
    }

    /// Analytics dashboard with custom time range
    func defaultTimeRange(_ range: TimeRange) -> some View {
        self.onAppear {
            selectedTimeRange = range
        }
    }
}

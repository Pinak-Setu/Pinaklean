//
//  AnalyticsDashboard.swift
//  PinakleanApp
//
//  Analytics dashboard for visualizing cleanup data, trends, and storage metrics
//  Features interactive charts, storage breakdown, advanced visualizations (Sunburst & Sankey), and performance metrics
//
//  Created: Analytics Implementation Phase
//  Features: Data visualization, Interactive charts, Trend analysis, Advanced 3D Charts
//

import Charts
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

                // Advanced Visualizations section
                advancedVisualizationsSection

                // Storage breakdown section
                storageBreakdownSection

                // Performance metrics section
                performanceMetricsSection
            }
            .padding()
        }
        .background(DesignSystem.gradientBackground)
    }

    private var advancedVisualizationsSection: some View {
        VStack(spacing: DesignSystem.spacing) {
            Text("Advanced Visualizations")
                .font(DesignSystem.fontHeadline)
                .foregroundColor(DesignSystem.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: DesignSystem.spacing) {
                // Sunburst Chart
                VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    Text("Storage Sunburst")
                        .font(DesignSystem.fontSubheadline)
                        .foregroundColor(DesignSystem.textSecondary)

                    SunburstChart(
                        data: generateSunburstData(),
                        centerText: "Disk Usage",
                        centerValue: formatFileSize(Int64(uiState.spaceToClean))
                    )
                    .frame(height: 300)
                }

                // Sankey Diagram
                VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    Text("Cleanup Flow")
                        .font(DesignSystem.fontSubheadline)
                        .foregroundColor(DesignSystem.textSecondary)

                    SankeyDiagram(
                        nodes: generateSankeyNodes(),
                        flows: generateSankeyFlows()
                    )
                    .frame(height: 300)
                }
            }
        }
    }

    private var chartSection: some View {
        FrostCard {
            VStack(spacing: DesignSystem.spacing) {
                Text("Cleanup Trends")
                    .font(DesignSystem.fontHeadline)
                    .foregroundColor(DesignSystem.textPrimary)

                // Chart view
                if let chartData = generateChartData() {
                    Chart {
                        ForEach(chartData) { dataPoint in
                            switch selectedChartType {
                            case .bar:
                                BarMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Size", dataPoint.size)
                                )
                                .foregroundStyle(DesignSystem.gradientPrimary)
                            case .line:
                                LineMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Size", dataPoint.size)
                                )
                                .foregroundStyle(DesignSystem.primary)
                                .lineStyle(StrokeStyle(lineWidth: 2))
                            case .area:
                                AreaMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Size", dataPoint.size)
                                )
                                .foregroundStyle(DesignSystem.gradientPrimary.opacity(0.3))
                            }
                        }
                    }
                    .frame(height: 300)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks(position: .bottom)
                    }
                } else {
                    Text("No data available")
                        .font(DesignSystem.fontBody)
                        .foregroundColor(DesignSystem.textSecondary)
                        .frame(height: 300)
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
                        label: "System Cache", value: breakdown.systemCache, total: total,
                        color: .blue)
                    StorageBarItem(
                        label: "User Cache", value: breakdown.userCache, total: total, color: .green
                    )
                    StorageBarItem(
                        label: "Logs", value: breakdown.logs, total: total, color: .orange)
                    StorageBarItem(
                        label: "Temporary Files", value: breakdown.temporaryFiles, total: total,
                        color: .red)
                    StorageBarItem(
                        label: "Duplicates", value: breakdown.duplicates, total: total,
                        color: .purple)
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

                    Text(formatFileSize(Int64(uiState.spaceToClean)))
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

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func generateSunburstData() -> [SunburstSegment] {
        let breakdown = uiState.storageBreakdown
        let total = breakdown.total

        return [
            SunburstSegment(
                id: 0, name: "System Cache", value: Double(breakdown.systemCache), color: .blue, level: 0),
            SunburstSegment(
                id: 1, name: "User Cache", value: Double(breakdown.userCache), color: .green, level: 0),
            SunburstSegment(id: 2, name: "Logs", value: Double(breakdown.logs), color: .orange, level: 1),
            SunburstSegment(
                id: 3, name: "Temporary", value: Double(breakdown.temporaryFiles), color: .red, level: 1),
            SunburstSegment(
                id: 4, name: "Duplicates", value: Double(breakdown.duplicates), color: .purple, level: 1),
        ].filter { $0.value > 0 }
    }

    private func generateSankeyNodes() -> [SankeyNode] {
        return [
            SankeyNode(id: 0, label: "Scanned Files", x: 0.1, y: 0.3, color: .blue),
            SankeyNode(id: 1, label: "Safe to Clean", x: 0.1, y: 0.7, color: .green),
            SankeyNode(
                id: 2, label: "Cleanup Engine", x: 0.5, y: 0.5, color: .orange),
            SankeyNode(id: 3, label: "Space Recovered", x: 0.9, y: 0.4, color: .purple),
            SankeyNode(id: 4, label: "Protected Files", x: 0.9, y: 0.8, color: .red),
        ]
    }

    private func generateSankeyFlows() -> [SankeyFlow] {
        let totalFiles = Double(uiState.totalFilesScanned)
        let safeFiles = Double.random(in: 0.3...0.7) * totalFiles  // Simulated data
        let protectedFiles = totalFiles - safeFiles

        return [
            SankeyFlow(id: 0, sourceId: 0, targetId: 2, value: safeFiles, color: .green),
            SankeyFlow(id: 1, sourceId: 1, targetId: 2, value: protectedFiles, color: .red),
            SankeyFlow(id: 2, sourceId: 2, targetId: 3, value: safeFiles * 0.8, color: .blue),
            SankeyFlow(id: 3, sourceId: 2, targetId: 4, value: protectedFiles, color: .orange),
        ]
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

                Text(formatFileSize(value))
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

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
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

struct AnalyticsDashboard_Previews: PreviewProvider {
    static var previews: some View {
        let mockUIState = UnifiedUIState()
        mockUIState.totalFilesScanned = 150
        mockUIState.spaceToClean = 2_500_000_000  // 2.5 GB
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

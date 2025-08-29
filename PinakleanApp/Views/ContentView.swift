import SwiftUI

/// Main Content View for Pinaklean Application
struct ContentView: View {
    @EnvironmentObject var engine: PinakleanEngine
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        LiquidGlass {
            NavigationSplitView {
                // Sidebar
                SidebarView()
            } detail: {
                // Main Content Area
                ZStack {
                    // Background
                    Color.clear

                    // Content based on current view
                    switch uiState.currentView {
                    case .dashboard:
                        DashboardView()
                    case .scan:
                        ScanView()
                    case .clean:
                        CleanView()
                    case .analyze:
                        AnalyzeView()
                    case .backup:
                        BackupView()
                    case .settings:
                        SettingsView()
                    }

                    // Inspector overlay
                    if uiState.inspectorVisible, let item = uiState.selectedInspectorItem {
                        InspectorView(item: item)
                            .transition(.move(edge: .trailing))
                    }
                }
                .animation(.spring(), value: uiState.currentView)
            }
        }
        .onAppear {
            // Initialize the engine when the view appears
            Task {
                do {
                    _ = try await PinakleanEngine()
                } catch {
                    print("Failed to initialize engine: \(error)")
                }
            }
        }
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundColor(DesignSystem.primary)

                Text("Pinaklean")
                    .font(DesignSystem.titleFont)
                    .foregroundColor(.primary)

                Text("Safe macOS Cleanup")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 24)

            // Navigation Items
            VStack(spacing: 4) {
                ForEach(SidebarItem.allCases, id: \.self) { item in
                    NavigationButton(
                        item: item,
                        isSelected: uiState.selectedSidebarItem == item
                    ) {
                        uiState.navigate(to: AppView(rawValue: item.rawValue) ?? .dashboard)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // Status Section
            VStack(spacing: 12) {
                // Quick Stats
                FrostCard(padding: DesignSystem.spacing) {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundColor(.secondary)
                            Text("CPU: \(Int(uiState.cpuUsage))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Image(systemName: "memorychip")
                                .foregroundColor(.secondary)
                            Text("Memory: \(Int(uiState.memoryUsage))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Notifications
                if !uiState.notifications.isEmpty {
                    Button(action: { uiState.showNotificationCenter = true }) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(DesignSystem.warning)
                            Text("\(uiState.notifications.count) notifications")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule()
                                .fill(DesignSystem.glassBackground)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(minWidth: 240, maxWidth: 280)
        .background(
            Color.black.opacity(0.2)
                .blur(radius: 20)
        )
    }
}

// MARK: - Navigation Button
struct NavigationButton: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? DesignSystem.primary : .secondary)
                    .frame(width: 20)

                Text(item.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? .primary : .secondary)

                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.borderRadius)
                    .fill(isSelected ? DesignSystem.primary.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var engine: PinakleanEngine
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.largePadding) {
                // Header
                VStack(spacing: 8) {
                    Text("Welcome to Pinaklean")
                        .font(DesignSystem.titleFont)
                        .foregroundColor(.primary)

                    Text("Intelligent disk cleanup for developers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, DesignSystem.largePadding)

                // Quick Actions
                VStack(spacing: DesignSystem.padding) {
                    Text("Quick Actions")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: DesignSystem.padding) {
                        ActionButton(
                            title: "Smart Scan",
                            icon: "magnifyingglass",
                            style: .primary
                        ) {
                            uiState.navigate(to: .scan)
                        }

                        ActionButton(
                            title: "Auto Clean",
                            icon: "sparkles",
                            style: .secondary
                        ) {
                            Task {
                                do {
                                    let results = try await engine.scan()
                                    uiState.scanResults = results
                                    uiState.navigate(to: .clean)
                                } catch {
                                    print("Scan failed: \(error)")
                                }
                            }
                        }
                    }

                    ActionButton(
                        title: "Analyze Storage",
                        icon: "chart.bar.fill",
                        style: .secondary
                    ) {
                        uiState.navigate(to: .analyze)
                    }
                }

                // Recent Activity
                if let scanResults = uiState.scanResults {
                    VStack(spacing: DesignSystem.padding) {
                        Text("Recent Scan Results")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        FrostCard {
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Files Found")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(scanResults.items.count)")
                                            .font(.title2)
                                            .foregroundColor(.primary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing) {
                                        Text("Space Available")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        let safeSize = ByteCountFormatter.string(
                                            fromByteCount: scanResults.safeTotalSize,
                                            countStyle: .file
                                        )
                                        Text(safeSize)
                                            .font(.title2)
                                            .foregroundColor(DesignSystem.success)
                                    }
                                }

                                ProgressView(
                                    value: Double(scanResults.safeTotalSize),
                                    total: Double(scanResults.totalSize)
                                )
                                    .tint(DesignSystem.success)
                            }
                        }
                    }
                }

                // Recommendations
                if !uiState.recommendations.isEmpty {
                    VStack(spacing: DesignSystem.padding) {
                        Text("Recommended Actions")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(uiState.recommendations.prefix(3)) { recommendation in
                            RecommendationCard(recommendation: recommendation)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.largePadding)
            .padding(.bottom, DesignSystem.largePadding)
        }
    }
}

// MARK: - Recommendation Card
struct RecommendationCard: View {
    let recommendation: CleaningRecommendation

    var body: some View {
        FrostCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iconForRisk(recommendation.riskLevel))
                        .foregroundColor(colorForRisk(recommendation.riskLevel))

                    Text(recommendation.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(recommendation.formattedSpace)
                        .font(.caption)
                        .foregroundColor(DesignSystem.success)
                }

                Text(recommendation.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    StatusBadge(status: .info, text: "\(Int(recommendation.confidence * 100))% confidence")

                    Spacer()

                    Text("\(recommendation.items.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func iconForRisk(_ risk: RiskLevel) -> String {
        switch risk {
        case .low: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "xmark.circle.fill"
        }
    }

    private func colorForRisk(_ risk: RiskLevel) -> Color {
        switch risk {
        case .low: return DesignSystem.success
        case .medium: return DesignSystem.warning
        case .high: return DesignSystem.error
        }
    }
}

// MARK: - Placeholder Views
struct ScanView: View {
    var body: some View {
        VStack {
            Text("Scan View")
                .font(.largeTitle)
            Text("Coming Soon")
                .foregroundColor(.secondary)
        }
    }
}

struct CleanView: View {
    var body: some View {
        VStack {
            Text("Clean View")
                .font(.largeTitle)
            Text("Coming Soon")
                .foregroundColor(.secondary)
        }
    }
}

struct AnalyzeView: View {
    var body: some View {
        VStack {
            Text("Analyze View")
                .font(.largeTitle)
            Text("Coming Soon")
                .foregroundColor(.secondary)
        }
    }
}

struct BackupView: View {
    var body: some View {
        VStack {
            Text("Backup View")
                .font(.largeTitle)
            Text("Coming Soon")
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.largePadding) {
                Text("Settings")
                    .font(DesignSystem.titleFont)
                    .foregroundColor(.primary)

                VStack(spacing: DesignSystem.padding) {
                    TogglePill(
                        isOn: .constant(uiState.glassEffectEnabled),
                        title: "Glass Effects",
                        subtitle: "Enable glassmorphic design elements",
                        icon: "sparkles"
                    )

                    TogglePill(
                        isOn: .constant(uiState.animationsEnabled),
                        title: "Animations",
                        subtitle: "Enable smooth transitions and effects",
                        icon: "wand.and.stars"
                    )

                    TogglePill(
                        isOn: .constant(uiState.sidebarVisible),
                        title: "Show Sidebar",
                        subtitle: "Display navigation sidebar",
                        icon: "sidebar.left"
                    )
                }

                Spacer()
            }
            .padding(.horizontal, DesignSystem.largePadding)
            .padding(.top, DesignSystem.largePadding)
        }
    }
}

// MARK: - Inspector View
struct InspectorView: View {
    let item: CleanableItem
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            FrostCard(padding: DesignSystem.largePadding) {
                VStack(alignment: .leading, spacing: DesignSystem.padding) {
                    // Header
                    HStack {
                        Text("File Details")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        Button(action: { uiState.inspectorVisible = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()

                    // File Information
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Name", value: item.name)
                        DetailRow(label: "Path", value: item.path)
                        DetailRow(label: "Category", value: item.category)
                        DetailRow(label: "Size", value: item.formattedSize)

                        if let modified = item.lastModified {
                            let modifiedStr = DateFormatter.localizedString(
                                from: modified,
                                dateStyle: .medium,
                                timeStyle: .short
                            )
                            DetailRow(label: "Modified", value: modifiedStr)
                        }

                        HStack {
                            Text("Safety Score:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            let safetyStatus: StatusBadge.Status = item.safetyScore >= 70 ? .safe :
                                item.safetyScore >= 40 ? .warning : .danger
                            StatusBadge(status: safetyStatus, text: "\(item.safetyScore)%")
                        }
                    }

                    Divider()

                    // Actions
                    VStack(spacing: 8) {
                        ActionButton(title: "Reveal in Finder", icon: "folder", style: .secondary) {
                            NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
                        }

                        ActionButton(title: "Copy Path", icon: "doc.on.doc", style: .secondary) {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(item.path, forType: .string)
                        }
                    }
                }
            }
            .frame(width: 400)
        }
        .background(
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    uiState.inspectorVisible = false
                }
        )
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PinakleanEngine())
            .environmentObject(UnifiedUIState())
    }
}

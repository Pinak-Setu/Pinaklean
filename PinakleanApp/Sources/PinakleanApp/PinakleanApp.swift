import SwiftUI

enum AppStrings {
    static let appTitle = "Pinaklean"
}

@main
struct PinakleanApp: App {
    @StateObject private var uiState = UnifiedUIState()

    var body: some Scene {
        WindowGroup {
            MainShellView()
                .environmentObject(uiState)
                .frame(minWidth: 1000, minHeight: 700)
        }

        MenuBarExtra("🏹") {
            MenuBarContent()
        }
    }
}

// MARK: - Main Shell

private struct MainShellView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
            ZStack {
            // Background
            LiquidGlass()

            // Content
            VStack(spacing: 0) {
                // Top toolbar/title
                HStack {
                    Text("🧹 \(AppStrings.appTitle)")
                        .font(DesignSystem.fontTitle)
                        .foregroundColor(DesignSystem.textPrimary)
                    Spacer()
                }
                .padding()

                // Active tab content
                Group {
                    switch uiState.currentTab {
                    case .dashboard:
                        AnalyticsDashboard()
                            .environmentObject(uiState)
                    case .scan:
                        ScanView()
                            .environmentObject(uiState)
                    case .recommendations:
                        RecommendationsView()
                            .environmentObject(uiState)
                    case .clean:
                        CleanView()
                            .environmentObject(uiState)
                    case .settings:
                        CheckForUpdatesView()
                    case .analytics:
                        AnalyticsDashboard()
                            .environmentObject(uiState)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)

                // Custom tab bar
                CustomTabBar(selectedTab: $uiState.currentTab)
                    .padding(.bottom)
            }
        }
    }
}

// MARK: - Clean View

private struct CleanView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            // Header
            HStack {
                Text("Clean Files")
                    .font(DesignSystem.fontTitle)
                    .foregroundColor(DesignSystem.textPrimary)
                Spacer()
            }
            .padding(.horizontal)

            // Options
            VStack(spacing: DesignSystem.spacingMedium) {
                FrostCard {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        Text("Cleaning Options")
                            .font(DesignSystem.fontHeadline)
                            .foregroundColor(DesignSystem.textPrimary)

                        HStack {
                            Text("Dry Run (Safe Preview)")
                                .font(DesignSystem.fontBody)
                                .foregroundColor(DesignSystem.textPrimary)
                            Spacer()
                            Toggle("", isOn: $uiState.enableDryRun)
                                .toggleStyle(SwitchToggleStyle())
                                .onChange(of: uiState.enableDryRun) { newValue in
                                    uiState.setDryRun(newValue)
                                }
                        }

                        Text("When enabled, shows what would be cleaned without actually deleting files")
                            .font(DesignSystem.fontCaption)
                            .foregroundColor(DesignSystem.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                Divider()
                            .padding(.vertical, DesignSystem.spacingSmall)

                        HStack {
                            Text("Create Backup Before Cleaning")
                                .font(DesignSystem.fontBody)
                                .foregroundColor(DesignSystem.textPrimary)
                            Spacer()
                            Toggle("", isOn: $uiState.enableBackup)
                                .toggleStyle(SwitchToggleStyle())
                                .onChange(of: uiState.enableBackup) { newValue in
                                    uiState.setBackup(newValue)
                                }
                        }

                        Text("Creates a backup archive of files before deletion for safety")
                            .font(DesignSystem.fontCaption)
                            .foregroundColor(DesignSystem.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal)

            // Selected items summary
            if uiState.selectedCount > 0 {
                FrostCard {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                        HStack {
                            Text("Selected Items")
                                .font(DesignSystem.fontHeadline)
                                .foregroundColor(DesignSystem.textPrimary)
                            Spacer()
                            Text("\(uiState.selectedCount) items")
                                .font(DesignSystem.fontCaption)
                                .foregroundColor(DesignSystem.textSecondary)
                        }

                        // Clean button
                        Button(action: { uiState.startClean() }) {
                            HStack {
                                Image(systemName: uiState.enableDryRun ? "eye" : "trash")
                                Text(uiState.enableDryRun ? "Preview Clean" : "Clean Files")
                                    .font(DesignSystem.fontBody)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(uiState.canStartClean ? DesignSystem.primary : DesignSystem.textTertiary)
                            .cornerRadius(8)
                        }
                        .disabled(!uiState.canStartClean)
                        .padding(.top, DesignSystem.spacingSmall)
                    }
                }
                .padding(.horizontal)
            } else {
                // No selection placeholder
                VStack(spacing: DesignSystem.spacingMedium) {
                    Spacer()
                    Text("No items selected")
                        .font(DesignSystem.fontHeadline)
                        .foregroundColor(DesignSystem.textSecondary)
                    Text("Select items from the Scan tab to clean them")
                        .font(DesignSystem.fontBody)
                        .foregroundColor(DesignSystem.textTertiary)
                    Spacer()
                }
            }

            Spacer()
        }
    }
}

// MARK: - Duplicate Groups Section

private struct DuplicateGroupsSection: View {
    let items: [CleanableItem]
    private let detector = DuplicateDetector()

    private var duplicateGroups: [DuplicateGroup] {
        detector.getTopDuplicateGroups(in: items, count: 3)
    }

    private var totalWastedSpace: Int64 {
        detector.calculateTotalWastedSpace(in: items)
    }

    var body: some View {
        if !duplicateGroups.isEmpty {
            FrostCard {
                VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                    // Header with total wasted space
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Duplicate Files Found")
                                .font(DesignSystem.fontHeadline)
                                .foregroundColor(DesignSystem.textPrimary)

                            Text("\(duplicateGroups.count) groups • \(totalWastedSpace.formattedSize()) wasted space")
                                .font(DesignSystem.fontCaption)
                                .foregroundColor(DesignSystem.warning)
                        }

                        Spacer()

                        // Duplicate icon
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 24))
                            .foregroundColor(DesignSystem.primary)
                    }

                    // Top duplicate groups
                    VStack(spacing: DesignSystem.spacingSmall) {
                        ForEach(Array(duplicateGroups.enumerated()), id: \.element.duplicates.first?.id) { index, group in
                            DuplicateGroupRow(group: group, rank: index + 1)
                        }
                    }

                    // Action button
                    Button(action: { /* Navigate to full duplicates view */ }) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("View All Duplicates")
                        }
                        .font(DesignSystem.fontBody)
                        .foregroundColor(DesignSystem.primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(DesignSystem.primary.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .padding(.top, DesignSystem.spacingSmall)
                }
            }
        }
    }
}

private struct DuplicateGroupRow: View {
    let group: DuplicateGroup
    let rank: Int

    var body: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(DesignSystem.surface.opacity(0.5))
                    .frame(width: 28, height: 28)

                Text("\(rank)")
                    .font(DesignSystem.fontCaption)
                    .foregroundColor(DesignSystem.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(group.duplicates.count) identical files")
                        .font(DesignSystem.fontBody)
                        .foregroundColor(DesignSystem.textPrimary)

                    if let primaryFile = group.primaryFile {
                        Text("(\(primaryFile.name))")
                            .font(DesignSystem.fontCaption)
                            .foregroundColor(DesignSystem.textSecondary)
                            .lineLimit(1)
                    }
                }

                Text("\(group.wastedSpace.formattedSize()) wasted space")
                    .font(DesignSystem.fontCaption)
                    .foregroundColor(DesignSystem.warning)
            }

            Spacer()

            // File type icon
            if let primaryFile = group.primaryFile {
                Image(systemName: getFileIcon(for: primaryFile.name))
                    .font(.system(size: 20))
                    .foregroundColor(DesignSystem.textSecondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(DesignSystem.surface.opacity(0.3))
        .cornerRadius(8)
    }

    private func getFileIcon(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()

        switch ext {
        case "txt", "doc", "pdf": return "doc.text"
        case "jpg", "png", "gif": return "photo"
        case "mp4", "mov", "avi": return "video"
        case "mp3", "wav", "aac": return "music.note"
        case "zip", "rar", "7z": return "archivebox"
        default: return "doc"
        }
    }
}

// MARK: - Recommendations View

private struct RecommendationsView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            // Header
            HStack {
                Text("Smart Recommendations")
                    .font(DesignSystem.fontTitle)
                    .foregroundColor(DesignSystem.textPrimary)
                Spacer()
                if let recommendations = uiState.recommendations {
                    Text("\(recommendations.count) suggestions")
                        .font(DesignSystem.fontCaption)
                        .foregroundColor(DesignSystem.textSecondary)
                }
            }
            .padding(.horizontal)

            // Recommendations content
            if let recommendations = uiState.recommendations, !recommendations.isEmpty {
                ScrollView {
                    VStack(spacing: DesignSystem.spacingMedium) {
                        ForEach(recommendations) { recommendation in
                            RecommendationCard(recommendation: recommendation)
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                // No recommendations state
                VStack(spacing: DesignSystem.spacingMedium) {
                    Spacer()
                    Text("No recommendations available")
                        .font(DesignSystem.fontHeadline)
                        .foregroundColor(DesignSystem.textSecondary)
                    Text("Run a scan to get personalized cleaning suggestions")
                        .font(DesignSystem.fontBody)
                        .foregroundColor(DesignSystem.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
            }
        }
    }
}

private struct RecommendationCard: View {
    let recommendation: CleaningRecommendation

    var body: some View {
        FrostCard {
            VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                // Header with priority badge
                HStack {
                    Text(recommendation.title)
                        .font(DesignSystem.fontHeadline)
                        .foregroundColor(DesignSystem.textPrimary)

                    Spacer()

                    PriorityBadge(priority: recommendation.priority)
                }

                // Description
                Text(recommendation.description)
                    .font(DesignSystem.fontBody)
                    .foregroundColor(DesignSystem.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Space savings
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundColor(DesignSystem.primary)
                    Text("Save \(recommendation.estimatedSpace.formattedSize())")
                        .font(DesignSystem.fontCaption)
                        .foregroundColor(DesignSystem.primary)
                }

                // Item count if applicable
                if !recommendation.items.isEmpty {
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(DesignSystem.textSecondary)
                        Text("\(recommendation.items.count) items")
                            .font(DesignSystem.fontCaption)
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                }

                // Action buttons
                HStack(spacing: DesignSystem.spacingMedium) {
                    Button(action: { applyRecommendation() }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Apply")
                        }
                        .font(DesignSystem.fontBody)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(DesignSystem.success)
                        .cornerRadius(6)
                    }

                    Button(action: { dismissRecommendation() }) {
                        Text("Skip")
                            .font(DesignSystem.fontBody)
                            .foregroundColor(DesignSystem.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(DesignSystem.surface.opacity(0.5))
                            .cornerRadius(6)
                    }
                }
                .padding(.top, DesignSystem.spacingSmall)
            }
        }
    }

    private func applyRecommendation() {
        // TODO: Implement recommendation application logic
        print("Applying recommendation: \(recommendation.title)")
    }

    private func dismissRecommendation() {
        // TODO: Implement recommendation dismissal logic
        print("Dismissing recommendation: \(recommendation.title)")
    }
}

private struct PriorityBadge: View {
    let priority: CleaningRecommendation.RecommendationPriority

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priority.color)
                .frame(width: 8, height: 8)

            Text(priority.displayName)
                .font(DesignSystem.fontCaption)
                .foregroundColor(priority.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priority.color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Scan View

private struct ScanView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            // Header
            HStack {
                Text("Scan Results")
                    .font(DesignSystem.fontTitle)
                    .foregroundColor(DesignSystem.textPrimary)
                Spacer()
                Button(action: { uiState.startScan() }) {
                    Text(uiState.isScanning ? "Scanning..." : "Start Scan")
                        .font(DesignSystem.fontBody)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(uiState.canStartScan ? DesignSystem.primary : DesignSystem.textTertiary)
                        .cornerRadius(8)
                }
                .disabled(!uiState.canStartScan)
            }
            .padding(.horizontal)

            // Progress bar if scanning
            if uiState.isScanning {
                VStack(spacing: DesignSystem.spacingSmall) {
                    ProgressView(value: uiState.scanProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.horizontal)
                    Text("Scanning... \(Int(uiState.scanProgress * 100))%")
                        .font(DesignSystem.fontCaption)
                        .foregroundColor(DesignSystem.textSecondary)
                }
            }

            // Scan results
            if let results = uiState.scanResults {
                ScrollView {
                    VStack(spacing: DesignSystem.spacingMedium) {
                        // Duplicate groups section (top 3 most wasteful)
                        DuplicateGroupsSection(items: results.items)

                        ForEach(results.itemsByCategory.keys.sorted(), id: \.self) { category in
                            ScanCategorySection(category: category, items: results.itemsByCategory[category] ?? [])
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                // No results placeholder
                VStack(spacing: DesignSystem.spacingMedium) {
                    Spacer()
                    Text("No scan results yet")
                        .font(DesignSystem.fontHeadline)
                        .foregroundColor(DesignSystem.textSecondary)
                    Text("Click 'Start Scan' to find cleanable files")
                        .font(DesignSystem.fontBody)
                        .foregroundColor(DesignSystem.textTertiary)
                    Spacer()
                }
            }
        }
    }
}

private struct ScanCategorySection: View {
    let category: String
    let items: [CleanableItem]

    var body: some View {
        FrostCard {
            VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                HStack {
                    Text(category.capitalized)
                        .font(DesignSystem.fontHeadline)
                        .foregroundColor(DesignSystem.textPrimary)
                    Spacer()
                    Text("\(items.count) items")
                        .font(DesignSystem.fontCaption)
                        .foregroundColor(DesignSystem.textSecondary)
                }

                ForEach(items) { item in
                    ScanItemRow(item: item)
                }
            }
        }
    }
}

private struct ScanItemRow: View {
    let item: CleanableItem
    @State private var showDetailedExplanation = false

    private let detector = SmartDetector()
    private let ragManager = RAGManager()

    private var enhancedScore: Int {
        detector.enhanceSafetyScore(for: item)
    }

    private var badgeText: String {
        detector.generateSafetyBadgeText(for: enhancedScore)
    }

    private var quickTooltipText: String {
        detector.generateScoreTooltip(for: item, enhancedScore: enhancedScore)
    }

    private var detailedExplanation: String {
        ragManager.generateExplanation(for: item)
    }

    private var quickSummary: String {
        ragManager.getQuickSummary(for: item)
    }

    var body: some View {
        HStack(spacing: DesignSystem.spacingMedium) {
            // Enhanced safety badge with tooltip
            EnhancedSafetyBadge(score: enhancedScore, badgeText: badgeText)
                .onTapGesture {
                    showDetailedExplanation.toggle()
                }
                .popover(isPresented: $showDetailedExplanation) {
                    DetailedItemExplanationView(
                        item: item,
                        enhancedScore: enhancedScore,
                        explanation: detailedExplanation
                    )
                    .frame(maxWidth: 350, maxHeight: 400)
                    .presentationCompactAdaptation(.popover)
                }
                .help(quickSummary) // Quick tooltip on hover

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.name)
                        .font(DesignSystem.fontBody)
                        .foregroundColor(DesignSystem.textPrimary)

                    if enhancedScore != item.safetyScore {
                        Text("(\(enhancedScore - item.safetyScore > 0 ? "+" : "")\(enhancedScore - item.safetyScore))")
                            .font(DesignSystem.fontCaption)
                            .foregroundColor(enhancedScore > item.safetyScore ? DesignSystem.success : DesignSystem.error)
                    }
                }

                Text(item.path)
                    .font(DesignSystem.fontCaption)
                    .foregroundColor(DesignSystem.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.size.formattedSize())
                    .font(DesignSystem.fontCaption)
                    .foregroundColor(DesignSystem.textSecondary)

                Text("\(enhancedScore)% safe")
                    .font(DesignSystem.fontCaption)
                    .foregroundColor(getScoreColor(enhancedScore))
            }

            if item.isRecommended {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignSystem.success)
                    .font(.system(size: 14))
            }

            // Info button for detailed explanation
            Button(action: { showDetailedExplanation.toggle() }) {
                Image(systemName: "info.circle")
                    .foregroundColor(DesignSystem.primary)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
            .help("View detailed analysis")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(item.isRecommended ? DesignSystem.success.opacity(0.1) : DesignSystem.surface.opacity(0.5))
        )
    }

    private func getScoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return DesignSystem.success
        case 60..<80: return DesignSystem.primary
        case 40..<60: return DesignSystem.warning
        case 0..<40: return DesignSystem.error
        default: return DesignSystem.textSecondary
        }
    }
}

private struct DetailedItemExplanationView: View {
    let item: CleanableItem
    let enhancedScore: Int
    let explanation: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("File Analysis")
                            .font(DesignSystem.fontHeadline)
                            .foregroundColor(DesignSystem.textPrimary)

                        Text(item.name)
                            .font(DesignSystem.fontTitle)
                            .foregroundColor(DesignSystem.primary)
                    }

                    Spacer()

                    EnhancedSafetyBadge(score: enhancedScore, badgeText: "")
                        .scaleEffect(1.2)
                }

                Divider()

                // Detailed explanation
                VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    ForEach(explanation.split(separator: "\n"), id: \.self) { line in
                        if line.contains("📍") || line.contains("📄") || line.contains("🛡️") || line.contains("💾") {
                            // Context lines with emojis
                            HStack(alignment: .top, spacing: DesignSystem.spacingSmall) {
                                Text(line)
                                    .font(DesignSystem.fontBody)
                                    .foregroundColor(DesignSystem.textPrimary)
                                    .lineSpacing(4)
                            }
                        } else if line.contains("💡") {
                            // Recommendation line
                            Text(line)
                                .font(DesignSystem.fontHeadline)
                                .foregroundColor(DesignSystem.primary)
                                .padding(.top, DesignSystem.spacingSmall)
                        } else {
                            // Regular text
                            Text(line)
                                .font(DesignSystem.fontBody)
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                    }
                }

                Divider()

                // File details
                VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                    Text("File Details")
                        .font(DesignSystem.fontHeadline)
                        .foregroundColor(DesignSystem.textPrimary)

                    HStack {
                        Text("Location:")
                            .font(DesignSystem.fontBody)
                            .foregroundColor(DesignSystem.textSecondary)
                        Text(item.path)
                            .font(DesignSystem.fontBody)
                            .foregroundColor(DesignSystem.textPrimary)
                            .lineLimit(2)
                    }

                    HStack {
                        Text("Size:")
                            .font(DesignSystem.fontBody)
                            .foregroundColor(DesignSystem.textSecondary)
                        Text(item.size.formattedSize())
                            .font(DesignSystem.fontBody)
                            .foregroundColor(DesignSystem.textPrimary)
                    }

                    HStack {
                        Text("Category:")
                            .font(DesignSystem.fontBody)
                            .foregroundColor(DesignSystem.textSecondary)
                        Text(item.category.capitalized)
                            .font(DesignSystem.fontBody)
                            .foregroundColor(DesignSystem.textPrimary)
                    }

                    HStack {
                        Text("Safety Score:")
                            .font(DesignSystem.fontBody)
                            .foregroundColor(DesignSystem.textSecondary)
                        Text("\(enhancedScore)/100")
                            .font(DesignSystem.fontBody)
                            .foregroundColor(getScoreColor(enhancedScore))
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(DesignSystem.spacingMedium)
        }
    }

    private func getScoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return DesignSystem.success
        case 60..<80: return DesignSystem.primary
        case 40..<60: return DesignSystem.warning
        case 0..<40: return DesignSystem.error
        default: return DesignSystem.textSecondary
        }
    }
}

private struct SafetyBadge: View {
    let level: SafetyLevel

    var body: some View {
        ZStack {
            Circle()
                .fill(level.color)
                .frame(width: 24, height: 24)

            Text(level.symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

private struct EnhancedSafetyBadge: View {
    let score: Int
    let badgeText: String

    private var badgeColor: Color {
        switch score {
        case 80...100: return DesignSystem.success
        case 60..<80: return DesignSystem.primary
        case 40..<60: return DesignSystem.warning
        case 0..<40: return DesignSystem.error
        default: return DesignSystem.textSecondary
        }
    }

    private var symbol: String {
        switch score {
        case 80...100: return "🛡️"
        case 60..<80: return "✓"
        case 40..<60: return "⚠️"
        case 20..<40: return "!"
        case 0..<20: return "🚫"
        default: return "?"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(badgeColor.opacity(0.2))
                .frame(width: 32, height: 32)

            Circle()
                .stroke(badgeColor, lineWidth: 2)
                .frame(width: 28, height: 28)

            VStack(spacing: 1) {
                Text(symbol)
                    .font(.system(size: 10))

                Text("\(score)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(badgeColor)
            }
        }
        .frame(width: 32, height: 32)
    }
}



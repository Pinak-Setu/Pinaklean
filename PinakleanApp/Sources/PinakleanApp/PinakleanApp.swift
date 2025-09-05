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
// MainShellView is defined in UI/MainShellView.swift

// UI-036: Public ContentView shell wrapper for tests/previews
public struct ContentView: View {
    @StateObject private var uiState = UnifiedUIState()
    public init() {}
    public var body: some View {
        MainShellView().environmentObject(uiState)
    }
}

// MARK: - Clean View
// CleanView is defined in UI/CleanView.swift

// MARK: - Duplicate Groups Section
// DuplicateGroupsSection is defined in UI/DuplicateGroupsSection.swift

// MARK: - Recommendations View
// RecommendationsView is defined in UI/RecommendationsView.swift

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
// ScanView is defined in UI/ScanView.swift

// ScanCategorySection, ScanItemRow, DetailedItemExplanationView, SafetyBadge, and EnhancedSafetyBadge
// are defined in their respective UI/ files



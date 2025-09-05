import SwiftUI

/// A view that displays smart recommendations for file cleaning.
struct RecommendationsView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            // Header
            HStack {
                Text("Smart Recommendations")
                    .font(DesignSystem.fontTitle)
                    .foregroundColor(DesignSystem.textPrimary)
                Spacer()
            }
            .padding(.horizontal)

            // Recommendations content
            VStack(spacing: DesignSystem.spacingMedium) {
                FrostCard {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        Text("AI-Powered Suggestions")
                            .font(DesignSystem.fontHeadline)
                            .foregroundColor(DesignSystem.textPrimary)

                        Text("Get intelligent recommendations for cleaning your files based on usage patterns, file types, and storage optimization.")
                            .font(DesignSystem.fontBody)
                            .foregroundColor(DesignSystem.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        // Placeholder for recommendations
                        Text("Recommendations will appear here after your first scan.")
                            .font(DesignSystem.fontCaption)
                            .foregroundColor(DesignSystem.textTertiary)
                            .padding(.top, DesignSystem.spacingSmall)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}


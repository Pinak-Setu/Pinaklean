import SwiftUI

/// Full settings view using the Liquid Crystal design system
struct SettingsView: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacing) {
                FrostCardHeader(title: "Appearance") {
                    VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                        Toggle("Enable Animations", isOn: $uiState.enableAnimations)
                        Toggle("Show Advanced Features", isOn: $uiState.showAdvancedFeatures)
                        Toggle("Show Experimental Charts", isOn: $uiState.showExperimentalCharts)
                    }
                }

                FrostCardHeader(title: "Notifications") {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                        Text("Enable system notifications for key events like cleanup completion.")
                            .font(DesignSystem.fontCallout)
                            .foregroundColor(DesignSystem.textSecondary)
                        HStack(spacing: DesignSystem.spacing) {
                            Button("Request Permission") {
                                NotificationManager.shared.requestAuthorization()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Test Notification") {
                                NotificationManager.shared.notifyCleanupComplete(
                                    spaceFreed: 1_234_567_890,
                                    itemsCleaned: 42
                                )
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                FrostCardHeader(title: "Updates") {
                    CheckForUpdatesView()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .background(DesignSystem.gradientBackground)
    }
}



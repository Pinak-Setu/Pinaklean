import SwiftUI

/// Full settings view using the Liquid Crystal design system
struct SettingsView: View {
    @EnvironmentObject var uiState: UnifiedUIState
    @State private var selection: TestFilter = .one

    enum TestFilter: String, CaseIterable, Identifiable {
        case one, two, three
        var id: String { self.rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.spacingLarge) {
                SimpleFilterSegmentedControl(selection: $selection, options: TestFilter.allCases)
                // Cleaning Settings
                FrostCardHeader(title: "🧹 Cleaning Options") {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        Text("Configure how Pinaklean handles file cleaning operations.")
                            .font(DesignSystem.fontBody)
                            .foregroundColor(DesignSystem.textSecondary)

                        // Dry Run Toggle
                        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                            HStack {
                                Text("Dry Run Mode")
                                    .font(DesignSystem.fontHeadline)
                                    .foregroundColor(DesignSystem.textPrimary)
                                Spacer()
                                TogglePill(isOn: $uiState.enableDryRun)
                            }

                            Text("Preview cleaning operations without actually deleting files. Perfect for testing and verification.")
                                .font(DesignSystem.fontCaption)
                                .foregroundColor(DesignSystem.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Divider()
                            .padding(.vertical, DesignSystem.spacingSmall)

                        // Backup Toggle
                        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                            HStack {
                                Text("Create Backup")
                                    .font(DesignSystem.fontHeadline)
                                    .foregroundColor(DesignSystem.textPrimary)
                                Spacer()
                                TogglePill(isOn: $uiState.enableBackup)
                            }

                            Text("Automatically create backup archives before deleting files for safety.")
                                .font(DesignSystem.fontCaption)
                                .foregroundColor(DesignSystem.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                // Appearance Settings
                FrostCardHeader(title: "🎨 Appearance") {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        Text("Customize the visual experience and interface behavior.")
                            .font(DesignSystem.fontBody)
                            .foregroundColor(DesignSystem.textSecondary)

                        // Animations Toggle
                        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                            HStack {
                                Text("Enable Animations")
                                    .font(DesignSystem.fontHeadline)
                                    .foregroundColor(DesignSystem.textPrimary)
                                Spacer()
                                TogglePill(isOn: $uiState.enableAnimations)
                            }

                            Text("Smooth transitions and visual effects throughout the interface.")
                                .font(DesignSystem.fontCaption)
                                .foregroundColor(DesignSystem.textTertiary)
                        }

                        Divider()
                            .padding(.vertical, DesignSystem.spacingSmall)

                        // Advanced Features Toggle
                        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                            HStack {
                                Text("Advanced Features")
                                    .font(DesignSystem.fontHeadline)
                                    .foregroundColor(DesignSystem.textPrimary)
                                Spacer()
                                TogglePill(isOn: $uiState.showAdvancedFeatures)
                            }

                            Text("Show additional options and controls for power users.")
                                .font(DesignSystem.fontCaption)
                                .foregroundColor(DesignSystem.textTertiary)
                        }

                        Divider()
                            .padding(.vertical, DesignSystem.spacingSmall)

                        // Experimental Charts Toggle
                        VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                            HStack {
                                Text("Experimental Charts")
                                    .font(DesignSystem.fontHeadline)
                                    .foregroundColor(DesignSystem.textPrimary)
                                Spacer()
                                TogglePill(isOn: $uiState.showExperimentalCharts)
                            }

                            Text("Display advanced data visualizations and analytics.")
                                .font(DesignSystem.fontCaption)
                                .foregroundColor(DesignSystem.textTertiary)
                        }
                    }
                }

                // Notifications Settings
                FrostCardHeader(title: "🔔 Notifications") {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        Text("Manage system notifications for important events and completion status.")
                            .font(DesignSystem.fontBody)
                            .foregroundColor(DesignSystem.textSecondary)

                        VStack(spacing: DesignSystem.spacingMedium) {
                            HStack(spacing: DesignSystem.spacing) {
                                Button(action: {
                                    NotificationManager.shared.requestAuthorization()
                                }) {
                                    HStack {
                                        Image(systemName: "bell.badge")
                                        Text("Request Permission")
                                    }
                                    .font(DesignSystem.fontBody)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(DesignSystem.primary)
                                    .cornerRadius(8)
                                }

                                Button(action: {
                                    NotificationManager.shared.notifyCleanupComplete(
                                        spaceFreed: 1_234_567_890,
                                        itemsCleaned: 42
                                    )
                                }) {
                                    HStack {
                                        Image(systemName: "bell")
                                        Text("Test Notification")
                                    }
                                    .font(DesignSystem.fontBody)
                                    .foregroundColor(DesignSystem.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(DesignSystem.primary.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }

                            Text("Notifications will inform you when cleaning operations complete, errors occur, or other important events happen.")
                                .font(DesignSystem.fontCaption)
                                .foregroundColor(DesignSystem.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                // Updates Settings
                FrostCardHeader(title: "⬆️ Updates") {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                        Text("Keep Pinaklean up-to-date with the latest features and improvements.")
                            .font(DesignSystem.fontBody)
                            .foregroundColor(DesignSystem.textSecondary)

                        CheckForUpdatesView()
                            .frame(maxWidth: .infinity)
                    }
                }

                // About Section
                FrostCardHeader(title: "ℹ️ About") {
                    VStack(alignment: .leading, spacing: DesignSystem.spacingMedium) {
                        HStack {
                            VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                                Text("Pinaklean")
                                    .font(DesignSystem.fontTitle)
                                    .foregroundColor(DesignSystem.primary)

                                Text("Smart Disk Cleaner & Optimizer")
                                    .font(DesignSystem.fontHeadline)
                                    .foregroundColor(DesignSystem.textSecondary)

                                Text("Version 1.0.0")
                                    .font(DesignSystem.fontBody)
                                    .foregroundColor(DesignSystem.textTertiary)
                            }

                            Spacer()

                            Image(systemName: "sparkles")
                                .font(.system(size: 48))
                                .foregroundColor(DesignSystem.primary.opacity(0.6))
                        }

                        Text("Powered by AI-driven analysis for intelligent file management and system optimization.")
                            .font(DesignSystem.fontBody)
                            .foregroundColor(DesignSystem.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
        }
        .background(DesignSystem.gradientBackground)
        .navigationTitle("Settings")
    }
}



import SwiftUI

/// Main Pinaklean Application with Liquid Crystal Design System
@main
struct PinakleanApp: App {
    // Initialize both view model and UI state
    @StateObject private var viewModel = PinakleanViewModel()
    @StateObject private var uiState = UnifiedUIState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(viewModel)
                .environmentObject(uiState)
                .preferredColorScheme(.dark)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.automatic)
        .commands {
            // Custom commands for Pinaklean
            CommandGroup(replacing: .newItem) {
                Button("New Scan") {
                    Task {
                        await viewModel.performQuickScan()
                    }
                }
                .keyboardShortcut("n", modifiers: [.command])
            }

            CommandGroup(replacing: .saveItem) {
                Button("Clean Safe") {
                    Task {
                        await viewModel.cleanSafeItems()
                    }
                }
                .keyboardShortcut("s", modifiers: [.command])
            }
        }

        // Enhanced Menu Bar Extra with glassmorphic design
        MenuBarExtra("Pinaklean", systemImage: "sparkles") {
            MenuBarView()
                .environmentObject(viewModel)
                .environmentObject(uiState)
                .frame(width: 320, height: 400)
        }
        .menuBarExtraStyle(.window)
    }

    init() {
        // Connect view model to UI state
        _viewModel.wrappedValue.setUIState(_uiState.wrappedValue)

        // Setup any initial UI state
        setupInitialState()
    }

    private func setupInitialState() {
        // Initialize with sample data for development
        #if DEBUG
        uiState.totalFilesScanned = 0
        uiState.spaceToClean = 0
        uiState.lastScanDate = nil

        // Add some sample recent activities for demo
        uiState.addActivity(ActivityItem(
            type: .scan,
            title: "Welcome to Pinaklean",
            description: "Ready to optimize your Mac",
            icon: "sparkles"
        ))
        #endif
    }
}

// MARK: - Menu Bar View

struct MenuBarView: View {
    @EnvironmentObject var viewModel: PinakleanViewModel
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        ZStack {
            // Liquid Glass background
            LiquidGlass()
                .opacity(0.8)

            VStack(spacing: DesignSystem.spacingSmall) {
                // Status section
                statusSection

                Divider()
                    .background(DesignSystem.textTertiary.opacity(0.3))

                // Quick actions
                quickActionsSection

                Divider()
                    .background(DesignSystem.textTertiary.opacity(0.3))

                // Recent results (if available)
                recentResultsSection

                Divider()
                    .background(DesignSystem.textTertiary.opacity(0.3))

                // Settings and info
                settingsSection
            }
            .padding(DesignSystem.spacing)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .animation(DesignSystem.spring, value: uiState.isProcessing)
    }

    private var statusSection: some View {
        VStack(spacing: DesignSystem.spacingSmall) {
            HStack {
                ZStack {
                    Circle()
                        .fill(uiState.isProcessing ? DesignSystem.warning.opacity(0.2) : DesignSystem.success.opacity(0.2))
                        .frame(width: 24, height: 24)

                    if uiState.isProcessing {
                        ProgressView()
                            .scaleEffect(0.5)
                            .tint(DesignSystem.warning)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.success)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }

                Text(uiState.isProcessing ? "Processing..." : "Ready")
                    .font(DesignSystem.fontCallout)
                    .foregroundColor(DesignSystem.textPrimary)

                Spacer()

                Text("🧹")
                    .font(.system(size: 18))
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(spacing: DesignSystem.spacingSmall) {
            MenuBarActionButton(
                title: "Quick Scan",
                icon: "magnifyingglass",
                color: DesignSystem.info
            ) {
                Task {
                    await viewModel.performQuickScan()
                }
            }

            MenuBarActionButton(
                title: "Auto Clean",
                icon: "trash.fill",
                color: DesignSystem.accent
            ) {
                Task {
                    await viewModel.cleanSafeItems()
                }
            }
        }
    }

    private var recentResultsSection: some View {
        Group {
            if let results = viewModel.scanResults, !results.isEmpty {
                VStack(spacing: DesignSystem.spacingSmall) {
                    Text("Last Scan")
                        .font(DesignSystem.fontCaption)
                        .foregroundColor(DesignSystem.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Text("\(results.items.count) items")
                            .font(DesignSystem.fontSubheadline)
                            .foregroundColor(DesignSystem.textPrimary)

                        Spacer()

                        Text(results.safeTotalSize.formattedSize())
                            .font(DesignSystem.fontCaption)
                            .foregroundColor(DesignSystem.success)
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(spacing: DesignSystem.spacingSmall) {
            MenuBarActionButton(
                title: "Settings",
                icon: "gear",
                color: DesignSystem.textSecondary
            ) {
                uiState.navigateTo(.settings)
                NSApp.activate(ignoringOtherApps: true)
            }

            MenuBarActionButton(
                title: "About",
                icon: "info.circle",
                color: DesignSystem.textSecondary
            ) {
                // Show about window
                let alert = NSAlert()
                alert.messageText = "Pinaklean v1.0.0"
                alert.informativeText = "Intelligent macOS cleanup toolkit"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }

            Divider()
                .background(DesignSystem.textTertiary.opacity(0.3))

            Button("Quit Pinaklean") {
                NSApp.terminate(nil)
            }
            .foregroundColor(DesignSystem.textPrimary)
            .font(DesignSystem.fontBody)
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Menu Bar Action Button

struct MenuBarActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.spacing) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .semibold))

                Text(title)
                    .foregroundColor(DesignSystem.textPrimary)
                    .font(DesignSystem.fontBody)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadiusSmall)
                .fill(Color.gray.opacity(0.1))
                .opacity(0)
        )
        .onHover { hovering in
            // Could add hover effects here if desired
        }
    }
}

// MARK: - Previews

struct PinakleanApp_Previews: PreviewProvider {
    static var previews: some View {
        let mockViewModel = PinakleanViewModel()
        let mockUIState = UnifiedUIState()

        // Setup mock data
        mockUIState.totalFilesScanned = 150
        mockUIState.spaceToClean = 1_500_000_000 // 1.5 GB
        mockUIState.lastScanDate = Date().addingTimeInterval(-3600)

        return Group {
            MainView()
                .environmentObject(mockViewModel)
                .environmentObject(mockUIState)
                .frame(width: 1000, height: 700)
                .preferredColorScheme(.light)

            MenuBarView()
                .environmentObject(mockViewModel)
                .environmentObject(mockUIState)
                .frame(width: 320, height: 400)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Supporting Extensions

extension Scene {
    func windowToolbarStyle(_ style: some ToolbarStyle) -> some Scene {
        #if os(macOS)
        if #available(macOS 13.0, *) {
            return self.windowToolbarStyle(style)
        } else {
            return self
        }
        #else
        return self
        #endif
    }
}
```

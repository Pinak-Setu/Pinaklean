import SwiftUI

/// Menu Bar Companion for Quick Access
struct MenuBarView: View {
    @EnvironmentObject var engine: PinakleanEngine
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        VStack(spacing: 8) {
            // Status Section
            VStack(spacing: 4) {
                Text("Pinaklean")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                if engine.isScanning {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.5)
                        Text("Scanning...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if engine.isCleaning {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.5)
                        Text("Cleaning...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Ready")
                        .font(.caption)
                        .foregroundColor(DesignSystem.success)
                }
            }
            .padding(.vertical, 4)

            Divider()

            // Quick Actions
            VStack(spacing: 2) {
                Button(action: quickScan) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Quick Scan")
                    }
                    .foregroundColor(.primary)
                    .font(.system(size: 13, design: .rounded))
                }
                .buttonStyle(.plain)

                Button(action: autoClean) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Auto Clean")
                    }
                    .foregroundColor(.primary)
                    .font(.system(size: 13, design: .rounded))
                }
                .buttonStyle(.plain)

                Button(action: openMainApp) {
                    HStack {
                        Image(systemName: "arrow.up.forward.app")
                        Text("Open Pinaklean")
                    }
                    .foregroundColor(.primary)
                    .font(.system(size: 13, design: .rounded))
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Recent Results
            if let results = uiState.scanResults {
                VStack(spacing: 4) {
                    Text("Last Scan")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    HStack {
                        Text("\(results.items.count) files")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.primary)

                        Spacer()

                        Text(results.safeTotalSize.formattedSize())
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(DesignSystem.success)
                    }
                }
                .padding(.vertical, 4)
            }

            Divider()

            // System Actions
            VStack(spacing: 2) {
                Button(action: { uiState.showSettings = true }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .foregroundColor(.primary)
                    .font(.system(size: 13, design: .rounded))
                }
                .buttonStyle(.plain)

                Button(action: { uiState.showAbout = true }) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("About")
                    }
                    .foregroundColor(.primary)
                    .font(.system(size: 13, design: .rounded))
                }
                .buttonStyle(.plain)

                Button(action: quitApp) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit")
                    }
                    .foregroundColor(.primary)
                    .font(.system(size: 13, design: .rounded))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 200)
    }

    // MARK: - Actions

    private func quickScan() {
        Task {
            do {
                uiState.isScanning = true
                let results = try await engine.scan(categories: .safe)
                uiState.scanResults = results
                uiState.addNotification(.init(
                    title: "Quick Scan Complete",
                    let safeSize = results.safeTotalSize.formattedSize()
                    message: "Found \(results.items.count) items (\(safeSize) safe to clean)",
                    type: .success
                ))
                uiState.isScanning = false
            } catch {
                uiState.addNotification(.init(
                    title: "Scan Failed",
                    message: error.localizedDescription,
                    type: .error
                ))
                uiState.isScanning = false
            }
        }
    }

    private func autoClean() {
        Task {
            do {
                uiState.isCleaning = true

                // First scan
                let results = try await engine.scan(categories: .safe)

                // Get recommendations
                let recommendations = try await engine.getRecommendations()

                // Auto-clean safe items
                if let safeRec = recommendations.first(where: { $0.title == "Safe to Delete" }) {
                    _ = try await engine.clean(safeRec.items)
                    uiState.addNotification(.init(
                        title: "Auto Clean Complete",
                        message: "Cleaned \(safeRec.items.count) items, freed \(safeRec.formattedSpace)",
                        type: .success
                    ))
                } else {
                    uiState.addNotification(.init(
                        title: "Auto Clean",
                        message: "No safe items found to clean",
                        type: .info
                    ))
                }

                uiState.isCleaning = false
            } catch {
                uiState.addNotification(.init(
                    title: "Auto Clean Failed",
                    message: error.localizedDescription,
                    type: .error
                ))
                uiState.isCleaning = false
            }
        }
    }

    private func openMainApp() {
        // Bring main app to front
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Extensions
extension Int64 {
    func formattedSize() -> String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}

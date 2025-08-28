import SwiftUI

// MARK: - Sidebar Commands
struct SidebarCommands: Commands {
    @FocusedBinding(\.selectedSidebarItem) private var selectedSidebarItem: SidebarItem?

    var body: some Commands {
        CommandGroup(before: .sidebar) {
            Button("Dashboard") {
                selectedSidebarItem = .dashboard
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("Scan") {
                selectedSidebarItem = .scan
            }
            .keyboardShortcut("2", modifiers: .command)

            Button("Clean") {
                selectedSidebarItem = .clean
            }
            .keyboardShortcut("3", modifiers: .command)

            Button("Analyze") {
                selectedSidebarItem = .analyze
            }
            .keyboardShortcut("4", modifiers: .command)

            Button("Backup") {
                selectedSidebarItem = .backup
            }
            .keyboardShortcut("5", modifiers: .command)

            Button("Settings") {
                selectedSidebarItem = .settings
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}

// MARK: - Toolbar Commands
struct ToolbarCommands: Commands {
    @EnvironmentObject var engine: PinakleanEngine
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About Pinaklean") {
                uiState.showAbout = true
            }
        }

        CommandGroup(replacing: .appSettings) {
            Button("Settings...") {
                uiState.navigate(to: .settings)
            }
            .keyboardShortcut(",", modifiers: .command)
        }

        CommandGroup(after: .appSettings) {
            Divider()

            Button("Quick Scan") {
                Task {
                    await performQuickScan()
                }
            }
            .keyboardShortcut("R", modifiers: .command)

            Button("Auto Clean") {
                Task {
                    await performAutoClean()
                }
            }
            .keyboardShortcut("A", modifiers: [.command, .shift])

            Divider()

            Button("Export Configuration") {
                exportConfiguration()
            }

            Button("Import Configuration") {
                importConfiguration()
            }
        }

        CommandGroup(replacing: .newItem) {
            Button("New Scan") {
                uiState.navigate(to: .scan)
            }
            .keyboardShortcut("N", modifiers: .command)
        }

        CommandGroup(replacing: .saveItem) {
            Button("Save Results") {
                saveResults()
            }
            .keyboardShortcut("S", modifiers: .command)
            .disabled(uiState.scanResults == nil)
        }

        CommandGroup(after: .windowSize) {
            Button("Inspector") {
                uiState.inspectorVisible.toggle()
            }
            .keyboardShortcut("I", modifiers: .command)
        }
    }

    // MARK: - Command Actions

    private func performQuickScan() async {
        guard !uiState.isScanning else { return }

        uiState.isScanning = true
        uiState.currentOperation = "Scanning..."

        do {
            let results = try await engine.scan(categories: .safe)
            uiState.scanResults = results
            uiState.addNotification(.init(
                title: "Quick Scan Complete",
                message: "Found \(results.items.count) items",
                type: .success
            ))
        } catch {
            uiState.addNotification(.init(
                title: "Scan Failed",
                message: error.localizedDescription,
                type: .error
            ))
        }

        uiState.isScanning = false
        uiState.currentOperation = ""
    }

    private func performAutoClean() async {
        guard !uiState.isCleaning else { return }

        uiState.isCleaning = true
        uiState.currentOperation = "Auto cleaning..."

        do {
            // First scan if no results
            if uiState.scanResults == nil {
                uiState.scanResults = try await engine.scan(categories: .safe)
            }

            // Get recommendations
            let recommendations = try await engine.getRecommendations()

            // Auto-clean safe items
            if let safeRec = recommendations.first(where: { $0.title == "Safe to Delete" }) {
                let results = try await engine.clean(safeRec.items)
                uiState.addNotification(.init(
                    title: "Auto Clean Complete",
                    message: "Cleaned \(results.deletedItems.count) items, freed \(results.freedSpace.formattedSize())",
                    type: .success
                ))
            }
        } catch {
            uiState.addNotification(.init(
                title: "Auto Clean Failed",
                message: error.localizedDescription,
                type: .error
            ))
        }

        uiState.isCleaning = false
        uiState.currentOperation = ""
    }

    private func exportConfiguration() {
        guard let configData = uiState.exportConfiguration() else {
            uiState.addNotification(.init(
                title: "Export Failed",
                message: "Unable to export configuration",
                type: .error
            ))
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["json"]
        savePanel.nameFieldStringValue = "pinaklean_config.json"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try configData.write(to: url)
                    uiState.addNotification(.init(
                        title: "Configuration Exported",
                        message: "Configuration saved to \(url.lastPathComponent)",
                        type: .success
                    ))
                } catch {
                    uiState.addNotification(.init(
                        title: "Export Failed",
                        message: error.localizedDescription,
                        type: .error
                    ))
                }
            }
        }
    }

    private func importConfiguration() {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["json"]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false

        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                do {
                    let data = try Data(contentsOf: url)
                    uiState.importConfiguration(from: data)
                    uiState.addNotification(.init(
                        title: "Configuration Imported",
                        message: "Configuration loaded from \(url.lastPathComponent)",
                        type: .success
                    ))
                } catch {
                    uiState.addNotification(.init(
                        title: "Import Failed",
                        message: error.localizedDescription,
                        type: .error
                    ))
                }
            }
        }
    }

    private func saveResults() {
        guard let results = uiState.scanResults else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["json"]
        savePanel.nameFieldStringValue = "pinaklean_scan_\(Date().timeIntervalSince1970).json"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    encoder.dateEncodingStrategy = .iso8601

                    let data = try encoder.encode(results)
                    try data.write(to: url)

                    uiState.addNotification(.init(
                        title: "Results Saved",
                        message: "Scan results saved to \(url.lastPathComponent)",
                        type: .success
                    ))
                } catch {
                    uiState.addNotification(.init(
                        title: "Save Failed",
                        message: error.localizedDescription,
                        type: .error
                    ))
                }
            }
        }
    }
}

// MARK: - Focused Value Key
private struct SelectedSidebarItemKey: FocusedValueKey {
    typealias Value = Binding<SidebarItem>
}

extension FocusedValues {
    var selectedSidebarItem: Binding<SidebarItem>? {
        get { self[SelectedSidebarItemKey.self] }
        set { self[SelectedSidebarItemKey.self] = newValue }
    }
}

// MARK: - Extensions
extension Int64 {
    func formattedSize() -> String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}

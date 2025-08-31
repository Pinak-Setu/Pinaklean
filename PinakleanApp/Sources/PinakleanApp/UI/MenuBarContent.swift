import SwiftUI
import PinakleanCore

struct MenuBarContent: View {
    var body: some View {
        VStack(spacing: DesignSystem.spacingSmall) {
            Text(AppStrings.appTitle)
                .font(DesignSystem.fontHeadline)

            Divider()

            Button(MenuStrings.quickScan) { runQuickScan() }
            .buttonStyle(.plain)

            Button(MenuStrings.autoClean) { runAutoClean() }
            .buttonStyle(.plain)

            Button(MenuStrings.openApp) {
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.plain)

            Button(MenuStrings.about) { showAbout() }
            .buttonStyle(.plain)

            Divider()

            Button(MenuStrings.quit) { NSApp.terminate(nil) }
                .buttonStyle(.plain)
        }
        .padding()
        .frame(width: 220)
    }
}

// MARK: - Actions
extension MenuBarContent {
    private func runQuickScan() {
        Task {
            do {
                let engine = try await PinakleanEngine()
                _ = try await engine.scan(categories: .safe)
                let count = engine.scanResults?.items.count ?? 0
                NotificationManager.shared.notifyCleanupComplete(spaceFreed: 0, itemsCleaned: count)
            } catch {
                showError("Quick Scan failed: \(error.localizedDescription)")
            }
        }
    }

    private func runAutoClean() {
        Task {
            do {
                let engine = try await PinakleanEngine()
                let results = try await engine.scan(categories: .safe)
                let items = try await engine.getRecommendations().flatMap { $0.items }
                let cleaned = try await engine.clean(items)
                NotificationManager.shared.notifyCleanupComplete(
                    spaceFreed: cleaned.freedSpace,
                    itemsCleaned: cleaned.deletedItems.count
                )
                showInfo("Auto Clean Complete\nCleaned: \(cleaned.deletedItems.count) items\nFreed: \(ByteCountFormatter.string(fromByteCount: cleaned.freedSpace, countStyle: .file))\nScanned: \(results.items.count) items")
            } catch {
                showError("Auto Clean failed: \(error.localizedDescription)")
            }
        }
    }

    private func showAbout() {
        #if os(macOS)
            let alert = NSAlert()
            alert.messageText = AppStrings.appTitle
            alert.informativeText = "Liquid Crystal macOS Cleanup Toolkit\nVersion 1.0.0"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        #endif
    }

    private func showError(_ message: String) {
        #if os(macOS)
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = message
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        #endif
    }

    private func showInfo(_ message: String) {
        #if os(macOS)
            let alert = NSAlert()
            alert.messageText = "Info"
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        #endif
    }
}



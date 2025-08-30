import SwiftUI

/// Main Pinaklean Application
@main
struct PinakleanApp: App {
    @StateObject private var viewModel = PinakleanViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.automatic)

        // Menu Bar Extra for quick access
        MenuBarExtra("Pinaklean", systemImage: "sparkles") {
            VStack(spacing: 10) {
                Button("Quick Scan") {
                    Task {
                        await viewModel.performQuickScan()
                    }
                }
                Button("Clean Safe Items") {
                    Task {
                        await viewModel.cleanSafeItems()
                    }
                }
                Divider()
                Button("View Dashboard") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                Divider()
                Button("Quit Pinaklean") {
                    NSApp.terminate(nil)
                }
            }
            .padding()
            .frame(width: 200)
        }
    }
}

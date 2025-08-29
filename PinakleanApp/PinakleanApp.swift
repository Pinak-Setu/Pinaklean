import SwiftUI

/// Main Pinaklean Application
@main
struct PinakleanApp: App {
    @StateObject private var engine = PinakleanEngine()
    @StateObject private var uiState = UnifiedUIState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .environmentObject(uiState)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands(content: {
            SidebarCommands()
                .focusedValue(\.selectedSidebarItem, $uiState.selectedSidebarItem)
            ToolbarCommands()
        })

        // Menu Bar Extra for quick access
        MenuBarExtra("Pinaklean", systemImage: "sparkles") {
            MenuBarView()
                .environmentObject(engine)
                .environmentObject(uiState)
        }

        // Settings Window
        Settings {
            SettingsView()
                .environmentObject(engine)
                .environmentObject(uiState)
        }

        // About Window
        Window("About Pinaklean", id: "about") {
            AboutView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

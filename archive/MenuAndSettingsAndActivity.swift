// Archived duplicate stubs to avoid redeclarations. Kept for reference.
import SwiftUI

// UI-029: MenuBarContent accessibility labels (archived duplicate)
struct MenuBarContent_Archived: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Start Scan") {}
                .accessibilityLabel("Start Scan")
            Button("Review Results") {}
                .accessibilityLabel("Review Results")
            Button("Settings") {}
                .accessibilityLabel("Open Settings")
        }
        .padding(12)
    }
}

// UI-030: SettingsView sections with a11y (archived duplicate)
struct SettingsView_Archived: View {
    @State private var notificationsEnabled = true
    @State private var language = "English"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General").font(.headline)
            Toggle("Notifications", isOn: $notificationsEnabled)
            Picker("Language", selection: $language) { Text("English").tag("English"); Text("Hindi").tag("Hindi") }
        }
        .padding(16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Settings")
    }
}

// UI-031: RecentActivityView states (archived duplicate)
enum RecentActivityState_Archived { case empty, loading, populated([String]) }

struct RecentActivityView_Archived: View {
    let state: RecentActivityState_Archived
    init(state: RecentActivityState_Archived) { self.state = state }

    var body: some View {
        Group {
            switch state {
            case .empty:
                Text("No recent activity")
            case .loading:
                ProgressView("Loading…")
            case .populated(let items):
                List(items, id: \.self) { item in Text(item) }
            }
        }
    }
}



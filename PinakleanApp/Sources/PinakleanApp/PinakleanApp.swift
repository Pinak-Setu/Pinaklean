import SwiftUI

@main
struct PinakleanApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.blue.opacity(0.1).ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("🧹 Pinaklean")
                        .font(.largeTitle)
                        .foregroundColor(.primary)

                    Text("Liquid Crystal UI")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Text("✨ Glassmorphic Design")
                        .font(.headline)
                        .foregroundColor(.orange)

                    Text("🏹 Bow & Arrow Menu Icon")
                        .font(.headline)
                        .foregroundColor(.purple)

                    Spacer()
                }
                .padding()
            }
            .frame(minWidth: 800, minHeight: 600)
        }

        MenuBarExtra("🏹", systemImage: "") {
            VStack(spacing: 10) {
                Text("🧹 Pinaklean")
                    .font(.headline)

                Divider()

                Button("About") {
                    let alert = NSAlert()
                    alert.messageText = "Pinaklean"
                    alert.informativeText = "Liquid Crystal macOS Cleanup\nBow & Arrow Menu Icon (🏹)"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
                .buttonStyle(.plain)

                Divider()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .frame(width: 200)
        }
    }
}

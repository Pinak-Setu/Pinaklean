
import SwiftUI

/// The view for reviewing scan results and executing the cleanup process.
struct CleanView: View {
    @State private var isDryRun: Bool = true
    @State private var isAutoBackupEnabled: Bool = true
    @State private var isCleaning: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Placeholder for results summary
                Text("Ready to clean 4.5 GB")
                    .font(.title)
                    .padding()
                
                CleanOptionsView(isDryRun: $isDryRun, isAutoBackupEnabled: $isAutoBackupEnabled)
                
                PrimaryButton(title: isCleaning ? "Cleaning..." : "Start Clean") {
                    // Start clean action
                    isCleaning.toggle()
                }
                .disabled(isCleaning)
            }
            .padding()
        }
    }
}

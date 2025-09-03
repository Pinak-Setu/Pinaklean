
import SwiftUI

/// A view that contains toggles for cleanup options like Dry Run and Auto Backup.
struct CleanOptionsView: View {
    @Binding var isDryRun: Bool
    @Binding var isAutoBackupEnabled: Bool
    
    var body: some View {
        VStack {
            Toggle(isOn: $isDryRun) {
                Text("Dry Run")
                Text("Preview changes without deleting files.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            Toggle(isOn: $isAutoBackupEnabled) {
                Text("Auto Backup")
                Text("Create a backup before cleaning.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(10)
    }
}

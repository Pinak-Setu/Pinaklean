
import SwiftUI

/// A view for managing notification settings.
struct NotificationControlsView: View {
    @State private var enableNotifications = true
    @State private var notifyOnCompletion = true
    
    var body: some View {
        VStack {
            Toggle("Enable Notifications", isOn: $enableNotifications)
            Toggle("Notify on Scan Completion", isOn: $notifyOnCompletion)
                .disabled(!enableNotifications)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(10)
    }
}

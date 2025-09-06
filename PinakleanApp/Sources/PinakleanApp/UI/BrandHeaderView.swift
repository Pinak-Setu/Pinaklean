
import SwiftUI

/// The header view displaying the application's brand identity.
struct BrandHeaderView: View {
    var body: some View {
        HStack {
            // Placeholder for the logo image
            Image(systemName: "sparkles.square.filled.on.square")
                .font(.largeTitle)
                .foregroundColor(.accentColor)
            
            Text("Pinaklean")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding()
    }
}


import SwiftUI

/// A view that displays a safety score with a color-coded badge.
struct EnhancedSafetyBadge: View {
    let score: Int
    
    private var color: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    private var label: String {
        switch score {
        case 80...100: return "Very Safe"
        case 60..<80: return "Safe"
        case 40..<60: return "Review"
        default: return "High Risk"
        }
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(score)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(8)
        .background(color)
        .cornerRadius(8)
    }
}

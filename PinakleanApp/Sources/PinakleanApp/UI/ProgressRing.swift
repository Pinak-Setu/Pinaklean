
import SwiftUI

/// A view that displays a circular progress ring.
struct ProgressRing: View {
    var progress: Double
    var color: Color = .accentColor
    var lineWidth: CGFloat = 10
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            
            Text(String(format: "%.0f%%", min(progress, 1.0) * 100))
                .font(.title)
                .fontWeight(.bold)
        }
    }
}

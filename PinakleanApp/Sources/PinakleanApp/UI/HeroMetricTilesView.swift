
import SwiftUI

/// A view that displays key metrics in large, prominent tiles.
struct HeroMetricTilesView: View {
    var body: some View {
        HStack {
            MetricTile(title: "Space Freed", value: "12.4 GB", color: .blue)
            MetricTile(title: "Files Cleaned", value: "1,204", color: .green)
            MetricTile(title: "Last Scan", value: "2h ago", color: .orange)
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.2))
        .cornerRadius(10)
    }
}

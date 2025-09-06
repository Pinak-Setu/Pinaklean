
import SwiftUI

/// The main dashboard view, showing an overview and key metrics.
struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeroMetricTilesView()
                AnalyticsDashboard()
                RecentActivityView()
            }
            .padding()
        }
    }
}

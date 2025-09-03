import SwiftUI

/// An enumeration representing the main tabs in the application.
enum AppTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case scan = "Scan"
    case clean = "Clean"
    case settings = "Settings"
    case analytics = "Analytics"
    
    var systemImageName: String {
        switch self {
        case .dashboard: return "chart.pie.fill"
        case .scan: return "magnifyingglass"
        case .clean: return "sparkles"
        case .settings: return "gearshape.fill"
        case .analytics: return "chart.bar.xaxis"
        }
    }
}

/// The custom tab bar view for navigating between the main sections of the app.
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        HStack {
            ForEach(AppTab.allCases, id: .self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImageName)
                            .font(.title2)
                        Text(tab.rawValue)
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
    }
}
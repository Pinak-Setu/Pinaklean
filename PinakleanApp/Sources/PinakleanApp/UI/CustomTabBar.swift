import SwiftUI

/// An enumeration representing the main tabs in the application.
enum AppTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case scan = "Scan"
    case recommendations = "Recommendations"
    case clean = "Clean"
    case settings = "Settings"
    case analytics = "Analytics"
    
    var systemImageName: String {
        switch self {
        case .dashboard: return "chart.pie.fill"
        case .scan: return "magnifyingglass"
        case .recommendations: return "lightbulb.fill"
        case .clean: return "sparkles"
        case .settings: return "gearshape.fill"
        case .analytics: return "chart.bar.xaxis"
        }
    }

    var keyboardShortcut: Character {
        switch self {
        case .dashboard: return "1"
        case .scan: return "2"
        case .recommendations: return "3"
        case .clean: return "4"
        case .settings: return "5"
        case .analytics: return "6"
        }
    }
}

/// The custom tab bar view for navigating between the main sections of the app.
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        let tabViews = AppTab.allCases.map { tab in
            tabButton(for: tab)
        }

        return HStack {
            ForEach(Array(zip(tabViews.indices, tabViews)), id: \.0) { index, tabView in
                tabView
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        let foregroundColor = isSelected ? Color.accentColor : Color.secondary

        return Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImageName)
                    .font(.title2)
                Text(tab.rawValue)
                    .font(.caption)
            }
            .foregroundColor(foregroundColor)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
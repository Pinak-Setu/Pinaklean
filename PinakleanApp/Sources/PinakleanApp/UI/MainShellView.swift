
import SwiftUI

/// The main container view for the entire application, hosting the tab bar and background.
struct MainShellView: View {
    @State private var selectedTab: AppTab = .dashboard
    
    var body: some View {
        ZStack {
            LiquidGlass()
            
            VStack {
                BrandHeaderView()
                
                // Content area that will switch based on the selected tab
                Group {
                    switch selectedTab {
                    case .dashboard:
                        DashboardView()
                    case .scan:
                        ScanView()
                    case .clean:
                        CleanView()
                    case .settings:
                        SettingsView()
                    case .analytics:
                        AnalyticsDashboard()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
    }
}

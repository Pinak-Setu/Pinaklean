
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
                Spacer()
                Text("Selected Tab: \(selectedTab.rawValue)")
                Spacer()
                
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
    }
}

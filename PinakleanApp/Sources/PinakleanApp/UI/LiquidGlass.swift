import SwiftUI

/// A view that creates a blurred, glass-like background effect.
struct LiquidGlass: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea()
    }
}
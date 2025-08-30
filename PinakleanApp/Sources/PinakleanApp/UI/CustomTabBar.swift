//  CustomTabBar.swift
//  PinakleanApp
//
//  Glassmorphic tab bar component for the "Liquid Crystal" design system
//  Features smooth animations, haptic feedback, and full accessibility support
//
//  Created: UI Implementation Phase
//  Features: Glassmorphic design, Animated transitions, Accessibility compliance
//

import SwiftUI

/// Custom tab bar with Liquid Crystal glassmorphic styling
/// Provides animated tab switching with haptic feedback and accessibility support
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    let tabs: [AppTab]

    /// Initialize with default tabs
    init(selectedTab: Binding<AppTab>, tabs: [AppTab] = AppTab.allCases) {
        self._selectedTab = selectedTab
        self.tabs = tabs
    }

    var body: some View {
        ZStack {
            // Glassmorphic background
            LiquidGlass(materialOpacity: 0.9)
                .cornerRadius(DesignSystem.cornerRadiusLarge)

            // Tab items
            HStack(spacing: 0) {
                ForEach(tabs) { tab in
                    TabBarItem(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        // Haptic feedback (if available)
                        #if os(iOS)
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.prepare()
                            generator.impactOccurred()
                        #endif

                        withAnimation(DesignSystem.spring) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.spacingSmall)
            .padding(.vertical, DesignSystem.spacingSmall)
        }
        .frame(height: 60)
        .shadow(
            color: DesignSystem.shadow.radius > 0 ? Color.black.opacity(0.2) : Color.clear,
            radius: DesignSystem.shadow.radius,
            x: 0,
            y: DesignSystem.shadow.y
        )
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tab Bar")
    }
}

/// Individual tab bar item with icon and title
struct TabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    @State private var scaleEffect: CGFloat = 1.0

    var body: some View {
        Button(action: {
            action()
            // Press feedback animation
            withAnimation(.spring(response: 0.2)) {
                scaleEffect = 0.95
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2)) {
                    scaleEffect = 1.0
                }
            }
        }) {
            VStack(spacing: DesignSystem.spacingSmall) {
                ZStack {
                    // Background for selected state
                    if isSelected {
                        Circle()
                            .fill(DesignSystem.gradientPrimary.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .blur(radius: 2)
                    }

                    // Icon
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(
                            isSelected ? DesignSystem.primary : DesignSystem.textSecondary
                        )
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring, value: isSelected)
                }

                // Title (optional, can be hidden on compact sizes)
                Text(tab.title)
                    .font(DesignSystem.fontCaption)
                    .foregroundColor(
                        isSelected ? DesignSystem.textPrimary : DesignSystem.textSecondary
                    )
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.spring, value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.spacingSmall)
            .scaleEffect(scaleEffect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityHint("Tap to switch to \(tab.title.lowercased())")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Previews

struct CustomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            DesignSystem.gradientBackground
                .ignoresSafeArea()

            VStack {
                Spacer()

                CustomTabBar(selectedTab: .constant(.dashboard))
                    .padding(.horizontal)

                Spacer()
            }
        }
        .frame(height: 100)
        .preferredColorScheme(.light)
    }
}

// MARK: - Extensions

extension AppTab {
    /// All available tabs for the tab bar
    static var allCases: [AppTab] {
        [.dashboard, .scan, .clean, .settings, .analytics]
    }
}

extension CustomTabBar {
    /// Custom tab bar with custom tabs
    func customTabs(_ tabs: [AppTab]) -> CustomTabBar {
        CustomTabBar(selectedTab: _selectedTab, tabs: tabs)
    }

    /// Custom tab bar with no animations (for accessibility)
    func disableAnimations() -> some View {
        self.transaction { transaction in
            transaction.animation = nil
        }
    }
}

// MARK: - Conditional Modifiers

extension CustomTabBar {
    /// Apply modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

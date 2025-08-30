//
//  QuickActionButton.swift
//  PinakleanApp
//
//  Interactive button component with press feedback animations
//  Features glassmorphic design, haptic feedback, and accessibility support
//
//  Created: UI Implementation Phase
//  Features: Press animations, Accessibility, Haptic feedback
//

import SwiftUI

/// Quick action button with press feedback and glassmorphic styling
/// Designed for the dashboard and main navigation areas
struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    let color: Color
    let size: CGSize

    @State private var isPressed = false
    @State private var scaleEffect: CGFloat = 1.0

    /// Initialize with default styling
    init(
        icon: String,
        title: String,
        color: Color = DesignSystem.primary,
        size: CGSize = CGSize(width: 120, height: 120),
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.color = color
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: {
            // Haptic feedback (if available)
            #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            #endif

            withAnimation(DesignSystem.spring) {
                scaleEffect = 0.95
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignSystem.spring) {
                    scaleEffect = 1.0
                }
            }

            action()
        }) {
            VStack(spacing: DesignSystem.spacingSmall) {
                ZStack {
                    // Glassmorphic background
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                        .fill(DesignSystem.glass.opacity(0.3))
                        .frame(width: size.width, height: size.height)
                        .background(DesignSystem.blur)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                                .stroke(color.opacity(0.3), lineWidth: DesignSystem.borderWidthThin)
                        )
                        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)

                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(color)
                        .symbolRenderingMode(.hierarchical)
                }

                // Title
                Text(title)
                    .font(DesignSystem.fontCallout)
                    .foregroundColor(DesignSystem.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .scaleEffect(scaleEffect)
            .animation(.spring(response: 0.3), value: scaleEffect)
        }
        .buttonStyle(.plain)
        .frame(width: size.width)
        .accessibilityLabel("\(title) action")
        .accessibilityHint("Tap to perform \(title.lowercased())")
        .accessibilityAddTraits(.isButton)
        .help("\(title) - Press to execute this action")
    }
}

/// Compact version for smaller layouts
struct CompactQuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        QuickActionButton(
            icon: icon,
            title: title,
            size: CGSize(width: 80, height: 80),
            action: action
        )
    }
}

/// Elevated version with stronger effects
struct ElevatedQuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        QuickActionButton(
            icon: icon,
            title: title,
            color: DesignSystem.accent,
            size: CGSize(width: 140, height: 140),
            action: action
        )
    }
}

// MARK: - Previews

struct QuickActionButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            DesignSystem.gradientBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                QuickActionButton(
                    icon: "magnifyingglass",
                    title: "Quick Scan"
                ) {
                    print("Scan tapped")
                }

                CompactQuickActionButton(
                    icon: "trash.fill",
                    title: "Clean"
                ) {
                    print("Clean tapped")
                }

                ElevatedQuickActionButton(
                    icon: "chart.bar.fill",
                    title: "Analytics"
                ) {
                    print("Analytics tapped")
                }
            }
            .padding()
        }
        .frame(width: 400, height: 600)
        .preferredColorScheme(.light)
    }
}

// MARK: - Accessibility Extensions

// Temporarily disabled due to API changes
// extension QuickActionButton {
//     /// Add custom accessibility actions
//     func accessibilityAction(named name: String, action: @escaping () -> Void) -> some View {
//         self.accessibilityAction(.named(name), action)
//     }
// }

// MARK: - Animation Extensions

extension QuickActionButton {
    /// Disable animations (for accessibility)
    func disableAnimations() -> some View {
        self.transaction { transaction in
            transaction.animation = nil
        }
    }

    /// Custom animation duration
    func animationDuration(_ duration: Double) -> some View {
        self.transaction { transaction in
            transaction.animation = .spring(response: duration)
        }
    }
}

// MARK: - Conditional Modifiers

extension QuickActionButton {
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

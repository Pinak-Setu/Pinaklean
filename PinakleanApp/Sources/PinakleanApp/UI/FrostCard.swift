//
//  FrostCard.swift
//  PinakleanApp
//
//  Glassmorphic container component for the "Liquid Crystal" design system
//  Features blur effects, translucent backgrounds, and dynamic shadows
//
//  Created: UI Implementation Phase
//  Features: Glassmorphism, Dynamic shadows, Configurable appearance
//

import SwiftUI

/// Glassmorphic container with blur effects and shadows
/// Provides a modern, translucent appearance that integrates seamlessly with macOS
struct FrostCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let shadow: Shadow
    let backgroundColor: Color

    /// Initialize with default glassmorphic appearance
    init(
        cornerRadius: CGFloat = DesignSystem.cornerRadiusLarge,
        shadow: Shadow = DesignSystem.shadow,
        backgroundColor: Color = DesignSystem.glass,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        ZStack {
            // Glassmorphic background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
                .background(DesignSystem.blur)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.2), lineWidth: DesignSystem.borderWidthThin)
                )

            // Content container with padding
            content
                .padding(DesignSystem.spacing)
        }
        .shadow(color: Color.black.opacity(0.1), radius: shadow.radius, x: 0, y: shadow.y)
        .compositingGroup()  // Ensures blur works properly
        .accessibilityElement(children: .combine)
    }
}

/// Compact version of FrostCard with smaller spacing
struct CompactFrostCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        FrostCard(
            cornerRadius: DesignSystem.cornerRadius,
            shadow: DesignSystem.shadowSoft,
            backgroundColor: DesignSystem.glass.opacity(0.8)
        ) {
            content
        }
    }
}

/// Elevated version with stronger shadow
struct ElevatedFrostCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        FrostCard(
            cornerRadius: DesignSystem.cornerRadiusLarge,
            shadow: DesignSystem.shadowStrong,
            backgroundColor: DesignSystem.glass
        ) {
            content
        }
    }
}

/// Header-only FrostCard for section titles
struct FrostCardHeader<Content: View>: View {
    let content: Content
    let title: String?

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        FrostCard {
            VStack(alignment: .leading, spacing: DesignSystem.spacingSmall) {
                if let title = title {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignSystem.textSecondary)
                }
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Previews (for SwiftUI Previews)

struct FrostCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            DesignSystem.gradientBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                FrostCard {
                    Text("Standard FrostCard")
                        .font(DesignSystem.fontHeadline)
                }

                CompactFrostCard {
                    Text("Compact Version")
                        .font(DesignSystem.fontBody)
                }

                ElevatedFrostCard {
                    Text("Elevated Version")
                        .font(DesignSystem.fontTitle)
                }

                FrostCardHeader(title: "Header Section") {
                    Text("Content with header")
                        .font(DesignSystem.fontBody)
                }
            }
            .padding()
        }
        .frame(width: 400, height: 600)
        .preferredColorScheme(.light)
    }
}

// MARK: - Accessibility Extensions

extension FrostCard {
    /// FrostCard with custom accessibility label
    func accessibilityLabel(_ label: String) -> some View {
        self.accessibilityElement()
            .accessibilityLabel(label)
    }

    /// FrostCard with custom accessibility hint
    func accessibilityHint(_ hint: String) -> some View {
        self.accessibilityElement()
            .accessibilityHint(hint)
    }
}

// MARK: - Animation Extensions

extension FrostCard {
    /// FrostCard with entrance animation
    func entranceAnimation(_ animation: Animation? = DesignSystem.spring) -> some View {
        self.transition(DesignSystem.slideIn.animation(animation ?? DesignSystem.spring))
    }

    /// FrostCard with scale animation
    func scaleAnimation(_ scale: CGFloat = 1.0) -> some View {
        self.scaleEffect(scale)
            .animation(DesignSystem.spring)
    }

    /// FrostCard with opacity animation
    func opacityAnimation(_ opacity: Double = 1.0) -> some View {
        self.opacity(opacity)
            .animation(DesignSystem.easeInOut)
    }
}

// MARK: - Conditional Modifiers

extension FrostCard {
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

//
//
import SwiftUI

/// Shadow configuration for consistent elevation effects
struct Shadow {
    let radius: CGFloat
    let yOffset: CGFloat
}

/// Pinaklean's "Liquid Crystal" design system
/// Combines glassmorphic elegance with functional data visualization
/// Designed for macOS with accessibility and performance in mind
enum DesignSystem {

    // MARK: - Colors

    /// Primary color - Topaz Yellow (Golden)
    static let primary = Color(hex: "#FFD700")

    /// Accent color - Red Damask (Crimson)
    static let accent = Color(hex: "#DC143C")

    /// Glass color for translucent overlays
    static let glass = Color.white.opacity(0.1)

    /// Background glass with slight blue tint
    static let glassBackground = Color.blue.opacity(0.05)

    // MARK: - Semantic Colors

    static let success = Color.green.opacity(0.8)
    static let warning = Color.orange.opacity(0.8)
    static let error = Color.red.opacity(0.8)
    static let info = Color.blue.opacity(0.8)

    /// Text primary color (adapts to theme)
    static let textPrimary = Color.primary

    /// Text secondary color
    static let textSecondary = Color.secondary

    /// Text tertiary color for muted content
    static let textTertiary = Color.secondary.opacity(0.7)

    /// Surface color for cards and backgrounds
    static let surface = Color.white.opacity(0.05)

    /// Border color for outlines
    static let border = Color.white.opacity(0.1)

    // MARK: - Materials & Effects

    /// Ultra thin material for glassmorphism
    static let blur = Material.ultraThin

    /// Thick material for strong glass effects
    static let blurThick = Material.thick

    /// Regular material for standard blur
    static let blurRegular = Material.regular

    /// Thin material for subtle effects
    static let blurThin = Material.thin

    // MARK: - Shadows

    /// Standard shadow for floating elements
    static let shadow = Shadow(radius: 20, yOffset: 10)

    /// Soft shadow for subtle elevation
    static let shadowSoft = Shadow(radius: 8, yOffset: 4)

    /// Minimal shadow for thin elements
    static let shadowMinimal = Shadow(radius: 4, yOffset: 2)

    /// Strong shadow for modal overlays
    static let shadowStrong = Shadow(radius: 30, yOffset: 15)

    // MARK: - Animations

    /// Standard spring animation (responsive: 0.4, damping: 0.8)
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)

    /// Bounce spring for playful interactions
    static let springBounce = Animation.spring(response: 0.6, dampingFraction: 0.4)

    /// Interactive spring for user-initiated changes
    static let interactive = Animation.interactiveSpring()

    /// Ease in out for smooth transitions
    static let easeInOut = Animation.easeInOut(duration: 0.3)

    /// Fast linear animation for progress indicators
    static let linearFast = Animation.linear(duration: 0.2)

    /// Slow ease out for settling animations
    static let easeOutSlow = Animation.easeOut(duration: 0.5)

    // MARK: - Transitions

    /// Default transition combining opacity and scale
    static let transition = AnyTransition.opacity.combined(with: .scale)

    /// Slide in from trailing edge
    static let slideIn = AnyTransition.move(edge: .trailing).combined(with: .opacity)

    /// Slide in from leading edge
    static let slideInLeading = AnyTransition.move(edge: .leading).combined(with: .opacity)

    /// Scale and fade transition
    static let scaleFade = AnyTransition.scale.combined(with: .opacity)

    // MARK: - Gradients

    /// Primary gradient for highlights
    static let gradientPrimary = LinearGradient(
        colors: [primary, accent.opacity(0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Glass gradient for translucent backgrounds
    static let gradientGlass = LinearGradient(
        colors: [glass.opacity(0.2), glass.opacity(0.1)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Background gradient for depth
    static let gradientBackground = LinearGradient(
        colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.03)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Success gradient for positive states
    static let gradientSuccess = LinearGradient(
        colors: [success.opacity(0.1), success.opacity(0.05)],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Warning gradient for caution states
    static let gradientWarning = LinearGradient(
        colors: [warning.opacity(0.1), warning.opacity(0.05)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Spacing & Layout

    /// Standard spacing (16pt)
    static let spacing: CGFloat = 16

    /// Small spacing (8pt)
    static let spacingSmall: CGFloat = 8

    /// Large spacing (24pt)
    static let spacingLarge: CGFloat = 24

    /// Extra large spacing (32pt)
    static let spacingXLarge: CGFloat = 32

    /// Medium spacing (20pt)
    static let spacingMedium: CGFloat = 20

    // MARK: - Corner Radii

    /// Standard corner radius (12pt)
    static let cornerRadius: CGFloat = 12

    /// Large corner radius (16pt)
    static let cornerRadiusLarge: CGFloat = 16

    /// Small corner radius (8pt)
    static let cornerRadiusSmall: CGFloat = 8

    /// Circular corner radius (999pt)
    static let cornerRadiusCircular: CGFloat = 999

    // MARK: - Line Widths

    /// Standard border width (1pt)
    static let borderWidth: CGFloat = 1

    /// Thin border width (0.5pt)
    static let borderWidthThin: CGFloat = 0.5

    /// Thick border width (2pt)
    static let borderWidthThick: CGFloat = 2

    // MARK: - Typography

    /// Large title font style
    static let fontLargeTitle = Font.system(size: 34, weight: .bold, design: .rounded)

    /// Title font style
    static let fontTitle = Font.system(size: 28, weight: .bold, design: .rounded)

    /// Headline font style
    static let fontHeadline = Font.system(size: 17, weight: .semibold, design: .rounded)

    /// Body font style
    static let fontBody = Font.system(size: 17, weight: .regular, design: .rounded)

    /// Callout font style
    static let fontCallout = Font.system(size: 16, weight: .regular, design: .rounded)

    /// Subheadline font style
    static let fontSubheadline = Font.system(size: 15, weight: .regular, design: .rounded)

    /// Footnote font style
    static let fontFootnote = Font.system(size: 13, weight: .regular, design: .rounded)

    /// Caption font style
    static let fontCaption = Font.system(size: 12, weight: .regular, design: .rounded)

    /// Caption small font style
    static let fontCaptionSmall = Font.system(size: 11, weight: .regular, design: .rounded)
}

// MARK: - Extensions

extension Color {
    /// Initialize Color from hex string
    /// - Parameter hex: Hex string (e.g., "#FFD700" or "FFD700")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha: UInt64
        let red: UInt64
        let green: UInt64
        let blue: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (alpha, red, green, blue) = (
                255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17
            )
        case 6:  // RGB (24-bit)
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            // Fallback: solid black for invalid input
            (alpha, red, green, blue) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}

extension Animation {
    /// Conditional animation respecting accessibility preferences
    /// - Parameters:
    ///   - condition: Condition to check
    ///   - animation: Animation to apply if condition is true
    /// - Returns: Animation if condition is true and motion is not reduced, nil otherwise
    static func conditional(_ condition: Bool, animation: Animation) -> Animation? {
        #if os(macOS)
            if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                return nil
            }
        #endif
        return condition ? animation : nil
    }
}

// MARK: - Convenience Functions

extension DesignSystem {
    /// Get animation considering accessibility
    /// - Parameter animation: Desired animation
    /// - Returns: Animation if motion is not reduced, nil otherwise
    static func accessibleAnimation(_ animation: Animation) -> Animation? {
        #if os(macOS)
            if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                return nil
            }
        #endif
        return animation
    }

    /// Get safe corner radius for given size
    /// - Parameters:
    ///   - size: Size of the element
    ///   - multiplier: Corner radius multiplier (0.1 = 10% of smallest dimension)
    /// - Returns: Safe corner radius
    static func safeCornerRadius(for size: CGSize, multiplier: CGFloat = 0.1) -> CGFloat {
        min(size.width, size.height) * multiplier
    }
}

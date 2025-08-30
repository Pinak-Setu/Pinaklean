//
//  LiquidGlass.swift
//  PinakleanApp
//
//  Background component featuring gradient overlays and ultra-thin material
//  Creates depth and visual hierarchy for the "Liquid Crystal" design system
//
//  Created: UI Implementation Phase
//  Features: Gradient backgrounds, Material overlays, Performance optimization
//

import SwiftUI

/// Background component that combines gradients with glassmorphic effects
/// Provides depth and visual interest while maintaining performance
struct LiquidGlass: View {
    let baseGradient: LinearGradient
    let accentGradient: LinearGradient?
    let materialOpacity: Double

    /// Initialize with default Liquid Crystal appearance
    init(
        baseGradient: LinearGradient = DesignSystem.gradientBackground,
        accentGradient: LinearGradient? = nil,
        materialOpacity: Double = 0.8
    ) {
        self.baseGradient = baseGradient
        self.accentGradient = accentGradient
        self.materialOpacity = materialOpacity
    }

    var body: some View {
        ZStack {
            // Base gradient layer
            baseGradient

            // Optional accent gradient
            if let accentGradient = accentGradient {
                accentGradient
                    .opacity(0.3)
            }

            // Material overlay for glassmorphism
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(materialOpacity)

            // Subtle noise texture for depth
            Rectangle()
                .fill(Color.white.opacity(0.02))
                .blendMode(.overlay)
        }
        .ignoresSafeArea()
        .compositingGroup()
    }
}

/// Compact version with reduced opacity
struct CompactLiquidGlass: View {
    var body: some View {
        LiquidGlass(materialOpacity: 0.6)
    }
}

/// Dark version for dark mode or overlay contexts
struct DarkLiquidGlass: View {
    var body: some View {
        let darkGradient = LinearGradient(
            colors: [Color.black.opacity(0.3), Color.gray.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        LiquidGlass(baseGradient: darkGradient, materialOpacity: 0.9)
    }
}

/// Animated version with subtle color shifts
struct AnimatedLiquidGlass: View {
    @State private var phase: Double = 0.0

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let animatedPhase = sin(time * 0.5) * 0.1

            ZStack {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05 + animatedPhase),
                        Color.purple.opacity(0.03 + animatedPhase),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
            }
        }
        .ignoresSafeArea()
        .compositingGroup()
    }
}

// MARK: - Previews

struct LiquidGlass_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LiquidGlass()
                .frame(height: 200)
                .preferredColorScheme(.light)

            CompactLiquidGlass()
                .frame(height: 200)
                .preferredColorScheme(.dark)

            AnimatedLiquidGlass()
                .frame(height: 200)
                .preferredColorScheme(.light)
        }
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Extensions for Convenience

extension View {
    /// Add LiquidGlass as background
    func liquidGlassBackground() -> some View {
        ZStack {
            LiquidGlass()
            self
        }
    }

    /// Add compact LiquidGlass as background
    func compactLiquidGlassBackground() -> some View {
        ZStack {
            CompactLiquidGlass()
            self
        }
    }
}

//
//  TogglePill.swift
//  PinakleanApp
//
//  Glassmorphic toggle component for the "Liquid Crystal" design system
//  Features smooth animations, pill-shaped design, and accessibility support
//
//  Created: UI Implementation Phase
//  Features: Glassmorphic toggle, Smooth animations, Accessibility compliance
//

import SwiftUI

// Import DesignSystem - assuming it's in the same module
// If not, it might need to be a different import or the DesignSystem needs to be made available

/// Glassmorphic toggle button with pill-shaped design
/// Provides smooth on/off transitions with Liquid Crystal styling
struct TogglePill: View {
    @Binding var isOn: Bool
    let label: String?
    let onColor: Color
    let offColor: Color

    /// Initialize with default colors
    init(
        isOn: Binding<Bool>,
        label: String? = nil,
        onColor: Color = Color(hex: "#FFD700"),  // Primary color - Topaz Yellow
        offColor: Color = Color.white.opacity(0.1)  // Glass color
    ) {
        self._isOn = isOn
        self.label = label
        self.onColor = onColor
        self.offColor = offColor
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
                isOn.toggle()
            }
        }) {
            HStack(spacing: 8) {  // DesignSystem.spacingSmall
                // Optional label
                if let label = label {
                    Text(label)
                        .font(.system(size: 17, weight: .regular, design: .rounded))  // fontBody
                        .foregroundColor(
                            isOn ? Color.primary : Color.secondary  // textPrimary/textSecondary
                        )
                        .transition(.opacity.animation(.easeInOut(duration: 0.3)))  // easeInOut
                }

                // Toggle pill
                ZStack {
                    // Background capsule
                    Capsule()
                        .fill(Color.white.opacity(0.1).opacity(0.3))  // glass.opacity(0.3)
                        .frame(width: 60, height: 32)
                        .overlay(
                            Capsule()
                                .stroke(
                                    isOn ? onColor.opacity(0.5) : offColor.opacity(0.3),
                                    lineWidth: 0.5  // borderWidthThin
                                )
                        )
                        .background(Material.ultraThin)  // blur

                    // Sliding circle
                    Circle()
                        .fill(isOn ? onColor : offColor)
                        .frame(width: 24, height: 24)
                        .offset(x: isOn ? 14 : -14)
                        .shadow(
                            color: (isOn ? onColor : offColor).opacity(0.3),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
                }
            }
            .padding(.horizontal, 8)  // spacingSmall
            .padding(.vertical, 8)  // spacingSmall
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label ?? "Toggle")
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint("Double-tap to toggle")
        .accessibilityAddTraits(.isButton)
    }
}

/// Compact version for smaller layouts
struct CompactTogglePill: View {
    @Binding var isOn: Bool

    var body: some View {
        TogglePill(isOn: _isOn, label: nil)
    }
}

/// Labeled version for settings
struct LabeledTogglePill: View {
    @Binding var isOn: Bool
    let label: String

    var body: some View {
        TogglePill(isOn: _isOn, label: label)
    }
}

// MARK: - Previews

struct TogglePill_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            DesignSystem.gradientBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {  // spacingLarge
                TogglePill(isOn: .constant(true), label: "Enable Notifications")
                TogglePill(isOn: .constant(false), label: "Auto Scan")
                CompactTogglePill(isOn: .constant(true))
                LabeledTogglePill(isOn: .constant(false), label: "Dark Mode")
            }
            .padding()
        }
        .frame(width: 300, height: 400)
        .preferredColorScheme(.light)
    }
}

// MARK: - Extensions

extension TogglePill {
    /// TogglePill with custom animation
    func animation(_ animation: Animation?) -> some View {
        self.transaction { transaction in
            transaction.animation = animation
        }
    }

    /// TogglePill with disabled state
    func disabled(_ disabled: Bool) -> some View {
        self.opacity(disabled ? 0.5 : 1.0)
            .disabled(disabled)
    }
}

// MARK: - Conditional Modifiers

extension TogglePill {
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

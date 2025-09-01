import SwiftUI

// SI-001: Conic gradient border helper
public struct ConicGradientBorder: View {
    public let cornerRadius: CGFloat
    public let lineWidth: CGFloat
    public init(cornerRadius: CGFloat = 12, lineWidth: CGFloat = 1) {
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
    }
    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(LinearGradient(colors: [Color.red, Color.blue, Color.green, Color.red], startPoint: .leading, endPoint: .trailing), lineWidth: lineWidth)
            .animation(Self.rotationAnimation(), value: UUID())
    }
    public static func rotationAnimation() -> Animation? {
        guard !DesignSystem.isReduceMotionEnabled() else { return nil }
        return Animation.linear(duration: 8).repeatForever(autoreverses: false)
    }
}

// SI-002: Aurora dynamics
public enum AuroraActivity { case idle, active }

public struct AuroraDynamics {
    public struct Parameters { public let speed: Double; public let brightness: Double }
    public static func parameters(activity: AuroraActivity) -> Parameters {
        switch activity {
        case .idle:
            return Parameters(speed: DesignSystem.isReduceMotionEnabled() ? 0.05 : 0.1, brightness: 0.4)
        case .active:
            let speed = DesignSystem.isReduceMotionEnabled() ? 0.2 : 0.6
            return Parameters(speed: speed, brightness: 0.8)
        }
    }
}

// SI-003: Haptics engine (no-op on unsupported platforms)
public final class HapticsEngine {
    public static let shared = HapticsEngine()
    private init() {}
    public func tap() { }
    public func success() { }
    public func warning() { }
}

// SI-004: Rive loader stub (placeholder API)
public struct RiveAnimationPlayer { public func play() {}; public func stop() {} }
public enum RiveAnimationLoader { public static func load(named: String) -> RiveAnimationPlayer { RiveAnimationPlayer() } }



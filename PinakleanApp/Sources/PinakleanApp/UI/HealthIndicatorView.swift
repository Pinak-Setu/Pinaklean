import SwiftUI

// UI-052: Health indicator with retry action (pure UI; no core logic dependency)
public enum HealthStatus {
    case healthy
    case connecting
    case down

    var color: Color {
        switch self {
        case .healthy: return DesignSystem.success
        case .connecting: return DesignSystem.warning
        case .down: return DesignSystem.error
        }
    }

    var label: String {
        switch self {
        case .ok: return "Healthy"
        case .connecting: return "Connecting…"
        case .down: return "Unavailable"
        }
    }
}

public struct HealthIndicatorView: View {
    @Binding private var status: HealthStatus
    private let onRetry: () -> Void

    public init(status: Binding<HealthStatus>, onRetry: @escaping () -> Void) {
        self._status = status
        self.onRetry = onRetry
    }

    public var body: some View {
        HStack(spacing: DesignSystem.spacing) {
            Circle()
                .fill(status.color)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
            Text(status.label)
                .font(DesignSystem.fontCaption)
                .foregroundColor(DesignSystem.textSecondary)
            if status != .ok {
                Button("Retry") { onRetry() }
                    .font(DesignSystem.fontCaption)
                    .buttonStyle(.borderedProminent)
                    .tint(DesignSystem.primary)
                    .accessibilityLabel("Retry health check")
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(DesignSystem.glass.opacity(0.08), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Health status: \(status.label)")
    }
}



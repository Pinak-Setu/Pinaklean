import SwiftUI

// UI-047: Keyboard shortcut helpers
enum KeyboardShortcutSupport {
    static func shortcutForAction(_ action: String) -> KeyEquivalent? {
        switch action {
        case "delete": return .delete
        case "refresh": return "r"
        case "selectAll": return "a"
        default: return nil
        }
    }
}

// UI-047: Contextual menu wrapper for any content
struct ContextualMenuWrapper<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content.contextMenu {
            Button("Select All") {}
            Button("Invert Selection") {}
            Divider()
            Button(role: .destructive) { } label: { Text("Delete") }
        }
    }
}

// UI-048: Notifications center view
struct NotificationsCenterView: View {
    @EnvironmentObject var uiState: UnifiedUIState
    var body: some View {
        List(uiState.notifications) { notification in
            HStack {
                Circle().fill(notification.type.color).frame(width: 8, height: 8)
                VStack(alignment: .leading) {
                    Text(notification.title).font(DesignSystem.fontHeadline)
                    Text(notification.message).font(DesignSystem.fontCaption).foregroundColor(DesignSystem.textTertiary)
                }
                Spacer()
                Text(notification.timestamp, style: .time).font(DesignSystem.fontCaptionSmall).foregroundColor(DesignSystem.textTertiary)
            }
        }
    }
}

// UI-049: Onboarding view
struct OnboardingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome to Pinaklean").font(DesignSystem.fontTitle).foregroundColor(DesignSystem.primary)
            Text("Safety tips: We never delete system files, dry-run is available, and backups are created when enabled.")
                .font(DesignSystem.fontBody)
                .foregroundColor(DesignSystem.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 480)
            SkeletonBlock()
        }
        .padding()
    }
}

// UI-051: Error boundary view
struct ErrorBoundary<Content: View, Fallback: View>: View {
    var fallback: () -> Fallback
    var content: () -> Content
    init(fallback: @escaping () -> Fallback, @ViewBuilder content: @escaping () -> Content) {
        self.fallback = fallback
        self.content = content
    }
    var body: some View {
        // For now, simply render content; fallback handling can be added later
        content()
    }
}


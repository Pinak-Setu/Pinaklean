import SwiftUI

// MARK: - UI-012 Segmented Control for Filters

public struct SegmentedFilterStyle { public init() {} }

public struct FilterSegmentedControl<Label: View, Filter: Hashable>: View {
    public let filters: [Filter]
    @Binding public var selection: Filter
    public let label: (Filter) -> Label

    public init(filters: [Filter], selection: Binding<Filter>, @ViewBuilder label: @escaping (Filter) -> Label) {
        self.filters = filters
        self._selection = selection
        self.label = label
    }

    public var body: some View {
        Picker("Filter", selection: $selection) {
            ForEach(Array(filters.enumerated()), id: \.offset) { _, filter in
                label(filter).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - UI-014 Badge View

public enum BadgeKind {
    case info
    case success
    case warning
    case error

    var color: Color {
        switch self {
        case .info: return DesignSystem.info
        case .success: return DesignSystem.success
        case .warning: return DesignSystem.warning
        case .error: return DesignSystem.error
        }
    }
}

public struct BadgeView<Content: View>: View {
    let kind: BadgeKind
    let content: () -> Content

    public init(kind: BadgeKind, @ViewBuilder content: @escaping () -> Content) {
        self.kind = kind
        self.content = content
    }

    public var body: some View {
        content()
            .font(DesignSystem.fontCaption)
            .foregroundColor(kind.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(kind.color.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - UI-015 Tag Chip (Removable)

public struct TagChipModel {
    public var title: String
    public var onRemove: (() -> Void)?
    public init(title: String, onRemove: (() -> Void)? = nil) {
        self.title = title
        self.onRemove = onRemove
    }
}

public struct TagChip<Content: View>: View {
    let model: TagChipModel
    let content: () -> Content

    public init(model: TagChipModel, @ViewBuilder content: @escaping () -> Content) {
        self.model = model
        self.content = content
    }

    public var body: some View {
        HStack(spacing: 6) {
            content()
            Button(action: { model.onRemove?() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(DesignSystem.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(model.title)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(DesignSystem.surface.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - UI-016 Progress Ring

public struct ProgressRingConfig {
    public var lineWidth: CGFloat = 8
    public var isIndeterminate: Bool = false
    public init(lineWidth: CGFloat = 8, isIndeterminate: Bool = false) {
        self.lineWidth = lineWidth
        self.isIndeterminate = isIndeterminate
    }
}

public struct ProgressRing: View {
    public var progress: Double // 0.0...1.0
    public var config: ProgressRingConfig

    public init(progress: Double, config: ProgressRingConfig = ProgressRingConfig()) {
        self.progress = progress
        self.config = config
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(DesignSystem.surface, lineWidth: config.lineWidth)
            Circle()
                .trim(from: 0.0, to: CGFloat(config.isIndeterminate ? 0.3 : min(max(progress, 0.0), 1.0)))
                .stroke(DesignSystem.primary, style: StrokeStyle(lineWidth: config.lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.easeInOut, value: progress)
        }
    }
}



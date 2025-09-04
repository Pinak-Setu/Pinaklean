import SwiftUI

public struct PrimaryButtonConfiguration {
    public let isLoading: Bool
    public let isDisabled: Bool
    public var isEnabled: Bool { !(isLoading || isDisabled) }
    public init(isLoading: Bool, isDisabled: Bool) {
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }
}

public struct SecondaryButton<Content: View>: View {
    let content: () -> Content
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    public var body: some View { content() }
}

public enum IconButton {
    public static let minTapTarget: CGFloat = 44
}

public struct GlassTextFieldStyle: TextFieldStyle {
    // swiftlint:disable:next identifier_name
    public func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

public struct SearchFieldModel {
    public var text: String
    public var debounceMs: Int = 300
    public mutating func clear() { text = "" }
    public init(text: String, debounceMs: Int = 300) {
        self.text = text
        self.debounceMs = debounceMs
    }
}



// UI-065: Hero metric tile component
public struct HeroMetricTile<Content: View>: View {
    let title: String
    let value: Int64
    let content: () -> Content

    public init(title: String, value: Int64, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.value = value
        self.content = content
    }

    public var body: some View {
        FrostCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(DesignSystem.fontCaption)
                    .foregroundColor(DesignSystem.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(DesignSystem.formatMetricValue(value))
                        .font(DesignSystem.fontTitle)
                        .foregroundColor(DesignSystem.primary)
                    content()
                }
            }
        }
    }
}


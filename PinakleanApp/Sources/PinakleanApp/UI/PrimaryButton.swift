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


import SwiftUI

// MARK: - UI-022 Confirmation Dialog

public struct ConfirmationDialogModel {
    public var title: String
    public var message: String
    public var confirmTitle: String
    public var cancelTitle: String
    public init(title: String, message: String, confirmTitle: String, cancelTitle: String) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
    }
}

public struct ConfirmationDialog<Content: View>: View {
    @Binding var isPresented: Bool
    let model: ConfirmationDialogModel
    let onConfirm: () -> Void
    let content: () -> Content

    public init(isPresented: Binding<Bool>, model: ConfirmationDialogModel, onConfirm: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self._isPresented = isPresented
        self.model = model
        self.onConfirm = onConfirm
        self.content = content
    }

    public var body: some View {
        ZStack {
            content()
            if isPresented {
                Color.black.opacity(0.2).ignoresSafeArea()
                VStack(spacing: DesignSystem.spacingMedium) {
                    Text(model.title).font(DesignSystem.fontHeadline).foregroundColor(DesignSystem.textPrimary)
                    Text(model.message).font(DesignSystem.fontBody).foregroundColor(DesignSystem.textSecondary).multilineTextAlignment(.center)
                    HStack(spacing: DesignSystem.spacing) {
                        Button(model.cancelTitle) { isPresented = false }
                            .font(DesignSystem.fontBody)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(DesignSystem.surface.opacity(0.6)).cornerRadius(8)
                        Button(model.confirmTitle) { onConfirm(); isPresented = false }
                            .font(DesignSystem.fontBody)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(DesignSystem.primary).foregroundColor(.white).cornerRadius(8)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding()
                .transition(.opacity)
            }
        }
    }
}

// MARK: - UI-023 Inline Error View

public struct InlineErrorView: View {
    let text: String
    let helpURL: URL?
    public init(text: String, helpURL: URL?) {
        self.text = text
        self.helpURL = helpURL
    }
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(DesignSystem.error)
            Text(text).font(DesignSystem.fontCallout).foregroundColor(DesignSystem.error)
            Spacer()
            if let url = helpURL {
                Link("Help", destination: url)
                    .font(DesignSystem.fontCaption)
            }
        }
        .padding(8)
        .background(DesignSystem.error.opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - UI-024 Dividers

public struct SubtleDivider: View {
    public init() {}
    public var body: some View {
        Divider().overlay(DesignSystem.border.opacity(0.5))
    }
}

public struct StrongDivider: View {
    public init() {}
    public var body: some View {
        Divider().overlay(DesignSystem.textSecondary.opacity(0.4))
    }
}

// MARK: - UI-025 ListRow

public struct ListRow<Meta: View>: View {
    let title: String
    let subtitle: String?
    let meta: () -> Meta
    public init(title: String, subtitle: String? = nil, @ViewBuilder meta: @escaping () -> Meta) {
        self.title = title
        self.subtitle = subtitle
        self.meta = meta
    }
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(DesignSystem.fontBody).foregroundColor(DesignSystem.textPrimary)
                if let subtitle = subtitle {
                    Text(subtitle).font(DesignSystem.fontCaption).foregroundColor(DesignSystem.textSecondary)
                }
            }
            Spacer()
            meta()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - UI-026 SettingsRow

public struct SettingsRow {
    public static func toggle(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title).font(DesignSystem.fontBody)
            Spacer()
            Toggle("", isOn: isOn).toggleStyle(SwitchToggleStyle())
        }
        .padding(.vertical, 6)
    }

    public static func dropdown(title: String, options: [String], selection: Binding<String>) -> some View {
        HStack {
            Text(title).font(DesignSystem.fontBody)
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
        }
        .padding(.vertical, 6)
    }

    public static func text(title: String, text: Binding<String>) -> some View {
        HStack {
            Text(title).font(DesignSystem.fontBody)
            Spacer()
            TextField("", text: text)
                .textFieldStyle(.plain)
                .frame(width: 180)
                .padding(6)
                .background(DesignSystem.surface.opacity(0.5))
                .cornerRadius(6)
        }
        .padding(.vertical, 6)
    }
}



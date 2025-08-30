import SwiftUI

/// Unified Design System for Pinaklean - "Liquid Crystal" Theme
/// Combining glassmorphism with functional design elements
enum DesignSystem {
    // MARK: - Colors
    static let primary = Color("TopazYellow")      // #FFD700
    static let accent = Color("RedDamask")         // #DC143C
    static let success = Color("EmeraldGreen")     // #10B981
    static let warning = Color("AmberOrange")      // #F59E0B
    static let error = Color("RubyRed")            // #EF4444
    static let info = Color("SkyBlue")             // #0EA5E9

    // Glass morphism colors
    static let glassBackground = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)
    static let glassShadow = Color.black.opacity(0.1)

    // MARK: - Spacing
    static let spacing: CGFloat = 8
    static let padding: CGFloat = 16
    static let largePadding: CGFloat = 24
    static let borderRadius: CGFloat = 12
    static let largeBorderRadius: CGFloat = 20

    // MARK: - Typography
    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 14, weight: .medium, design: .rounded)
    static let smallFont = Font.system(size: 12, weight: .regular, design: .rounded)

    // MARK: - Effects
    static let glassMaterial = Material.ultraThin
    static let blurRadius: CGFloat = 20
    static let shadowRadius: CGFloat = 10
    static let shadowY: CGFloat = 5

    // MARK: - Animations
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let interactiveSpring = Animation.interactiveSpring(response: 0.4, dampingFraction: 0.7)
    static let easeOutAnimation = Animation.easeOut(duration: 0.3)
    static let easeInOutAnimation = Animation.easeInOut(duration: 0.4)

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary.opacity(0.8), primary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassGradient = LinearGradient(
        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [accent.opacity(0.8), accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Shadows
    static func shadow(
        color: Color = .black,
        radius: CGFloat = shadowRadius,
        yOffset: CGFloat = shadowY
    ) -> some ViewModifier {
        ShadowModifier(color: color.opacity(0.1), radius: radius, yOffset: yOffset)
    }

    static func glassShadow() -> some ViewModifier {
        ShadowModifier(color: glassShadow, radius: blurRadius, yOffset: shadowY)
    }
}

// MARK: - Core Components

/// Frost Card - Main container with glassmorphism effect
struct FrostCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = DesignSystem.borderRadius
    var padding: CGFloat = DesignSystem.padding

    init(cornerRadius: CGFloat = DesignSystem.borderRadius,
         padding: CGFloat = DesignSystem.padding,
         @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(DesignSystem.glassBackground)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(DesignSystem.glassGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(DesignSystem.glassBorder, lineWidth: 1)
                )
                .shadow(color: DesignSystem.glassShadow, radius: DesignSystem.blurRadius, y: DesignSystem.shadowY)

            content
                .padding(padding)
        }
        .compositingGroup()
        .shadow(color: DesignSystem.glassShadow, radius: DesignSystem.blurRadius, y: DesignSystem.shadowY)
    }
}

/// Liquid Glass - Background container
struct LiquidGlass<Content: View>: View {
    let content: Content
    var showBackground = true

    init(showBackground: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.showBackground = showBackground
    }

    var body: some View {
        ZStack {
            if showBackground {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()

                // Animated background pattern
                GeometryReader { geometry in
                    ZStack {
                        ForEach(0..<20) { index in
                            Circle()
                                .fill(Color.white.opacity(0.02))
                                .frame(width: CGFloat.random(in: 50...200))
                                .position(
                                    x: CGFloat.random(in: 0...geometry.size.width),
                                    y: CGFloat.random(in: 0...geometry.size.height)
                                )
                                .animation(
                                    Animation.linear(duration: Double.random(in: 10...30))
                                        .repeatForever(autoreverses: true)
                                        .delay(Double.random(in: 0...10)),
                                    value: UUID()
                                )
                        }
                    }
                }
            }

            content
        }
    }
}

/// Toggle Pill - Modern toggle switch
struct TogglePill: View {
    @Binding var isOn: Bool
    let title: String
    let subtitle: String?
    let icon: String?

    init(isOn: Binding<Bool>, title: String, subtitle: String? = nil, icon: String? = nil) {
        self._isOn = isOn
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }

    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(isOn ? DesignSystem.primary : .gray)
                    .frame(width: 24)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            ZStack {
                Capsule()
                    .fill(isOn ? DesignSystem.primary.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 50, height: 28)

                Capsule()
                    .fill(isOn ? DesignSystem.primary : .gray)
                    .frame(width: 24, height: 24)
                    .offset(x: isOn ? 11 : -11)
                    .animation(DesignSystem.springAnimation, value: isOn)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(DesignSystem.springAnimation) {
                isOn.toggle()
            }
        }
    }
}

/// Progress Ring - Circular progress indicator
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat = 6
    let size: CGFloat = 60

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [DesignSystem.primary, DesignSystem.accent]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.easeOutAnimation, value: progress)

            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Complete")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Action Button - Primary action button with glass effect
struct ActionButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle {
        case primary, secondary, danger

        var background: Color {
            switch self {
            case .primary: return DesignSystem.primary
            case .secondary: return DesignSystem.glassBackground
            case .danger: return DesignSystem.error
            }
        }

        var foreground: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .primary
            case .danger: return .white
            }
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(style.foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                Capsule()
                    .fill(style.background)
                    .overlay(
                        Capsule()
                            .stroke(style == .secondary ? DesignSystem.glassBorder : .clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

/// Status Badge - Status indicator with color coding
struct StatusBadge: View {
    let status: Status
    let text: String?

    enum Status {
        case safe, warning, danger, info

        var color: Color {
            switch self {
            case .safe: return DesignSystem.success
            case .warning: return DesignSystem.warning
            case .danger: return DesignSystem.error
            case .info: return DesignSystem.info
            }
        }

        var icon: String {
            switch self {
            case .safe: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .danger: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    init(status: Status, text: String? = nil) {
        self.status = status
        self.text = text
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 12))

            if let text = text {
                Text(text)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(status.color.opacity(0.1))
        )
    }
}

/// Search Bar - Modern search input
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .font(.system(size: 16, design: .rounded))
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.borderRadius)
                .fill(DesignSystem.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.borderRadius)
                        .stroke(DesignSystem.glassBorder, lineWidth: 1)
                )
        )
    }
}

/// File Item Row - Clean file display
struct FileItemRow: View {
    let item: CleanableItem
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleSelection: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? DesignSystem.primary : .secondary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)

            // File icon
            Image(systemName: iconForCategory(item.category))
                .foregroundColor(colorForCategory(item.category))
                .frame(width: 24, height: 24)

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(item.category)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)

                    Text(item.formattedSize)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)

                    StatusBadge(status: statusForSafety(item.safetyScore))
                }
            }

            Spacer()

            // Safety score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.safetyScore)%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(colorForSafety(item.safetyScore))

                Text("Safe")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.borderRadius)
                .fill(isSelected ? DesignSystem.primary.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case ".userCaches", ".appCaches": return "trash"
        case ".logs": return "doc.text"
        case ".nodeModules": return "folder"
        case ".xcodeJunk": return "hammer"
        case ".trash": return "trash.fill"
        default: return "doc"
        }
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case ".userCaches", ".appCaches", ".trash": return .red
        case ".logs": return .blue
        case ".nodeModules", ".xcodeJunk": return .orange
        default: return .gray
        }
    }

    private func statusForSafety(_ score: Int) -> StatusBadge.Status {
        if score >= 70 { return .safe }
        if score >= 40 { return .warning }
        return .danger
    }

    private func colorForSafety(_ score: Int) -> Color {
        if score >= 70 { return .green }
        if score >= 40 { return .yellow }
        return .red
    }
}

// MARK: - View Modifiers

struct ShadowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let yOffset: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius, x: 0, y: yOffset)
    }
}

struct GlassEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.borderRadius)
                    .fill(DesignSystem.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.borderRadius)
                            .stroke(DesignSystem.glassBorder, lineWidth: 1)
                    )
            )
            .compositingGroup()
            .shadow(color: DesignSystem.glassShadow, radius: DesignSystem.blurRadius, y: DesignSystem.shadowY)
    }
}

// MARK: - Extensions

extension View {
    func glassEffect() -> some View {
        modifier(GlassEffectModifier())
    }

    func designShadow() -> some View {
        modifier(DesignSystem.shadow())
    }
}

// MARK: - Preview Provider

struct DesignSystem_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            FrostCard {
                Text("Frost Card Example")
                    .font(.title2)
            }

            TogglePill(
                isOn: .constant(true),
                title: "Enable Smart Detection",
                subtitle: "Automatically analyze files",
                icon: "brain"
            )

            ProgressRing(progress: 0.75)

            ActionButton(title: "Start Scan", icon: "magnifyingglass", style: .primary) {}

            StatusBadge(status: .safe, text: "Safe")

            SearchBar(text: .constant(""), placeholder: "Search files...")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

import SwiftUI

// UI-054: StatusBadgeView - Status indicators with glassmorphic design
struct StatusBadgeView: View {
    let status: StatusType
    let size: BadgeSize
    let style: BadgeStyle
    let showIcon: Bool
    let showText: Bool
    let animation: Animation
    
    @State private var isVisible = false
    @State private var pulseScale: CGFloat = 1.0
    
    init(
        status: StatusType,
        size: BadgeSize = .medium,
        style: BadgeStyle = .filled,
        showIcon: Bool = true,
        showText: Bool = true,
        animation: Animation = DesignSystem.spring
    ) {
        self.status = status
        self.size = size
        self.style = style
        self.showIcon = showIcon
        self.showText = showText
        self.animation = animation
    }
    
    var body: some View {
        HStack(spacing: size.iconSpacing) {
            // Icon
            if showIcon {
                status.icon
                    .font(size.iconFont)
                    .foregroundColor(iconColor)
                    .scaleEffect(pulseScale)
                    .animation(
                        status.isAnimated ? 
                        Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : 
                        .default,
                        value: pulseScale
                    )
            }
            
            // Text
            if showText {
                Text(status.text)
                    .font(size.textFont)
                    .foregroundColor(textColor)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(backgroundView)
        .overlay(overlayView)
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(animation) {
                isVisible = true
            }
            if status.isAnimated {
                startPulseAnimation()
            }
        }
        .uiLoggedAppear("StatusBadgeView")
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .filled:
            status.backgroundColor
        case .outlined:
            Color.clear
        case .glass:
            status.backgroundColor.opacity(0.2)
                .background(DesignSystem.blur)
        case .gradient:
            status.gradientBackground
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        if style == .outlined {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(status.borderColor, lineWidth: size.borderWidth)
        }
    }
    
    private var iconColor: Color {
        switch style {
        case .filled, .gradient:
            return .white
        case .outlined, .glass:
            return status.iconColor
        }
    }
    
    private var textColor: Color {
        switch style {
        case .filled, .gradient:
            return .white
        case .outlined, .glass:
            return status.textColor
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.2
        }
    }
}

// MARK: - Status Types

enum StatusType: CaseIterable {
    case success
    case warning
    case error
    case info
    case processing
    case idle
    case offline
    case online
    
    var text: String {
        switch self {
        case .success: return "Success"
        case .warning: return "Warning"
        case .error: return "Error"
        case .info: return "Info"
        case .processing: return "Processing"
        case .idle: return "Idle"
        case .offline: return "Offline"
        case .online: return "Online"
        }
    }
    
    var icon: Image {
        switch self {
        case .success: return Image(systemName: "checkmark.circle.fill")
        case .warning: return Image(systemName: "exclamationmark.triangle.fill")
        case .error: return Image(systemName: "xmark.circle.fill")
        case .info: return Image(systemName: "info.circle.fill")
        case .processing: return Image(systemName: "arrow.clockwise")
        case .idle: return Image(systemName: "pause.circle.fill")
        case .offline: return Image(systemName: "wifi.slash")
        case .online: return Image(systemName: "wifi")
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success: return DesignSystem.success
        case .warning: return DesignSystem.warning
        case .error: return DesignSystem.error
        case .info: return DesignSystem.info
        case .processing: return DesignSystem.primary
        case .idle: return DesignSystem.textSecondary
        case .offline: return DesignSystem.error
        case .online: return DesignSystem.success
        }
    }
    
    var iconColor: Color {
        switch self {
        case .success: return DesignSystem.success
        case .warning: return DesignSystem.warning
        case .error: return DesignSystem.error
        case .info: return DesignSystem.info
        case .processing: return DesignSystem.primary
        case .idle: return DesignSystem.textSecondary
        case .offline: return DesignSystem.error
        case .online: return DesignSystem.success
        }
    }
    
    var textColor: Color {
        switch self {
        case .success: return DesignSystem.success
        case .warning: return DesignSystem.warning
        case .error: return DesignSystem.error
        case .info: return DesignSystem.info
        case .processing: return DesignSystem.primary
        case .idle: return DesignSystem.textSecondary
        case .offline: return DesignSystem.error
        case .online: return DesignSystem.success
        }
    }
    
    var borderColor: Color {
        return iconColor
    }
    
    var gradientBackground: LinearGradient {
        switch self {
        case .success:
            return LinearGradient(
                colors: [DesignSystem.success, DesignSystem.success.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .warning:
            return LinearGradient(
                colors: [DesignSystem.warning, DesignSystem.warning.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .error:
            return LinearGradient(
                colors: [DesignSystem.error, DesignSystem.error.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .info:
            return LinearGradient(
                colors: [DesignSystem.info, DesignSystem.info.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .processing:
            return DesignSystem.gradientPrimary
        case .idle:
            return LinearGradient(
                colors: [DesignSystem.textSecondary, DesignSystem.textSecondary.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .offline:
            return LinearGradient(
                colors: [DesignSystem.error, DesignSystem.error.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .online:
            return LinearGradient(
                colors: [DesignSystem.success, DesignSystem.success.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var isAnimated: Bool {
        switch self {
        case .processing: return true
        default: return false
        }
    }
}

// MARK: - Badge Sizes

enum BadgeSize: CaseIterable {
    case small
    case medium
    case large
    case extraLarge
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        case .extraLarge: return 20
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        case .extraLarge: return 10
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 10
        case .extraLarge: return 12
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .small: return 1
        case .medium: return 1.5
        case .large: return 2
        case .extraLarge: return 2.5
        }
    }
    
    var iconFont: Font {
        switch self {
        case .small: return .system(size: 12, weight: .medium)
        case .medium: return .system(size: 14, weight: .medium)
        case .large: return .system(size: 16, weight: .medium)
        case .extraLarge: return .system(size: 18, weight: .medium)
        }
    }
    
    var textFont: Font {
        switch self {
        case .small: return DesignSystem.fontCaption
        case .medium: return DesignSystem.fontCallout
        case .large: return DesignSystem.fontSubheadline
        case .extraLarge: return DesignSystem.fontHeadline
        }
    }
    
    var iconSpacing: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        case .extraLarge: return 10
        }
    }
}

// MARK: - Badge Styles

enum BadgeStyle: CaseIterable {
    case filled
    case outlined
    case glass
    case gradient
    
    var description: String {
        switch self {
        case .filled: return "Filled"
        case .outlined: return "Outlined"
        case .glass: return "Glass"
        case .gradient: return "Gradient"
        }
    }
}

// MARK: - Preview

struct StatusBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            // All status types
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: DesignSystem.spacingMedium) {
                ForEach(StatusType.allCases, id: \.self) { status in
                    StatusBadgeView(
                        status: status,
                        size: .medium,
                        style: .filled
                    )
                }
            }
            
            // Size variations
            HStack(spacing: DesignSystem.spacingMedium) {
                ForEach(BadgeSize.allCases, id: \.self) { size in
                    StatusBadgeView(
                        status: .success,
                        size: size,
                        style: .filled
                    )
                }
            }
            
            // Style variations
            HStack(spacing: DesignSystem.spacingMedium) {
                ForEach(BadgeStyle.allCases, id: \.self) { style in
                    StatusBadgeView(
                        status: .info,
                        size: .medium,
                        style: style
                    )
                }
            }
            
            // Icon and text variations
            HStack(spacing: DesignSystem.spacingMedium) {
                StatusBadgeView(
                    status: .success,
                    size: .medium,
                    style: .filled,
                    showIcon: true,
                    showText: true
                )
                
                StatusBadgeView(
                    status: .success,
                    size: .medium,
                    style: .filled,
                    showIcon: true,
                    showText: false
                )
                
                StatusBadgeView(
                    status: .success,
                    size: .medium,
                    style: .filled,
                    showIcon: false,
                    showText: true
                )
            }
        }
        .padding()
        .background(DesignSystem.gradientBackground)
        .previewDisplayName("Status Badges")
    }
}
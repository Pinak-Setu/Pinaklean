import SwiftUI

// UI-053: ProgressIndicatorView - Animated progress indicator with glassmorphic design
struct ProgressIndicatorView: View {
    let progress: Double // 0.0 to 1.0
    let size: ProgressSize
    let style: ProgressStyle
    let showPercentage: Bool
    let animation: Animation
    
    @State private var animatedProgress: Double = 0
    @State private var isAnimating = false
    
    init(
        progress: Double,
        size: ProgressSize = .medium,
        style: ProgressStyle = .circular,
        showPercentage: Bool = true,
        animation: Animation = DesignSystem.spring
    ) {
        self.progress = max(0, min(1, progress))
        self.size = size
        self.style = style
        self.showPercentage = showPercentage
        self.animation = animation
    }
    
    var body: some View {
        Group {
            switch style {
            case .circular:
                CircularProgressView(
                    progress: animatedProgress,
                    size: size,
                    showPercentage: showPercentage
                )
            case .linear:
                LinearProgressView(
                    progress: animatedProgress,
                    size: size,
                    showPercentage: showPercentage
                )
            case .pulsing:
                PulsingProgressView(
                    progress: animatedProgress,
                    size: size,
                    showPercentage: showPercentage
                )
            }
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: progress) { oldValue, newValue in
            updateProgress(newValue)
        }
        .uiLoggedAppear("ProgressIndicatorView")
    }
    
    private func startAnimation() {
        withAnimation(animation) {
            animatedProgress = progress
        }
    }
    
    private func updateProgress(_ newProgress: Double) {
        withAnimation(animation) {
            animatedProgress = newProgress
        }
    }
}

// MARK: - Progress Styles

enum ProgressStyle: CaseIterable {
    case circular
    case linear
    case pulsing
    
    var description: String {
        switch self {
        case .circular: return "Circular"
        case .linear: return "Linear"
        case .pulsing: return "Pulsing"
        }
    }
}

enum ProgressSize: CaseIterable {
    case small
    case medium
    case large
    case extraLarge
    
    var dimension: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 60
        case .large: return 80
        case .extraLarge: return 120
        }
    }
    
    var strokeWidth: CGFloat {
        switch self {
        case .small: return 3
        case .medium: return 4
        case .large: return 5
        case .extraLarge: return 6
        }
    }
    
    var fontSize: Font {
        switch self {
        case .small: return DesignSystem.fontCaption
        case .medium: return DesignSystem.fontCallout
        case .large: return DesignSystem.fontHeadline
        case .extraLarge: return DesignSystem.fontTitle
        }
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let size: ProgressSize
    let showPercentage: Bool
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    DesignSystem.border,
                    style: StrokeStyle(
                        lineWidth: size.strokeWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size.dimension, height: size.dimension)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    DesignSystem.gradientPrimary,
                    style: StrokeStyle(
                        lineWidth: size.strokeWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size.dimension, height: size.dimension)
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.spring, value: progress)
            
            // Percentage text
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(size.fontSize)
                    .foregroundColor(DesignSystem.textPrimary)
                    .fontWeight(.semibold)
            }
        }
        .background(
            Circle()
                .fill(DesignSystem.glassBackground)
                .frame(width: size.dimension + 10, height: size.dimension + 10)
        )
    }
}

// MARK: - Linear Progress View

struct LinearProgressView: View {
    let progress: Double
    let size: ProgressSize
    let showPercentage: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.spacingSmall) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: size.strokeWidth / 2)
                        .fill(DesignSystem.border)
                        .frame(height: size.strokeWidth)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: size.strokeWidth / 2)
                        .fill(DesignSystem.gradientPrimary)
                        .frame(
                            width: geometry.size.width * progress,
                            height: size.strokeWidth
                        )
                        .animation(DesignSystem.spring, value: progress)
                }
            }
            .frame(height: size.strokeWidth)
            
            // Percentage text
            if showPercentage {
                HStack {
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(size.fontSize)
                        .foregroundColor(DesignSystem.textSecondary)
                        .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - Pulsing Progress View

struct PulsingProgressView: View {
    let progress: Double
    let size: ProgressSize
    let showPercentage: Bool
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // Pulsing background
            Circle()
                .fill(DesignSystem.primary.opacity(0.2))
                .frame(width: size.dimension, height: size.dimension)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: pulseScale
                )
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    DesignSystem.gradientPrimary,
                    style: StrokeStyle(
                        lineWidth: size.strokeWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size.dimension, height: size.dimension)
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.spring, value: progress)
            
            // Percentage text
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(size.fontSize)
                    .foregroundColor(DesignSystem.textPrimary)
                    .fontWeight(.semibold)
            }
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.2
            pulseOpacity = 0.3
        }
    }
}

// MARK: - Preview

struct ProgressIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignSystem.spacingLarge) {
            // Circular Progress
            HStack(spacing: DesignSystem.spacingLarge) {
                ProgressIndicatorView(
                    progress: 0.3,
                    size: .small,
                    style: .circular
                )
                
                ProgressIndicatorView(
                    progress: 0.6,
                    size: .medium,
                    style: .circular
                )
                
                ProgressIndicatorView(
                    progress: 0.9,
                    size: .large,
                    style: .circular
                )
            }
            
            // Linear Progress
            VStack(spacing: DesignSystem.spacingMedium) {
                ProgressIndicatorView(
                    progress: 0.25,
                    size: .small,
                    style: .linear
                )
                
                ProgressIndicatorView(
                    progress: 0.5,
                    size: .medium,
                    style: .linear
                )
                
                ProgressIndicatorView(
                    progress: 0.75,
                    size: .large,
                    style: .linear
                )
            }
            
            // Pulsing Progress
            HStack(spacing: DesignSystem.spacingLarge) {
                ProgressIndicatorView(
                    progress: 0.4,
                    size: .medium,
                    style: .pulsing
                )
                
                ProgressIndicatorView(
                    progress: 0.8,
                    size: .large,
                    style: .pulsing
                )
            }
        }
        .padding()
        .background(DesignSystem.gradientBackground)
        .previewDisplayName("Progress Indicators")
    }
}
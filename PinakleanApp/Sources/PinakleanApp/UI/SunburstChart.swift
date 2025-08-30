//
//  SunburstChart.swift
//  PinakleanApp
//
//  3D Sunburst chart component for disk visualization in the "Liquid Crystal" design system
//  Features interactive wedges, depth simulation, and animated transitions
//
//  Created: Data Visualization Implementation Phase
//  Features: 3D Rendering, Interactive Hover, Animated Updates, Glassmorphic Integration
//

import SwiftUI

/// 3D Sunburst chart for visualizing hierarchical data (e.g., disk usage)
/// Provides interactive segments with depth simulation and smooth animations
struct SunburstChart: View {
    let data: [SunburstSegment]
    let centerText: String?
    let centerValue: String?

    @State private var hoveredSegment: SunburstSegment.ID? = nil
    @State private var rotationAngle: Angle = .zero
    @State private var isAnimating: Bool = false

    /// Initialize with data
    init(
        data: [SunburstSegment],
        centerText: String? = nil,
        centerValue: String? = nil
    ) {
        self.data = data
        self.centerText = centerText
        self.centerValue = centerValue
    }

    var body: some View {
        ZStack {
            // Glassmorphic background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(Material.ultraThin)
                .cornerRadius(16)

            // Sunburst visualization
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let outerRadius = min(geometry.size.width, geometry.size.height) / 2 - 20

                ZStack {
                    // Render wedges
                    ForEach(data) { segment in
                        SunburstWedge(
                            segment: segment,
                            data: data,
                            center: center,
                            outerRadius: outerRadius,
                            isHovered: hoveredSegment == segment.id,
                            totalValue: data.reduce(0) { $0 + $1.value }
                        )
                        .onHover { hovering in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                hoveredSegment = hovering ? segment.id : nil
                            }
                        }
                    }

                    // Center content
                    VStack(spacing: DesignSystem.spacingSmall) {
                        if let centerText = centerText {
                            Text(centerText)
                                .font(DesignSystem.fontBody)
                                .foregroundColor(DesignSystem.textSecondary)
                        }
                        if let centerValue = centerValue {
                            Text(centerValue)
                                .font(DesignSystem.fontLargeTitle)
                                .foregroundColor(DesignSystem.textPrimary)
                        }
                    }
                    .position(center)
                    .zIndex(1)
                }
            }
            .padding(16)
        }
        .frame(minWidth: 300, minHeight: 300)
        .shadow(
            color: Color.black.opacity(0.2),
            radius: 30, x: 0, y: 15
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
        .rotationEffect(rotationAngle)
        .gesture(
            RotationGesture()
                .onChanged { angle in
                    rotationAngle = angle
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        rotationAngle = .zero
                    }
                }
        )
    }
}

/// Individual wedge in the sunburst chart with 3D depth simulation
struct SunburstWedge: View {
    let segment: SunburstSegment
    let data: [SunburstSegment]
    let center: CGPoint
    let outerRadius: CGFloat
    let isHovered: Bool
    let totalValue: Double

    var body: some View {
        ZStack {
            // Main wedge
            WedgePath(
                center: center,
                innerRadius: segment.level == 0 ? 0 : outerRadius * 0.3 * Double(segment.level),
                outerRadius: outerRadius * 0.3 * Double(segment.level + 1),
                startAngle: startAngle,
                endAngle: endAngle
            )
            .fill(segment.color.opacity(isHovered ? 1.0 : 0.8))
            .overlay(
                WedgePath(
                    center: center,
                    innerRadius: segment.level == 0 ? 0 : outerRadius * 0.3 * Double(segment.level),
                    outerRadius: outerRadius * 0.3 * Double(segment.level + 1),
                    startAngle: startAngle,
                    endAngle: endAngle
                )
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )

            // 3D depth shadow
            WedgePath(
                center: center,
                innerRadius: outerRadius * 0.3 * Double(segment.level),
                outerRadius: outerRadius * 0.3 * Double(segment.level + 1) + 2,
                startAngle: startAngle,
                endAngle: endAngle
            )
            .fill(Color.black.opacity(0.1))
            .offset(y: 2)
            .blur(radius: 1)

            // Highlight on hover
            if isHovered {
                WedgePath(
                    center: center,
                    innerRadius: segment.level == 0 ? 0 : outerRadius * 0.3 * Double(segment.level),
                    outerRadius: outerRadius * 0.3 * Double(segment.level + 1),
                    startAngle: startAngle,
                    endAngle: endAngle
                )
                .fill(Color.white.opacity(0.3))
                .blendMode(.overlay)
            }
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(DesignSystem.spring, value: isHovered)
    }

    private var startAngle: Angle {
        let cumulative = data.filter { $0.id < segment.id }.reduce(0.0) { $0 + $1.value }
        return .radians(2 * .pi * cumulative / totalValue)
    }

    private var endAngle: Angle {
        let cumulative = data.filter { $0.id <= segment.id }.reduce(0.0) { $0 + $1.value }
        return .radians(2 * .pi * cumulative / totalValue)
    }
}

/// Custom shape for wedge paths
struct WedgePath: Shape {
    let center: CGPoint
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
        let _ = CGPoint(
            x: centerPoint.x + outerRadius * cos(CGFloat(startAngle.radians)),
            y: centerPoint.y + outerRadius * sin(CGFloat(startAngle.radians))
        )
        let endOuter = CGPoint(
            x: centerPoint.x + outerRadius * cos(CGFloat(endAngle.radians)),
            y: centerPoint.y + outerRadius * sin(CGFloat(endAngle.radians))
        )

        if innerRadius > 0 {
            let _ = CGPoint(
                x: centerPoint.x + innerRadius * cos(CGFloat(startAngle.radians)),
                y: centerPoint.y + innerRadius * sin(CGFloat(startAngle.radians))
            )
            let endInner = CGPoint(
                x: centerPoint.x + innerRadius * cos(CGFloat(endAngle.radians)),
                y: centerPoint.y + innerRadius * sin(CGFloat(endAngle.radians))
            )

            path.move(to: startOuter)
            path.addArc(
                center: centerPoint,
                radius: outerRadius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.addLine(to: endInner)
            path.addArc(
                center: centerPoint,
                radius: innerRadius,
                startAngle: endAngle,
                endAngle: startAngle,
                clockwise: true
            )
            path.closeSubpath()
        } else {
            path.move(to: centerPoint)
            path.addLine(to: startOuter)
            path.addArc(
                center: centerPoint,
                radius: outerRadius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.closeSubpath()
        }

        return path
    }
}

// MARK: - Data Models

/// Segment data for sunburst chart
struct SunburstSegment: Identifiable {
    var id: Int
    let name: String
    let value: Double
    let color: Color
    let level: Int
    let children: [SunburstSegment]? = nil
}

// MARK: - Previews

struct SunburstChart_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData: [SunburstSegment] = [
            .init(id: 0, name: "System", value: 50, color: .blue, level: 0),
            .init(id: 1, name: "User", value: 30, color: .green, level: 0),
            .init(id: 2, name: "Cache", value: 20, color: .orange, level: 1),
            .init(id: 3, name: "Documents", value: 10, color: .red, level: 1),
        ]

        SunburstChart(
            return SunburstChart(
                data: sampleData,
                centerText: "Total Space",
                centerValue: "256 GB"
            )
            .frame(width: 400, height: 400)
            .preferredColorScheme(.light)
        }
    }

    // MARK: - Extensions

    extension SunburstChart {
        /// Sunburst chart with custom colors
        func customColors(_ colors: [Color]) -> some View {
            // Implementation would modify data colors
            self
        }

        /// Sunburst chart with animation delay
        func animationDelay(_ delay: Double) -> some View {
            self.onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        // Trigger animation
                    }
                }
            }
        }
    }

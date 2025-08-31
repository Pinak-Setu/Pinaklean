//
//  SankeyDiagram.swift
//  PinakleanApp
//
//  Sankey flow diagram component for visualizing data flows in the "Liquid Crystal" design system
//  Features interactive nodes, animated flows, and smooth transitions
//
//  Created: Data Visualization Implementation Phase
//  Features: Flow Animation, Interactive Nodes, Glassmorphic Integration
//

import SwiftUI

/// Sankey diagram for visualizing flow data (e.g., data cleanup flows)
/// Provides interactive nodes and animated flow paths with Liquid Crystal styling
struct SankeyDiagram: View {
    let nodes: [SankeyNode]
    let flows: [SankeyFlow]

    @State private var hoveredFlow: SankeyFlow.ID? = nil
    @State private var animationPhase: Double = 0.0

    /// Initialize with nodes and flows
    init(nodes: [SankeyNode], flows: [SankeyFlow]) {
        self.nodes = nodes
        self.flows = flows
    }

    var body: some View {
        ZStack {
            // Glassmorphic background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(Material.ultraThin)
                .cornerRadius(16)

            // Diagram visualization
            GeometryReader { geometry in
                ZStack {
                    // Render flows first (behind nodes)
                    ForEach(flows) { flow in
                        SankeyFlowView(
                            flow: flow,
                            nodes: nodes,
                            geometry: geometry,
                            isHovered: hoveredFlow == flow.id,
                            animationPhase: animationPhase
                        )
                        .onHover { hovering in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                hoveredFlow = hovering ? flow.id : nil
                            }
                        }
                    }

                    // Render nodes on top
                    ForEach(nodes) { node in
                        SankeyNodeView(node: node, geometry: geometry)
                    }
                }
            }
            .padding(16)
        }
        .frame(minWidth: 600, minHeight: 300)
        .shadow(
            color: Color.black.opacity(0.2),
            radius: 30, x: 0, y: 15
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animationPhase = 1.0
            }
        }
    }
}

/// Individual node in the Sankey diagram
struct SankeyNodeView: View {
    let node: SankeyNode
    let geometry: GeometryProxy

    var body: some View {
        let position = node.position(in: geometry.size)
        let width: CGFloat = node.isWide ? 120 : 80
        let height: CGFloat = 40

        ZStack {
            // Node rectangle
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(node.color.opacity(0.5), lineWidth: 0.5)
                )
                .background(Material.ultraThin)

            // Node content
            Text(node.label)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundColor(Color.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .position(position)
        .shadow(
            color: node.color.opacity(0.3),
            radius: 4, x: 0, y: 2
        )
    }
}

/// Flow path between nodes
struct SankeyFlowView: View {
    let flow: SankeyFlow
    let nodes: [SankeyNode]
    let geometry: GeometryProxy
    let isHovered: Bool
    let animationPhase: Double

    var body: some View {
        if let sourceNode = nodes.first(where: { $0.id == flow.sourceId }),
            let targetNode = nodes.first(where: { $0.id == flow.targetId })
        {

            let sourcePos = sourceNode.position(in: geometry.size)
            let targetPos = targetNode.position(in: geometry.size)
            let flowWidth = min(flow.value / 100 * 20, 50)  // Dynamic width based on value

            ZStack {
                // Flow path
                SankeyFlowPath(
                    source: sourcePos,
                    target: targetPos,
                    width: flowWidth,
                    color: flow.color,
                    isHovered: isHovered
                )

                // Animated flow particles
                FlowParticle(
                    from: sourcePos,
                    destinationPoint: targetPos,
                    progress: 0.5,
                    color: flow.color
                )
            }
        }
    }
}

/// Custom shape for flow paths
struct SankeyFlowPath: Shape {
    let source: CGPoint
    let target: CGPoint
    let width: CGFloat
    let color: Color
    let isHovered: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let midY = (source.y + target.y) / 2

        // Create curved flow path
        path.move(to: CGPoint(x: source.x + 40, y: source.y))
        path.addQuadCurve(
            to: CGPoint(x: target.x - 40, y: target.y),
            control: CGPoint(x: (source.x + target.x) / 2, y: midY)
        )
        path.addLine(to: CGPoint(x: target.x - 40, y: target.y + width))
        path.addQuadCurve(
            to: CGPoint(x: source.x + 40, y: source.y + width),
            control: CGPoint(x: (source.x + target.x) / 2, y: midY + width)
        )
        path.closeSubpath()

        return path
    }
}

/// Animated particle for flow visualization
struct FlowParticle: View {
    let from: CGPoint
    let destinationPoint: CGPoint
    let progress: Double
    let color: Color

    var body: some View {
        let position = CGPoint(
            x: from.x + (destinationPoint.x - from.x) * progress,
            y: from.y + (destinationPoint.y - from.y) * progress
        )

        Circle()
            .fill(color.opacity(0.7))
            .frame(width: 6, height: 6)
            .position(position)
            .shadow(color: color.opacity(0.5), radius: 3)
    }
}

// MARK: - Data Models

/// Node in Sankey diagram
struct SankeyNode: Identifiable {
    var id: Int
    let label: String
    let xCoordinate: Double  // 0.0 to 1.0
    let yCoordinate: Double  // 0.0 to 1.0
    let color: Color
    let isWide: Bool = false

    func position(in size: CGSize) -> CGPoint {
        CGPoint(x: xCoordinate * size.width, y: yCoordinate * size.height)
    }
}

/// Flow between nodes
struct SankeyFlow: Identifiable {
    var id: Int
    let sourceId: Int
    let targetId: Int
    let value: Double
    let color: Color
    let label: String? = nil
}

// MARK: - Previews

struct SankeyDiagram_Previews: PreviewProvider {
    static var previews: some View {
        let sampleNodes: [SankeyNode] = [
            SankeyNode(
                id: 0, label: "Scanned Files", xCoordinate: 0.1, yCoordinate: 0.3, color: .blue),
            SankeyNode(
                id: 1, label: "Safe to Clean", xCoordinate: 0.1, yCoordinate: 0.7, color: .green),
            SankeyNode(
                id: 2, label: "Cleanup Engine", xCoordinate: 0.5, yCoordinate: 0.5, color: .orange),
            SankeyNode(
                id: 3, label: "Space Recovered", xCoordinate: 0.9, yCoordinate: 0.4, color: .purple),
            SankeyNode(
                id: 4, label: "Protected Files", xCoordinate: 0.9, yCoordinate: 0.8, color: .red),
        ]

        let sampleFlows: [SankeyFlow] = [
            SankeyFlow(id: 0, sourceId: 0, targetId: 2, value: 50, color: .blue),
            SankeyFlow(id: 1, sourceId: 1, targetId: 2, value: 30, color: .green),
            SankeyFlow(id: 2, sourceId: 2, targetId: 3, value: 40, color: .purple),
            SankeyFlow(id: 3, sourceId: 2, targetId: 4, value: 40, color: .red),
        ]

        SankeyDiagram(nodes: sampleNodes, flows: sampleFlows)
            .frame(width: 600, height: 300)
            .preferredColorScheme(.light)
    }
}

// MARK: - Extensions

extension SankeyDiagram {
    /// Sankey diagram with custom animation
    func customAnimation(_ animation: Animation) -> some View {
        self.onAppear {
            withAnimation(animation) {
                // Custom animation trigger
            }
        }
    }

    /// Sankey diagram with flow labels
    func showFlowLabels() -> some View {
        // Implementation would add labels to flows
        self
    }
}

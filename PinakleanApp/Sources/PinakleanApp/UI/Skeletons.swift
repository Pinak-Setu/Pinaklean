import SwiftUI

// UI-044: Simple skeleton placeholder views
public struct SkeletonLine: View {
    public var width: CGFloat = 120
    public var height: CGFloat = 12
    public init(width: CGFloat = 120, height: CGFloat = 12) { self.width = width; self.height = height }
    public var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(DesignSystem.glass.opacity(0.2))
            .frame(width: width, height: height)
            .redacted(reason: .placeholder)
    }
}

public struct SkeletonBlock: View {
    public var size: CGSize = .init(width: 200, height: 120)
    public init(size: CGSize = .init(width: 200, height: 120)) { self.size = size }
    public var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(DesignSystem.glass.opacity(0.15))
            .frame(width: size.width, height: size.height)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DesignSystem.glass.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            .redacted(reason: .placeholder)
    }
}


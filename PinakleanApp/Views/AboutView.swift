import SwiftUI

/// About View for Pinaklean Application
struct AboutView: View {
    var body: some View {
        VStack(spacing: DesignSystem.largePadding) {
            // Header Section
            VStack(spacing: DesignSystem.padding) {
                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundColor(DesignSystem.primary)

                Text("Pinaklean")
                    .font(DesignSystem.titleFont)
                    .foregroundColor(.primary)

                Text("Safe macOS Cleanup Toolkit")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Version 2.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding(.top, DesignSystem.largePadding)

            // Description Section
            FrostCard {
                VStack(alignment: .leading, spacing: DesignSystem.padding) {
                    Text("About Pinaklean")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Pinaklean is an intelligent disk cleanup utility designed specifically for macOS developers. It combines advanced safety mechanisms with powerful automation to help you maintain a clean and efficient development environment.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "🛡️", title: "Safety First", description: "Comprehensive security audit before any deletion")
                        FeatureRow(icon: "🤖", title: "Smart Detection", description: "ML-powered analysis of file importance")
                        FeatureRow(icon: "⚡", title: "Parallel Processing", description: "High-performance concurrent file operations")
                        FeatureRow(icon: "☁️", title: "Cloud Backup", description: "Automatic backups to multiple free providers")
                        FeatureRow(icon: "📊", title: "Rich Analytics", description: "Detailed storage analysis and recommendations")
                    }
                }
            }

            // Stats Section
            HStack(spacing: DesignSystem.largePadding) {
                StatCard(title: "Files Cleaned", value: "1,234", icon: "trash.fill", color: DesignSystem.error)
                StatCard(title: "Space Freed", value: "45.6 GB", icon: "chart.pie.fill", color: DesignSystem.success)
                StatCard(title: "Uptime", value: "99.9%", icon: "checkmark.shield.fill", color: DesignSystem.info)
            }

            // Links Section
            FrostCard {
                VStack(spacing: DesignSystem.padding) {
                    Text("Links & Resources")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: DesignSystem.largePadding) {
                        LinkButton(title: "GitHub", icon: "link", url: "https://github.com/Pinak-Setu/Pinaklean")
                        LinkButton(title: "Documentation", icon: "book.fill", url: "https://pinaklean.dev/docs")
                        LinkButton(title: "Support", icon: "questionmark.circle.fill", url: "https://pinaklean.dev/support")
                    }
                }
            }

            // Footer
            VStack(spacing: 8) {
                Text("Made with ❤️ for developers")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Copyright © 2024 Pinaklean. All rights reserved.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, DesignSystem.padding)
        }
        .padding(DesignSystem.largePadding)
        .frame(minWidth: 600, minHeight: 700)
    }
}

// MARK: - Supporting Components

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.padding) {
            Text(icon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        FrostCard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Text(value)
                    .font(.title2)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct LinkButton: View {
    let title: String
    let icon: String
    let url: String

    var body: some View {
        Button(action: { openURL(url) }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(DesignSystem.primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(width: 80, height: 60)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.borderRadius)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Preview
struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
            .frame(width: 700, height: 800)
    }
}

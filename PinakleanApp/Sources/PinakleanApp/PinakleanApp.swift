//
//  PinakleanApp.swift
//  PinakleanApp
//
//  Main application showcasing the "Liquid Crystal" design system
//  Demonstrates glassmorphic components, animations, and responsive layout
//
//  Created: UI Implementation Phase
//  Features: Glassmorphic UI, Liquid Crystal design, Component showcase
//

import SwiftUI

/// Main Pinaklean Application with Liquid Crystal Design System
@main
struct PinakleanApp: App {
    @StateObject private var uiState = UnifiedUIState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(uiState)
                .preferredColorScheme(.dark)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.automatic)
        .commands {
            // Custom commands for Pinaklean
            CommandGroup(replacing: .newItem) {
                Button("Quick Scan") {
                    uiState.addScanActivity(foundFiles: 1234, duration: 2.5)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }

            CommandGroup(replacing: .saveItem) {
                Button("Auto Clean") {
                    uiState.addCleanActivity(cleanedBytes: 1_200_000_000, fileCount: 45)
                }
                .keyboardShortcut("s", modifiers: [.command])
            }
        }
    }
}

// MARK: - Menu Bar Content
struct MenuBarContent: View {
    @EnvironmentObject var uiState: UnifiedUIState

    var body: some View {
        VStack(spacing: DesignSystem.spacing) {
            // Status Section
            VStack(spacing: DesignSystem.spacingSmall) {
                HStack {
                    Text("🏹 Pinaklean")
                        .font(DesignSystem.fontHeadline)
                        .foregroundColor(DesignSystem.textPrimary)

                    Spacer()

                    if uiState.isProcessing {
                        ProgressView()
                            .scaleEffect(0.5)
                    } else {
                        Circle()
                            .fill(DesignSystem.success)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(uiState.isProcessing ? "Processing..." : "Ready to optimize")
                    .font(DesignSystem.fontCaption)
                    .foregroundColor(DesignSystem.textSecondary)
            }
            .padding(.horizontal)

            Divider()

            // Quick Actions
            VStack(spacing: 0) {
                MenuBarButton(
                    title: "Quick Scan",
                    icon: "🔍"
                ) {
                    uiState.addScanActivity(foundFiles: 1234, duration: 2.5)
                }

                MenuBarButton(
                    title: "Auto Clean", 
                    icon: "🧹"
                ) {
                    uiState.addCleanActivity(cleanedBytes: 1_200_000_000, fileCount: 45)
                }

                MenuBarButton(
                    title: "Show Main App",
                    icon: "📱"
                ) {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.windows.first?.makeKeyAndOrderFront(nil)
                }
            }

            Divider()

            // Footer
            VStack(spacing: DesignSystem.spacingSmall) {
                MenuBarButton(
                    title: "About Pinaklean",
                    icon: "ℹ️"
                ) {
                    let alert = NSAlert()
                    alert.messageText = "Pinaklean"
                    alert.informativeText = "Liquid Crystal macOS Cleanup Toolkit\nVersion 1.0.0"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }

                MenuBarButton(
                    title: "Quit",
                    icon: "❌"
                ) {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(.vertical, DesignSystem.spacing)
        .background(
            LiquidGlass(materialOpacity: 0.9)
                .cornerRadius(DesignSystem.cornerRadius)
        )
        .cornerRadius(DesignSystem.cornerRadius)
    }
}

// MARK: - Menu Bar Button
struct MenuBarButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.spacing) {
                Text(icon)
                    .font(.system(size: 14))

                Text(title)
                    .font(DesignSystem.fontBody)
                    .foregroundColor(DesignSystem.textPrimary)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

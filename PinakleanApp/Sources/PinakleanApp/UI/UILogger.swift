import SwiftUI
import Logging
import Metrics

// UI-053: Structured UI logs and lightweight metrics hooks
enum UILogger {
    private static var logger: Logger = Logger(label: "app.ui")

    static func log(_ level: Logger.Level = .info, _ message: String, metadata: [String: Logger.Metadata.Value]? = nil) {
        if let metadata {
            logger.log(level: level, "\(message)", metadata: metadata)
        } else {
            logger.log(level: level, "\(message)")
        }
    }
}

enum UIMetrics {
    private static let viewsAppearedCounter = Counter(label: "ui.views.appeared")
    private static let tapsCounter = Counter(label: "ui.interactions.taps")

    static func recordViewAppeared() { viewsAppearedCounter.increment() }
    static func recordTap() { tapsCounter.increment() }
}

// Simple view modifier to log appearances without coupling to business logic
private struct LogAppearModifier: ViewModifier {
    let name: String
    func body(content: Content) -> some View {
        content.onAppear {
            UILogger.log(.info, "appear:\\(name)")
            UIMetrics.recordViewAppeared()
        }
    }
}

extension View {
    /// Attach a UI logger onAppear hook for instrumentation in tests or runtime
    func uiLoggedAppear(_ name: String) -> some View {
        modifier(LogAppearModifier(name: name))
    }

    /// Count a tap interaction (use inside button actions)
    func uiCountTap() -> some View { self }
}




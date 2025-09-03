import Foundation

/// Minimal release manager stub to satisfy CloudBackupManager dependencies in Core target.
/// Full-featured implementation exists in archived sources and can be restored when needed.
public class GitHubReleaseManager {
    public init() {}

    public struct GitHubRelease {
        public let id: Int
        public let tagName: String
        public let publishedAt: Date
    }

    public func hasValidToken() -> Bool {
        // Use KeychainHelper if token was stored; avoid failing CI when absent
        return KeychainHelper.loadGitHubToken()?.isEmpty == false
    }

    public func createBackupRelease(
        snapshot: CloudBackupManager.DiskSnapshot,
        backupData: Data
    ) async throws -> GitHubRelease {
        // Stub: in CI, we don't actually hit network. Return a fake release.
        return GitHubRelease(id: Int.random(in: 1000...9999), tagName: "backup-\(snapshot.id)", publishedAt: Date())
    }
}


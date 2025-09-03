import Foundation
import os.log

/// GitHub Release Manager for creating and managing backup releases
/// Provides comprehensive GitHub API integration for backup storage and management
public class GitHubReleaseManager {
    
    private static let logger = Logger(subsystem: "com.pinaklean", category: "GitHubReleaseManager")
    
    private let apiClient: GitHubAPIClient
    private let token: String?
    
    // MARK: - Initialization
    
    /// Initialize with custom API client
    /// - Parameter apiClient: GitHub API client implementation
    public init(apiClient: GitHubAPIClient) {
        self.apiClient = apiClient
        self.token = nil
    }
    
    /// Initialize with GitHub token
    /// - Parameter token: GitHub personal access token
    public init(token: String) {
        self.token = token
        self.apiClient = GitHubAPIClientImpl(token: token)
    }
    
    /// Initialize with token from Keychain
    public convenience init() {
        if let token = KeychainHelper.loadGitHubToken() {
            self.init(token: token)
        } else {
            self.init(apiClient: GitHubAPIClientImpl(token: ""))
        }
    }
    
    // MARK: - Release Management
    
    /// Create a new GitHub release
    /// - Parameters:
    ///   - data: Release data
    ///   - assetData: Asset data to upload
    ///   - assetName: Asset file name
    /// - Returns: Created release with uploaded asset
    public func createRelease(
        data: GitHubReleaseData,
        assetData: Data,
        assetName: String
    ) async throws -> GitHubRelease {
        
        logger.info("Creating GitHub release: \(data.tagName)")
        
        // Create the release
        let release = try await apiClient.createRelease(data)
        
        // Upload the asset
        let asset = try await apiClient.uploadAsset(
            releaseId: release.id,
            assetData: assetData,
            assetName: assetName,
            contentType: getContentType(for: assetName)
        )
        
        logger.info("Successfully created release \(data.tagName) with asset \(assetName)")
        
        return release
    }
    
    /// Create a backup release from snapshot
    /// - Parameters:
    ///   - snapshot: Disk snapshot
    ///   - backupData: Backup data
    /// - Returns: Created backup release
    public func createBackupRelease(
        snapshot: DiskSnapshot,
        backupData: Data
    ) async throws -> GitHubRelease {
        
        let tagName = "backup-\(snapshot.id.uuidString.prefix(8))"
        let releaseName = "Pinaklean Backup - \(DateFormatter.shortDate.string(from: snapshot.timestamp))"
        let releaseBody = generateBackupReleaseNotes(snapshot: snapshot)
        
        let releaseData = GitHubReleaseData(
            tagName: tagName,
            name: releaseName,
            body: releaseBody,
            draft: false,
            prerelease: false
        )
        
        let assetName = "backup_\(snapshot.id.uuidString).pinaklean"
        
        return try await createRelease(
            data: releaseData,
            assetData: backupData,
            assetName: assetName
        )
    }
    
    /// Upload asset to existing release
    /// - Parameters:
    ///   - releaseId: Release ID
    ///   - assetData: Asset data
    ///   - assetName: Asset file name
    ///   - contentType: MIME content type
    /// - Returns: Uploaded asset information
    public func uploadAsset(
        releaseId: Int,
        assetData: Data,
        assetName: String,
        contentType: String
    ) async throws -> GitHubAsset {
        
        logger.info("Uploading asset \(assetName) to release \(releaseId)")
        
        let asset = try await apiClient.uploadAsset(
            releaseId: releaseId,
            assetData: assetData,
            assetName: assetName,
            contentType: contentType
        )
        
        logger.info("Successfully uploaded asset \(assetName)")
        return asset
    }
    
    // MARK: - Release Querying
    
    /// List all releases
    /// - Parameter tagPattern: Optional tag pattern filter (e.g., "backup-*")
    /// - Returns: Array of releases
    public func listReleases(tagPattern: String? = nil) async throws -> [GitHubRelease] {
        logger.info("Listing GitHub releases")
        
        let allReleases = try await apiClient.listReleases()
        
        if let pattern = tagPattern {
            let filteredReleases = allReleases.filter { release in
                release.tagName.range(of: pattern.replacingOccurrences(of: "*", with: ".*"), options: .regularExpression) != nil
            }
            logger.info("Filtered \(filteredReleases.count) releases matching pattern: \(pattern)")
            return filteredReleases
        }
        
        logger.info("Retrieved \(allReleases.count) releases")
        return allReleases
    }
    
    /// Get release by tag name
    /// - Parameter tagName: Tag name
    /// - Returns: Release if found
    public func getRelease(tagName: String) async throws -> GitHubRelease? {
        let releases = try await listReleases()
        return releases.first { $0.tagName == tagName }
    }
    
    /// Get latest release
    /// - Returns: Latest release if found
    public func getLatestRelease() async throws -> GitHubRelease? {
        let releases = try await listReleases()
        return releases.sorted { $0.publishedAt > $1.publishedAt }.first
    }
    
    // MARK: - Release Management
    
    /// Delete a release
    /// - Parameter releaseId: Release ID
    /// - Returns: True if successful
    public func deleteRelease(releaseId: Int) async throws -> Bool {
        logger.info("Deleting GitHub release: \(releaseId)")
        
        let success = try await apiClient.deleteRelease(releaseId: releaseId)
        
        if success {
            logger.info("Successfully deleted release: \(releaseId)")
        } else {
            logger.warning("Failed to delete release: \(releaseId)")
        }
        
        return success
    }
    
    /// Delete release by tag name
    /// - Parameter tagName: Tag name
    /// - Returns: True if successful
    public func deleteRelease(tagName: String) async throws -> Bool {
        guard let release = try await getRelease(tagName: tagName) else {
            logger.warning("Release not found for tag: \(tagName)")
            return false
        }
        
        return try await deleteRelease(releaseId: release.id)
    }
    
    // MARK: - Backup Management
    
    /// List all backup releases
    /// - Returns: Array of backup releases
    public func listBackupReleases() async throws -> [GitHubRelease] {
        return try await listReleases(tagPattern: "backup-*")
    }
    
    /// Clean up old backup releases
    /// - Parameter keepCount: Number of recent backups to keep
    /// - Returns: Number of releases deleted
    public func cleanupOldBackups(keepCount: Int = 10) async throws -> Int {
        logger.info("Cleaning up old backup releases, keeping \(keepCount) most recent")
        
        let backupReleases = try await listBackupReleases()
        let sortedReleases = backupReleases.sorted { $0.publishedAt > $1.publishedAt }
        
        let releasesToDelete = Array(sortedReleases.dropFirst(keepCount))
        var deletedCount = 0
        
        for release in releasesToDelete {
            do {
                let success = try await deleteRelease(releaseId: release.id)
                if success {
                    deletedCount += 1
                }
            } catch {
                logger.error("Failed to delete backup release \(release.tagName): \(error.localizedDescription)")
            }
        }
        
        logger.info("Cleaned up \(deletedCount) old backup releases")
        return deletedCount
    }
    
    // MARK: - Utility Methods
    
    /// Check if GitHub token is valid
    /// - Returns: True if token is available and valid
    public func hasValidToken() -> Bool {
        return token != nil && !token!.isEmpty
    }
    
    /// Generate release notes for backup
    /// - Parameter snapshot: Disk snapshot
    /// - Returns: Formatted release notes
    public func generateBackupReleaseNotes(snapshot: DiskSnapshot) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        
        let sizeString = formatter.string(fromByteCount: snapshot.totalSize)
        let fileCount = snapshot.fileCount
        let backupType = snapshot.metadata["type"] ?? "unknown"
        let timestamp = DateFormatter.shortDate.string(from: snapshot.timestamp)
        
        return """
        # Pinaklean Backup
        
        **Backup ID:** `\(snapshot.id.uuidString)`
        **Created:** \(timestamp)
        **Type:** \(backupType.capitalized)
        **Size:** \(sizeString)
        **Files:** \(fileCount)
        
        ## Backup Details
        
        This is an automated backup created by Pinaklean macOS cleanup tool.
        
        ### Recovery Instructions
        
        1. Download the `.pinaklean` file from the assets below
        2. Use Pinaklean's restore functionality to recover your data
        3. Ensure you have the correct encryption key in your Keychain
        
        ### Security
        
        - ✅ Encrypted with AES-256
        - ✅ Compressed for efficient storage
        - ✅ Integrity verified with checksums
        
        ---
        
        *This backup was created automatically by Pinaklean v1.0.0*
        """
    }
    
    /// Get content type for file extension
    /// - Parameter fileName: File name
    /// - Returns: MIME content type
    private func getContentType(for fileName: String) -> String {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        case "pinaklean":
            return "application/octet-stream"
        case "json":
            return "application/json"
        case "txt":
            return "text/plain"
        case "md":
            return "text/markdown"
        case "zip":
            return "application/zip"
        case "tar":
            return "application/x-tar"
        case "gz":
            return "application/gzip"
        default:
            return "application/octet-stream"
        }
    }
}

// MARK: - GitHub API Client Protocol

public protocol GitHubAPIClient {
    func createRelease(_ data: GitHubReleaseData) async throws -> GitHubRelease
    func uploadAsset(releaseId: Int, assetData: Data, assetName: String, contentType: String) async throws -> GitHubAsset
    func listReleases() async throws -> [GitHubRelease]
    func deleteRelease(releaseId: Int) async throws -> Bool
}

// MARK: - GitHub API Client Implementation

public class GitHubAPIClientImpl: GitHubAPIClient {
    
    private static let logger = Logger(subsystem: "com.pinaklean", category: "GitHubAPIClient")
    
    private let token: String
    private let baseURL = "https://api.github.com"
    private let owner: String
    private let repo: String
    
    public init(token: String, owner: String = "Pinak-Setu", repo: String = "Pinaklean") {
        self.token = token
        self.owner = owner
        self.repo = repo
    }
    
    public func createRelease(_ data: GitHubReleaseData) async throws -> GitHubRelease {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/releases")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(data)
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw GitHubAPIError.releaseCreationFailed(errorMessage)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(GitHubRelease.self, from: responseData)
    }
    
    public func uploadAsset(releaseId: Int, assetData: Data, assetName: String, contentType: String) async throws -> GitHubAsset {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/releases/\(releaseId)/assets?name=\(assetName)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = assetData
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw GitHubAPIError.assetUploadFailed(errorMessage)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(GitHubAsset.self, from: responseData)
    }
    
    public func listReleases() async throws -> [GitHubRelease] {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/releases")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw GitHubAPIError.listReleasesFailed(errorMessage)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([GitHubRelease].self, from: responseData)
    }
    
    public func deleteRelease(releaseId: Int) async throws -> Bool {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/releases/\(releaseId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }
        
        return httpResponse.statusCode == 204
    }
}

// MARK: - Data Models

public struct GitHubReleaseData: Codable {
    public let tagName: String
    public let name: String
    public let body: String
    public let draft: Bool
    public let prerelease: Bool
    
    public init(tagName: String, name: String, body: String, draft: Bool = false, prerelease: Bool = false) {
        self.tagName = tagName
        self.name = name
        self.body = body
        self.draft = draft
        self.prerelease = prerelease
    }
}

public struct GitHubRelease: Codable {
    public let id: Int
    public let tagName: String
    public let name: String
    public let body: String
    public let draft: Bool
    public let prerelease: Bool
    public let publishedAt: Date
    public let assets: [GitHubAsset]
    
    public init(id: Int, tagName: String, name: String, body: String, draft: Bool, prerelease: Bool, publishedAt: Date, assets: [GitHubAsset]) {
        self.id = id
        self.tagName = tagName
        self.name = name
        self.body = body
        self.draft = draft
        self.prerelease = prerelease
        self.publishedAt = publishedAt
        self.assets = assets
    }
}

public struct GitHubAsset: Codable {
    public let id: Int
    public let name: String
    public let size: Int64
    public let downloadUrl: String
    public let contentType: String
    
    public init(id: Int, name: String, size: Int64, downloadUrl: String, contentType: String) {
        self.id = id
        self.name = name
        self.size = size
        self.downloadUrl = downloadUrl
        self.contentType = contentType
    }
}

// MARK: - Error Types

public enum GitHubAPIError: LocalizedError {
    case invalidResponse
    case releaseCreationFailed(String)
    case assetUploadFailed(String)
    case listReleasesFailed(String)
    case releaseNotFound(Int)
    case rateLimitExceeded(Int)
    case authenticationFailed
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from GitHub API"
        case .releaseCreationFailed(let message):
            return "Failed to create release: \(message)"
        case .assetUploadFailed(let message):
            return "Failed to upload asset: \(message)"
        case .listReleasesFailed(let message):
            return "Failed to list releases: \(message)"
        case .releaseNotFound(let id):
            return "Release not found: \(id)"
        case .rateLimitExceeded(let resetTime):
            return "Rate limit exceeded. Reset at: \(resetTime)"
        case .authenticationFailed:
            return "GitHub authentication failed"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
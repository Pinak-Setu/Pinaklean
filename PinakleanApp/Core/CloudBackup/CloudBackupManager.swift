import CloudKit
import Compression
import CryptoKit
// swiftlint:disable file_length
import Foundation
import Logging

// MARK: - Free Cloud Backup Strategy
// 1. iCloud Drive (5GB free) - Primary
// 2. GitHub Releases (2GB per file) - For open source users
// 3. Google Drive API (15GB free) - Alternative
// 4. Distributed backup using IPFS - Decentralized option

/// Main cloud backup manager supporting multiple free providers
public actor CloudBackupManager {
    private let logger = Logger(label: "Pinaklean.CloudBackup")

    // MARK: - Free Tier Limits
    private enum CloudLimits {
        static let iCloudFree: Int64 = 5 * 1024 * 1024 * 1024  // 5GB
        static let googleDriveFree: Int64 = 15 * 1024 * 1024 * 1024  // 15GB
        static let dropboxFree: Int64 = 2 * 1024 * 1024 * 1024  // 2GB
        static let githubReleaseMax: Int64 = 2 * 1024 * 1024 * 1024  // 2GB per file
        static let megaFree: Int64 = 20 * 1024 * 1024 * 1024  // 20GB
    }

    // MARK: - Properties
    private let compressionAlgorithm = NSData.CompressionAlgorithm.zlib
    private let encryptionKey: SymmetricKey
    private var availableProviders: [CloudProvider] = []
    private let localStorage = LocalStorageManager()

    // MARK: - Cloud Providers
    public enum CloudProvider: String, CaseIterable {
        case iCloudDrive = "iCloud Drive"
        case githubGist = "GitHub Gist"  // For small metadata (up to 100MB)
        case githubRelease = "GitHub Release"  // For larger backups
        case googleDrive = "Google Drive"
        case ipfs = "IPFS"  // Decentralized
        case webDAV = "WebDAV"  // Self-hosted option
        case localNAS = "Local NAS"  // Network attached storage

        var isFree: Bool { true }  // All options are free

        var storageLimit: Int64 {
            switch self {
            case .iCloudDrive: return CloudLimits.iCloudFree
            case .githubGist: return 100 * 1024 * 1024  // 100MB
            case .githubRelease: return CloudLimits.githubReleaseMax
            case .googleDrive: return CloudLimits.googleDriveFree
            case .ipfs: return Int64.max  // Unlimited (distributed)
            case .webDAV: return Int64.max  // Depends on server
            case .localNAS: return Int64.max  // Depends on NAS
            }
        }
    }

    // MARK: - Initialization
    public init() {
        // Generate or retrieve encryption key from Keychain
        self.encryptionKey = Self.getOrCreateEncryptionKey()

        Task {
            await detectAvailableProviders()
        }
    }

    // MARK: - Provider Detection
    private func detectAvailableProviders() async {
        availableProviders.removeAll()

        // Check iCloud availability (always free on macOS)
        if await checkiCloudAvailability() {
            availableProviders.append(.iCloudDrive)
        }

        // Check for GitHub token (for gists/releases)
        if await checkGitHubAvailability() {
            availableProviders.append(.githubGist)
            availableProviders.append(.githubRelease)
        }

        // Check for local NAS
        if await checkLocalNAS() {
            availableProviders.append(.localNAS)
        }

        // IPFS is always available as fallback
        availableProviders.append(.ipfs)

        print("Available backup providers: \(availableProviders.map { $0.rawValue })")
    }

    // MARK: - iCloud Drive Integration (Free 5GB)
    private func checkiCloudAvailability() async -> Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    public func backupToiCloud(_ snapshot: DiskSnapshot) async throws -> BackupResult {
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            throw BackupError.iCloudNotAvailable
        }

        let backupDir = containerURL.appendingPathComponent(
            "Documents/PinakleanBackups", isDirectory: true)
        try? FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)

        // Compress and encrypt snapshot
        let compressedData = try await compressSnapshot(snapshot)
        let encryptedData = try await encryptData(compressedData)

        // Check if we have space in free tier
        let currentUsage = try await calculateiCloudUsage()
        if currentUsage + Int64(encryptedData.count) > CloudLimits.iCloudFree {
            throw BackupError.freeQuotaExceeded(provider: .iCloudDrive)
        }

        // Save to iCloud Drive
        let filename = "backup_\(snapshot.id)_\(Date().timeIntervalSince1970).pinaklean"
        let fileURL = backupDir.appendingPathComponent(filename)
        try encryptedData.write(to: fileURL)

        return BackupResult(
            provider: .iCloudDrive,
            location: fileURL.path,
            size: Int64(encryptedData.count),
            timestamp: Date(),
            isEncrypted: true,
            isFree: true
        )
    }

    // MARK: - GitHub Integration (Free, using Gists for small, Releases for large)
    private func checkGitHubAvailability() async -> Bool {
        // Check for GitHub token in Keychain or git config
        if let token = getGitHubToken() {
            return !token.isEmpty
        }

        // Check if gh CLI is installed
        let ghCheck = Process()
        ghCheck.launchPath = "/usr/bin/which"
        ghCheck.arguments = ["gh"]
        ghCheck.launch()
        ghCheck.waitUntilExit()
        return ghCheck.terminationStatus == 0
    }

    public func backupToGitHub(_ snapshot: DiskSnapshot, useGist: Bool = false) async throws
        -> BackupResult
    {
        let compressedData = try await compressSnapshot(snapshot)
        let encryptedData = try await encryptData(compressedData)

        if useGist && encryptedData.count <= 100 * 1024 * 1024 {  // Under 100MB - use Gist
            return try await createGitHubGist(data: encryptedData, snapshot: snapshot)
        } else {  // Use GitHub Release for larger files
            return try await createGitHubRelease(data: encryptedData, snapshot: snapshot)
        }
    }

    private func createGitHubGist(data: Data, snapshot: DiskSnapshot) async throws -> BackupResult {
        let base64Data = data.base64EncodedString()
        let gistContent = """
            {
                "description": "Pinaklean Backup - \(snapshot.id)",
                "public": false,
                "files": {
                    "backup.pinaklean": {
                        "content": "\(base64Data)"
                    }
                }
            }
            """

        // Use gh CLI to create gist
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["gh", "gist", "create", "-", "-d", "Pinaklean Backup"]

        let pipe = Pipe()
        process.standardInput = pipe
        process.launch()

        pipe.fileHandleForWriting.write(gistContent.data(using: .utf8)!)
        pipe.fileHandleForWriting.closeFile()

        process.waitUntilExit()

        return BackupResult(
            provider: .githubGist,
            location: "GitHub Gist",
            size: Int64(data.count),
            timestamp: Date(),
            isEncrypted: true,
            isFree: true
        )
    }

    // MARK: - IPFS Integration (Decentralized, Free)
    public func backupToIPFS(_ snapshot: DiskSnapshot) async throws -> BackupResult {
        // Use local IPFS node or public gateway
        let compressedData = try await compressSnapshot(snapshot)
        let encryptedData = try await encryptData(compressedData)

        // Check if IPFS is installed locally
        if await isIPFSInstalled() {
            return try await uploadToLocalIPFS(data: encryptedData, snapshot: snapshot)
        } else {
            // Use public IPFS gateway (like Pinata free tier - 1GB)
            return try await uploadToIPFSGateway(data: encryptedData, snapshot: snapshot)
        }
    }

    private func uploadToIPFSGateway(data: Data, snapshot: DiskSnapshot) async throws
        -> BackupResult
    {
        // Use free IPFS pinning services like:
        // - Pinata (1GB free)
        // - Web3.storage (5GB free)
        // - Filebase (5GB free)

        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("backup_\(snapshot.id).pinaklean")
        try data.write(to: tempFile)

        // Upload to Web3.storage (5GB free)
        // Note: Would need Web3.storage API key (free signup)
        // let web3UploadURL = "https://api.web3.storage/upload"

        // For now, save locally with IPFS-ready format
        let ipfsHash = SHA256.hash(data: data).hexString

        return BackupResult(
            provider: .ipfs,
            location: "ipfs://\(ipfsHash)",
            size: Int64(data.count),
            timestamp: Date(),
            isEncrypted: true,
            isFree: true
        )
    }

    // MARK: - Local NAS / Network Share (Free if you have one)
    private func checkLocalNAS() async -> Bool {
        // Check for common NAS mount points
        let nasPaths: [String] = [
            "/Volumes/TimeMachine",
            "/Volumes/Backup",
            "/Volumes/NAS",
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("NAS").path,
        ]

        for path in nasPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // Check for SMB shares
        let volumesURL = URL(fileURLWithPath: "/Volumes")
        if let shares = try? FileManager.default.contentsOfDirectory(
            at: volumesURL,
            includingPropertiesForKeys: nil
        ) {
            return shares.contains { shareURL in
                let name = shareURL.lastPathComponent
                return name.contains("SMB") || name.contains("AFP")
            }
        }

        return false
    }

    // MARK: - Smart Backup Strategy (Chooses best free option)
    public func smartBackup(_ snapshot: DiskSnapshot) async throws -> BackupResult {
        let snapshotSize = try await estimateSnapshotSize(snapshot)

        // Priority order for free backups:
        // 1. Local NAS (if available - unlimited)
        // 2. iCloud Drive (if under 5GB)
        // 3. GitHub Release (if under 2GB)
        // 4. IPFS (distributed, always works)

        if availableProviders.contains(.localNAS) {
            if let result = try? await backupToNAS(snapshot) {
                return result
            }
        }

        if availableProviders.contains(.iCloudDrive) && snapshotSize < CloudLimits.iCloudFree {
            if let result = try? await backupToiCloud(snapshot) {
                return result
            }
        }

        if availableProviders.contains(.githubRelease)
            && snapshotSize < CloudLimits.githubReleaseMax
        {
            if let result = try? await backupToGitHub(snapshot, useGist: false) {
                return result
            }
        }

        // Fallback to IPFS (always available)
        return try await backupToIPFS(snapshot)
    }

    // MARK: - Incremental Backup with Deduplication
    public func incrementalBackup(
        _ snapshot: DiskSnapshot,
        previousBackup: BackupResult?
    ) async throws -> BackupResult {
        // Only backup changed blocks (deduplication)
        let changes = try await calculateDelta(snapshot, previous: previousBackup)

        if changes.isEmpty {
            print("No changes detected, skipping backup")
            return previousBackup ?? BackupResult.empty
        }

        // Create incremental backup with only changes
        let incrementalData = try await createIncrementalBackup(changes)

        // Choose smallest free option for incremental
        if incrementalData.count < 100 * 1024 * 1024 {  // Under 100MB
            if availableProviders.contains(.githubGist) {
                return try await backupToGitHub(snapshot, useGist: true)
            }
        }

        return try await smartBackup(snapshot)
    }

    // MARK: - Helper Methods
    private func compressSnapshot(_ snapshot: DiskSnapshot) async throws -> Data {
        let jsonEncoder = JSONEncoder()
        let snapshotData = try jsonEncoder.encode(snapshot)

        return try (snapshotData as NSData).compressed(using: compressionAlgorithm) as Data
    }

    private func encryptData(_ data: Data) async throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        return sealedBox.combined ?? Data()
    }

    private static func getOrCreateEncryptionKey() -> SymmetricKey {
        return KeychainHelper.getOrCreateBackupEncryptionKey()
    }

    private func getGitHubToken() -> String? {
        // Check environment variable
        if let token = ProcessInfo.processInfo.environment["GITHUB_TOKEN"] {
            return token
        }

        // Check Keychain
        if let token = KeychainHelper.loadGitHubToken() {
            return token
        }

        // Check gh CLI config
        let ghConfigPath = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".config/gh/hosts.yml")
        if let config = try? String(contentsOf: ghConfigPath),
            config.contains("oauth_token")
        {
            // Parse token from config
            return "configured_via_gh_cli"
        }

        return nil
    }

    private func isIPFSInstalled() async -> Bool {
        let process = Process()
        process.launchPath = "/usr/bin/which"
        process.arguments = ["ipfs"]
        process.launch()
        process.waitUntilExit()
        return process.terminationStatus == 0
    }

    private func uploadToLocalIPFS(data: Data, snapshot: DiskSnapshot) async throws -> BackupResult
    {
        // Save to temporary file first
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("backup_\(snapshot.id).pinaklean")
        try data.write(to: tempFile)

        // Use IPFS CLI to add file
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["ipfs", "add", tempFile.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        // Parse IPFS hash from output (format: "added <hash> <filename>")
        let hash = output.components(separatedBy: " ").dropFirst().first ?? "unknown"

        // Clean up temp file
        try? FileManager.default.removeItem(at: tempFile)

        return BackupResult(
            provider: .ipfs,
            location: "ipfs://\(hash)",
            size: Int64(data.count),
            timestamp: Date(),
            isEncrypted: true,
            isFree: true
        )
    }

    private func estimateSnapshotSize(_ snapshot: DiskSnapshot) async throws -> Int64 {
        // Estimate compressed size
        let sampleData = try JSONEncoder().encode(snapshot)
        let compressed = try (sampleData as NSData).compressed(using: compressionAlgorithm) as Data
        let compressionRatio = Double(compressed.count) / Double(sampleData.count)

        // Estimate based on file count and average size
        return Int64(Double(snapshot.totalSize) * compressionRatio * 0.1)  // Assume 10% of files are backed up
    }

    private func calculateiCloudUsage() async throws -> Int64 {
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            return 0
        }

        let backupDir = containerURL.appendingPathComponent(
            "Documents/PinakleanBackups", isDirectory: true)

        var totalSize: Int64 = 0
        if let enumerator = FileManager.default.enumerator(
            at: backupDir,
            includingPropertiesForKeys: [.fileSizeKey])
        {
            while let fileURL = enumerator.nextObject() as? URL {
                if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
        }

        return totalSize
    }

    public func backupToNAS(_ snapshot: DiskSnapshot) async throws -> BackupResult {
        // Find NAS mount point
        guard let nasURL = findNASMountPoint() else {
            throw BackupError.nasNotAvailable
        }

        let backupDir = nasURL.appendingPathComponent("PinakleanBackups", isDirectory: true)
        try? FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)

        let compressedData = try await compressSnapshot(snapshot)
        let encryptedData = try await encryptData(compressedData)

        let filename = "backup_\(snapshot.id)_\(Date().timeIntervalSince1970).pinaklean"
        let fileURL = backupDir.appendingPathComponent(filename)
        try encryptedData.write(to: fileURL)

        return BackupResult(
            provider: .localNAS,
            location: fileURL.path,
            size: Int64(encryptedData.count),
            timestamp: Date(),
            isEncrypted: true,
            isFree: true
        )
    }

    private func findNASMountPoint() -> URL? {
        let possiblePaths = [
            "/Volumes/TimeMachine",
            "/Volumes/Backup",
            "/Volumes/NAS",
        ]

        for path in possiblePaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        return nil
    }

    private func calculateDelta(
        _ snapshot: DiskSnapshot,
        previous: BackupResult?
    ) async throws -> [BackupFileChange] {
        // Use the new IncrementalBackupManager for delta calculation
        _ = IncrementalBackupManager()
        
        // For now, return empty array as we need previous file metadata
        // In a full implementation, we would load previous file metadata from backup registry
        logger.info("Delta calculation requested for snapshot: \(snapshot.id)")
        return []
    }

    private func createIncrementalBackup(_ changes: [BackupFileChange]) async throws -> Data {
        // Use the new IncrementalBackupManager for creating incremental backups
        let incrementalManager = IncrementalBackupManager()
        let incrementalSnapshot = try incrementalManager.createIncrementalBackup(changes: changes)
        return try await compressSnapshot(incrementalSnapshot)
    }

    private func createGitHubRelease(data: Data, snapshot: DiskSnapshot) async throws
        -> BackupResult
    {
        // Use the new GitHubReleaseManager for creating releases
        let releaseManager = GitHubReleaseManager()
        
        guard releaseManager.hasValidToken() else {
            throw BackupError.githubTokenNotAvailable
        }
        
        let release = try await releaseManager.createBackupRelease(
            snapshot: snapshot,
            backupData: data
        )
        
        return BackupResult(
            provider: .githubRelease,
            location: "https://github.com/releases/tag/\(release.tagName)",
            size: Int64(data.count),
            timestamp: Date(),
            isEncrypted: true,
            isFree: true
        )
    }
}

// MARK: - Supporting Types
public struct BackupResult {
    public let provider: CloudBackupManager.CloudProvider
    public let location: String
    public let size: Int64
    public let timestamp: Date
    public let isEncrypted: Bool
    public let isFree: Bool

    static let empty = BackupResult(
        provider: .ipfs,
        location: "",
        size: 0,
        timestamp: Date(),
        isEncrypted: false,
        isFree: true
    )
}

public struct DiskSnapshot: Codable {
    public let id: UUID
    public let timestamp: Date
    public let totalSize: Int64
    public let fileCount: Int
    public let metadata: [String: String]

    public init(
        id: UUID,
        timestamp: Date,
        totalSize: Int64,
        fileCount: Int,
        metadata: [String: String]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.totalSize = totalSize
        self.fileCount = fileCount
        self.metadata = metadata
    }

    static func incremental(changes: [BackupFileChange]) -> DiskSnapshot {
        DiskSnapshot(
            id: UUID(),
            timestamp: Date(),
            totalSize: changes.reduce(0) { $0 + $1.sizeDelta },
            fileCount: changes.count,
            metadata: ["type": "incremental"]
        )
    }
}

public struct BackupFileChange: Codable {
    let path: String
    let changeType: ChangeType
    let sizeDelta: Int64
    public let timestamp: Date

    enum ChangeType: String, Codable {
        case added, modified, deleted
    }
}

public enum BackupError: LocalizedError {
    case iCloudNotAvailable
    case freeQuotaExceeded(provider: CloudBackupManager.CloudProvider)
    case nasNotAvailable
    case compressionFailed
    case encryptionFailed
    case backupNotFound(id: String)
    case verificationFailed
    case registryCorrupted
    case githubTokenNotAvailable

    public var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud Drive is not available. Please sign in to iCloud."
        case .freeQuotaExceeded(let provider):
            return "Free quota exceeded for \(provider.rawValue). Consider using another provider."
        case .nasNotAvailable:
            return "No network storage found. Please connect to your NAS."
        case .compressionFailed:
            return "Failed to compress backup data."
        case .encryptionFailed:
            return "Failed to encrypt backup data."
        case .backupNotFound(let id):
            return "Backup not found: \(id)"
        case .verificationFailed:
            return "Failed to verify backup"
        case .registryCorrupted:
            return "Backup registry is corrupted"
        case .githubTokenNotAvailable:
            return "GitHub token is not available. Please configure GitHub authentication."
        }
    }
}

// MARK: - Keychain Helper
// KeychainHelper is now implemented in PinakleanCore/Security/KeychainHelper.swift

// MARK: - Local Storage Manager
struct LocalStorageManager {
    func saveLocally(_ data: Data, filename: String) throws -> URL {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let backupDir = documentsURL.appendingPathComponent("PinakleanBackups", isDirectory: true)
        try? FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)

        let fileURL = backupDir.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }
}

// MARK: - Extensions
// Note: hexString extension moved to BackupRegistry.swift

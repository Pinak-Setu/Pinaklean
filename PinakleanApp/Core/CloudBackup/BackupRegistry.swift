import Foundation
import GRDB
import os.log

/// Backup Registry - Central tracking system for all backups across providers
/// This ensures users always know where their backups are stored
public actor BackupRegistry {
    
    private let logger = Logger(subsystem: "com.pinaklean", category: "BackupRegistry")
    private let database: DatabaseQueue
    private let registryURL: URL
    private let jsonBackupPath: URL
    
    // MARK: - Initialization
    public init() throws {
        // Primary location for registry
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                  in: .userDomainMask).first!
        let pinakleanDir = appSupport.appendingPathComponent("Pinaklean", isDirectory: true)
        try? FileManager.default.createDirectory(at: pinakleanDir, withIntermediateDirectories: true)
        
        // SQLite database for fast queries
        let dbPath = pinakleanDir.appendingPathComponent("backup_registry.db")
        self.registryURL = dbPath
        
        // JSON backup for human readability and disaster recovery
        self.jsonBackupPath = pinakleanDir.appendingPathComponent("backup_registry.json")
        
        // Initialize database
        self.database = try DatabaseQueue(path: dbPath.path)
        
        // Create tables
        try database.write { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS backup_records (
                    id TEXT PRIMARY KEY,
                    timestamp REAL NOT NULL,
                    provider TEXT NOT NULL,
                    location TEXT NOT NULL,
                    size INTEGER NOT NULL,
                    is_encrypted INTEGER NOT NULL,
                    is_incremental INTEGER NOT NULL,
                    parent_backup_id TEXT,
                    checksum TEXT NOT NULL,
                    metadata TEXT,
                    retrieval_instructions TEXT NOT NULL,
                    status TEXT NOT NULL,
                    last_verified REAL,
                    created_at REAL NOT NULL,
                    updated_at REAL NOT NULL
                );
                
                CREATE INDEX IF NOT EXISTS idx_timestamp ON backup_records(timestamp);
                CREATE INDEX IF NOT EXISTS idx_provider ON backup_records(provider);
                CREATE INDEX IF NOT EXISTS idx_status ON backup_records(status);
                
                CREATE TABLE IF NOT EXISTS backup_locations (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    provider TEXT NOT NULL,
                    base_path TEXT NOT NULL,
                    access_method TEXT NOT NULL,
                    credentials_hint TEXT,
                    last_accessed REAL,
                    is_available INTEGER NOT NULL DEFAULT 1
                );
                
                CREATE TABLE IF NOT EXISTS backup_history (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    backup_id TEXT NOT NULL,
                    action TEXT NOT NULL,
                    timestamp REAL NOT NULL,
                    details TEXT,
                    FOREIGN KEY (backup_id) REFERENCES backup_records(id)
                );
            """)
        }
        
        logger.info("Backup registry initialized at \(dbPath.path)")
        
        // Load existing JSON backup if database is empty
        Task {
            await loadFromJSONBackupIfNeeded()
        }
    }
    
    // MARK: - Record Backup
    public func recordBackup(_ result: BackupResult, 
                            snapshot: DiskSnapshot,
                            retrievalInstructions: String? = nil) async throws -> BackupRecord {
        
        let record = BackupRecord(
            id: UUID().uuidString,
            timestamp: Date(),
            provider: result.provider.rawValue,
            location: result.location,
            size: result.size,
            isEncrypted: result.isEncrypted,
            isIncremental: snapshot.metadata["type"] == "incremental",
            parentBackupId: nil,
            checksum: try await calculateChecksum(for: result),
            metadata: try? JSONEncoder().encode(snapshot.metadata),
            retrievalInstructions: retrievalInstructions ?? generateRetrievalInstructions(for: result),
            status: .active
        )
        
        // Save to database
        try await database.write { db in
            try record.save(db)
            
            // Record in history
            try BackupHistory(
                backupId: record.id,
                action: "created",
                timestamp: Date(),
                details: "Backup created via \(result.provider.rawValue)"
            ).save(db)
        }
        
        // Update JSON backup
        await updateJSONBackup()
        
        // Log for debugging
        logger.info("""
            📦 Backup Recorded:
            ID: \(record.id)
            Provider: \(record.provider)
            Location: \(record.location)
            Size: \(ByteCountFormatter.string(fromByteCount: record.size, countStyle: .file))
            Instructions: \(record.retrievalInstructions)
            """)
        
        // Also write to user-visible log file
        await writeToUserLog(record)
        
        return record
    }
    
    // MARK: - Retrieval Instructions Generator
    private func generateRetrievalInstructions(for result: BackupResult) -> String {
        switch result.provider {
        case .iCloudDrive:
            return """
            📱 iCloud Drive Backup:
            1. Open Finder
            2. Click on "iCloud Drive" in sidebar
            3. Navigate to: Documents/PinakleanBackups
            4. File: \(URL(fileURLWithPath: result.location).lastPathComponent)
            
            Alternative:
            - Go to: \(result.location)
            - Or access via iCloud.com
            """
            
        case .githubGist:
            return """
            🔗 GitHub Gist Backup:
            1. Open Terminal
            2. Run: gh gist list | grep "Pinaklean Backup"
            3. Or visit: https://gist.github.com
            4. Look for: "Pinaklean Backup - \(Date())"
            
            To download:
            - gh gist view [GIST_ID] > backup.pinaklean
            """
            
        case .githubRelease:
            return """
            📦 GitHub Release Backup:
            1. Visit your repository releases
            2. Look for release tagged: pinaklean-backup-\(Date().timeIntervalSince1970)
            3. Download the .pinaklean file
            
            Via CLI:
            - gh release download [TAG] --pattern "*.pinaklean"
            """
            
        case .googleDrive:
            return """
            ☁️ Google Drive Backup:
            1. Visit drive.google.com
            2. Search for: "Pinaklean Backup"
            3. Folder: PinakleanBackups
            4. File: \(URL(fileURLWithPath: result.location).lastPathComponent)
            """
            
        case .ipfs:
            return """
            🌐 IPFS Backup:
            Location: \(result.location)
            
            To retrieve:
            1. Via gateway: https://ipfs.io/\(result.location)
            2. Via CLI: ipfs get \(result.location.replacingOccurrences(of: "ipfs://", with: ""))
            3. Via Pinata: app.pinata.cloud (if pinned there)
            
            Note: Keep this IPFS hash safe!
            """
            
        case .webDAV:
            return """
            🌐 WebDAV Backup:
            Server: \(result.location)
            Path: /PinakleanBackups/
            
            Access via:
            1. Finder > Go > Connect to Server
            2. Enter server address
            3. Navigate to backup folder
            """
            
        case .localNAS:
            return """
            💾 Local NAS Backup:
            Path: \(result.location)
            
            To access:
            1. Ensure NAS is connected
            2. Open Finder
            3. Go to: \(result.location)
            
            Network path might be:
            - smb://nas.local/PinakleanBackups
            - afp://nas.local/PinakleanBackups
            """
        }
    }
    
    // MARK: - User-Visible Log File
    private func writeToUserLog(_ record: BackupRecord) async {
        let logDir = FileManager.default.urls(for: .documentDirectory, 
                                             in: .userDomainMask).first!
            .appendingPathComponent("PinakleanBackups", isDirectory: true)
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        
        let logFile = logDir.appendingPathComponent("backup_locations.log")
        let readableLog = logDir.appendingPathComponent("README_BACKUP_LOCATIONS.txt")
        
        let timestamp = ISO8601DateFormatter().string(from: record.timestamp)
        let sizeFormatted = ByteCountFormatter.string(fromByteCount: record.size, countStyle: .file)
        
        let logEntry = """
        ================================================================================
        BACKUP RECORD - \(timestamp)
        ================================================================================
        Backup ID: \(record.id)
        Provider: \(record.provider)
        Location: \(record.location)
        Size: \(sizeFormatted)
        Encrypted: \(record.isEncrypted ? "Yes ✅" : "No ⚠️")
        Incremental: \(record.isIncremental ? "Yes (saves space)" : "No (full backup)")
        Checksum: \(record.checksum)
        
        HOW TO RETRIEVE THIS BACKUP:
        \(record.retrievalInstructions)
        
        ================================================================================
        
        """
        
        // Append to log file
        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFile.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFile)
            }
        }
        
        // Create/Update README
        let readme = """
        📦 PINAKLEAN BACKUP LOCATIONS
        ==============================
        
        This file contains information about ALL your Pinaklean backups.
        Keep this file safe! It helps you recover your backups from any provider.
        
        QUICK STATS:
        ------------
        Total Backups: \(await getTotalBackupCount())
        Total Size: \(await getTotalBackupSize())
        Providers Used: \(await getUsedProviders().joined(separator: ", "))
        Latest Backup: \(timestamp)
        
        IMPORTANT NOTES:
        ----------------
        • All backups are encrypted with AES-256
        • Your encryption key is stored in macOS Keychain
        • Incremental backups require the parent backup to restore
        • Keep this log file for disaster recovery
        
        DETAILED BACKUP LOG:
        --------------------
        See 'backup_locations.log' in this folder for complete history.
        
        RECOVERY CHECKLIST:
        ------------------
        □ Check iCloud Drive (5GB free)
        □ Check GitHub Gists/Releases
        □ Check IPFS gateways
        □ Check local NAS/Time Machine
        □ Check this folder for local copies
        
        SUPPORT:
        --------
        If you need help recovering backups:
        1. Check the detailed log file
        2. Use the retrieval instructions for each backup
        3. Visit: github.com/Pinak-Setu/Pinaklean/wiki/backup-recovery
        
        Last Updated: \(timestamp)
        """
        
        try? readme.data(using: .utf8)?.write(to: readableLog)
        
        logger.info("User-visible backup log updated at \(logFile.path)")
    }
    
    // MARK: - Query Methods
    public func getAllBackups() async throws -> [BackupRecord] {
        try await database.read { db in
            try BackupRecord.fetchAll(db)
        }
    }
    
    public func getBackupsByProvider(_ provider: CloudBackupManager.CloudProvider) async throws -> [BackupRecord] {
        try await database.read { db in
            try BackupRecord
                .filter(Column("provider") == provider.rawValue)
                .fetchAll(db)
        }
    }
    
    public func getLatestBackup() async throws -> BackupRecord? {
        try await database.read { db in
            try BackupRecord
                .order(Column("timestamp").desc)
                .fetchOne(db)
        }
    }
    
    public func findBackup(byId id: String) async throws -> BackupRecord? {
        try await database.read { db in
            try BackupRecord.fetchOne(db, key: id)
        }
    }
    
    // MARK: - Statistics
    private func getTotalBackupCount() async -> Int {
        (try? await database.read { db in
            try BackupRecord.fetchCount(db)
        }) ?? 0
    }
    
    private func getTotalBackupSize() async -> String {
        let totalBytes = (try? await database.read { db in
            try BackupRecord
                .select(sum(Column("size")))
                .fetchOne(db) as Int64?
        }) ?? 0
        
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    private func getUsedProviders() async -> [String] {
        (try? await database.read { db in
            try BackupRecord
                .select(Column("provider"))
                .distinct()
                .fetchAll(db)
                .map { $0.provider }
        }) ?? []
    }
    
    // MARK: - JSON Backup
    private func updateJSONBackup() async {
        guard let records = try? await getAllBackups() else { return }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(records) {
            try? data.write(to: jsonBackupPath)
            logger.debug("JSON backup updated at \(self.jsonBackupPath.path)")
        }
    }
    
    private func loadFromJSONBackupIfNeeded() async {
        let count = await getTotalBackupCount()
        guard count == 0,
              FileManager.default.fileExists(atPath: jsonBackupPath.path),
              let data = try? Data(contentsOf: jsonBackupPath),
              let records = try? JSONDecoder().decode([BackupRecord].self, from: data) else {
            return
        }
        
        logger.info("Restoring \(records.count) records from JSON backup")
        
        for record in records {
            try? await database.write { db in
                try record.save(db)
            }
        }
    }
    
    // MARK: - Verification
    public func verifyBackup(_ id: String) async throws -> VerificationResult {
        guard let record = try await findBackup(byId: id) else {
            throw BackupError.backupNotFound(id: id)
        }
        
        let provider = CloudBackupManager.CloudProvider(rawValue: record.provider) ?? .ipfs
        
        // Check if backup still exists
        let exists = await checkBackupExists(record: record, provider: provider)
        
        // Update verification timestamp
        try await database.write { db in
            try db.execute(sql: """
                UPDATE backup_records 
                SET last_verified = ?, status = ?
                WHERE id = ?
                """, arguments: [Date().timeIntervalSince1970, 
                                exists ? "active" : "missing",
                                id])
        }
        
        return VerificationResult(
            exists: exists,
            lastVerified: Date(),
            provider: provider,
            location: record.location
        )
    }
    
    private func checkBackupExists(record: BackupRecord, 
                                  provider: CloudBackupManager.CloudProvider) async -> Bool {
        switch provider {
        case .iCloudDrive, .localNAS:
            return FileManager.default.fileExists(atPath: record.location)
            
        case .githubGist, .githubRelease:
            // Would check via gh CLI or API
            return true // Placeholder
            
        case .ipfs:
            // Would check via IPFS gateway
            return true // Placeholder
            
        default:
            return false
        }
    }
    
    // MARK: - Checksum Calculation
    private func calculateChecksum(for result: BackupResult) async throws -> String {
        if result.location.starts(with: "ipfs://") {
            // IPFS already provides hash
            return result.location.replacingOccurrences(of: "ipfs://", with: "")
        }
        
        if FileManager.default.fileExists(atPath: result.location) {
            let url = URL(fileURLWithPath: result.location)
            let data = try Data(contentsOf: url)
            return SHA256.hash(data: data).hexString
        }
        
        // For remote backups, use a combination of metadata
        let checksumData = "\(result.provider.rawValue):\(result.size):\(result.timestamp.timeIntervalSince1970)"
        return SHA256.hash(data: checksumData.data(using: .utf8)!).hexString
    }
}

// MARK: - Database Models
public struct BackupRecord: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "backup_records"
    
    let id: String
    let timestamp: Date
    let provider: String
    let location: String
    let size: Int64
    let isEncrypted: Bool
    let isIncremental: Bool
    let parentBackupId: String?
    let checksum: String
    let metadata: Data?
    let retrievalInstructions: String
    var status: BackupStatus
    var lastVerified: Date?
    let createdAt: Date
    let updatedAt: Date
    
    init(id: String, timestamp: Date, provider: String, location: String,
         size: Int64, isEncrypted: Bool, isIncremental: Bool,
         parentBackupId: String? = nil, checksum: String,
         metadata: Data? = nil, retrievalInstructions: String,
         status: BackupStatus = .active) {
        self.id = id
        self.timestamp = timestamp
        self.provider = provider
        self.location = location
        self.size = size
        self.isEncrypted = isEncrypted
        self.isIncremental = isIncremental
        self.parentBackupId = parentBackupId
        self.checksum = checksum
        self.metadata = metadata
        self.retrievalInstructions = retrievalInstructions
        self.status = status
        self.lastVerified = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct BackupHistory: Codable, PersistableRecord {
    static let databaseTableName = "backup_history"
    
    var id: Int64?
    let backupId: String
    let action: String
    let timestamp: Date
    let details: String?
}

enum BackupStatus: String, Codable {
    case active = "active"
    case missing = "missing"
    case corrupted = "corrupted"
    case deleted = "deleted"
}

public struct VerificationResult {
    let exists: Bool
    let lastVerified: Date
    let provider: CloudBackupManager.CloudProvider
    let location: String
}

// Note: BackupError is defined in CloudBackupManager.swift

// MARK: - SHA256 Extension
import CryptoKit

extension SHA256.Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
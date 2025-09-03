import Foundation
import os.log

/// Comprehensive configuration management system for Pinaklean
/// Provides structured configuration with validation, migration, and synchronization support
public class ConfigurationManager {
    
    private static let logger = Logger(subsystem: "com.pinaklean", category: "ConfigurationManager")
    
    private let configDirectory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    // MARK: - Configuration File Paths
    
    private var applicationConfigPath: URL {
        configDirectory.appendingPathComponent("application_config.json")
    }
    
    private var scanSettingsPath: URL {
        configDirectory.appendingPathComponent("scan_settings.json")
    }
    
    private var backupSettingsPath: URL {
        configDirectory.appendingPathComponent("backup_settings.json")
    }
    
    private var securitySettingsPath: URL {
        configDirectory.appendingPathComponent("security_settings.json")
    }
    
    private var userPreferencesPath: URL {
        configDirectory.appendingPathComponent("user_preferences.json")
    }
    
    // MARK: - Initialization
    
    /// Initialize configuration manager with custom directory
    /// - Parameter configDirectory: Directory to store configuration files
    public init(configDirectory: URL) {
        self.configDirectory = configDirectory
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: configDirectory, withIntermediateDirectories: true)
        
        // Configure JSON encoder/decoder
        self.encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        logger.info("ConfigurationManager initialized with directory: \(configDirectory.path)")
    }
    
    /// Initialize with default application support directory
    public convenience init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let pinakleanDir = appSupport.appendingPathComponent("Pinaklean", isDirectory: true)
        self.init(configDirectory: pinakleanDir)
    }
    
    // MARK: - Application Configuration
    
    /// Load complete application configuration
    public func loadApplicationConfiguration() -> ApplicationConfiguration {
        do {
            let data = try Data(contentsOf: applicationConfigPath)
            let config = try decoder.decode(ApplicationConfiguration.self, from: data)
            logger.debug("Loaded application configuration from file")
            return config
        } catch {
            logger.info("No application configuration found, using defaults")
            return ApplicationConfiguration.default
        }
    }
    
    /// Save application configuration
    public func saveApplicationConfiguration(_ config: ApplicationConfiguration) throws {
        let validationResult = validateConfiguration(config)
        guard validationResult.isValid else {
            throw ConfigurationError.validationFailed(errors: validationResult.errors)
        }
        
        let data = try encoder.encode(config)
        try data.write(to: applicationConfigPath)
        logger.info("Saved application configuration")
    }
    
    // MARK: - Scan Settings
    
    /// Load scan settings
    public func loadScanSettings() -> ScanSettings {
        do {
            let data = try Data(contentsOf: scanSettingsPath)
            let settings = try decoder.decode(ScanSettings.self, from: data)
            logger.debug("Loaded scan settings from file")
            return settings
        } catch {
            logger.info("No scan settings found, using defaults")
            return ScanSettings.default
        }
    }
    
    /// Save scan settings
    public func saveScanSettings(_ settings: ScanSettings) throws {
        let validationResult = validateScanSettings(settings)
        guard validationResult.isValid else {
            throw ConfigurationError.validationFailed(errors: validationResult.errors)
        }
        
        let data = try encoder.encode(settings)
        try data.write(to: scanSettingsPath)
        logger.info("Saved scan settings")
    }
    
    // MARK: - Backup Settings
    
    /// Load backup settings
    public func loadBackupSettings() -> BackupSettings {
        do {
            let data = try Data(contentsOf: backupSettingsPath)
            let settings = try decoder.decode(BackupSettings.self, from: data)
            logger.debug("Loaded backup settings from file")
            return settings
        } catch {
            logger.info("No backup settings found, using defaults")
            return BackupSettings.default
        }
    }
    
    /// Save backup settings
    public func saveBackupSettings(_ settings: BackupSettings) throws {
        let validationResult = validateBackupSettings(settings)
        guard validationResult.isValid else {
            throw ConfigurationError.validationFailed(errors: validationResult.errors)
        }
        
        let data = try encoder.encode(settings)
        try data.write(to: backupSettingsPath)
        logger.info("Saved backup settings")
    }
    
    // MARK: - Security Settings
    
    /// Load security settings
    public func loadSecuritySettings() -> SecuritySettings {
        do {
            let data = try Data(contentsOf: securitySettingsPath)
            let settings = try decoder.decode(SecuritySettings.self, from: data)
            logger.debug("Loaded security settings from file")
            return settings
        } catch {
            logger.info("No security settings found, using defaults")
            return SecuritySettings.default
        }
    }
    
    /// Save security settings
    public func saveSecuritySettings(_ settings: SecuritySettings) throws {
        let validationResult = validateSecuritySettings(settings)
        guard validationResult.isValid else {
            throw ConfigurationError.validationFailed(errors: validationResult.errors)
        }
        
        let data = try encoder.encode(settings)
        try data.write(to: securitySettingsPath)
        logger.info("Saved security settings")
    }
    
    // MARK: - User Preferences
    
    /// Load user preferences
    public func loadUserPreferences() -> UserPreferences {
        do {
            let data = try Data(contentsOf: userPreferencesPath)
            let preferences = try decoder.decode(UserPreferences.self, from: data)
            logger.debug("Loaded user preferences from file")
            return preferences
        } catch {
            logger.info("No user preferences found, using defaults")
            return UserPreferences.default
        }
    }
    
    /// Save user preferences
    public func saveUserPreferences(_ preferences: UserPreferences) throws {
        let data = try encoder.encode(preferences)
        try data.write(to: userPreferencesPath)
        logger.info("Saved user preferences")
    }
    
    // MARK: - Configuration Validation
    
    /// Validate complete application configuration
    public func validateConfiguration(_ config: ApplicationConfiguration) -> ValidationResult {
        var errors: [String] = []
        
        // Validate scan settings
        let scanValidation = validateScanSettings(config.scanSettings)
        if !scanValidation.isValid {
            errors.append(contentsOf: scanValidation.errors.map { "Scan: \($0)" })
        }
        
        // Validate backup settings
        let backupValidation = validateBackupSettings(config.backupSettings)
        if !backupValidation.isValid {
            errors.append(contentsOf: backupValidation.errors.map { "Backup: \($0)" })
        }
        
        // Validate security settings
        let securityValidation = validateSecuritySettings(config.securitySettings)
        if !securityValidation.isValid {
            errors.append(contentsOf: securityValidation.errors.map { "Security: \($0)" })
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    /// Validate scan settings
    private func validateScanSettings(_ settings: ScanSettings) -> ValidationResult {
        var errors: [String] = []
        
        if settings.maxFileSize <= 0 {
            errors.append("maxFileSize must be positive")
        }
        
        if settings.maxFileSize > 10 * 1024 * 1024 * 1024 { // 10GB
            errors.append("maxFileSize too large (max 10GB)")
        }
        
        for path in settings.excludedPaths {
            if !path.hasPrefix("/") {
                errors.append("Excluded path must be absolute: \(path)")
            }
        }
        
        for ext in settings.includedExtensions {
            if !ext.hasPrefix(".") {
                errors.append("Extension must start with dot: \(ext)")
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    /// Validate backup settings
    private func validateBackupSettings(_ settings: BackupSettings) -> ValidationResult {
        var errors: [String] = []
        
        if settings.retentionDays < 0 {
            errors.append("retentionDays must be non-negative")
        }
        
        if settings.retentionDays > 365 {
            errors.append("retentionDays too large (max 365 days)")
        }
        
        if settings.providers.isEmpty {
            errors.append("At least one backup provider must be selected")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    /// Validate security settings
    private func validateSecuritySettings(_ settings: SecuritySettings) -> ValidationResult {
        var errors: [String] = []
        
        if settings.auditLevel == .invalid {
            errors.append("Invalid audit level")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Configuration Migration
    
    /// Migrate from old configuration format
    public func migrateFromOldFormat(_ oldConfigPath: URL) throws {
        guard FileManager.default.fileExists(atPath: oldConfigPath.path) else {
            throw ConfigurationError.fileNotFound(oldConfigPath.path)
        }
        
        let data = try Data(contentsOf: oldConfigPath)
        
        // Try to parse as old format
        guard let oldConfig = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ConfigurationError.migrationFailed(reason: "Invalid JSON format")
        }
        
        // Create new configuration with migrated values
        var newConfig = ApplicationConfiguration.default
        
        // Migrate scan settings
        if let includeHidden = oldConfig["scan_include_hidden"] as? Bool {
            newConfig.scanSettings.includeHiddenFiles = includeHidden
        }
        
        if let maxSize = oldConfig["scan_max_size"] as? Int {
            newConfig.scanSettings.maxFileSize = Int64(maxSize)
        }
        
        // Migrate backup settings
        if let backupEnabled = oldConfig["backup_enabled"] as? Bool {
            newConfig.backupSettings.enabled = backupEnabled
        }
        
        // Save migrated configuration
        try saveApplicationConfiguration(newConfig)
        
        // Archive old configuration
        let archivePath = configDirectory.appendingPathComponent("migrated_config_\(Date().timeIntervalSince1970).json")
        try data.write(to: archivePath)
        
        logger.info("Successfully migrated configuration from old format")
    }
    
    // MARK: - Configuration Backup and Restore
    
    /// Backup current configuration
    public func backupConfiguration() throws -> URL {
        let timestamp = Date().timeIntervalSince1970
        let backupPath = configDirectory.appendingPathComponent("config_backup_\(timestamp).json")
        
        let config = loadApplicationConfiguration()
        let data = try encoder.encode(config)
        try data.write(to: backupPath)
        
        logger.info("Configuration backed up to: \(backupPath.path)")
        return backupPath
    }
    
    /// Restore configuration from backup
    public func restoreConfiguration(from backupPath: URL) throws {
        guard FileManager.default.fileExists(atPath: backupPath.path) else {
            throw ConfigurationError.fileNotFound(backupPath.path)
        }
        
        let data = try Data(contentsOf: backupPath)
        let config = try decoder.decode(ApplicationConfiguration.self, from: data)
        
        // Validate before restoring
        let validationResult = validateConfiguration(config)
        guard validationResult.isValid else {
            throw ConfigurationError.validationFailed(errors: validationResult.errors)
        }
        
        try saveApplicationConfiguration(config)
        logger.info("Configuration restored from: \(backupPath.path)")
    }
    
    // MARK: - Configuration Synchronization
    
    /// Export configuration for synchronization
    public func exportConfigurationForSync(_ config: ApplicationConfiguration) throws -> Data {
        let syncData = ConfigurationSyncData(
            version: "1.0",
            timestamp: Date(),
            configuration: config
        )
        
        return try encoder.encode(syncData)
    }
    
    /// Import configuration from synchronization
    public func importConfigurationFromSync(_ data: Data) throws -> ApplicationConfiguration {
        let syncData = try decoder.decode(ConfigurationSyncData.self, from: data)
        
        // Validate version compatibility
        guard syncData.version == "1.0" else {
            throw ConfigurationError.invalidSyncData
        }
        
        // Validate configuration
        let validationResult = validateConfiguration(syncData.configuration)
        guard validationResult.isValid else {
            throw ConfigurationError.validationFailed(errors: validationResult.errors)
        }
        
        return syncData.configuration
    }
    
    // MARK: - Configuration Reset
    
    /// Reset all configuration to defaults
    public func resetToDefaults() throws {
        let defaultConfig = ApplicationConfiguration.default
        try saveApplicationConfiguration(defaultConfig)
        
        // Also reset individual settings files
        try saveScanSettings(defaultConfig.scanSettings)
        try saveBackupSettings(defaultConfig.backupSettings)
        try saveSecuritySettings(defaultConfig.securitySettings)
        
        logger.info("Configuration reset to defaults")
    }
    
    // MARK: - Configuration Statistics
    
    /// Get configuration statistics
    public func getConfigurationStatistics() -> ConfigurationStatistics {
        let config = loadApplicationConfiguration()
        
        return ConfigurationStatistics(
            totalSettings: 4, // scan, backup, security, user preferences
            configuredSettings: [
                config.scanSettings.includeHiddenFiles ? "scan.includeHidden" : nil,
                config.backupSettings.enabled ? "backup.enabled" : nil,
                config.securitySettings.performSecurityAudit ? "security.audit" : nil,
                config.userPreferences.showAdvancedOptions ? "ui.advanced" : nil
            ].compactMap { $0 },
            lastModified: getLastModifiedDate(),
            configurationSize: getConfigurationSize()
        )
    }
    
    private func getLastModifiedDate() -> Date {
        let paths = [applicationConfigPath, scanSettingsPath, backupSettingsPath, securitySettingsPath, userPreferencesPath]
        var latestDate = Date.distantPast
        
        for path in paths {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: path.path),
               let modificationDate = attributes[.modificationDate] as? Date {
                latestDate = max(latestDate, modificationDate)
            }
        }
        
        return latestDate
    }
    
    private func getConfigurationSize() -> Int64 {
        let paths = [applicationConfigPath, scanSettingsPath, backupSettingsPath, securitySettingsPath, userPreferencesPath]
        var totalSize: Int64 = 0
        
        for path in paths {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: path.path),
               let size = attributes[.size] as? Int64 {
                totalSize += size
            }
        }
        
        return totalSize
    }
}

// MARK: - Configuration Models

/// Complete application configuration
public struct ApplicationConfiguration: Codable {
    public let scanSettings: ScanSettings
    public let backupSettings: BackupSettings
    public let securitySettings: SecuritySettings
    public let userPreferences: UserPreferences
    
    public static let `default` = ApplicationConfiguration(
        scanSettings: ScanSettings.default,
        backupSettings: BackupSettings.default,
        securitySettings: SecuritySettings.default,
        userPreferences: UserPreferences.default
    )
}

/// Scan settings configuration
public struct ScanSettings: Codable {
    public var includeHiddenFiles: Bool
    public var maxFileSize: Int64
    public var excludedPaths: [String]
    public var includedExtensions: [String]
    public var scanDepth: Int
    public var parallelScanning: Bool
    
    public static let `default` = ScanSettings(
        includeHiddenFiles: false,
        maxFileSize: 1024 * 1024 * 1024, // 1GB
        excludedPaths: ["/System", "/Applications", "/Library"],
        includedExtensions: [],
        scanDepth: 10,
        parallelScanning: true
    )
}

/// Backup settings configuration
public struct BackupSettings: Codable {
    public var enabled: Bool
    public var providers: [BackupProvider]
    public var encryptionEnabled: Bool
    public var compressionEnabled: Bool
    public var retentionDays: Int
    public var autoBackup: Bool
    public var backupInterval: TimeInterval
    
    public static let `default` = BackupSettings(
        enabled: true,
        providers: [.iCloudDrive],
        encryptionEnabled: true,
        compressionEnabled: true,
        retentionDays: 30,
        autoBackup: false,
        backupInterval: 24 * 60 * 60 // 24 hours
    )
}

/// Security settings configuration
public struct SecuritySettings: Codable {
    public var performSecurityAudit: Bool
    public var checkFilePermissions: Bool
    public var requireConfirmationForDeletion: Bool
    public var auditLevel: SecurityAuditLevel
    public var enableFileIntegrityCheck: Bool
    public var quarantineSuspiciousFiles: Bool
    
    public static let `default` = SecuritySettings(
        performSecurityAudit: true,
        checkFilePermissions: true,
        requireConfirmationForDeletion: true,
        auditLevel: .standard,
        enableFileIntegrityCheck: false,
        quarantineSuspiciousFiles: false
    )
}

/// User preferences configuration
public struct UserPreferences: Codable {
    public var theme: AppTheme
    public var language: String
    public var showAdvancedOptions: Bool
    public var enableNotifications: Bool
    public var enableAnalytics: Bool
    public var enableCrashReporting: Bool
    
    public static let `default` = UserPreferences(
        theme: .system,
        language: "en",
        showAdvancedOptions: false,
        enableNotifications: true,
        enableAnalytics: false,
        enableCrashReporting: true
    )
}

// MARK: - Supporting Types

public enum BackupProvider: String, Codable, CaseIterable {
    case iCloudDrive = "iCloud Drive"
    case githubGist = "GitHub Gist"
    case githubRelease = "GitHub Release"
    case googleDrive = "Google Drive"
    case ipfs = "IPFS"
    case webDAV = "WebDAV"
    case localNAS = "Local NAS"
}

public enum SecurityAuditLevel: String, Codable, CaseIterable {
    case basic = "basic"
    case standard = "standard"
    case strict = "strict"
    case invalid = "invalid"
}

public enum AppTheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
}

public struct ValidationResult {
    public let isValid: Bool
    public let errors: [String]
}

public struct ConfigurationSyncData: Codable {
    public let version: String
    public let timestamp: Date
    public let configuration: ApplicationConfiguration
}

public struct ConfigurationStatistics: Codable {
    public let totalSettings: Int
    public let configuredSettings: [String]
    public let lastModified: Date
    public let configurationSize: Int64
}

// MARK: - Error Types

public enum ConfigurationError: LocalizedError {
    case fileNotFound(String)
    case validationFailed(errors: [String])
    case migrationFailed(reason: String)
    case invalidSyncData
    case invalidValue(key: String, value: String, reason: String)
    case saveFailed(String)
    case loadFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Configuration file not found: \(path)"
        case .validationFailed(let errors):
            return "Configuration validation failed: \(errors.joined(separator: ", "))"
        case .migrationFailed(let reason):
            return "Configuration migration failed: \(reason)"
        case .invalidSyncData:
            return "Invalid synchronization data"
        case .invalidValue(let key, let value, let reason):
            return "Invalid value for '\(key)': \(value) - \(reason)"
        case .saveFailed(let reason):
            return "Failed to save configuration: \(reason)"
        case .loadFailed(let reason):
            return "Failed to load configuration: \(reason)"
        }
    }
}
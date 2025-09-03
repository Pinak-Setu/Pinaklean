import XCTest
import Quick
import Nimble
@testable import PinakleanCore

class ConfigurationManagerTests: QuickSpec {
    override func spec() {
        describe("ConfigurationManager") {
            var configManager: ConfigurationManager!
            var tempDirectory: URL!
            
            beforeEach {
                tempDirectory = FileManager.default.temporaryDirectory
                    .appendingPathComponent("ConfigurationManagerTests")
                try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
                
                configManager = ConfigurationManager(configDirectory: tempDirectory)
            }
            
            afterEach {
                try? FileManager.default.removeItem(at: tempDirectory)
            }
            
            context("when managing application configuration") {
                it("should load default configuration") {
                    // When
                    let config = configManager.loadApplicationConfiguration()
                    
                    // Then
                    expect(config).toNot(beNil())
                    expect(config.scanSettings).toNot(beNil())
                    expect(config.backupSettings).toNot(beNil())
                    expect(config.securitySettings).toNot(beNil())
                }
                
                it("should save and load custom configuration") {
                    // Given
                    var config = configManager.loadApplicationConfiguration()
                    config.scanSettings.includeHiddenFiles = true
                    config.scanSettings.maxFileSize = 100 * 1024 * 1024 // 100MB
                    
                    // When
                    try configManager.saveApplicationConfiguration(config)
                    let loadedConfig = configManager.loadApplicationConfiguration()
                    
                    // Then
                    expect(loadedConfig.scanSettings.includeHiddenFiles).to(beTrue())
                    expect(loadedConfig.scanSettings.maxFileSize).to(equal(100 * 1024 * 1024))
                }
                
                it("should validate configuration values") {
                    // Given
                    var config = configManager.loadApplicationConfiguration()
                    config.scanSettings.maxFileSize = -1 // Invalid value
                    
                    // When/Then
                    expect { try configManager.saveApplicationConfiguration(config) }
                        .to(throwError(ConfigurationError.invalidValue(key: "maxFileSize", value: "-1", reason: "Must be positive")))
                }
            }
            
            context("when managing scan settings") {
                it("should load default scan settings") {
                    // When
                    let settings = configManager.loadScanSettings()
                    
                    // Then
                    expect(settings.includeHiddenFiles).to(beFalse())
                    expect(settings.maxFileSize).to(equal(1024 * 1024 * 1024)) // 1GB
                    expect(settings.excludedPaths).to(beEmpty())
                    expect(settings.includedExtensions).to(beEmpty())
                }
                
                it("should save and load custom scan settings") {
                    // Given
                    var settings = configManager.loadScanSettings()
                    settings.includeHiddenFiles = true
                    settings.maxFileSize = 500 * 1024 * 1024 // 500MB
                    settings.excludedPaths = ["/System", "/Applications"]
                    settings.includedExtensions = [".txt", ".pdf", ".doc"]
                    
                    // When
                    try configManager.saveScanSettings(settings)
                    let loadedSettings = configManager.loadScanSettings()
                    
                    // Then
                    expect(loadedSettings.includeHiddenFiles).to(beTrue())
                    expect(loadedSettings.maxFileSize).to(equal(500 * 1024 * 1024))
                    expect(loadedSettings.excludedPaths).to(equal(["/System", "/Applications"]))
                    expect(loadedSettings.includedExtensions).to(equal([".txt", ".pdf", ".doc"]))
                }
                
                it("should validate scan settings") {
                    // Given
                    var settings = configManager.loadScanSettings()
                    settings.maxFileSize = -1 // Invalid
                    
                    // When/Then
                    expect { try configManager.saveScanSettings(settings) }
                        .to(throwError(ConfigurationError.invalidValue(key: "maxFileSize", value: "-1", reason: "Must be positive")))
                }
            }
            
            context("when managing backup settings") {
                it("should load default backup settings") {
                    // When
                    let settings = configManager.loadBackupSettings()
                    
                    // Then
                    expect(settings.enabled).to(beTrue())
                    expect(settings.providers).to(contain(.iCloudDrive))
                    expect(settings.encryptionEnabled).to(beTrue())
                    expect(settings.compressionEnabled).to(beTrue())
                }
                
                it("should save and load custom backup settings") {
                    // Given
                    var settings = configManager.loadBackupSettings()
                    settings.enabled = false
                    settings.providers = [.githubGist, .ipfs]
                    settings.encryptionEnabled = false
                    settings.compressionEnabled = false
                    settings.retentionDays = 30
                    
                    // When
                    try configManager.saveBackupSettings(settings)
                    let loadedSettings = configManager.loadBackupSettings()
                    
                    // Then
                    expect(loadedSettings.enabled).to(beFalse())
                    expect(loadedSettings.providers).to(equal([.githubGist, .ipfs]))
                    expect(loadedSettings.encryptionEnabled).to(beFalse())
                    expect(loadedSettings.compressionEnabled).to(beFalse())
                    expect(loadedSettings.retentionDays).to(equal(30))
                }
            }
            
            context("when managing security settings") {
                it("should load default security settings") {
                    // When
                    let settings = configManager.loadSecuritySettings()
                    
                    // Then
                    expect(settings.performSecurityAudit).to(beTrue())
                    expect(settings.checkFilePermissions).to(beTrue())
                    expect(settings.requireConfirmationForDeletion).to(beTrue())
                    expect(settings.auditLevel).to(equal(.standard))
                }
                
                it("should save and load custom security settings") {
                    // Given
                    var settings = configManager.loadSecuritySettings()
                    settings.performSecurityAudit = false
                    settings.checkFilePermissions = false
                    settings.requireConfirmationForDeletion = false
                    settings.auditLevel = .strict
                    
                    // When
                    try configManager.saveSecuritySettings(settings)
                    let loadedSettings = configManager.loadSecuritySettings()
                    
                    // Then
                    expect(loadedSettings.performSecurityAudit).to(beFalse())
                    expect(loadedSettings.checkFilePermissions).to(beFalse())
                    expect(loadedSettings.requireConfirmationForDeletion).to(beFalse())
                    expect(loadedSettings.auditLevel).to(equal(.strict))
                }
            }
            
            context("when managing user preferences") {
                it("should load default user preferences") {
                    // When
                    let preferences = configManager.loadUserPreferences()
                    
                    // Then
                    expect(preferences.theme).to(equal(.system))
                    expect(preferences.language).to(equal("en"))
                    expect(preferences.showAdvancedOptions).to(beFalse())
                    expect(preferences.enableNotifications).to(beTrue())
                }
                
                it("should save and load custom user preferences") {
                    // Given
                    var preferences = configManager.loadUserPreferences()
                    preferences.theme = .dark
                    preferences.language = "es"
                    preferences.showAdvancedOptions = true
                    preferences.enableNotifications = false
                    
                    // When
                    try configManager.saveUserPreferences(preferences)
                    let loadedPreferences = configManager.loadUserPreferences()
                    
                    // Then
                    expect(loadedPreferences.theme).to(equal(.dark))
                    expect(loadedPreferences.language).to(equal("es"))
                    expect(loadedPreferences.showAdvancedOptions).to(beTrue())
                    expect(loadedPreferences.enableNotifications).to(beFalse())
                }
            }
            
            context("when handling configuration migration") {
                it("should migrate from old configuration format") {
                    // Given
                    let oldConfigData = """
                    {
                        "scan_include_hidden": true,
                        "scan_max_size": 1048576,
                        "backup_enabled": false
                    }
                    """.data(using: .utf8)!
                    
                    let oldConfigFile = tempDirectory.appendingPathComponent("old_config.json")
                    try oldConfigData.write(to: oldConfigFile)
                    
                    // When
                    try configManager.migrateFromOldFormat(oldConfigFile)
                    let newConfig = configManager.loadApplicationConfiguration()
                    
                    // Then
                    expect(newConfig.scanSettings.includeHiddenFiles).to(beTrue())
                    expect(newConfig.scanSettings.maxFileSize).to(equal(1048576))
                    expect(newConfig.backupSettings.enabled).to(beFalse())
                }
                
                it("should handle migration errors gracefully") {
                    // Given
                    let invalidConfigData = "invalid json".data(using: .utf8)!
                    let invalidConfigFile = tempDirectory.appendingPathComponent("invalid_config.json")
                    try invalidConfigData.write(to: invalidConfigFile)
                    
                    // When/Then
                    expect { try configManager.migrateFromOldFormat(invalidConfigFile) }
                        .to(throwError(ConfigurationError.migrationFailed(reason: "Invalid JSON format")))
                }
            }
            
            context("when handling configuration validation") {
                it("should validate all configuration sections") {
                    // Given
                    var config = configManager.loadApplicationConfiguration()
                    config.scanSettings.maxFileSize = -1
                    config.backupSettings.retentionDays = -1
                    config.securitySettings.auditLevel = .invalid
                    
                    // When
                    let validationResult = configManager.validateConfiguration(config)
                    
                    // Then
                    expect(validationResult.isValid).to(beFalse())
                    expect(validationResult.errors).to(haveCount(3))
                    expect(validationResult.errors).to(contain("maxFileSize must be positive"))
                    expect(validationResult.errors).to(contain("retentionDays must be positive"))
                    expect(validationResult.errors).to(contain("Invalid audit level"))
                }
                
                it("should pass validation for valid configuration") {
                    // Given
                    let config = configManager.loadApplicationConfiguration()
                    
                    // When
                    let validationResult = configManager.validateConfiguration(config)
                    
                    // Then
                    expect(validationResult.isValid).to(beTrue())
                    expect(validationResult.errors).to(beEmpty())
                }
            }
            
            context("when handling configuration backup and restore") {
                it("should backup current configuration") {
                    // Given
                    var config = configManager.loadApplicationConfiguration()
                    config.scanSettings.includeHiddenFiles = true
                    try configManager.saveApplicationConfiguration(config)
                    
                    // When
                    let backupPath = try configManager.backupConfiguration()
                    
                    // Then
                    expect(FileManager.default.fileExists(atPath: backupPath.path)).to(beTrue())
                    expect(backupPath.pathExtension).to(equal("json"))
                }
                
                it("should restore configuration from backup") {
                    // Given
                    var config = configManager.loadApplicationConfiguration()
                    config.scanSettings.includeHiddenFiles = true
                    try configManager.saveApplicationConfiguration(config)
                    
                    let backupPath = try configManager.backupConfiguration()
                    
                    // Modify current config
                    config.scanSettings.includeHiddenFiles = false
                    try configManager.saveApplicationConfiguration(config)
                    
                    // When
                    try configManager.restoreConfiguration(from: backupPath)
                    let restoredConfig = configManager.loadApplicationConfiguration()
                    
                    // Then
                    expect(restoredConfig.scanSettings.includeHiddenFiles).to(beTrue())
                }
            }
            
            context("when handling configuration synchronization") {
                it("should synchronize configuration across devices") {
                    // Given
                    var config = configManager.loadApplicationConfiguration()
                    config.scanSettings.includeHiddenFiles = true
                    
                    // When
                    let syncData = try configManager.exportConfigurationForSync(config)
                    let importedConfig = try configManager.importConfigurationFromSync(syncData)
                    
                    // Then
                    expect(importedConfig.scanSettings.includeHiddenFiles).to(beTrue())
                }
                
                it("should handle sync data validation") {
                    // Given
                    let invalidSyncData = "invalid data".data(using: .utf8)!
                    
                    // When/Then
                    expect { try configManager.importConfigurationFromSync(invalidSyncData) }
                        .to(throwError(ConfigurationError.invalidSyncData))
                }
            }
            
            context("when handling configuration reset") {
                it("should reset to default configuration") {
                    // Given
                    var config = configManager.loadApplicationConfiguration()
                    config.scanSettings.includeHiddenFiles = true
                    config.backupSettings.enabled = false
                    try configManager.saveApplicationConfiguration(config)
                    
                    // When
                    try configManager.resetToDefaults()
                    let defaultConfig = configManager.loadApplicationConfiguration()
                    
                    // Then
                    expect(defaultConfig.scanSettings.includeHiddenFiles).to(beFalse())
                    expect(defaultConfig.backupSettings.enabled).to(beTrue())
                }
            }
        }
    }
}
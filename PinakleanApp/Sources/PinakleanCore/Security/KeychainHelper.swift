import Foundation
import Security
import CryptoKit
import os.log

/// Secure keychain helper for storing sensitive data like encryption keys and API tokens
/// Follows macOS Keychain best practices with proper error handling and logging
public struct KeychainHelper {
    
    private static let logger = Logger(subsystem: "com.pinaklean", category: "KeychainHelper")
    private static let serviceName = "com.pinaklean.app"
    
    // MARK: - Core Keychain Operations
    
    /// Save data to keychain with secure attributes
    /// - Parameters:
    ///   - key: Unique identifier for the data
    ///   - data: Data to store securely
    /// - Returns: True if successful, false otherwise
    public static func save(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            logger.debug("Successfully saved data for key: \(key)")
            return true
        } else {
            logger.error("Failed to save data for key: \(key), status: \(status)")
            return false
        }
    }
    
    /// Load data from keychain
    /// - Parameter key: Unique identifier for the data
    /// - Returns: Data if found, nil otherwise
    public static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            logger.debug("Successfully loaded data for key: \(key)")
            return result as? Data
        } else if status == errSecItemNotFound {
            logger.debug("No data found for key: \(key)")
            return nil
        } else {
            logger.error("Failed to load data for key: \(key), status: \(status)")
            return nil
        }
    }
    
    /// Delete data from keychain
    /// - Parameter key: Unique identifier for the data
    /// - Returns: True if successful, false otherwise
    public static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            logger.debug("Successfully deleted data for key: \(key)")
            return true
        } else {
            logger.error("Failed to delete data for key: \(key), status: \(status)")
            return false
        }
    }
    
    /// Check if data exists in keychain
    /// - Parameter key: Unique identifier for the data
    /// - Returns: True if data exists, false otherwise
    public static func exists(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Specialized Key Management
    
    /// Generate or retrieve encryption key for a specific service
    /// - Parameter service: Service identifier
    /// - Returns: SymmetricKey for encryption/decryption
    public static func generateEncryptionKey(for service: String) -> SymmetricKey {
        let keyName = "\(service)_encryption_key"
        
        if let existingKeyData = load(key: keyName) {
            logger.debug("Retrieved existing encryption key for service: \(service)")
            return SymmetricKey(data: existingKeyData)
        } else {
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            
            if save(key: keyName, data: keyData) {
                logger.info("Generated new encryption key for service: \(service)")
                return newKey
            } else {
                logger.error("Failed to save encryption key for service: \(service)")
                // Return a temporary key as fallback
                return SymmetricKey(size: .bits256)
            }
        }
    }
    
    /// Get or create backup encryption key
    /// - Returns: SymmetricKey for backup encryption
    public static func getOrCreateBackupEncryptionKey() -> SymmetricKey {
        return generateEncryptionKey(for: "PinakleanBackup")
    }
    
    // MARK: - API Token Management
    
    /// Save GitHub token securely
    /// - Parameter token: GitHub personal access token
    /// - Returns: True if successful, false otherwise
    public static func saveGitHubToken(_ token: String) -> Bool {
        guard let tokenData = token.data(using: .utf8) else {
            logger.error("Failed to convert GitHub token to data")
            return false
        }
        
        let result = save(key: "GitHubToken", data: tokenData)
        if result {
            logger.info("GitHub token saved successfully")
        } else {
            logger.error("Failed to save GitHub token")
        }
        return result
    }
    
    /// Load GitHub token
    /// - Returns: GitHub token if found, nil otherwise
    public static func loadGitHubToken() -> String? {
        guard let tokenData = load(key: "GitHubToken") else {
            logger.debug("No GitHub token found")
            return nil
        }
        
        guard let token = String(data: tokenData, encoding: .utf8) else {
            logger.error("Failed to convert GitHub token data to string")
            return nil
        }
        
        logger.debug("GitHub token loaded successfully")
        return token
    }
    
    /// Delete GitHub token
    /// - Returns: True if successful, false otherwise
    public static func deleteGitHubToken() -> Bool {
        let result = delete(key: "GitHubToken")
        if result {
            logger.info("GitHub token deleted successfully")
        } else {
            logger.error("Failed to delete GitHub token")
        }
        return result
    }
    
    // MARK: - Configuration Management
    
    /// Save configuration data securely
    /// - Parameters:
    ///   - configKey: Configuration key
    ///   - data: Configuration data
    /// - Returns: True if successful, false otherwise
    public static func saveConfiguration(_ configKey: String, data: Data) -> Bool {
        let key = "config_\(configKey)"
        return save(key: key, data: data)
    }
    
    /// Load configuration data
    /// - Parameter configKey: Configuration key
    /// - Returns: Configuration data if found, nil otherwise
    public static func loadConfiguration(_ configKey: String) -> Data? {
        let key = "config_\(configKey)"
        return load(key: key)
    }
    
    /// Delete configuration data
    /// - Parameter configKey: Configuration key
    /// - Returns: True if successful, false otherwise
    public static func deleteConfiguration(_ configKey: String) -> Bool {
        let key = "config_\(configKey)"
        return delete(key: key)
    }
    
    // MARK: - Security Utilities
    
    /// Generate secure random data
    /// - Parameter length: Length of random data in bytes
    /// - Returns: Random data
    public static func generateSecureRandomData(length: Int) -> Data {
        var randomData = Data(count: length)
        let result = randomData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        if result == errSecSuccess {
            logger.debug("Generated \(length) bytes of secure random data")
            return randomData
        } else {
            logger.error("Failed to generate secure random data, status: \(result)")
            // Fallback to CryptoKit
            return Data((0..<length).map { _ in UInt8.random(in: 0...255) })
        }
    }
    
    /// Generate secure random string
    /// - Parameters:
    ///   - length: Length of random string
    ///   - characters: Character set to use
    /// - Returns: Random string
    public static func generateSecureRandomString(
        length: Int,
        characters: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    ) -> String {
        let randomData = generateSecureRandomData(length: length)
        let characterSet = Array(characters)
        
        return String(randomData.map { byte in
            characterSet[Int(byte) % characterSet.count]
        })
    }
    
    // MARK: - Keychain Health Check
    
    /// Check keychain accessibility and health
    /// - Returns: True if keychain is accessible, false otherwise
    public static func isKeychainAccessible() -> Bool {
        let testKey = "keychain_health_check"
        let testData = "test".data(using: .utf8)!
        
        // Try to save and delete test data
        let saveResult = save(key: testKey, data: testData)
        let deleteResult = delete(key: testKey)
        
        let isHealthy = saveResult && deleteResult
        
        if !isHealthy {
            logger.error("Keychain health check failed - save: \(saveResult), delete: \(deleteResult)")
        } else {
            logger.debug("Keychain health check passed")
        }
        
        return isHealthy
    }
    
    // MARK: - Migration Support
    
    /// Migrate data from old key format to new format
    /// - Parameters:
    ///   - oldKey: Old key format
    ///   - newKey: New key format
    /// - Returns: True if migration successful, false otherwise
    public static func migrateKey(from oldKey: String, to newKey: String) -> Bool {
        guard let data = load(key: oldKey) else {
            logger.debug("No data found for old key: \(oldKey)")
            return true // Nothing to migrate
        }
        
        let saveResult = save(key: newKey, data: data)
        if saveResult {
            _ = delete(key: oldKey) // Clean up old key
            logger.info("Successfully migrated key from \(oldKey) to \(newKey)")
        } else {
            logger.error("Failed to migrate key from \(oldKey) to \(newKey)")
        }
        
        return saveResult
    }
    
    // MARK: - Debugging Support
    
    /// Get all stored keys (for debugging only)
    /// - Returns: Array of stored key names
    public static func getAllStoredKeys() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let items = result as? [[String: Any]] {
            return items.compactMap { item in
                item[kSecAttrAccount as String] as? String
            }
        }
        
        return []
    }
    
    /// Clear all Pinaklean data from keychain (for debugging only)
    /// - Returns: True if successful, false otherwise
    public static func clearAllData() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            logger.info("Cleared all Pinaklean data from keychain")
            return true
        } else {
            logger.error("Failed to clear keychain data, status: \(status)")
            return false
        }
    }
}

// MARK: - Error Handling Extensions

extension KeychainHelper {
    
    /// Get human-readable error message for keychain status
    /// - Parameter status: Keychain status code
    /// - Returns: Human-readable error message
    public static func errorMessage(for status: OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return "Success"
        case errSecItemNotFound:
            return "Item not found"
        case errSecDuplicateItem:
            return "Duplicate item"
        case errSecAuthFailed:
            return "Authentication failed"
        case errSecParam:
            return "Invalid parameter"
        case errSecAllocate:
            return "Memory allocation failed"
        case errSecNotAvailable:
            return "Keychain not available"
        case errSecUserCancel:
            return "User cancelled operation"
        case errSecBadReq:
            return "Bad request"
        case errSecInternalComponent:
            return "Internal component error"
        case errSecNotInteractive:
            return "Not interactive"
        case errSecReadOnly:
            return "Read only"
        case errSecNoSuchKeychain:
            return "No such keychain"
        case errSecInvalidKeychain:
            return "Invalid keychain"
        case errSecDuplicateKeychain:
            return "Duplicate keychain"
        case errSecDuplicateCallback:
            return "Duplicate callback"
        case errSecInvalidCallback:
            return "Invalid callback"
        case errSecDuplicateItem:
            return "Duplicate item"
        case errSecItemNotFound:
            return "Item not found"
        case errSecBufferTooSmall:
            return "Buffer too small"
        case errSecDataTooLarge:
            return "Data too large"
        case errSecNoSuchAttr:
            return "No such attribute"
        case errSecInvalidItemRef:
            return "Invalid item reference"
        case errSecInvalidSearchRef:
            return "Invalid search reference"
        case errSecNoSuchClass:
            return "No such class"
        case errSecNoDefaultKeychain:
            return "No default keychain"
        case errSecInteractionNotAllowed:
            return "Interaction not allowed"
        case errSecReadOnlyAttr:
            return "Read only attribute"
        case errSecWrongSecVersion:
            return "Wrong security version"
        case errSecKeySizeNotAllowed:
            return "Key size not allowed"
        case errSecNoStorageModule:
            return "No storage module"
        case errSecNoCertificateModule:
            return "No certificate module"
        case errSecNoPolicyModule:
            return "No policy module"
        case errSecInteractionRequired:
            return "Interaction required"
        case errSecDataNotAvailable:
            return "Data not available"
        case errSecDataNotModifiable:
            return "Data not modifiable"
        case errSecCreateChainFailed:
            return "Create chain failed"
        case errSecInvalidPrefsDomain:
            return "Invalid preferences domain"
        case errSecInDarkWake:
            return "In dark wake"
        default:
            return "Unknown error: \(status)"
        }
    }
}
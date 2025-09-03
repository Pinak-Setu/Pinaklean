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
                return newKey // Return generated key even if saving failed
            }
        }
    }
    
    // MARK: - Convenience Methods for App
    
    public static func getOrCreateBackupEncryptionKey() -> SymmetricKey {
        return generateEncryptionKey(for: "backup")
    }
    
    public static func saveGitHubToken(_ token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        return save(key: "github_token", data: data)
    }
    
    public static func loadGitHubToken() -> String? {
        guard let data = load(key: "github_token") else { return nil }
        return String(data: data, encoding: .utf8)
    }
}


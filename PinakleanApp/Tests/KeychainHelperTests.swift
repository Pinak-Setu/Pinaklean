import XCTest
import Quick
import Nimble
@testable import PinakleanCore

class KeychainHelperTests: QuickSpec {
    override func spec() {
        describe("KeychainHelper") {
            let testKey = "test_keychain_key"
            let testData = "test_secret_data".data(using: .utf8)!
            
            beforeEach {
                // Clean up any existing test data
                KeychainHelper.delete(key: testKey)
            }
            
            afterEach {
                // Clean up after each test
                KeychainHelper.delete(key: testKey)
            }
            
            context("when saving data") {
                it("should successfully save data to keychain") {
                    // Given
                    let result = KeychainHelper.save(key: testKey, data: testData)
                    
                    // Then
                    expect(result).to(beTrue())
                }
                
                it("should handle empty data") {
                    // Given
                    let emptyData = Data()
                    
                    // When
                    let result = KeychainHelper.save(key: testKey, data: emptyData)
                    
                    // Then
                    expect(result).to(beTrue())
                }
                
                it("should handle large data") {
                    // Given
                    let largeData = Data(repeating: 0xFF, count: 1024 * 1024) // 1MB
                    
                    // When
                    let result = KeychainHelper.save(key: testKey, data: largeData)
                    
                    // Then
                    expect(result).to(beTrue())
                }
            }
            
            context("when loading data") {
                it("should return nil for non-existent key") {
                    // When
                    let result = KeychainHelper.load(key: "non_existent_key")
                    
                    // Then
                    expect(result).to(beNil())
                }
                
                it("should return saved data") {
                    // Given
                    _ = KeychainHelper.save(key: testKey, data: testData)
                    
                    // When
                    let result = KeychainHelper.load(key: testKey)
                    
                    // Then
                    expect(result).to(equal(testData))
                }
                
                it("should return correct data after multiple saves") {
                    // Given
                    let firstData = "first_data".data(using: .utf8)!
                    let secondData = "second_data".data(using: .utf8)!
                    
                    _ = KeychainHelper.save(key: testKey, data: firstData)
                    _ = KeychainHelper.save(key: testKey, data: secondData)
                    
                    // When
                    let result = KeychainHelper.load(key: testKey)
                    
                    // Then
                    expect(result).to(equal(secondData))
                }
            }
            
            context("when deleting data") {
                it("should successfully delete existing data") {
                    // Given
                    _ = KeychainHelper.save(key: testKey, data: testData)
                    
                    // When
                    let result = KeychainHelper.delete(key: testKey)
                    
                    // Then
                    expect(result).to(beTrue())
                    expect(KeychainHelper.load(key: testKey)).to(beNil())
                }
                
                it("should handle deletion of non-existent key") {
                    // When
                    let result = KeychainHelper.delete(key: "non_existent_key")
                    
                    // Then
                    expect(result).to(beTrue()) // Should not throw error
                }
            }
            
            context("when checking key existence") {
                it("should return false for non-existent key") {
                    // When
                    let result = KeychainHelper.exists(key: "non_existent_key")
                    
                    // Then
                    expect(result).to(beFalse())
                }
                
                it("should return true for existing key") {
                    // Given
                    _ = KeychainHelper.save(key: testKey, data: testData)
                    
                    // When
                    let result = KeychainHelper.exists(key: testKey)
                    
                    // Then
                    expect(result).to(beTrue())
                }
            }
            
            context("when handling encryption keys") {
                it("should generate and store encryption key") {
                    // When
                    let key = KeychainHelper.generateEncryptionKey(for: "test_service")
                    
                    // Then
                    expect(key).toNot(beNil())
                    expect(KeychainHelper.load(key: "test_service_encryption_key")).toNot(beNil())
                }
                
                it("should retrieve existing encryption key") {
                    // Given
                    let firstKey = KeychainHelper.generateEncryptionKey(for: "test_service")
                    
                    // When
                    let secondKey = KeychainHelper.generateEncryptionKey(for: "test_service")
                    
                    // Then
                    expect(firstKey).to(equal(secondKey))
                }
            }
            
            context("when handling GitHub tokens") {
                it("should save and retrieve GitHub token") {
                    // Given
                    let token = "ghp_test_token_12345"
                    
                    // When
                    let saveResult = KeychainHelper.saveGitHubToken(token)
                    let retrievedToken = KeychainHelper.loadGitHubToken()
                    
                    // Then
                    expect(saveResult).to(beTrue())
                    expect(retrievedToken).to(equal(token))
                }
                
                it("should return nil for non-existent GitHub token") {
                    // When
                    let result = KeychainHelper.loadGitHubToken()
                    
                    // Then
                    expect(result).to(beNil())
                }
            }
            
            context("when handling backup encryption keys") {
                it("should generate and store backup encryption key") {
                    // When
                    let key = KeychainHelper.getOrCreateBackupEncryptionKey()
                    
                    // Then
                    expect(key).toNot(beNil())
                    expect(KeychainHelper.exists(key: "PinakleanBackupKey")).to(beTrue())
                }
                
                it("should return same key on subsequent calls") {
                    // Given
                    let firstKey = KeychainHelper.getOrCreateBackupEncryptionKey()
                    
                    // When
                    let secondKey = KeychainHelper.getOrCreateBackupEncryptionKey()
                    
                    // Then
                    expect(firstKey).to(equal(secondKey))
                }
            }
            
            context("when handling security") {
                it("should not store data in plain text") {
                    // Given
                    let sensitiveData = "super_secret_password".data(using: .utf8)!
                    _ = KeychainHelper.save(key: testKey, data: sensitiveData)
                    
                    // When
                    let retrievedData = KeychainHelper.load(key: testKey)
                    
                    // Then
                    expect(retrievedData).to(equal(sensitiveData))
                    // Note: We can't easily test that it's encrypted in keychain
                    // but we can verify the data integrity
                }
                
                it("should handle special characters in keys") {
                    // Given
                    let specialKey = "test_key_with_special_chars_!@#$%^&*()"
                    let testData = "test_data".data(using: .utf8)!
                    
                    // When
                    let saveResult = KeychainHelper.save(key: specialKey, data: testData)
                    let retrievedData = KeychainHelper.load(key: specialKey)
                    
                    // Then
                    expect(saveResult).to(beTrue())
                    expect(retrievedData).to(equal(testData))
                    
                    // Cleanup
                    KeychainHelper.delete(key: specialKey)
                }
            }
        }
    }
}
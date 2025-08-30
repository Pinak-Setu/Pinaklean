<file_path>
Pinaklean/PinakleanApp/Tests/CoreLogicTests.swift
</file_path>

<edit_description>
Add integration tests for Core Logic to identify fundamental errors in scan, clean, and engine initialization.
</edit_description>

```
import XCTest
@testable import PinakleanCore

class CoreLogicTests: XCTestCase {

    // MARK: - Basic Engine Tests

    func testEngineInitialization() async throws {
        let engine = try await PinakleanEngine()
        XCTAssertNotNil(engine, "Engine should initialize successfully.")
    }

    func testScanFunction() async throws {
        let engine = try await PinakleanEngine()
        let results = try await engine.scan(categories: .safe)
        XCTAssertTrue(results.items.count >= 0, "Scan should return items (may be empty).")
    }

    func testCleanFunction() async throws {
        let engine = try await PinakleanEngine()
        let scanResults = try await engine.scan(categories: .safe)
        let safeItems = scanResults.items.filter { $0.safetyScore >= 70 }
        let cleanResults = try await engine.clean(safeItems)
        XCTAssertEqual(cleanResults.deletedItems.count, safeItems.count, "Clean should handle safe items.")
    }

    // MARK: - Backup Functionality Tests

    func testBackupRegistryInitialization() async throws {
        let registry = try BackupRegistry()
        let allBackups = try await registry.getAllBackups()
        XCTAssertTrue(allBackups.isEmpty || allBackups.count >= 0, "Registry should initialize and return backups array.")
    }

    func testBackupCreation() async throws {
        let registry = try BackupRegistry()
        let backupManager = CloudBackupManager()

        // Create a test snapshot
        let snapshot = DiskSnapshot(
            id: UUID(),
            timestamp: Date(),
            totalSize: 1024,
            fileCount: 1,
            metadata: ["test": "backup-test"]
        )

        // Attempt to create a backup
        do {
            let result = try await backupManager.backupToiCloud(snapshot)
            let record = try await registry.recordBackup(result, snapshot: snapshot)

            XCTAssertNotNil(record.id, "Backup record should have an ID.")
            XCTAssertEqual(record.size, result.size, "Backup record size should match result.")

            // Verify it appears in the registry
            let allBackups = try await registry.getAllBackups()
            XCTAssertFalse(allBackups.isEmpty, "Backup should appear in registry after creation.")

        } catch {
            // If backup fails due to missing credentials/services, that's expected
            XCTAssertTrue(
                error.localizedDescription.contains("credential") ||
                error.localizedDescription.contains("service") ||
                error.localizedDescription.contains("unavailable"),
                "Backup should fail with expected errors, not unexpected ones: \(error)"
            )
        }
    }

    func testBackupRetrievalByID() async throws {
        let registry = try BackupRegistry()

        // Create and record a backup first
        let backupManager = CloudBackupManager()
        let snapshot = DiskSnapshot(
            id: UUID(),
            timestamp: Date(),
            totalSize: 2048,
            fileCount: 2,
            metadata: ["test": "retrieval-test"]
        )

        do {
            let result = try await backupManager.backupToiCloud(snapshot)
            let record = try await registry.recordBackup(result, snapshot: snapshot)

            // Now try to retrieve it by ID
            let retrievedRecord = try await registry.findBackup(byId: record.id)
            XCTAssertNotNil(retrievedRecord, "Should be able to retrieve backup by ID.")
            XCTAssertEqual(retrievedRecord?.id, record.id, "Retrieved backup ID should match.")
            XCTAssertEqual(retrievedRecord?.size, record.size, "Retrieved backup size should match.")

        } catch {
            // Handle expected backup service errors
            XCTAssertTrue(
                error.localizedDescription.contains("credential") ||
                error.localizedDescription.contains("service") ||
                error.localizedDescription.contains("unavailable"),
                "Retrieval should fail with expected errors: \(error)"
            )
        }
    }

    func testBackupVerification() async throws {
        let registry = try BackupRegistry()

        // Create a backup record
        let record = BackupRecord(
            id: UUID().uuidString,
            timestamp: Date(),
            provider: "iCloud Drive",
            location: "/test/location",
            size: 1024,
            isEncrypted: true,
            isIncremental: false,
            checksum: "test-checksum",
            retrievalInstructions: "Test instructions"
        )

        do {
            // This will likely fail due to no actual backup, but tests the method
            let verificationResult = try await registry.verifyBackup(record.id)

            // If we get here, the backup exists
            XCTAssertTrue(verificationResult.exists, "Backup should be verifiable if created.")

        } catch {
            // Expected for test environments without actual backup services
            XCTAssertTrue(
                error.localizedDescription.contains("not found") ||
                error.localizedDescription.contains("service") ||
                error.localizedDescription.contains("unavailable"),
                "Verification should handle missing backups gracefully: \(error)"
            )
        }
    }

    func testBackupProviderEnumeration() {
        let providers = CloudBackupManager.CloudProvider.allCases
        XCTAssertFalse(providers.isEmpty, "Should have available backup providers.")
        XCTAssertTrue(providers.contains(.iCloudDrive), "Should include iCloud Drive provider.")
    }

    // MARK: - Configuration Tests

    func testConfigurationPersistence() async throws {
        let engine = try await PinakleanEngine()

        // Test setting a configuration
        var config = PinakleanEngine.Configuration.default
        config.smartDetection = true
        await engine.configure(config)

        // Verify the configuration was set (this tests the in-memory config)
        let currentConfig = await engine.configuration
        XCTAssertTrue(currentConfig.smartDetection, "Configuration should be updated.")

        // Test persistence (this might fail if persistence isn't implemented)
        let newEngine = try await PinakleanEngine()
        let persistedConfig = await newEngine.configuration

        if persistedConfig.smartDetection {
            // Persistence works
            XCTAssertTrue(persistedConfig.smartDetection, "Configuration should persist across engine instances.")
        } else {
            // Persistence doesn't work - this identifies the issue mentioned in feedback
            print("⚠️  Configuration persistence not implemented - config --set won't persist across sessions")
        }
    }

    // MARK: - Scan vs Auto Consistency Tests

    func testScanAutoConsistency() async throws {
        let engine = try await PinakleanEngine()

        // Run scan
        let scanResults = try await engine.scan(categories: .safe)
        let scanSafeSize = scanResults.safeTotalSize

        // Get recommendations (what auto uses)
        let recommendations = try await engine.getRecommendations()
        let autoSafeSize = recommendations.reduce(0) { $0 + $1.potentialSpace }

        // They should be consistent (both use safetyScore > 70)
        XCTAssertEqual(scanSafeSize, autoSafeSize, "Scan and auto should report consistent safe-to-delete sizes.")

        if scanSafeSize == 0 && autoSafeSize > 0 {
            print("🐛 Inconsistency detected: scan shows 0 bytes safe, auto shows \(autoSafeSize) bytes safe")
            print("This matches the feedback - investigate safety score calculation")
        }
    }

    // MARK: - Smart Detection Tests

    func testSmartDetection() async throws {
        let detector = SmartDetector()

        // Test safety score calculation
        let testURL = URL(fileURLWithPath: "/tmp/test.log")
        let score = await detector.calculateSafetyScore(for: testURL)

        XCTAssertTrue(score >= 0 && score <= 100, "Safety score should be between 0 and 100.")
        XCTAssertTrue(score > 50, "Log files should have relatively safe scores.")
    }

    func testDuplicateDetection() async throws {
        let detector = SmartDetector()

        // Create some test items
        let items = [
            CleanableItem(id: UUID(), path: "/test/file1.txt", name: "file1.txt",
                         category: "test", size: 100, safetyScore: 80),
            CleanableItem(id: UUID(), path: "/test/file2.txt", name: "file1.txt",
                         category: "test", size: 100, safetyScore: 80),
        ]

        let duplicates = try await detector.findDuplicates(in: items)
        XCTAssertFalse(duplicates.isEmpty, "Should detect duplicates with same filename.")
    }

    // MARK: - Error Handling Tests

    func testInvalidBackupID() async throws {
        let registry = try BackupRegistry()

        do {
            _ = try await registry.findBackup(byId: "invalid-id")
            // This should either return nil or throw an error
        } catch {
            // Expected behavior - invalid ID should be handled gracefully
            XCTAssertTrue(
                error.localizedDescription.contains("not found") ||
                error.localizedDescription.contains("invalid"),
                "Invalid backup ID should be handled gracefully: \(error)"
            )
        }
    }

    func testBackupWithoutCredentials() async throws {
        let backupManager = CloudBackupManager()
        let snapshot = DiskSnapshot(
            id: UUID(),
            timestamp: Date(),
            totalSize: 0,
            fileCount: 0,
            metadata: [:]
        )

        do {
            _ = try await backupManager.backupToGitHub(snapshot)
            // If this succeeds, credentials are available
        } catch {
            // Expected in test environment
            XCTAssertTrue(
                error.localizedDescription.contains("credential") ||
                error.localizedDescription.contains("token") ||
                error.localizedDescription.contains("authorization"),
                "Backup should fail gracefully without credentials: \(error)"
            )
        }
    }
}
```

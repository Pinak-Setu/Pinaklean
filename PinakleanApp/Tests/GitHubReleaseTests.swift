import XCTest
import Quick
import Nimble
@testable import PinakleanCore

class GitHubReleaseTests: QuickSpec {
    override func spec() {
        describe("GitHubReleaseManager") {
            var releaseManager: GitHubReleaseManager!
            var mockGitHubAPI: MockGitHubAPI!
            
            beforeEach {
                mockGitHubAPI = MockGitHubAPI()
                releaseManager = GitHubReleaseManager(apiClient: mockGitHubAPI)
            }
            
            context("when creating GitHub releases") {
                it("should create a new release successfully") {
                    // Given
                    let releaseData = GitHubReleaseData(
                        tagName: "v1.0.0",
                        name: "Pinaklean v1.0.0",
                        body: "Release notes for v1.0.0",
                        draft: false,
                        prerelease: false
                    )
                    
                    let assetData = "test backup data".data(using: .utf8)!
                    let assetName = "backup.pinaklean"
                    
                    mockGitHubAPI.mockCreateReleaseResponse = GitHubRelease(
                        id: 12345,
                        tagName: "v1.0.0",
                        name: "Pinaklean v1.0.0",
                        body: "Release notes for v1.0.0",
                        draft: false,
                        prerelease: false,
                        publishedAt: Date(),
                        assets: []
                    )
                    
                    // When
                    let result = try releaseManager.createRelease(
                        data: releaseData,
                        assetData: assetData,
                        assetName: assetName
                    )
                    
                    // Then
                    expect(result).toNot(beNil())
                    expect(result.tagName).to(equal("v1.0.0"))
                    expect(mockGitHubAPI.createReleaseCalled).to(beTrue())
                    expect(mockGitHubAPI.uploadAssetCalled).to(beTrue())
                }
                
                it("should handle release creation errors") {
                    // Given
                    let releaseData = GitHubReleaseData(
                        tagName: "v1.0.0",
                        name: "Pinaklean v1.0.0",
                        body: "Release notes",
                        draft: false,
                        prerelease: false
                    )
                    
                    let assetData = "test data".data(using: .utf8)!
                    let assetName = "backup.pinaklean"
                    
                    mockGitHubAPI.mockError = GitHubAPIError.releaseCreationFailed("Tag already exists")
                    
                    // When/Then
                    expect { try releaseManager.createRelease(
                        data: releaseData,
                        assetData: assetData,
                        assetName: assetName
                    ) }.to(throwError(GitHubAPIError.releaseCreationFailed("Tag already exists")))
                }
                
                it("should handle asset upload errors") {
                    // Given
                    let releaseData = GitHubReleaseData(
                        tagName: "v1.0.0",
                        name: "Pinaklean v1.0.0",
                        body: "Release notes",
                        draft: false,
                        prerelease: false
                    )
                    
                    let assetData = "test data".data(using: .utf8)!
                    let assetName = "backup.pinaklean"
                    
                    mockGitHubAPI.mockCreateReleaseResponse = GitHubRelease(
                        id: 12345,
                        tagName: "v1.0.0",
                        name: "Pinaklean v1.0.0",
                        body: "Release notes",
                        draft: false,
                        prerelease: false,
                        publishedAt: Date(),
                        assets: []
                    )
                    
                    mockGitHubAPI.mockAssetUploadError = GitHubAPIError.assetUploadFailed("File too large")
                    
                    // When/Then
                    expect { try releaseManager.createRelease(
                        data: releaseData,
                        assetData: assetData,
                        assetName: assetName
                    ) }.to(throwError(GitHubAPIError.assetUploadFailed("File too large")))
                }
            }
            
            context("when creating backup releases") {
                it("should create backup release with proper metadata") {
                    // Given
                    let snapshot = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date(),
                        totalSize: 1024 * 1024, // 1MB
                        fileCount: 100,
                        metadata: ["type": "full"]
                    )
                    
                    let backupData = "backup data".data(using: .utf8)!
                    
                    mockGitHubAPI.mockCreateReleaseResponse = GitHubRelease(
                        id: 12345,
                        tagName: "backup-\(snapshot.id.uuidString.prefix(8))",
                        name: "Pinaklean Backup - \(DateFormatter.shortDate.string(from: snapshot.timestamp))",
                        body: "Automated backup created by Pinaklean",
                        draft: false,
                        prerelease: false,
                        publishedAt: Date(),
                        assets: []
                    )
                    
                    // When
                    let result = try releaseManager.createBackupRelease(
                        snapshot: snapshot,
                        backupData: backupData
                    )
                    
                    // Then
                    expect(result).toNot(beNil())
                    expect(result.tagName).to(contain("backup-"))
                    expect(mockGitHubAPI.createReleaseCalled).to(beTrue())
                    expect(mockGitHubAPI.uploadAssetCalled).to(beTrue())
                }
                
                it("should generate proper release notes for backup") {
                    // Given
                    let snapshot = DiskSnapshot(
                        id: UUID(),
                        timestamp: Date(),
                        totalSize: 1024 * 1024,
                        fileCount: 100,
                        metadata: ["type": "full"]
                    )
                    
                    // When
                    let releaseNotes = releaseManager.generateBackupReleaseNotes(snapshot: snapshot)
                    
                    // Then
                    expect(releaseNotes).to(contain("Pinaklean Backup"))
                    expect(releaseNotes).to(contain("1.0 MB"))
                    expect(releaseNotes).to(contain("100 files"))
                    expect(releaseNotes).to(contain("Full backup"))
                }
            }
            
            context("when managing release assets") {
                it("should upload asset with correct metadata") {
                    // Given
                    let releaseId = 12345
                    let assetData = "test asset data".data(using: .utf8)!
                    let assetName = "backup.pinaklean"
                    let contentType = "application/octet-stream"
                    
                    mockGitHubAPI.mockAssetUploadResponse = GitHubAsset(
                        id: 67890,
                        name: assetName,
                        size: Int64(assetData.count),
                        downloadUrl: "https://github.com/releases/download/v1.0.0/\(assetName)",
                        contentType: contentType
                    )
                    
                    // When
                    let result = try releaseManager.uploadAsset(
                        releaseId: releaseId,
                        assetData: assetData,
                        assetName: assetName,
                        contentType: contentType
                    )
                    
                    // Then
                    expect(result).toNot(beNil())
                    expect(result.name).to(equal(assetName))
                    expect(result.size).to(equal(Int64(assetData.count)))
                    expect(mockGitHubAPI.uploadAssetCalled).to(beTrue())
                }
                
                it("should handle large asset uploads") {
                    // Given
                    let releaseId = 12345
                    let largeData = Data(repeating: 0xFF, count: 100 * 1024 * 1024) // 100MB
                    let assetName = "large_backup.pinaklean"
                    
                    mockGitHubAPI.mockAssetUploadResponse = GitHubAsset(
                        id: 67890,
                        name: assetName,
                        size: Int64(largeData.count),
                        downloadUrl: "https://github.com/releases/download/v1.0.0/\(assetName)",
                        contentType: "application/octet-stream"
                    )
                    
                    // When
                    let result = try releaseManager.uploadAsset(
                        releaseId: releaseId,
                        assetData: largeData,
                        assetName: assetName,
                        contentType: "application/octet-stream"
                    )
                    
                    // Then
                    expect(result).toNot(beNil())
                    expect(result.size).to(equal(Int64(largeData.count)))
                }
            }
            
            context("when listing releases") {
                it("should list all releases") {
                    // Given
                    let mockReleases = [
                        GitHubRelease(
                            id: 1,
                            tagName: "v1.0.0",
                            name: "Release 1.0.0",
                            body: "First release",
                            draft: false,
                            prerelease: false,
                            publishedAt: Date().addingTimeInterval(-86400),
                            assets: []
                        ),
                        GitHubRelease(
                            id: 2,
                            tagName: "v1.1.0",
                            name: "Release 1.1.0",
                            body: "Second release",
                            draft: false,
                            prerelease: false,
                            publishedAt: Date(),
                            assets: []
                        )
                    ]
                    
                    mockGitHubAPI.mockListReleasesResponse = mockReleases
                    
                    // When
                    let releases = try releaseManager.listReleases()
                    
                    // Then
                    expect(releases).to(haveCount(2))
                    expect(releases[0].tagName).to(equal("v1.0.0"))
                    expect(releases[1].tagName).to(equal("v1.1.0"))
                    expect(mockGitHubAPI.listReleasesCalled).to(beTrue())
                }
                
                it("should filter releases by tag pattern") {
                    // Given
                    let mockReleases = [
                        GitHubRelease(
                            id: 1,
                            tagName: "backup-abc123",
                            name: "Backup Release",
                            body: "Backup release",
                            draft: false,
                            prerelease: false,
                            publishedAt: Date(),
                            assets: []
                        ),
                        GitHubRelease(
                            id: 2,
                            tagName: "v1.0.0",
                            name: "Version Release",
                            body: "Version release",
                            draft: false,
                            prerelease: false,
                            publishedAt: Date(),
                            assets: []
                        )
                    ]
                    
                    mockGitHubAPI.mockListReleasesResponse = mockReleases
                    
                    // When
                    let backupReleases = try releaseManager.listReleases(tagPattern: "backup-*")
                    
                    // Then
                    expect(backupReleases).to(haveCount(1))
                    expect(backupReleases[0].tagName).to(equal("backup-abc123"))
                }
            }
            
            context("when deleting releases") {
                it("should delete release successfully") {
                    // Given
                    let releaseId = 12345
                    
                    mockGitHubAPI.mockDeleteReleaseResponse = true
                    
                    // When
                    let result = try releaseManager.deleteRelease(releaseId: releaseId)
                    
                    // Then
                    expect(result).to(beTrue())
                    expect(mockGitHubAPI.deleteReleaseCalled).to(beTrue())
                }
                
                it("should handle delete errors") {
                    // Given
                    let releaseId = 12345
                    
                    mockGitHubAPI.mockError = GitHubAPIError.releaseNotFound(releaseId)
                    
                    // When/Then
                    expect { try releaseManager.deleteRelease(releaseId: releaseId) }
                        .to(throwError(GitHubAPIError.releaseNotFound(releaseId)))
                }
            }
            
            context("when handling authentication") {
                it("should use GitHub token for authentication") {
                    // Given
                    let token = "ghp_test_token_12345"
                    let authenticatedManager = GitHubReleaseManager(token: token)
                    
                    // When
                    let hasToken = authenticatedManager.hasValidToken()
                    
                    // Then
                    expect(hasToken).to(beTrue())
                }
                
                it("should handle invalid tokens") {
                    // Given
                    let invalidManager = GitHubReleaseManager(token: "")
                    
                    // When
                    let hasToken = invalidManager.hasValidToken()
                    
                    // Then
                    expect(hasToken).to(beFalse())
                }
            }
            
            context("when handling rate limiting") {
                it("should handle rate limit exceeded") {
                    // Given
                    let releaseData = GitHubReleaseData(
                        tagName: "v1.0.0",
                        name: "Test Release",
                        body: "Test",
                        draft: false,
                        prerelease: false
                    )
                    
                    mockGitHubAPI.mockError = GitHubAPIError.rateLimitExceeded(3600)
                    
                    // When/Then
                    expect { try releaseManager.createRelease(
                        data: releaseData,
                        assetData: "test".data(using: .utf8)!,
                        assetName: "test.txt"
                    ) }.to(throwError(GitHubAPIError.rateLimitExceeded(3600)))
                }
            }
        }
    }
}

// MARK: - Mock GitHub API

class MockGitHubAPI: GitHubAPIClient {
    var createReleaseCalled = false
    var uploadAssetCalled = false
    var listReleasesCalled = false
    var deleteReleaseCalled = false
    
    var mockCreateReleaseResponse: GitHubRelease?
    var mockAssetUploadResponse: GitHubAsset?
    var mockListReleasesResponse: [GitHubRelease] = []
    var mockDeleteReleaseResponse = false
    
    var mockError: Error?
    var mockAssetUploadError: Error?
    
    func createRelease(_ data: GitHubReleaseData) async throws -> GitHubRelease {
        createReleaseCalled = true
        
        if let error = mockError {
            throw error
        }
        
        guard let response = mockCreateReleaseResponse else {
            throw GitHubAPIError.releaseCreationFailed("No mock response")
        }
        
        return response
    }
    
    func uploadAsset(releaseId: Int, assetData: Data, assetName: String, contentType: String) async throws -> GitHubAsset {
        uploadAssetCalled = true
        
        if let error = mockAssetUploadError {
            throw error
        }
        
        guard let response = mockAssetUploadResponse else {
            throw GitHubAPIError.assetUploadFailed("No mock response")
        }
        
        return response
    }
    
    func listReleases() async throws -> [GitHubRelease] {
        listReleasesCalled = true
        
        if let error = mockError {
            throw error
        }
        
        return mockListReleasesResponse
    }
    
    func deleteRelease(releaseId: Int) async throws -> Bool {
        deleteReleaseCalled = true
        
        if let error = mockError {
            throw error
        }
        
        return mockDeleteReleaseResponse
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
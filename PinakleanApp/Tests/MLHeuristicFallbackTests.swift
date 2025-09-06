import XCTest
import Quick
import Nimble
@testable import PinakleanCore

class MLHeuristicFallbackTests: QuickSpec {
    override func spec() {
        describe("MLHeuristicFallbackSystem") {
            var fallbackSystem: MLHeuristicFallbackSystem!
            
            beforeEach {
                fallbackSystem = MLHeuristicFallbackSystem()
            }
            
            context("when calculating safety scores") {
                it("should calculate safety score for safe files") {
                    // Given
                    let fileInfo = FileAnalysisInfo(
                        path: "/Users/test/Documents/document.pdf",
                        size: 1024 * 1024, // 1MB
                        modified: Date().addingTimeInterval(-86400), // 1 day ago
                        isHidden: false,
                        isSystemFile: false,
                        extension: "pdf",
                        isRecent: false,
                        isOld: false
                    )
                    
                    // When
                    let safetyScore = fallbackSystem.calculateSafetyScore(for: fileInfo)
                    
                    // Then
                    expect(safetyScore).to(beGreaterThan(0.7)) // Should be safe
                    expect(safetyScore).to(beLessThanOrEqualTo(1.0))
                }
                
                it("should calculate low safety score for system files") {
                    // Given
                    let fileInfo = FileAnalysisInfo(
                        path: "/System/Library/CoreServices/SystemUIServer",
                        size: 1024 * 1024,
                        modified: Date().addingTimeInterval(-86400),
                        isHidden: false,
                        isSystemFile: true,
                        extension: "",
                        isRecent: false,
                        isOld: false
                    )
                    
                    // When
                    let safetyScore = fallbackSystem.calculateSafetyScore(for: fileInfo)
                    
                    // Then
                    expect(safetyScore).to(beLessThan(0.3)) // Should be unsafe
                    expect(safetyScore).to(beGreaterThanOrEqualTo(0.0))
                }
                
                it("should calculate low safety score for hidden files") {
                    // Given
                    let fileInfo = FileAnalysisInfo(
                        path: "/Users/test/.hidden_file",
                        size: 1024,
                        modified: Date().addingTimeInterval(-86400),
                        isHidden: true,
                        isSystemFile: false,
                        extension: "",
                        isRecent: false,
                        isOld: false
                    )
                    
                    // When
                    let safetyScore = fallbackSystem.calculateSafetyScore(for: fileInfo)
                    
                    // Then
                    expect(safetyScore).to(beLessThan(0.5)) // Should be less safe
                }
                
                it("should calculate high safety score for common document types") {
                    // Given
                    let documentExtensions = ["pdf", "doc", "docx", "txt", "rtf", "pages"]
                    
                    for ext in documentExtensions {
                        let fileInfo = FileAnalysisInfo(
                            path: "/Users/test/Documents/document.\(ext)",
                            size: 1024 * 1024,
                            modified: Date().addingTimeInterval(-86400),
                            isHidden: false,
                            isSystemFile: false,
                            extension: ext,
                            isRecent: false,
                            isOld: false
                        )
                        
                        // When
                        let safetyScore = fallbackSystem.calculateSafetyScore(for: fileInfo)
                        
                        // Then
                        expect(safetyScore).to(beGreaterThan(0.6), description: "Extension \(ext) should be safe")
                    }
                }
                
                it("should calculate low safety score for executable files") {
                    // Given
                    let executableExtensions = ["app", "exe", "dmg", "pkg", "command", "sh"]
                    
                    for ext in executableExtensions {
                        let fileInfo = FileAnalysisInfo(
                            path: "/Users/test/Downloads/executable.\(ext)",
                            size: 1024 * 1024,
                            modified: Date().addingTimeInterval(-86400),
                            isHidden: false,
                            isSystemFile: false,
                            extension: ext,
                            isRecent: false,
                            isOld: false
                        )
                        
                        // When
                        let safetyScore = fallbackSystem.calculateSafetyScore(for: fileInfo)
                        
                        // Then
                        expect(safetyScore).to(beLessThan(0.4), description: "Extension \(ext) should be less safe")
                    }
                }
            }
            
            context("when detecting content types") {
                it("should detect document content types") {
                    // Given
                    let documentFiles = [
                        ("document.pdf", "application/pdf"),
                        ("report.docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
                        ("notes.txt", "text/plain"),
                        ("presentation.pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation")
                    ]
                    
                    for (filename, expectedType) in documentFiles {
                        // When
                        let contentType = fallbackSystem.detectContentType(filename: filename)
                        
                        // Then
                        expect(contentType).to(equal(expectedType))
                    }
                }
                
                it("should detect media content types") {
                    // Given
                    let mediaFiles = [
                        ("photo.jpg", "image/jpeg"),
                        ("video.mp4", "video/mp4"),
                        ("audio.mp3", "audio/mpeg"),
                        ("image.png", "image/png")
                    ]
                    
                    for (filename, expectedType) in mediaFiles {
                        // When
                        let contentType = fallbackSystem.detectContentType(filename: filename)
                        
                        // Then
                        expect(contentType).to(equal(expectedType))
                    }
                }
                
                it("should detect archive content types") {
                    // Given
                    let archiveFiles = [
                        ("archive.zip", "application/zip"),
                        ("backup.tar.gz", "application/gzip"),
                        ("data.7z", "application/x-7z-compressed"),
                        ("package.rar", "application/x-rar-compressed")
                    ]
                    
                    for (filename, expectedType) in archiveFiles {
                        // When
                        let contentType = fallbackSystem.detectContentType(filename: filename)
                        
                        // Then
                        expect(contentType).to(equal(expectedType))
                    }
                }
                
                it("should return unknown for unrecognized files") {
                    // Given
                    let unknownFiles = ["file.xyz", "data.unknown", "file.123"]
                    
                    for filename in unknownFiles {
                        // When
                        let contentType = fallbackSystem.detectContentType(filename: filename)
                        
                        // Then
                        expect(contentType).to(equal("application/octet-stream"))
                    }
                }
            }
            
            context("when analyzing file patterns") {
                it("should identify temporary files") {
                    // Given
                    let tempFiles = [
                        "/tmp/temp_file.tmp",
                        "/var/tmp/cache.tmp",
                        "/Users/test/Library/Caches/temp.cache",
                        "file~",
                        "file.temp"
                    ]
                    
                    for filePath in tempFiles {
                        // When
                        let isTemporary = fallbackSystem.isTemporaryFile(path: filePath)
                        
                        // Then
                        expect(isTemporary).to(beTrue(), description: "\(filePath) should be identified as temporary")
                    }
                }
                
                it("should identify cache files") {
                    // Given
                    let cacheFiles = [
                        "/Users/test/Library/Caches/app.cache",
                        "/System/Library/Caches/system.cache",
                        "/var/cache/data.cache"
                    ]
                    
                    for filePath in cacheFiles {
                        // When
                        let isCache = fallbackSystem.isCacheFile(path: filePath)
                        
                        // Then
                        expect(isCache).to(beTrue(), description: "\(filePath) should be identified as cache")
                    }
                }
                
                it("should identify log files") {
                    // Given
                    let logFiles = [
                        "/var/log/system.log",
                        "/Users/test/Library/Logs/app.log",
                        "error.log",
                        "debug.log"
                    ]
                    
                    for filePath in logFiles {
                        // When
                        let isLog = fallbackSystem.isLogFile(path: filePath)
                        
                        // Then
                        expect(isLog).to(beTrue(), description: "\(filePath) should be identified as log")
                    }
                }
            }
            
            context("when calculating cleanup recommendations") {
                it("should recommend cleanup for temporary files") {
                    // Given
                    let fileInfo = FileAnalysisInfo(
                        path: "/tmp/temp_file.tmp",
                        size: 1024 * 1024,
                        modified: Date().addingTimeInterval(-86400),
                        isHidden: false,
                        isSystemFile: false,
                        extension: "tmp",
                        isRecent: false,
                        isOld: true
                    )
                    
                    // When
                    let recommendation = fallbackSystem.generateCleanupRecommendation(for: fileInfo)
                    
                    // Then
                    expect(recommendation.action).to(equal(.delete))
                    expect(recommendation.confidence).to(beGreaterThan(0.8))
                    expect(recommendation.reason).to(contain("temporary"))
                }
                
                it("should recommend cleanup for old cache files") {
                    // Given
                    let fileInfo = FileAnalysisInfo(
                        path: "/Users/test/Library/Caches/old_cache.cache",
                        size: 10 * 1024 * 1024, // 10MB
                        modified: Date().addingTimeInterval(-30 * 86400), // 30 days ago
                        isHidden: false,
                        isSystemFile: false,
                        extension: "cache",
                        isRecent: false,
                        isOld: true
                    )
                    
                    // When
                    let recommendation = fallbackSystem.generateCleanupRecommendation(for: fileInfo)
                    
                    // Then
                    expect(recommendation.action).to(equal(.delete))
                    expect(recommendation.confidence).to(beGreaterThan(0.7))
                    expect(recommendation.reason).to(contain("cache"))
                }
                
                it("should recommend keeping important documents") {
                    // Given
                    let fileInfo = FileAnalysisInfo(
                        path: "/Users/test/Documents/important.pdf",
                        size: 1024 * 1024,
                        modified: Date().addingTimeInterval(-86400),
                        isHidden: false,
                        isSystemFile: false,
                        extension: "pdf",
                        isRecent: true,
                        isOld: false
                    )
                    
                    // When
                    let recommendation = fallbackSystem.generateCleanupRecommendation(for: fileInfo)
                    
                    // Then
                    expect(recommendation.action).to(equal(.keep))
                    expect(recommendation.confidence).to(beGreaterThan(0.8))
                    expect(recommendation.reason).to(contain("document"))
                }
                
                it("should recommend archiving old files") {
                    // Given
                    let fileInfo = FileAnalysisInfo(
                        path: "/Users/test/Documents/old_document.pdf",
                        size: 1024 * 1024,
                        modified: Date().addingTimeInterval(-365 * 86400), // 1 year ago
                        isHidden: false,
                        isSystemFile: false,
                        extension: "pdf",
                        isRecent: false,
                        isOld: true
                    )
                    
                    // When
                    let recommendation = fallbackSystem.generateCleanupRecommendation(for: fileInfo)
                    
                    // Then
                    expect(recommendation.action).to(equal(.archive))
                    expect(recommendation.confidence).to(beGreaterThan(0.6))
                    expect(recommendation.reason).to(contain("old"))
                }
            }
            
            context("when analyzing file size patterns") {
                it("should identify large files for cleanup") {
                    // Given
                    let largeFileInfo = FileAnalysisInfo(
                        path: "/Users/test/Downloads/large_file.zip",
                        size: 1024 * 1024 * 1024, // 1GB
                        modified: Date().addingTimeInterval(-86400),
                        isHidden: false,
                        isSystemFile: false,
                        extension: "zip",
                        isRecent: false,
                        isOld: false
                    )
                    
                    // When
                    let recommendation = fallbackSystem.generateCleanupRecommendation(for: largeFileInfo)
                    
                    // Then
                    expect(recommendation.action).to(equal(.archive))
                    expect(recommendation.reason).to(contain("large"))
                }
                
                it("should identify duplicate files") {
                    // Given
                    let duplicateFiles = [
                        FileAnalysisInfo(
                            path: "/Users/test/Documents/file.pdf",
                            size: 1024 * 1024,
                            modified: Date().addingTimeInterval(-86400),
                            isHidden: false,
                            isSystemFile: false,
                            extension: "pdf",
                            isRecent: false,
                            isOld: false
                        ),
                        FileAnalysisInfo(
                            path: "/Users/test/Downloads/file (1).pdf",
                            size: 1024 * 1024,
                            modified: Date().addingTimeInterval(-86400),
                            isHidden: false,
                            isSystemFile: false,
                            extension: "pdf",
                            isRecent: false,
                            isOld: false
                        )
                    ]
                    
                    // When
                    let recommendations = fallbackSystem.analyzeDuplicateFiles(duplicateFiles)
                    
                    // Then
                    expect(recommendations).to(haveCount(2))
                    expect(recommendations[0].action).to(equal(.keep))
                    expect(recommendations[1].action).to(equal(.delete))
                    expect(recommendations[1].reason).to(contain("duplicate"))
                }
            }
            
            context("when handling ML model fallback") {
                it("should use heuristic when ML model is unavailable") {
                    // Given
                    let fileInfo = FileAnalysisInfo(
                        path: "/Users/test/Documents/document.pdf",
                        size: 1024 * 1024,
                        modified: Date().addingTimeInterval(-86400),
                        isHidden: false,
                        isSystemFile: false,
                        extension: "pdf",
                        isRecent: false,
                        isOld: false
                    )
                    
                    // When
                    let result = fallbackSystem.analyzeFile(fileInfo, useMLModel: false)
                    
                    // Then
                    expect(result.safetyScore).to(beGreaterThan(0.0))
                    expect(result.contentType).toNot(beEmpty())
                    expect(result.recommendation).toNot(beNil())
                    expect(result.method).to(equal(.heuristic))
                }
                
                it("should provide fallback when ML model fails") {
                    // Given
                    let fileInfo = FileAnalysisInfo(
                        path: "/Users/test/Documents/document.pdf",
                        size: 1024 * 1024,
                        modified: Date().addingTimeInterval(-86400),
                        isHidden: false,
                        isSystemFile: false,
                        extension: "pdf",
                        isRecent: false,
                        isOld: false
                    )
                    
                    // When
                    let result = fallbackSystem.analyzeFile(fileInfo, useMLModel: true)
                    
                    // Then
                    expect(result.safetyScore).to(beGreaterThan(0.0))
                    expect(result.contentType).toNot(beEmpty())
                    expect(result.recommendation).toNot(beNil())
                    // Should fallback to heuristic if ML fails
                    expect(result.method).to(beOneOf([.mlModel, .heuristic]))
                }
            }
            
            context("when generating analysis reports") {
                it("should generate comprehensive analysis report") {
                    // Given
                    let files = [
                        FileAnalysisInfo(
                            path: "/Users/test/Documents/document.pdf",
                            size: 1024 * 1024,
                            modified: Date().addingTimeInterval(-86400),
                            isHidden: false,
                            isSystemFile: false,
                            extension: "pdf",
                            isRecent: false,
                            isOld: false
                        ),
                        FileAnalysisInfo(
                            path: "/tmp/temp_file.tmp",
                            size: 1024,
                            modified: Date().addingTimeInterval(-86400),
                            isHidden: false,
                            isSystemFile: false,
                            extension: "tmp",
                            isRecent: false,
                            isOld: true
                        )
                    ]
                    
                    // When
                    let report = fallbackSystem.generateAnalysisReport(for: files)
                    
                    // Then
                    expect(report.totalFiles).to(equal(2))
                    expect(report.analysisResults).to(haveCount(2))
                    expect(report.summary).toNot(beEmpty())
                    expect(report.recommendations).toNot(beEmpty())
                }
            }
        }
    }
}
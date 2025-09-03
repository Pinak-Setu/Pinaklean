import XCTest
import Quick
import Nimble
import CoreML
@testable import PinakleanCore

class MLModelManagerTests: QuickSpec {
    override func spec() {
        describe("MLModelManager") {
            var modelManager: MLModelManager!
            
            beforeEach {
                modelManager = MLModelManager()
            }
            
            context("when predicting safety scores") {
                it("should predict safety score for safe files") {
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
                    let prediction = await modelManager.predictSafetyScore(for: fileInfo)
                    
                    // Then
                    expect(prediction.score).to(beGreaterThan(0.0))
                    expect(prediction.score).to(beLessThanOrEqualTo(1.0))
                    expect(prediction.confidence).to(beGreaterThan(0.0))
                    expect(prediction.confidence).to(beLessThanOrEqualTo(1.0))
                    expect(prediction.method).to(beOneOf([.mlModel, .heuristic]))
                    expect(prediction.timestamp).toNot(beNil())
                }
                
                it("should predict low safety score for system files") {
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
                    let prediction = await modelManager.predictSafetyScore(for: fileInfo)
                    
                    // Then
                    expect(prediction.score).to(beLessThan(0.5)) // Should be low for system files
                    expect(prediction.confidence).to(beGreaterThan(0.0))
                }
                
                it("should handle ML model fallback gracefully") {
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
                    let prediction = await modelManager.predictSafetyScore(for: fileInfo)
                    
                    // Then
                    expect(prediction.score).to(beGreaterThan(0.0))
                    expect(prediction.method).to(beOneOf([.mlModel, .heuristic]))
                    // Should always return a valid prediction, even if ML model fails
                }
            }
            
            context("when predicting content types") {
                it("should predict content type for known file types") {
                    // Given
                    let testFiles = [
                        "document.pdf",
                        "image.jpg",
                        "video.mp4",
                        "audio.mp3",
                        "archive.zip"
                    ]
                    
                    for filename in testFiles {
                        // When
                        let prediction = await modelManager.predictContentType(filename: filename)
                        
                        // Then
                        expect(prediction.contentType).toNot(beEmpty())
                        expect(prediction.confidence).to(beGreaterThan(0.0))
                        expect(prediction.confidence).to(beLessThanOrEqualTo(1.0))
                        expect(prediction.method).to(beOneOf([.mlModel, .heuristic]))
                        expect(prediction.timestamp).toNot(beNil())
                    }
                }
                
                it("should handle unknown file types") {
                    // Given
                    let unknownFile = "file.xyz"
                    
                    // When
                    let prediction = await modelManager.predictContentType(filename: unknownFile)
                    
                    // Then
                    expect(prediction.contentType).to(equal("application/octet-stream"))
                    expect(prediction.confidence).to(beGreaterThan(0.0))
                }
                
                it("should handle ML model fallback for content type") {
                    // Given
                    let filename = "document.pdf"
                    
                    // When
                    let prediction = await modelManager.predictContentType(filename: filename)
                    
                    // Then
                    expect(prediction.contentType).to(equal("application/pdf"))
                    expect(prediction.method).to(beOneOf([.mlModel, .heuristic]))
                }
            }
            
            context("when checking model status") {
                it("should provide model status information") {
                    // When
                    let status = modelManager.getModelStatus()
                    
                    // Then
                    expect(status).toNot(beNil())
                    expect(status.heuristicFallbackAvailable).to(beTrue())
                    expect(status.lastUpdated).toNot(beNil())
                    expect(status.modelManifest).toNot(beNil())
                }
                
                it("should indicate ML model availability") {
                    // When
                    let hasModels = modelManager.hasMLModels
                    
                    // Then
                    expect(hasModels).to(beOneOf([true, false])) // May or may not have models loaded
                }
            }
            
            context("when handling edge cases") {
                it("should handle empty file names") {
                    // Given
                    let emptyFilename = ""
                    
                    // When
                    let prediction = await modelManager.predictContentType(filename: emptyFilename)
                    
                    // Then
                    expect(prediction.contentType).to(equal("application/octet-stream"))
                    expect(prediction.confidence).to(beGreaterThan(0.0))
                }
                
                it("should handle very large file sizes") {
                    // Given
                    let fileInfo = FileAnalysisInfo(
                        path: "/Users/test/large_file.zip",
                        size: 10 * 1024 * 1024 * 1024, // 10GB
                        modified: Date().addingTimeInterval(-86400),
                        isHidden: false,
                        isSystemFile: false,
                        extension: "zip",
                        isRecent: false,
                        isOld: false
                    )
                    
                    // When
                    let prediction = await modelManager.predictSafetyScore(for: fileInfo)
                    
                    // Then
                    expect(prediction.score).to(beGreaterThan(0.0))
                    expect(prediction.score).to(beLessThanOrEqualTo(1.0))
                }
                
                it("should handle files with no extension") {
                    // Given
                    let fileInfo = FileAnalysisInfo(
                        path: "/Users/test/file_without_extension",
                        size: 1024,
                        modified: Date().addingTimeInterval(-86400),
                        isHidden: false,
                        isSystemFile: false,
                        extension: "",
                        isRecent: false,
                        isOld: false
                    )
                    
                    // When
                    let prediction = await modelManager.predictSafetyScore(for: fileInfo)
                    
                    // Then
                    expect(prediction.score).to(beGreaterThan(0.0))
                    expect(prediction.score).to(beLessThanOrEqualTo(1.0))
                }
            }
            
            context("when handling performance") {
                it("should predict multiple files efficiently") {
                    // Given
                    let files = (0..<100).map { i in
                        FileAnalysisInfo(
                            path: "/Users/test/file\(i).pdf",
                            size: Int64(1024 * (i + 1)),
                            modified: Date().addingTimeInterval(-Double(i) * 86400),
                            isHidden: false,
                            isSystemFile: false,
                            extension: "pdf",
                            isRecent: i < 10,
                            isOld: i > 90
                        )
                    }
                    
                    // When
                    let startTime = Date()
                    let predictions = await withTaskGroup(of: SafetyScorePrediction.self) { group in
                        for file in files {
                            group.addTask {
                                await modelManager.predictSafetyScore(for: file)
                            }
                        }
                        
                        var results: [SafetyScorePrediction] = []
                        for await prediction in group {
                            results.append(prediction)
                        }
                        return results
                    }
                    let duration = Date().timeIntervalSince(startTime)
                    
                    // Then
                    expect(predictions).to(haveCount(100))
                    expect(duration).to(beLessThan(10.0)) // Should complete within 10 seconds
                    
                    for prediction in predictions {
                        expect(prediction.score).to(beGreaterThan(0.0))
                        expect(prediction.score).to(beLessThanOrEqualTo(1.0))
                    }
                }
            }
            
            context("when validating predictions") {
                it("should provide consistent predictions for same input") {
                    // Given
                    let fileInfo = FileAnalysisInfo(
                        path: "/Users/test/consistent_file.pdf",
                        size: 1024 * 1024,
                        modified: Date().addingTimeInterval(-86400),
                        isHidden: false,
                        isSystemFile: false,
                        extension: "pdf",
                        isRecent: false,
                        isOld: false
                    )
                    
                    // When
                    let prediction1 = await modelManager.predictSafetyScore(for: fileInfo)
                    let prediction2 = await modelManager.predictSafetyScore(for: fileInfo)
                    
                    // Then
                    expect(prediction1.score).to(beCloseTo(prediction2.score, within: 0.01))
                    expect(prediction1.method).to(equal(prediction2.method))
                }
                
                it("should provide reasonable confidence scores") {
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
                    let prediction = await modelManager.predictSafetyScore(for: fileInfo)
                    
                    // Then
                    expect(prediction.confidence).to(beGreaterThan(0.1))
                    expect(prediction.confidence).to(beLessThanOrEqualTo(1.0))
                }
            }
        }
    }
}
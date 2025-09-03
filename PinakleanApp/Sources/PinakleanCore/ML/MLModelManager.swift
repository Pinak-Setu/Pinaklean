import Foundation
import CoreML
import os.log

/// Production-ready ML Model Manager with fallback to heuristic system
/// Manages Core ML models and provides seamless fallback when models are unavailable
public class MLModelManager {
    
    private static let logger = Logger(subsystem: "com.pinaklean", category: "MLModelManager")
    
    // MARK: - Properties
    
    private var safetyModel: MLModel?
    private var contentTypeModel: MLModel?
    private let heuristicFallback: MLHeuristicFallbackSystem
    private let modelManifest: ModelManifest
    
    // MARK: - Initialization
    
    public init() {
        self.heuristicFallback = MLHeuristicFallbackSystem()
        self.modelManifest = ModelManifest()
        
        Task {
            await loadModels()
        }
    }
    
    // MARK: - Model Loading
    
    /// Load all available ML models
    private func loadModels() async {
        await loadSafetyModel()
        await loadContentTypeModel()
        
        let loadedModels = [safetyModel, contentTypeModel].compactMap { $0 }.count
        logger.info("Loaded \(loadedModels)/2 ML models successfully")
    }
    
    /// Load safety prediction model
    private func loadSafetyModel() async {
        do {
            guard let modelURL = Bundle.main.url(forResource: "SafetyModel", withExtension: "mlmodelc") else {
                logger.warning("SafetyModel.mlmodelc not found in bundle")
                return
            }
            
            safetyModel = try MLModel(contentsOf: modelURL)
            logger.info("SafetyModel loaded successfully")
        } catch {
            logger.error("Failed to load SafetyModel: \(error.localizedDescription)")
        }
    }
    
    /// Load content type prediction model
    private func loadContentTypeModel() async {
        do {
            guard let modelURL = Bundle.main.url(forResource: "ContentTypeModel", withExtension: "mlmodelc") else {
                logger.warning("ContentTypeModel.mlmodelc not found in bundle")
                return
            }
            
            contentTypeModel = try MLModel(contentsOf: modelURL)
            logger.info("ContentTypeModel loaded successfully")
        } catch {
            logger.error("Failed to load ContentTypeModel: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Safety Score Prediction
    
    /// Predict safety score for a file
    /// - Parameter fileInfo: File analysis information
    /// - Returns: Safety score prediction result
    public func predictSafetyScore(for fileInfo: FileAnalysisInfo) async -> SafetyScorePrediction {
        // Try ML model first
        if let model = safetyModel {
            do {
                let mlPrediction = try await predictSafetyScoreWithML(model: model, fileInfo: fileInfo)
                logger.debug("Safety score predicted using ML model: \(mlPrediction.score)")
                return mlPrediction
            } catch {
                logger.warning("ML safety prediction failed, falling back to heuristic: \(error.localizedDescription)")
            }
        }
        
        // Fallback to heuristic
        let heuristicScore = heuristicFallback.calculateSafetyScore(for: fileInfo)
        logger.debug("Safety score predicted using heuristic: \(heuristicScore)")
        
        return SafetyScorePrediction(
            score: heuristicScore,
            confidence: 0.7, // Heuristic confidence
            method: .heuristic,
            modelVersion: "heuristic-1.0",
            timestamp: Date()
        )
    }
    
    /// Predict safety score using ML model
    private func predictSafetyScoreWithML(model: MLModel, fileInfo: FileAnalysisInfo) async throws -> SafetyScorePrediction {
        // Prepare input features
        let inputFeatures = prepareSafetyInputFeatures(fileInfo: fileInfo)
        
        // Create MLMultiArray input
        let inputArray = try MLMultiArray(shape: [1, NSNumber(value: inputFeatures.count)], dataType: .double)
        for (index, value) in inputFeatures.enumerated() {
            inputArray[index] = NSNumber(value: value)
        }
        
        // Create input
        let input = SafetyModelInput(input: inputArray)
        
        // Make prediction
        let output = try await model.prediction(from: input)
        let safetyOutput = output.featureValue(for: "safety_score")?.multiArrayValue
        
        guard let scoreArray = safetyOutput, scoreArray.count > 0 else {
            throw MLError.predictionFailed("Invalid output from safety model")
        }
        
        let score = Double(truncating: scoreArray[0])
        let confidence = calculateConfidence(score: score, fileInfo: fileInfo)
        
        return SafetyScorePrediction(
            score: max(0.0, min(1.0, score)),
            confidence: confidence,
            method: .mlModel,
            modelVersion: model.modelDescription.metadata[.version] as? String ?? "1.0.0",
            timestamp: Date()
        )
    }
    
    // MARK: - Content Type Prediction
    
    /// Predict content type for a file
    /// - Parameter filename: File name
    /// - Returns: Content type prediction result
    public func predictContentType(filename: String) async -> ContentTypePrediction {
        // Try ML model first
        if let model = contentTypeModel {
            do {
                let mlPrediction = try await predictContentTypeWithML(model: model, filename: filename)
                logger.debug("Content type predicted using ML model: \(mlPrediction.contentType)")
                return mlPrediction
            } catch {
                logger.warning("ML content type prediction failed, falling back to heuristic: \(error.localizedDescription)")
            }
        }
        
        // Fallback to heuristic
        let heuristicType = heuristicFallback.detectContentType(filename: filename)
        logger.debug("Content type predicted using heuristic: \(heuristicType)")
        
        return ContentTypePrediction(
            contentType: heuristicType,
            confidence: 0.8, // Heuristic confidence
            method: .heuristic,
            modelVersion: "heuristic-1.0",
            timestamp: Date()
        )
    }
    
    /// Predict content type using ML model
    private func predictContentTypeWithML(model: MLModel, filename: String) async throws -> ContentTypePrediction {
        // Prepare input features
        let inputFeatures = prepareContentTypeInputFeatures(filename: filename)
        
        // Create MLMultiArray input
        let inputArray = try MLMultiArray(shape: [1, NSNumber(value: inputFeatures.count)], dataType: .double)
        for (index, value) in inputFeatures.enumerated() {
            inputArray[index] = NSNumber(value: value)
        }
        
        // Create input
        let input = ContentTypeModelInput(input: inputArray)
        
        // Make prediction
        let output = try await model.prediction(from: input)
        let contentTypeOutput = output.featureValue(for: "content_type")?.multiArrayValue
        
        guard let typeArray = contentTypeOutput, typeArray.count > 0 else {
            throw MLError.predictionFailed("Invalid output from content type model")
        }
        
        // Find the content type with highest probability
        let contentType = determineContentType(from: typeArray)
        let confidence = Double(truncating: typeArray[0]) // Use highest probability as confidence
        
        return ContentTypePrediction(
            contentType: contentType,
            confidence: confidence,
            method: .mlModel,
            modelVersion: model.modelDescription.metadata[.version] as? String ?? "1.0.0",
            timestamp: Date()
        )
    }
    
    // MARK: - Feature Preparation
    
    /// Prepare input features for safety model
    private func prepareSafetyInputFeatures(fileInfo: FileAnalysisInfo) -> [Double] {
        return [
            Double(fileInfo.size),                    // file_size
            fileInfo.modified.timeIntervalSince1970, // days_since_modified
            Double(fileInfo.path.components(separatedBy: "/").count), // path_depth
            fileInfo.isRecent ? 1.0 : 0.0,           // is_recent
            fileInfo.isOld ? 1.0 : 0.0,              // is_old
            fileInfo.isSystemFile ? 1.0 : 0.0,       // is_system_dir
            fileInfo.path.contains("/Users/") ? 1.0 : 0.0, // is_user_dir
            hasCommonExtension(fileInfo.extension) ? 1.0 : 0.0 // has_common_extensions
        ]
    }
    
    /// Prepare input features for content type model
    private func prepareContentTypeInputFeatures(filename: String) -> [Double] {
        let extension = (filename as NSString).pathExtension.lowercased()
        let name = (filename as NSString).lastPathComponent.lowercased()
        
        // Convert to feature vector (simplified for demo)
        var features: [Double] = Array(repeating: 0.0, count: 100) // Fixed size vector
        
        // Hash extension to feature index
        let extHash = extension.hashValue % 50
        features[extHash] = 1.0
        
        // Hash filename to feature index
        let nameHash = name.hashValue % 50
        features[50 + nameHash] = 1.0
        
        return features
    }
    
    // MARK: - Helper Methods
    
    /// Check if extension is common
    private func hasCommonExtension(_ extension: String) -> Bool {
        let commonExtensions = ["pdf", "doc", "docx", "txt", "jpg", "png", "mp4", "mp3", "zip"]
        return commonExtensions.contains(extension.lowercased())
    }
    
    /// Calculate confidence based on score and file info
    private func calculateConfidence(score: Double, fileInfo: FileAnalysisInfo) -> Double {
        var confidence = 0.8 // Base confidence
        
        // Adjust confidence based on file characteristics
        if fileInfo.isSystemFile {
            confidence -= 0.2 // Lower confidence for system files
        }
        
        if fileInfo.isHidden {
            confidence -= 0.1 // Lower confidence for hidden files
        }
        
        if hasCommonExtension(fileInfo.extension) {
            confidence += 0.1 // Higher confidence for common extensions
        }
        
        return max(0.1, min(1.0, confidence))
    }
    
    /// Determine content type from ML model output
    private func determineContentType(from output: MLMultiArray) -> String {
        // Find the index with highest probability
        var maxIndex = 0
        var maxValue = Double(truncating: output[0])
        
        for i in 1..<output.count {
            let value = Double(truncating: output[i])
            if value > maxValue {
                maxValue = value
                maxIndex = i
            }
        }
        
        // Map index to content type (simplified mapping)
        let contentTypes = [
            "application/pdf", "application/msword", "text/plain", "image/jpeg",
            "image/png", "video/mp4", "audio/mpeg", "application/zip",
            "application/octet-stream"
        ]
        
        return contentTypes[min(maxIndex, contentTypes.count - 1)]
    }
    
    // MARK: - Model Status
    
    /// Get model status information
    public func getModelStatus() -> ModelStatus {
        return ModelStatus(
            safetyModelLoaded: safetyModel != nil,
            contentTypeModelLoaded: contentTypeModel != nil,
            heuristicFallbackAvailable: true,
            modelManifest: modelManifest,
            lastUpdated: Date()
        )
    }
    
    /// Check if ML models are available
    public var hasMLModels: Bool {
        return safetyModel != nil && contentTypeModel != nil
    }
}

// MARK: - Supporting Types

/// Safety score prediction result
public struct SafetyScorePrediction: Codable {
    public let score: Double
    public let confidence: Double
    public let method: PredictionMethod
    public let modelVersion: String
    public let timestamp: Date
    
    public init(score: Double, confidence: Double, method: PredictionMethod, modelVersion: String, timestamp: Date) {
        self.score = score
        self.confidence = confidence
        self.method = method
        self.modelVersion = modelVersion
        self.timestamp = timestamp
    }
}

/// Content type prediction result
public struct ContentTypePrediction: Codable {
    public let contentType: String
    public let confidence: Double
    public let method: PredictionMethod
    public let modelVersion: String
    public let timestamp: Date
    
    public init(contentType: String, confidence: Double, method: PredictionMethod, modelVersion: String, timestamp: Date) {
        self.contentType = contentType
        self.confidence = confidence
        self.method = method
        self.modelVersion = modelVersion
        self.timestamp = timestamp
    }
}

/// Prediction method
public enum PredictionMethod: String, Codable {
    case mlModel = "ml_model"
    case heuristic = "heuristic"
}

/// Model status information
public struct ModelStatus: Codable {
    public let safetyModelLoaded: Bool
    public let contentTypeModelLoaded: Bool
    public let heuristicFallbackAvailable: Bool
    public let modelManifest: ModelManifest
    public let lastUpdated: Date
    
    public init(safetyModelLoaded: Bool, contentTypeModelLoaded: Bool, heuristicFallbackAvailable: Bool, modelManifest: ModelManifest, lastUpdated: Date) {
        self.safetyModelLoaded = safetyModelLoaded
        self.contentTypeModelLoaded = contentTypeModelLoaded
        self.heuristicFallbackAvailable = heuristicFallbackAvailable
        self.modelManifest = modelManifest
        self.lastUpdated = lastUpdated
    }
}

/// ML Error types
public enum MLError: LocalizedError {
    case modelNotFound(String)
    case predictionFailed(String)
    case invalidInput(String)
    case modelLoadFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "ML model not found: \(name)"
        case .predictionFailed(let reason):
            return "ML prediction failed: \(reason)"
        case .invalidInput(let reason):
            return "Invalid input for ML model: \(reason)"
        case .modelLoadFailed(let reason):
            return "Failed to load ML model: \(reason)"
        }
    }
}

// MARK: - Core ML Model Input/Output Types

/// Safety model input
public struct SafetyModelInput: MLFeatureProvider {
    public let input: MLMultiArray
    
    public var featureNames: Set<String> {
        return ["input"]
    }
    
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "input" {
            return MLFeatureValue(multiArray: input)
        }
        return nil
    }
}

/// Content type model input
public struct ContentTypeModelInput: MLFeatureProvider {
    public let input: MLMultiArray
    
    public var featureNames: Set<String> {
        return ["input"]
    }
    
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "input" {
            return MLFeatureValue(multiArray: input)
        }
        return nil
    }
}
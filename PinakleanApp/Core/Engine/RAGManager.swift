import Foundation

#if canImport(NaturalLanguage) && canImport(CoreML)
import NaturalLanguage
import CoreML

/// RAG (Retrieval-Augmented Generation) Manager for explainable cleaning decisions
public actor RAGManager {
    // Knowledge base for file cleaning explanations
    private var knowledgeBase: [CleaningKnowledge] = []
    private var filePatterns: [FilePattern] = []
    private var userPreferences: [String: UserPreference] = [:]

    // ML model for explanation generation
    private var explanationModel: NLModel?

    // Configuration
    private let maxExplanations = 5
    private let confidenceThreshold = 0.6

    public init() async throws {
        await loadKnowledgeBase()
        await setupPatterns()
        await initializeMLModel()
    }

    /// Generate explanation for why a file should or shouldn't be deleted
    public func generateExplanation(for item: CleanableItem) async -> String {
        let context = await analyzeContext(for: item)
        let reasons = await determineReasons(for: item, context: context)

        // Generate human-readable explanation
        return await formatExplanation(item: item, reasons: reasons, context: context)
    }

    /// Get multiple cleaning recommendations with explanations
    public func getCleaningRecommendations(for items: [CleanableItem]) async -> [CleaningRecommendation] {
        var recommendations: [CleaningRecommendation] = []

        // Group items by risk level
        let highRisk = items.filter { item in
            item.safetyScore < 40
        }
        let mediumRisk = items.filter { item in
            item.safetyScore >= 40 && item.safetyScore < 70
        }
        let lowRisk = items.filter { item in
            item.safetyScore >= 70
        }

        // Create recommendations for each risk level
        if !lowRisk.isEmpty {
            let rec = await createRecommendation(
                title: "Safe to Clean",
                description: "These files are very safe to delete based on our analysis",
                items: lowRisk,
                riskLevel: .low
            )
            recommendations.append(rec)
        }

        if !mediumRisk.isEmpty {
            let rec = await createRecommendation(
                title: "Review Recommended",
                description: "These files may be safe but we recommend reviewing them",
                items: mediumRisk,
                riskLevel: .medium
            )
            recommendations.append(rec)
        }

        if !highRisk.isEmpty {
            let rec = await createRecommendation(
                title: "High Risk - Manual Review Required",
                description: "These files have higher risk and should be reviewed carefully",
                items: highRisk,
                riskLevel: .high
            )
            recommendations.append(rec)
        }

        return recommendations
    }

    /// Learn from user decisions to improve future recommendations
    public func learnFromDecision(item: CleanableItem, userKept: Bool) async {
        let pattern = extractPattern(from: item)
        let preference = UserPreference(
            pattern: pattern,
            typicallyKept: userKept,
            confidence: 0.8,
            lastUpdated: Date(),
            decisionCount: 1
        )

        if let existing = userPreferences[pattern] {
            // Update existing preference
            let newCount = existing.decisionCount + 1
            let keptValue = existing.typicallyKept ? Double(existing.decisionCount) : 0
            let additionalValue = userKept ? 1.0 : 0.0
            let newTypicallyKept = (keptValue + additionalValue) / Double(newCount)

            userPreferences[pattern] = UserPreference(
                pattern: pattern,
                typicallyKept: newCount > 1 ? newTypicallyKept > 0.5 : userKept,
                confidence: min(existing.confidence + 0.1, 1.0),
                lastUpdated: Date(),
                decisionCount: newCount
            )
        } else {
            userPreferences[pattern] = preference
        }

        await saveUserPreferences()
    }

    /// Get similar files based on pattern matching
    public func findSimilarFiles(to item: CleanableItem, in items: [CleanableItem]) async -> [CleanableItem] {
        let pattern = extractPattern(from: item)

        return items.filter { candidate in
            let candidatePattern = extractPattern(from: candidate)
            return pattern == candidatePattern && candidate.id != item.id
        }
    }

    // MARK: - Private Methods

    private func analyzeContext(for item: CleanableItem) async -> CleaningContext {
        let pattern = extractPattern(from: item)
        let category = determineCategory(for: item)

        // Check user preferences
        let userPrefersKeeping = userPreferences[pattern]?.typicallyKept ?? false

        // Check knowledge base
        let relevantKnowledge = knowledgeBase.filter { knowledge in
            knowledge.appliesTo(category: category) || knowledge.appliesTo(pattern: pattern)
        }

        return CleaningContext(
            category: category,
            pattern: pattern,
            userPreference: userPrefersKeeping,
            relevantKnowledge: relevantKnowledge,
            age: calculateAge(of: item),
            size: item.size
        )
    }

    private func determineReasons(for item: CleanableItem, context: CleaningContext) async -> [CleaningReason] {
        var reasons: [CleaningReason] = []

        // Size-based reasons
        if item.size > 100 * 1024 * 1024 { // > 100MB
            reasons.append(CleaningReason(
                type: .size,
                description: "Large file that could free significant space",
                impact: .high,
                confidence: 0.9
            ))
        }

        // Age-based reasons
        if context.age > 365 { // > 1 year old
            reasons.append(CleaningReason(
                type: .age,
                description: "File hasn't been accessed in over a year",
                impact: .medium,
                confidence: 0.8
            ))
        }

        // Category-based reasons
        switch context.category {
        case .cache:
            reasons.append(CleaningReason(
                type: .category,
                description: "Cache files are safe to delete and will be recreated as needed",
                impact: .high,
                confidence: 0.95
            ))
        case .temporary:
            reasons.append(CleaningReason(
                type: .category,
                description: "Temporary files are no longer needed",
                impact: .high,
                confidence: 0.9
            ))
        case .log:
            reasons.append(CleaningReason(
                type: .category,
                description: "Log files can be safely archived or deleted",
                impact: .medium,
                confidence: 0.85
            ))
        case .buildArtifact:
            reasons.append(CleaningReason(
                type: .category,
                description: "Build artifacts can be regenerated from source",
                impact: .high,
                confidence: 0.9
            ))
        default:
            break
        }

        // Pattern-based reasons from knowledge base
        for knowledge in context.relevantKnowledge {
            if knowledge.recommendation == .delete {
                reasons.append(CleaningReason(
                    type: .knowledge,
                    description: knowledge.explanation,
                    impact: knowledge.impact,
                    confidence: knowledge.confidence
                ))
            }
        }

        // User preference reasons
        if context.userPreference {
            reasons.append(CleaningReason(
                type: .userPreference,
                description: "You've typically kept similar files in the past",
                impact: .low,
                confidence: 0.7
            ))
        }

        return reasons.sorted { $0.confidence > $1.confidence }
    }

    private func formatExplanation(
        item: CleanableItem,
        reasons: [CleaningReason],
        context: CleaningContext
    ) async -> String {
        var explanation = ""

        if item.safetyScore > 70 {
            explanation = "✅ **Safe to delete**\n\n"
        } else if item.safetyScore > 40 {
            explanation = "⚠️ **Review recommended**\n\n"
        } else {
            explanation = "❌ **High risk - manual review required**\n\n"
        }

        explanation += "**File:** \(item.name)\n"
        explanation += "**Location:** \(item.path)\n"
        explanation += "**Size:** \(item.formattedSize)\n"
        explanation += "**Category:** \(context.category.rawValue)\n\n"

        if !reasons.isEmpty {
            explanation += "**Why this recommendation:**\n"
            for (index, reason) in reasons.prefix(3).enumerated() {
                let number = index + 1
                let confidencePercent = Int(reason.confidence * 100)
                explanation += "\(number). \(reason.description) (\(confidencePercent)% confidence)\n"
            }
            explanation += "\n"
        }

        // Add context-specific advice
        switch context.category {
        case .cache:
            explanation += "**💡 Tip:** Cache files will be recreated automatically when needed.\n"
        case .temporary:
            explanation += "**💡 Tip:** Temporary files are safe to delete as they're not needed anymore.\n"
        case .buildArtifact:
            explanation += "**💡 Tip:** These files will be regenerated during your next build.\n"
        case .log:
            explanation += "**💡 Tip:** Consider archiving old logs instead of deleting "
            explanation += "if you need them for debugging.\n"
        default:
            break
        }

        return explanation
    }

    private func createRecommendation(
        title: String,
        description: String,
        items: [CleanableItem],
        riskLevel: RiskLevel
    ) async -> CleaningRecommendation {
        let totalSpace = items.reduce(0) { $0 + $1.size }
        let confidence = calculateAverageConfidence(for: items)

        return CleaningRecommendation(
            id: UUID(),
            title: title,
            description: description,
            items: items,
            potentialSpace: totalSpace,
            confidence: confidence
        )
    }

    private func calculateAverageConfidence(for items: [CleanableItem]) -> Double {
        guard !items.isEmpty else { return 0 }
        let totalScore = items.reduce(0) { $0 + Double($1.safetyScore) }
        return totalScore / Double(items.count) / 100.0
    }

    private func extractPattern(from item: CleanableItem) -> String {
        let components = item.path.components(separatedBy: "/")
        if components.count >= 3 {
            return components.suffix(3).joined(separator: "/")
        }
        return item.name
    }

    private func determineCategory(for item: CleanableItem) -> FileCategory {
        let path = item.path.lowercased()
        let name = item.name.lowercased()

        if path.contains("cache") || path.contains("caches") {
            return .cache
        } else if path.contains("tmp") || path.contains("temp") {
            return .temporary
        } else if path.contains("log") || name.hasSuffix(".log") {
            return .log
        } else if path.contains("node_modules") || path.contains("build") || path.contains("dist") {
            return .buildArtifact
        } else if path.contains("download") {
            return .download
        } else {
            return .other
        }
    }

    private func calculateAge(of item: CleanableItem) -> TimeInterval {
        guard let lastAccessed = item.lastAccessed ?? item.lastModified else {
            return 0
        }
        return Date().timeIntervalSince(lastAccessed)
    }

    private func loadKnowledgeBase() async {
        // Initialize with built-in cleaning knowledge
        knowledgeBase = [
            CleaningKnowledge(
                pattern: "*cache*",
                category: .cache,
                explanation: "Cache files store temporary data to speed up applications",
                recommendation: .delete,
                impact: .high,
                confidence: 0.95
            ),
            CleaningKnowledge(
                pattern: "*tmp*",
                category: .temporary,
                explanation: "Temporary files are created for short-term use",
                recommendation: .delete,
                impact: .high,
                confidence: 0.90
            ),
            CleaningKnowledge(
                pattern: "*.log",
                category: .log,
                explanation: "Log files contain application debugging information",
                recommendation: .archive,
                impact: .medium,
                confidence: 0.80
            ),
            CleaningKnowledge(
                pattern: "node_modules",
                category: .buildArtifact,
                explanation: "Node.js dependencies that can be reinstalled with npm install",
                recommendation: .delete,
                impact: .high,
                confidence: 0.95
            ),
            CleaningKnowledge(
                pattern: ".next/*",
                category: .buildArtifact,
                explanation: "Next.js build artifacts that will be regenerated",
                recommendation: .delete,
                impact: .high,
                confidence: 0.90
            )
        ]
    }

    private func setupPatterns() async {
        filePatterns = [
            FilePattern(pattern: "*cache*", category: .cache),
            FilePattern(pattern: "*tmp*", category: .temporary),
            FilePattern(pattern: "*.log", category: .log),
            FilePattern(pattern: "node_modules", category: .buildArtifact),
            FilePattern(pattern: ".next", category: .buildArtifact),
            FilePattern(pattern: "dist", category: .buildArtifact),
            FilePattern(pattern: "build", category: .buildArtifact)
        ]
    }

    private func initializeMLModel() async {
        // Initialize Natural Language model for text analysis
        // This would load a Core ML model in production
    }

    private func saveUserPreferences() async {
        // Save user preferences to disk
        // Implementation would persist the userPreferences dictionary
    }
}

// MARK: - Supporting Types

public enum FileCategory: String {
    case cache, temporary, log, buildArtifact, download, document, media, other
}

public enum RiskLevel {
    case low, medium, high
}

public enum Recommendation {
    case keep, delete, archive
}

public enum Impact {
    case low, medium, high
}

public struct CleaningContext {
    let category: FileCategory
    let pattern: String
    let userPreference: Bool
    let relevantKnowledge: [CleaningKnowledge]
    let age: TimeInterval
    let size: Int64
}

public struct CleaningReason {
    let type: ReasonType
    let description: String
    let impact: Impact
    let confidence: Double
}

public enum ReasonType {
    case size, age, category, knowledge, userPreference
}

public struct CleaningKnowledge {
    let pattern: String
    let category: FileCategory
    let explanation: String
    let recommendation: Recommendation
    let impact: Impact
    let confidence: Double

    func appliesTo(category: FileCategory) -> Bool {
        return self.category == category
    }

    func appliesTo(pattern: String) -> Bool {
        return self.pattern == pattern || pattern.contains(self.pattern.replacingOccurrences(of: "*", with: ""))
    }
}

public struct FilePattern {
    let pattern: String
    let category: FileCategory
}

public struct UserPreference {
    let pattern: String
    var typicallyKept: Bool
    var confidence: Double
    var lastUpdated: Date
    var decisionCount: Int
}

// Note: CleaningRecommendation is defined in PinakleanEngine.swift
#else
public actor RAGManager {
    public init() {}

    public func generateExplanation(for item: CleanableItem) async -> String {
        "RAG explanations are unavailable on this platform."
    }

    public func getCleaningRecommendations(for items: [CleanableItem]) async -> [CleaningRecommendation] {
        []
    }

    public func learnFromDecision(item: CleanableItem, userKept: Bool) async {}

    public func findSimilarFiles(to item: CleanableItem, in items: [CleanableItem]) async -> [CleanableItem] {
        []
    }
}

// Minimal placeholder types for non-Apple platforms
public struct CleanableItem {
    public init() {}
}

public struct CleaningRecommendation {
    public init() {}
}
#endif

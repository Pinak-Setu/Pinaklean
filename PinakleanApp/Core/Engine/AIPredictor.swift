// AIPredictor_new.swift - Minimal working version
import Foundation

#if canImport(Combine)
import Combine

@MainActor
final class AIPredictor: ObservableObject {
    
    func generateCleaningRecommendations(for items: [CleanableItem]) async -> [CleaningRecommendation] {
        let recommendations = items.prefix(3).map { item in
            CleaningRecommendation(
                id: UUID(),
                title: "Clean \(item.category)",
                description: "Remove unused \(item.category) files", 
                items: [item],
                potentialSpace: item.size,
                confidence: 0.8
            )
        }
        return Array(recommendations)
    }
    
    func predictFileImportance(for item: CleanableItem) async -> Double {
        let ageScore = item.lastAccessed.map { Date().timeIntervalSince($0) < 86400 * 30 } ?? false ? 0.8 : 0.3
        let sizeScore = Double(item.size) < 100_000_000 ? 0.9 : 0.4
        return (ageScore + sizeScore) / 2.0
    }
}
#endif

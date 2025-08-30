import Combine
import PinakleanCore
import SwiftUI

@MainActor
class PinakleanViewModel: ObservableObject {
    @Published var scanResults: [CleanableItem]?
    @Published var isProcessing = false
    @Published var statusMessage: String?
    @Published var lastScanTime: String?

    private var cancellables = Set<AnyCancellable>()

    var formattedSpaceToClean: String {
        guard let results = scanResults else { return "0 MB" }
        let totalSize = results.reduce(0) { $0 + $1.size }
        return formatFileSize(totalSize)
    }

    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    func performQuickScan() async {
        isProcessing = true
        statusMessage = "Starting quick scan..."

        // Simulate scan process
        try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        // Create sample results
        let sampleItems = [
            CleanableItem(
                id: UUID(), path: "~/Library/Caches/com.apple.Safari", name: "Safari Cache",
                category: "Cache", size: 50_000_000, safetyScore: 100),
            CleanableItem(
                id: UUID(), path: "~/Library/Logs", name: "System Logs", category: "Logs",
                size: 25_000_000, safetyScore: 100),
            CleanableItem(
                id: UUID(), path: "/tmp", name: "Temp Files", category: "Temp", size: 10_000_000,
                safetyScore: 100),
            CleanableItem(
                id: UUID(), path: "~/Library/Caches/Homebrew", name: "Homebrew Cache",
                category: "Package Cache", size: 15_000_000, safetyScore: 100),
        ]

        scanResults = sampleItems
        lastScanTime = Date().formatted(date: .abbreviated, time: .shortened)
        statusMessage = "Quick scan completed! Found \(sampleItems.count) items to clean."
        isProcessing = false
    }

    func performComprehensiveScan() async {
        isProcessing = true
        statusMessage = "Starting comprehensive scan..."

        // Simulate longer scan process
        try? await Task.sleep(nanoseconds: 3_000_000_000)  // 3 seconds

        // Create more comprehensive sample results
        let comprehensiveItems = [
            CleanableItem(
                id: UUID(), path: "~/Library/Caches/com.apple.Safari", name: "Safari Browser Cache",
                category: "Browser Cache", size: 50_000_000, safetyScore: 100),
            CleanableItem(
                id: UUID(), path: "~/Library/Caches/com.google.Chrome",
                name: "Chrome Browser Cache", category: "Browser Cache", size: 75_000_000,
                safetyScore: 100),
            CleanableItem(
                id: UUID(), path: "~/Library/Logs", name: "System Logs", category: "System Logs",
                size: 25_000_000, safetyScore: 100),
            CleanableItem(
                id: UUID(), path: "/tmp", name: "Temp Files", category: "Temp Files",
                size: 10_000_000, safetyScore: 100),
            CleanableItem(
                id: UUID(), path: "~/Library/Caches/Homebrew", name: "Homebrew Package Cache",
                category: "Package Cache", size: 15_000_000, safetyScore: 100),
            CleanableItem(
                id: UUID(), path: "~/Library/Developer/Xcode/DerivedData",
                name: "Xcode Derived Data", category: "Xcode Cache", size: 500_000_000,
                safetyScore: 100),
            CleanableItem(
                id: UUID(), path: "~/Library/Caches/com.apple.dt.Xcode", name: "Xcode Cache",
                category: "Xcode Cache", size: 100_000_000, safetyScore: 100),
            CleanableItem(
                id: UUID(), path: "~/Library/Caches/Pip", name: "Python Pip Cache",
                category: "Python Cache", size: 5_000_000, safetyScore: 100),
            CleanableItem(
                id: UUID(), path: "~/Library/Caches/Yarn", name: "Yarn Cache",
                category: "Node Cache", size: 8_000_000, safetyScore: 100),
            CleanableItem(
                id: UUID(), path: "~/Library/Caches/CocoaPods", name: "CocoaPods Cache",
                category: "iOS Cache", size: 12_000_000, safetyScore: 100),
        ]

        scanResults = comprehensiveItems
        lastScanTime = Date().formatted(date: .abbreviated, time: .shortened)
        statusMessage =
            "Comprehensive scan completed! Found \(comprehensiveItems.count) items to clean."
        isProcessing = false
    }

    func cleanSafeItems() async {
        guard let results = scanResults else {
            statusMessage = "No scan results available. Please run a scan first."
            return
        }

        isProcessing = true
        statusMessage = "Cleaning safe items..."

        // Simulate cleaning process
        try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds

        let safeItems = results.filter { $0.safetyScore >= 70 }
        let cleanedSize = safeItems.reduce(0) { $0 + $1.size }

        statusMessage =
            "Successfully cleaned \(safeItems.count) items, freeing \(formatFileSize(cleanedSize))"
        scanResults = []  // Clear results after cleaning
        isProcessing = false
    }

    func cleanSelectedItems() async {
        isProcessing = true
        statusMessage = "Cleaning selected items..."

        // Simulate cleaning process
        try? await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5 seconds

        statusMessage = "Selected items cleaned successfully!"
        isProcessing = false
    }

    func clearAllCaches() async {
        isProcessing = true
        statusMessage = "Clearing all caches..."

        // Simulate cache clearing
        try? await Task.sleep(nanoseconds: 2_500_000_000)  // 2.5 seconds

        scanResults = nil
        statusMessage = "All caches cleared successfully!"
        isProcessing = false
    }
}

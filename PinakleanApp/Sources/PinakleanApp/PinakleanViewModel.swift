<file_path>
Pinaklean/PinakleanApp/Sources/PinakleanApp/PinakleanViewModel.swift
</file_path>

<edit_description>
Update PinakleanViewModel to integrate with UnifiedUIState and provide missing methods
</edit_description>

```swift
import Combine
import PinakleanCore
import SwiftUI

@MainActor
class PinakleanViewModel: ObservableObject {
    @Published var scanResults: ScanResults?
    @Published var isProcessing = false
    @Published var statusMessage: String?
    @Published var lastScanTime: String?

    // UI State integration
    private weak var uiState: UnifiedUIState?

    private var cancellables = Set<AnyCancellable>()

    init(uiState: UnifiedUIState? = nil) {
        self.uiState = uiState
        setupBindings()
    }

    private func setupBindings() {
        guard let uiState = uiState else { return }

        // Bind UI state changes
        $isProcessing
            .sink { [weak uiState] isProcessing in
                if isProcessing {
                    uiState?.startAnimation()
                } else {
                    uiState?.endAnimation()
                }
            }
            .store(in: &cancellables)
    }

    var formattedSpaceToClean: String {
        guard let results = scanResults else { return "0 MB" }
        return results.safeTotalSize.formattedSize()
    }

    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    func performQuickScan() async {
        await executeScan("Quick Scan", duration: 1.0, itemCount: 4)
    }

    func performComprehensiveScan() async {
        await executeScan("Comprehensive Scan", duration: 3.0, itemCount: 10)
    }

    private func executeScan(_ scanType: String, duration: Double, itemCount: Int) async {
        isProcessing = true
        statusMessage = "Starting \(scanType.lowercased())..."
        uiState?.startAnimation()

        // Simulate scan process with progress updates
        let startTime = Date()
        let totalSteps = 10

        for step in 1...totalSteps {
            try? await Task.sleep(nanoseconds: UInt64((duration / Double(totalSteps)) * 1_000_000_000))
            uiState?.updateAnimationProgress(Double(step) / Double(totalSteps))
        }

        // Create sample results
        let sampleItems = createSampleItems(count: itemCount)
        let results = ScanResults(items: sampleItems, safeTotalSize: sampleItems.reduce(0) { $0 + $1.size })

        scanResults = results
        lastScanTime = Date().formatted(date: .abbreviated, time: .shortened)
        statusMessage = "\(scanType) completed! Found \(sampleItems.count) items to clean."

        // Update UI state
        uiState?.updateMetrics(
            totalFiles: sampleItems.count,
            spaceToClean: results.safeTotalSize,
            breakdown: StorageBreakdown() // Would be calculated from actual data
        )
        uiState?.addScanActivity(foundFiles: sampleItems.count, duration: Date().timeIntervalSince(startTime))

        isProcessing = false
        uiState?.endAnimation()
    }

    private func createSampleItems(count: Int) -> [CleanableItem] {
        let samplePaths = [
            "~/Library/Caches/com.apple.Safari",
            "~/Library/Caches/com.google.Chrome",
            "~/Library/Logs",
            "/tmp",
            "~/Library/Caches/Homebrew",
            "~/Library/Developer/Xcode/DerivedData",
            "~/Library/Caches/com.apple.dt.Xcode",
            "~/Library/Caches/Pip",
            "~/Library/Caches/Yarn",
            "~/Library/Caches/CocoaPods"
        ]

        let categories = [
            "Browser Cache", "Browser Cache", "System Logs", "Temp Files",
            "Package Cache", "Xcode Cache", "Xcode Cache", "Python Cache",
            "Node Cache", "iOS Cache"
        ]

        let sizes: [Int64] = [
            50_000_000, 75_000_000, 25_000_000, 10_000_000, 15_000_000,
            500_000_000, 100_000_000, 5_000_000, 8_000_000, 12_000_000
        ]

        return (0..<min(count, samplePaths.count)).map { index in
            CleanableItem(
                id: UUID(),
                path: samplePaths[index],
                name: URL(fileURLWithPath: samplePaths[index]).lastPathComponent,
                category: categories[index],
                size: sizes[index],
                safetyScore: 100
            )
        }
    }

    func cleanSafeItems() async {
        guard let results = scanResults else {
            statusMessage = "No scan results available. Please run a scan first."
            return
        }

        await executeClean("Safe Items", items: results.items.filter { $0.safetyScore >= 70 })
    }

    func cleanSelectedItems() async {
        guard let results = scanResults, !results.items.isEmpty else {
            statusMessage = "No items selected. Please run a scan first."
            return
        }

        await executeClean("Selected Items", items: results.items)
    }

    private func executeClean(_ cleanType: String, items: [CleanableItem]) async {
        isProcessing = true
        statusMessage = "Cleaning \(cleanType.lowercased())..."
        uiState?.startAnimation()

        let startTime = Date()
        let totalSteps = items.count

        // Simulate cleaning process with progress
        for (index, item) in items.enumerated() {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds per item
            uiState?.updateAnimationProgress(Double(index + 1) / Double(totalSteps))
        }

        let cleanedSize = items.reduce(0) { $0 + $1.size }

        statusMessage = "Successfully cleaned \(items.count) \(cleanType.lowercased()), freeing \(formatFileSize(cleanedSize))"

        // Update UI state
        uiState?.addCleanActivity(cleanedBytes: cleanedSize, fileCount: items.count)
        uiState?.updateMetrics(totalFiles: 0, spaceToClean: 0, breakdown: StorageBreakdown())

        scanResults = ScanResults(items: [], safeTotalSize: 0) // Clear results after cleaning

        isProcessing = false
        uiState?.endAnimation()
    }

    func clearAllCaches() async {
        isProcessing = true
        statusMessage = "Clearing all caches..."
        uiState?.startAnimation()

        // Simulate cache clearing
        try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds

        scanResults = nil
        statusMessage = "All caches cleared successfully!"

        // Update UI state
        uiState?.updateMetrics(totalFiles: 0, spaceToClean: 0, breakdown: StorageBreakdown())
        uiState?.addErrorActivity("All caches cleared - \(Date().formatted(date: .abbreviated, time: .shortened))")

        isProcessing = false
        uiState?.endAnimation()
    }

    // MARK: - Public Accessors for UI State

    func setUIState(_ state: UnifiedUIState) {
        self.uiState = state
        setupBindings()
    }

    var isProcessingObservable: Published<Bool>.Publisher {
        $isProcessing
    }
}

// MARK: - Supporting Types

struct ScanResults {
    var items: [CleanableItem]
    var safeTotalSize: Int64

    static var empty: ScanResults {
        ScanResults(items: [], safeTotalSize: 0)
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    mutating func remove(at index: Int) {
        if index < items.count {
            safeTotalSize -= items[index].size
            items.remove(at: index)
        }
    }

    mutating func remove(_ item: CleanableItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            remove(at: index)
        }
    }
}

// MARK: - ScanResults Extensions

extension ScanResults {
    /// Calculate total safe size (convenience)
    var totalSize: Int64 {
        safeTotalSize
    }

    /// Get items by risk level
    func itemsByRisk(_ risk: SafetyLevel) -> [CleanableItem] {
        items.filter { $0.safetyLevel == risk }
    }

    /// Get items by category
    func itemsByCategory(_ category: String) -> [CleanableItem] {
        items.filter { $0.category == category }
    }
}

// MARK: - CleanableItem Extensions

extension CleanableItem {
    var safetyLevel: SafetyLevel {
        switch safetyScore {
        case 90...100: return .safe
        case 70...89: return .medium
        case 0...69: return .high
        default: return .high
        }
    }
}

enum SafetyLevel: Int, Comparable {
    case safe = 0
    case medium = 1
    case high = 2

    static func < (lhs: SafetyLevel, rhs: SafetyLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Preview Helpers

extension PinakleanViewModel {
    static var preview: PinakleanViewModel {
        let viewModel = PinakleanViewModel()

        // Create sample data for previews
        let sampleItems = [
            CleanableItem(
                id: UUID(),
                path: "~/Library/Caches/com.apple.Safari",
                name: "Safari Cache",
                category: "Browser Cache",
                size: 50_000_000,
                safetyScore: 100
            )
        ]

        viewModel.scanResults = ScanResults(items: sampleItems, safeTotalSize: 50_000_000)
        viewModel.lastScanTime = "Today at 2:30 PM"
        viewModel.statusMessage = "Ready to clean"

        return viewModel
    }
}

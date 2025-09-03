
import SwiftUI

/// The view for initiating and monitoring file system scans.
struct ScanView: View {
    @State private var selectedCategories: PinakleanEngine.ScanCategories = .safe
    @State private var scanProgress: Double = 0.0
    @State private var safetyScore: Int = 0
    @State private var duplicateGroups: [DuplicateGroup] = []
    @State private var isScanning: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ScanCategorySection(selection: $selectedCategories)
                
                if isScanning {
                    ProgressRing(progress: scanProgress)
                        .frame(width: 150, height: 150)
                }
                
                PrimaryButton(title: isScanning ? "Scanning..." : "Start Scan") {
                    // Start scan action
                    isScanning.toggle()
                }
                .disabled(isScanning)
                
                if !isScanning && safetyScore > 0 {
                    EnhancedSafetyBadge(score: safetyScore)
                    DuplicateGroupsSection(duplicateGroups: duplicateGroups)
                }
            }
            .padding()
        }
    }
}

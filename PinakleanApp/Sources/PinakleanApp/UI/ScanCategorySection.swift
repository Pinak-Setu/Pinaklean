
import PinakleanCore
import SwiftUI

/// A view that allows users to select which categories to include in a scan.
struct ScanCategorySection: View {
    @Binding var selection: PinakleanEngine.ScanCategories
    
    private let columns = [GridItem(.adaptive(minimum: 120))]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Scan Categories")
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(PinakleanEngine.ScanCategories.allCases, id: \.rawValue) { category in
                    Button(action: { toggleSelection(for: category) }) {
                        Text(category.name)
                            .font(.subheadline)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(selection.contains(category) ? Color.accentColor : Color.secondary.opacity(0.2))
                            .foregroundColor(selection.contains(category) ? .white : .primary)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(10)
    }
    
    private func toggleSelection(for category: PinakleanEngine.ScanCategories) {
        if selection.contains(category) {
            selection.remove(category)
        } else {
            selection.insert(category)
        }
    }
}

// Add CaseIterable and a name property to ScanCategories for the UI
extension PinakleanEngine.ScanCategories: CaseIterable {
    public static var allCases: [PinakleanEngine.ScanCategories] = [
        .userCaches, .systemCaches, .developerJunk, .appCaches, .logs, .downloads, .trash, .duplicates, .largeFiles, .oldFiles, .brokenSymlinks, .nodeModules, .xcodeJunk, .dockerJunk, .brewCache, .pipCache
    ]
    
    var name: String {
        switch self {
        case .userCaches: return "User Caches"
        case .systemCaches: return "System Caches"
        case .developerJunk: return "Developer Junk"
        case .appCaches: return "App Caches"
        case .logs: return "Logs"
        case .downloads: return "Downloads"
        case .trash: return "Trash"
        case .duplicates: return "Duplicates"
        case .largeFiles: return "Large Files"
        case .oldFiles: return "Old Files"
        case .brokenSymlinks: return "Broken Symlinks"
        case .nodeModules: return "Node Modules"
        case .xcodeJunk: return "Xcode Junk"
        case .dockerJunk: return "Docker Junk"
        case .brewCache: return "Brew Cache"
        case .pipCache: return "Pip Cache"
        default: return "Unknown"
        }
    }
}

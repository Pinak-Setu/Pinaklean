
import SwiftUI

/// A view that displays groups of duplicate files found during a scan.
struct DuplicateGroupsSection: View {
    let duplicateGroups: [DuplicateGroup]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Duplicate Files")
                .font(.headline)
            
            if duplicateGroups.isEmpty {
                Text("No duplicates found.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(duplicateGroups) { group in
                    VStack(alignment: .leading) {
                        Text("Group: \(group.checksum)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        
                        ForEach(group.items) { item in
                            Text(item.path)
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

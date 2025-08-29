import SwiftUI
import UniformTypeIdentifiers

/// View for managing and viewing all backup locations
struct BackupRegistryView: View {
    @StateObject private var viewModel = BackupRegistryViewModel()
    @State private var selectedBackup: BackupRecord?
    @State private var searchText = ""
    @State private var filterProvider: CloudBackupManager.CloudProvider?
    @State private var showingExportSheet = false
    @State private var showingDetailSheet = false
    
    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            if let backup = selectedBackup {
                BackupDetailView(backup: backup)
            } else {
                EmptyDetailView()
            }
        }
        .navigationTitle("Backup Registry")
        .searchable(text: $searchText, prompt: "Search backups...")
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportBackupListView(backups: viewModel.filteredBackups)
        }
        .sheet(item: $selectedBackup) { backup in
            BackupDetailSheet(backup: backup)
        }
        .task {
            await viewModel.loadBackups()
        }
    }
    
    // MARK: - Sidebar Content
    private var sidebarContent: some View {
        List(selection: $selectedBackup) {
            // Summary Section
            Section {
                SummaryCard(
                    totalBackups: viewModel.backups.count,
                    totalSize: viewModel.totalSize,
                    providers: viewModel.uniqueProviders
                )
            }
            
            // Filter Pills
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterPill(title: "All", isSelected: filterProvider == nil) {
                            filterProvider = nil
                        }
                        
                        ForEach(viewModel.uniqueProviders, id: \.self) { provider in
                            FilterPill(
                                title: provider.rawValue,
                                icon: provider.icon,
                                isSelected: filterProvider == provider
                            ) {
                                filterProvider = provider
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Backup List
            Section("Backups") {
                ForEach(filteredAndSearchedBackups) { backup in
                    BackupRowView(backup: backup, isSelected: selectedBackup?.id == backup.id)
                        .tag(backup)
                        .contextMenu {
                            contextMenu(for: backup)
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .refreshable {
            await viewModel.loadBackups()
        }
    }
    
    // MARK: - Filtered Backups
    private var filteredAndSearchedBackups: [BackupRecord] {
        var results = viewModel.backups
        
        // Filter by provider
        if let provider = filterProvider {
            results = results.filter { $0.provider == provider.rawValue }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            results = results.filter { backup in
                backup.id.localizedCaseInsensitiveContains(searchText) ||
                backup.provider.localizedCaseInsensitiveContains(searchText) ||
                backup.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return results
    }
    
    // MARK: - Context Menu
    @ViewBuilder
    private func contextMenu(for backup: BackupRecord) -> some View {
        Button {
            viewModel.copyLocation(backup)
        } label: {
            Label("Copy Location", systemImage: "doc.on.doc")
        }
        
        Button {
            viewModel.copyInstructions(backup)
        } label: {
            Label("Copy Retrieval Instructions", systemImage: "text.quote")
        }
        
        Button {
            viewModel.openInFinder(backup)
        } label: {
            Label("Show in Finder", systemImage: "folder")
        }
        .disabled(!backup.isLocal)
        
        Divider()
        
        Button {
            Task {
                await viewModel.verifyBackup(backup)
            }
        } label: {
            Label("Verify Backup", systemImage: "checkmark.shield")
        }
        
        Button(role: .destructive) {
            viewModel.deleteBackup(backup)
        } label: {
            Label("Delete Record", systemImage: "trash")
        }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showingExportSheet = true
            } label: {
                Label("Export Registry", systemImage: "square.and.arrow.up")
            }
        }
        
        ToolbarItem {
            Button {
                viewModel.openBackupFolder()
            } label: {
                Label("Open Backup Folder", systemImage: "folder")
            }
        }
        
        ToolbarItem {
            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        viewModel.sortOption = option
                    } label: {
                        HStack {
                            Text(option.title)
                            if viewModel.sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
        }
    }
}

// MARK: - Backup Row View
struct BackupRowView: View {
    let backup: BackupRecord
    let isSelected: Bool
    
    private var provider: CloudBackupManager.CloudProvider {
        CloudBackupManager.CloudProvider(rawValue: backup.provider) ?? .ipfs
    }
    
    private var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: backup.size, countStyle: .file)
    }
    
    private var relativeTime: String {
        RelativeDateTimeFormatter().localizedString(for: backup.timestamp, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Provider Icon
            Image(systemName: provider.icon)
                .font(.title2)
                .foregroundStyle(provider.color)
                .frame(width: 32, height: 32)
                .background(provider.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(provider.rawValue)
                        .font(.headline)
                    
                    if backup.isIncremental {
                        Badge("Incremental")
                    }
                    
                    if backup.isEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                
                Text(backup.location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack {
                    Text(relativeTime)
                    Text("•")
                    Text(formattedSize)
                    
                    if let lastVerified = backup.lastVerified {
                        Text("•")
                        Label("Verified", systemImage: "checkmark.shield.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Status Indicator
            BackupStatusIndicator(status: backup.status)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - Backup Detail View
struct BackupDetailView: View {
    let backup: BackupRecord
    @State private var showingInstructions = false
    @State private var isVerifying = false
    @State private var verificationResult: VerificationResult?
    
    private var provider: CloudBackupManager.CloudProvider {
        CloudBackupManager.CloudProvider(rawValue: backup.provider) ?? .ipfs
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                // Quick Actions
                quickActionsSection
                
                // Details Grid
                detailsGrid
                
                // Retrieval Instructions
                retrievalInstructionsSection
                
                // Verification Status
                if let result = verificationResult {
                    verificationSection(result)
                }
            }
            .padding()
        }
        .navigationTitle("Backup Details")
        .navigationSubtitle(backup.id)
    }
    
    private var headerSection: some View {
        HStack {
            Image(systemName: provider.icon)
                .font(.largeTitle)
                .foregroundStyle(provider.color)
                .frame(width: 60, height: 60)
                .background(provider.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(provider.rawValue)
                    .font(.title2.bold())
                
                HStack {
                    if backup.isEncrypted {
                        Label("Encrypted", systemImage: "lock.fill")
                            .foregroundStyle(.green)
                    }
                    
                    if backup.isIncremental {
                        Label("Incremental", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.blue)
                    }
                }
                .font(.caption)
            }
            
            Spacer()
            
            BackupStatusIndicator(status: backup.status, large: true)
        }
    }
    
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            ActionButton(title: "Copy Location", icon: "doc.on.doc") {
                copyLocation()
            }
            
            ActionButton(title: "Show Instructions", icon: "questionmark.circle") {
                showingInstructions.toggle()
            }
            
            ActionButton(title: "Verify", icon: "checkmark.shield", isLoading: isVerifying) {
                Task {
                    await verifyBackup()
                }
            }
            
            if backup.isLocal {
                ActionButton(title: "Open", icon: "folder") {
                    openInFinder()
                }
            }
        }
    }
    
    private var detailsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            DetailCard(title: "Backup ID", value: backup.id, icon: "number")
            let backupSize = ByteCountFormatter.string(fromByteCount: backup.size, countStyle: .file)
            DetailCard(title: "Size", value: backupSize, icon: "internaldrive")
            DetailCard(title: "Created", value: backup.timestamp.formatted(), icon: "calendar")
            DetailCard(title: "Checksum", value: String(backup.checksum.prefix(12)) + "...", icon: "checkmark.seal")
        }
    }
    
    private var retrievalInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Retrieval Instructions", systemImage: "text.book.closed")
                    .font(.headline)
                Spacer()
                Button {
                    showingInstructions.toggle()
                } label: {
                    Image(systemName: showingInstructions ? "chevron.up" : "chevron.down")
                }
            }
            
            if showingInstructions {
                Text(backup.retrievalInstructions)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .textSelection(.enabled)
            }
        }
    }
    
    private func verificationSection(_ result: VerificationResult) -> some View {
        HStack {
            Image(systemName: result.exists ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(result.exists ? .green : .red)
            
            VStack(alignment: .leading) {
                Text(result.exists ? "Backup Verified" : "Backup Not Found")
                    .font(.headline)
                Text("Last checked: \(result.lastVerified.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(result.exists ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
    
    // Actions
    private func copyLocation() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(backup.location, forType: .string)
    }
    
    private func openInFinder() {
        if FileManager.default.fileExists(atPath: backup.location) {
            NSWorkspace.shared.selectFile(backup.location, inFileViewerRootedAtPath: "")
        }
    }
    
    private func verifyBackup() async {
        isVerifying = true
        // Verify backup exists
        // verificationResult = await registry.verifyBackup(backup.id)
        isVerifying = false
    }
}

// MARK: - Supporting Views
struct SummaryCard: View {
    let totalBackups: Int
    let totalSize: Int64
    let providers: [CloudBackupManager.CloudProvider]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatView(title: "Total Backups", value: "\(totalBackups)", icon: "archivebox")
                Divider().frame(height: 40)
                let totalSizeFormatted = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
                StatView(title: "Total Size", value: totalSizeFormatted, icon: "internaldrive")
            }
            
            HStack {
                Text("Providers:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ForEach(providers, id: \.self) { provider in
                    Image(systemName: provider.icon)
                        .foregroundStyle(provider.color)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

struct StatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FilterPill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    var isLoading = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

struct DetailCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

struct BackupStatusIndicator: View {
    let status: BackupStatus
    var large = false
    
    var color: Color {
        switch status {
        case .active: return .green
        case .missing: return .orange
        case .corrupted: return .red
        case .deleted: return .gray
        }
    }
    
    var icon: String {
        switch status {
        case .active: return "checkmark.circle.fill"
        case .missing: return "questionmark.circle.fill"
        case .corrupted: return "exclamationmark.triangle.fill"
        case .deleted: return "trash.circle.fill"
        }
    }
    
    var body: some View {
        Image(systemName: icon)
            .font(large ? .title2 : .body)
            .foregroundStyle(color)
    }
}

struct Badge: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.blue.opacity(0.2)))
            .foregroundColor(.blue)
    }
}

struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Select a backup to view details")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

struct BackupDetailSheet: View {
    let backup: BackupRecord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            BackupDetailView(backup: backup)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

struct ExportBackupListView: View {
    let backups: [BackupRecord]
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat = ExportFormat.json
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        case markdown = "Markdown"
        case text = "Plain Text"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("Export Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                
                Button("Export") {
                    exportBackups()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Export Backup Registry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func exportBackups() {
        // Export logic here
        dismiss()
    }
}

// MARK: - View Model
@MainActor
class BackupRegistryViewModel: ObservableObject {
    @Published var backups: [BackupRecord] = []
    @Published var filteredBackups: [BackupRecord] = []
    @Published var sortOption = SortOption.newest
    
    var totalSize: Int64 {
        backups.reduce(0) { $0 + $1.size }
    }
    
    var uniqueProviders: [CloudBackupManager.CloudProvider] {
        let providerStrings = Set(backups.map { $0.provider })
        return providerStrings.compactMap { CloudBackupManager.CloudProvider(rawValue: $0) }
    }
    
    func loadBackups() async {
        // Load from registry
        // backups = await registry.getAllBackups()
        sortBackups()
    }
    
    private func sortBackups() {
        switch sortOption {
        case .newest:
            backups.sort { $0.timestamp > $1.timestamp }
        case .oldest:
            backups.sort { $0.timestamp < $1.timestamp }
        case .largest:
            backups.sort { $0.size > $1.size }
        case .smallest:
            backups.sort { $0.size < $1.size }
        case .provider:
            backups.sort { $0.provider < $1.provider }
        }
    }
    
    func copyLocation(_ backup: BackupRecord) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(backup.location, forType: .string)
    }
    
    func copyInstructions(_ backup: BackupRecord) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(backup.retrievalInstructions, forType: .string)
    }
    
    func openInFinder(_ backup: BackupRecord) {
        if FileManager.default.fileExists(atPath: backup.location) {
            NSWorkspace.shared.selectFile(backup.location, inFileViewerRootedAtPath: "")
        }
    }
    
    func openBackupFolder() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupFolder = documentsURL.appendingPathComponent("PinakleanBackups")
        NSWorkspace.shared.open(backupFolder)
    }
    
    func verifyBackup(_ backup: BackupRecord) async {
        // Verify backup
    }
    
    func deleteBackup(_ backup: BackupRecord) {
        // Delete backup record
    }
}

enum SortOption: String, CaseIterable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case largest = "Largest First"
    case smallest = "Smallest First"
    case provider = "By Provider"
    
    var title: String { rawValue }
}

// MARK: - Extensions
extension BackupRecord: Identifiable {}

extension BackupRecord {
    var isLocal: Bool {
        provider == CloudBackupManager.CloudProvider.localNAS.rawValue ||
        (provider == CloudBackupManager.CloudProvider.iCloudDrive.rawValue && 
         FileManager.default.fileExists(atPath: location))
    }
}
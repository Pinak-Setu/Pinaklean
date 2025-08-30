import SwiftUI
import CloudKit

/// Free cloud backup settings and management view
struct BackupSettingsView: View {
    @StateObject private var backupManager = CloudBackupViewModel()
    @State private var selectedProvider: CloudBackupManager.CloudProvider = .iCloudDrive
    @State private var showingSetupGuide = false
    @State private var isPerformingBackup = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                freeProvidersSection
                storageUsageSection
                backupScheduleSection
                setupGuidesSection
                backupActionsSection
            }
            .padding()
        }
        .navigationTitle("Free Cloud Backup")
        .sheet(isPresented: $showingSetupGuide) {
            SetupGuideView(provider: selectedProvider)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("100% Free Backup Solutions")
                    .font(.title2.bold())
            } icon: {
                Image(systemName: "icloud.and.arrow.up")
                    .font(.title2)
                    .foregroundStyle(.green)
            }

            Text("All backup options below are completely free. No subscription required!")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            InfoCard {
                Text("💡 **Smart Tip**: Pinaklean automatically chooses the best free option based on your backup size.")
            }
        }
    }

    // MARK: - Free Providers Section
    private var freeProvidersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Free Providers")
                .font(.headline)

            ForEach(backupManager.availableProviders, id: \.self) { provider in
                ProviderCard(
                    provider: provider,
                    isSelected: selectedProvider == provider,
                    usage: backupManager.getUsage(for: provider)
                ) {
                    selectedProvider = provider
                }
            }
        }
    }

    // MARK: - Storage Usage Section
    private var storageUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storage Usage")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(backupManager.storageStats, id: \.provider) { stat in
                    StorageBarView(
                        provider: stat.provider,
                        usedGB: stat.usedGB,
                        totalGB: stat.totalGB,
                        color: stat.provider.color
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Backup Schedule Section
    private var backupScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Automatic Backup")
                .font(.headline)

            Toggle("Enable Auto-Backup", isOn: $backupManager.autoBackupEnabled)

            if backupManager.autoBackupEnabled {
                Picker("Schedule", selection: $backupManager.backupSchedule) {
                    Text("Daily").tag(BackupSchedule.daily)
                    Text("Weekly").tag(BackupSchedule.weekly)
                    Text("Monthly").tag(BackupSchedule.monthly)
                    Text("After Each Cleanup").tag(BackupSchedule.afterCleanup)
                }
                .pickerStyle(.segmented)

                Toggle("Incremental Backup (Saves Space)", isOn: $backupManager.incrementalEnabled)
                    .help("Only backs up changes since last backup")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Setup Guides Section
    private var setupGuidesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Setup Guides")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    SetupCard(
                        icon: "icloud",
                        title: "iCloud Drive",
                        subtitle: "5GB Free",
                        color: .blue
                    ) {
                        selectedProvider = .iCloudDrive
                        showingSetupGuide = true
                    }

                    SetupCard(
                        icon: "arrow.up.circle",
                        title: "GitHub",
                        subtitle: "2GB per file",
                        color: .purple
                    ) {
                        selectedProvider = .githubRelease
                        showingSetupGuide = true
                    }

                    SetupCard(
                        icon: "network",
                        title: "IPFS",
                        subtitle: "Unlimited",
                        color: .orange
                    ) {
                        selectedProvider = .ipfs
                        showingSetupGuide = true
                    }

                    SetupCard(
                        icon: "externaldrive.connected.to.line.below",
                        title: "Local NAS",
                        subtitle: "Your storage",
                        color: .green
                    ) {
                        selectedProvider = .localNAS
                        showingSetupGuide = true
                    }
                }
            }
        }
    }

    // MARK: - Backup Actions Section
    private var backupActionsSection: some View {
        VStack(spacing: 12) {
            Button(action: performBackup) {
                Label(
                    isPerformingBackup ? "Backing up..." : "Backup Now",
                    systemImage: isPerformingBackup ? "arrow.clockwise" : "arrow.up.circle.fill"
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isPerformingBackup)

            HStack(spacing: 12) {
                Button(action: restoreBackup) {
                    Label("Restore", systemImage: "arrow.down.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: viewBackups) {
                    Label("View Backups", systemImage: "list.bullet")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Actions
    private func performBackup() {
        Task {
            isPerformingBackup = true
            await backupManager.performBackup(to: selectedProvider)
            isPerformingBackup = false
        }
    }

    private func restoreBackup() {
        // Show restore sheet
    }

    private func viewBackups() {
        // Show backups list
    }
}

// MARK: - Provider Card
struct ProviderCard: View {
    let provider: CloudBackupManager.CloudProvider
    let isSelected: Bool
    let usage: StorageUsage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: provider.icon)
                    .font(.title2)
                    .foregroundStyle(provider.color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.rawValue)
                        .font(.headline)
                    Text(provider.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(provider.freeStorage)
                        .font(.headline)
                        .foregroundStyle(.green)
                    Text("FREE")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Setup Card
struct SetupCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundStyle(color)

                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 120, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Storage Bar View
struct StorageBarView: View {
    let provider: CloudBackupManager.CloudProvider
    let usedGB: Double
    let totalGB: Double
    let color: Color

    private var percentage: Double {
        guard totalGB > 0 else { return 0 }
        return min(usedGB / totalGB, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(provider.rawValue, systemImage: provider.icon)
                    .font(.caption)
                Spacer()
                Text("\(String(format: "%.1f", usedGB))GB / \(String(format: "%.0f", totalGB))GB")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Info Card
struct InfoCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            content
                .font(.footnote)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

// MARK: - Setup Guide View
struct SetupGuideView: View {
    let provider: CloudBackupManager.CloudProvider
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Provider specific setup instructions
                    switch provider {
                    case .iCloudDrive:
                        iCloudSetupGuide
                    case .githubRelease, .githubGist:
                        githubSetupGuide
                    case .ipfs:
                        ipfsSetupGuide
                    case .localNAS:
                        nasSetupGuide
                    default:
                        genericSetupGuide
                    }
                }
                .padding()
            }
            .navigationTitle("\(provider.rawValue) Setup")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            })
        }
    }

    private var iCloudSetupGuide: some View {
        VStack(alignment: .leading, spacing: 16) {
            SetupStep(number: 1, title: "Sign in to iCloud",
                     description: "Go to System Settings > Apple ID and sign in")
            SetupStep(number: 2, title: "Enable iCloud Drive",
                     description: "Turn on iCloud Drive in System Settings > Apple ID > iCloud")
            SetupStep(number: 3, title: "That's it!",
                     description: "You have 5GB free storage. Pinaklean will automatically use it.")
        }
    }

    private var githubSetupGuide: some View {
        VStack(alignment: .leading, spacing: 16) {
            SetupStep(number: 1, title: "Install GitHub CLI",
                     description: "Run: brew install gh")
            SetupStep(number: 2, title: "Authenticate",
                     description: "Run: gh auth login")
            SetupStep(number: 3, title: "Create a repository",
                     description: "Pinaklean will create releases in your repo (2GB per file limit)")
        }
    }

    private var ipfsSetupGuide: some View {
        VStack(alignment: .leading, spacing: 16) {
            SetupStep(number: 1, title: "No setup needed!",
                     description: "Pinaklean uses Web3.storage (5GB free)")
            SetupStep(number: 2, title: "Optional: Install IPFS",
                     description: "For unlimited local storage: brew install ipfs")
            SetupStep(number: 3, title: "Distributed backup",
                     description: "Your backups are distributed across the network")
        }
    }

    private var nasSetupGuide: some View {
        VStack(alignment: .leading, spacing: 16) {
            SetupStep(number: 1, title: "Connect to NAS",
                     description: "Use Finder > Go > Connect to Server")
            SetupStep(number: 2, title: "Mount the drive",
                     description: "Enter smb://your-nas-ip or afp://your-nas-ip")
            SetupStep(number: 3, title: "Unlimited storage",
                     description: "Uses your own NAS storage capacity")
        }
    }

    private var genericSetupGuide: some View {
        Text("Setup guide for \(provider.rawValue)")
    }
}

// MARK: - Setup Step
struct SetupStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 30, height: 30)
                .overlay(
                    Text("\(number)")
                        .font(.headline)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - View Model
@MainActor
class CloudBackupViewModel: ObservableObject {
    @Published var availableProviders: [CloudBackupManager.CloudProvider] = []
    @Published var storageStats: [StorageStats] = []
    @Published var autoBackupEnabled = false
    @Published var incrementalEnabled = true
    @Published var backupSchedule: BackupSchedule = .weekly

    init() {
        loadProviders()
        loadStorageStats()
    }

    func loadProviders() {
        // Check which providers are available
        availableProviders = [
            .iCloudDrive,
            .githubGist,
            .ipfs
        ]

        // Check for NAS
        if FileManager.default.fileExists(atPath: "/Volumes/NAS") {
            availableProviders.append(.localNAS)
        }
    }

    func loadStorageStats() {
        storageStats = [
            StorageStats(provider: .iCloudDrive, usedGB: 2.3, totalGB: 5.0),
            StorageStats(provider: .githubGist, usedGB: 0.05, totalGB: 0.1),
            StorageStats(provider: .ipfs, usedGB: 0.8, totalGB: 5.0),
        ]
    }

    func getUsage(for provider: CloudBackupManager.CloudProvider) -> StorageUsage {
        storageStats.first { $0.provider == provider }?.usage ?? .init(used: 0, total: 0)
    }

    func performBackup(to provider: CloudBackupManager.CloudProvider) async {
        // Perform backup
        try? await Task.sleep(nanoseconds: 2_000_000_000) // Simulate
    }
}

// MARK: - Supporting Types
struct StorageStats: Identifiable {
    let id = UUID()
    let provider: CloudBackupManager.CloudProvider
    let usedGB: Double
    let totalGB: Double

    var usage: StorageUsage {
        StorageUsage(used: Int64(usedGB * 1024 * 1024 * 1024),
                    total: Int64(totalGB * 1024 * 1024 * 1024))
    }
}

struct StorageUsage {
    let used: Int64
    let total: Int64
}

enum BackupSchedule: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case afterCleanup = "After Cleanup"
}

// MARK: - Provider Extensions
extension CloudBackupManager.CloudProvider {
    var icon: String {
        switch self {
        case .iCloudDrive: return "icloud"
        case .githubGist, .githubRelease: return "arrow.up.circle"
        case .googleDrive: return "g.circle"
        case .ipfs: return "network"
        case .webDAV: return "server.rack"
        case .localNAS: return "externaldrive.connected.to.line.below"
        }
    }

    var color: Color {
        switch self {
        case .iCloudDrive: return .blue
        case .githubGist, .githubRelease: return .purple
        case .googleDrive: return .green
        case .ipfs: return .orange
        case .webDAV: return .indigo
        case .localNAS: return .teal
        }
    }

    var description: String {
        switch self {
        case .iCloudDrive: return "Apple's cloud storage"
        case .githubGist: return "Small backups via GitHub"
        case .githubRelease: return "Large backups via GitHub"
        case .googleDrive: return "Google's cloud storage"
        case .ipfs: return "Decentralized storage"
        case .webDAV: return "Your own server"
        case .localNAS: return "Network attached storage"
        }
    }

    var freeStorage: String {
        switch self {
        case .iCloudDrive: return "5GB"
        case .githubGist: return "100MB"
        case .githubRelease: return "2GB/file"
        case .googleDrive: return "15GB"
        case .ipfs: return "5GB"
        case .webDAV: return "Unlimited"
        case .localNAS: return "Unlimited"
        }
    }
}

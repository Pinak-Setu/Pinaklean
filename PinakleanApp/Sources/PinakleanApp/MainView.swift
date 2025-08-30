import SwiftUI

struct MainView: View {
    @EnvironmentObject var viewModel: PinakleanViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)

            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "magnifyingglass")
                }
                .tag(1)

            CleanView()
                .tabItem {
                    Label("Clean", systemImage: "trash.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .frame(minWidth: 800, minHeight: 600)
        .navigationTitle("Pinaklean - macOS Cleanup Tool")
    }
}

struct DashboardView: View {
    @EnvironmentObject var viewModel: PinakleanViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("🧹 Pinaklean Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)

            HStack(spacing: 30) {
                VStack {
                    Text("Files Scanned")
                        .font(.headline)
                    Text("\(viewModel.scanResults?.count ?? 0)")
                        .font(.title)
                        .foregroundColor(.blue)
                }

                VStack {
                    Text("Space to Clean")
                        .font(.headline)
                    Text(viewModel.formattedSpaceToClean)
                        .font(.title)
                        .foregroundColor(.green)
                }

                VStack {
                    Text("Last Scan")
                        .font(.headline)
                    Text(viewModel.lastScanTime ?? "Never")
                        .font(.title)
                        .foregroundColor(.orange)
                }
            }

            HStack(spacing: 20) {
                Button("Quick Scan") {
                    Task {
                        await viewModel.performQuickScan()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Clean Safe Items") {
                    Task {
                        await viewModel.cleanSafeItems()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(viewModel.scanResults?.isEmpty ?? true)
            }

            if let message = viewModel.statusMessage {
                Text(message)
                    .foregroundColor(viewModel.isProcessing ? .blue : .green)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
    }
}

struct ScanView: View {
    @EnvironmentObject var viewModel: PinakleanViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("🔍 Scan for Cleanable Files")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 15) {
                Toggle("Scan Cache Files", isOn: .constant(true))
                Toggle("Scan Log Files", isOn: .constant(true))
                Toggle("Scan Temporary Files", isOn: .constant(true))
                Toggle("Scan Package Manager Cache", isOn: .constant(true))
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

            Button("Start Comprehensive Scan") {
                Task {
                    await viewModel.performComprehensiveScan()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isProcessing)

            if viewModel.isProcessing {
                ProgressView("Scanning...")
                    .progressViewStyle(.circular)
            }

            Spacer()
        }
        .padding()
    }
}

struct CleanView: View {
    @EnvironmentObject var viewModel: PinakleanViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("🗑️ Clean Files")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let results = viewModel.scanResults, !results.isEmpty {
                List(results, id: \.self) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.path)
                                .font(.headline)
                            Text("Size: \(viewModel.formatFileSize(item.size))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Safe to clean")
                            .foregroundColor(.green)
                    }
                }
                .frame(height: 300)

                HStack {
                    Button("Clean Selected") {
                        Task {
                            await viewModel.cleanSelectedItems()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Clean All Safe") {
                        Task {
                            await viewModel.cleanSafeItems()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Text("No files to clean. Run a scan first.")
                    .foregroundColor(.secondary)
                    .padding()
            }

            Spacer()
        }
        .padding()
    }
}

struct SettingsView: View {
    @EnvironmentObject var viewModel: PinakleanViewModel
    @AppStorage("autoBackup") private var autoBackup = true
    @AppStorage("safeMode") private var safeMode = true

    var body: some View {
        VStack(spacing: 20) {
            Text("⚙️ Settings")
                .font(.largeTitle)
                .fontWeight(.bold)

            Form {
                Section("General") {
                    Toggle("Safe Mode (Recommended)", isOn: $safeMode)
                    Toggle("Auto Backup Before Cleaning", isOn: $autoBackup)
                }

                Section("Scan Options") {
                    Toggle("Include System Caches", isOn: .constant(true))
                    Toggle("Include User Caches", isOn: .constant(true))
                    Toggle("Include Log Files", isOn: .constant(true))
                }

                Section("Advanced") {
                    Button("Clear All Caches") {
                        Task {
                            await viewModel.clearAllCaches()
                        }
                    }
                    .foregroundColor(.red)

                    Button("Reset Settings") {
                        autoBackup = true
                        safeMode = true
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
}

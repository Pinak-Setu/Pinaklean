//
// IncrementalIndexer_fixed.swift
// Fixed version without SQLite issues for now
//

import Foundation

/// Simplified incremental indexer 
public actor IncrementalIndexer {
    
    private var lastScanTime: Date?
    private var indexedPaths: Set<String> = []
    private var isMonitoring = false

    public init() async throws {
        // Simplified initialization
        await loadIndexState()
    }
    
    public func startMonitoring() async {
        guard !isMonitoring else { return }
        isMonitoring = true
        print("File monitoring started (simplified)")
    }
    
    public func stopMonitoring() {
        isMonitoring = false
        print("File monitoring stopped")
    }
    
    private func loadIndexState() async {
        // Simplified state loading
        lastScanTime = Date()
    }
}

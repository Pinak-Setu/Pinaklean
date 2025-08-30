//
//  UnifiedUIState.swift
//  PinakleanApp
//
//  Stub implementation for UI state management
//

import Combine
import Foundation
import PinakleanCore

/// A stub ObservableObject for unified UI state.
/// Extend this with real properties as needed for your app.
final class UnifiedUIState: ObservableObject {
    // Example published properties
    @Published var isScanning: Bool = false
    @Published var isCleaning: Bool = false
    @Published var scanResults: ScanResults? = nil
    @Published var notifications: [PinakleanNotification] = []

    // Add more properties and methods as needed for your UI logic

    func addNotification(_ notification: PinakleanNotification) {
        notifications.append(notification)
    }
}

// Stub types for compilation (using core types where possible)
// Assuming CleanableItem is imported from PinakleanCore
// If not, import: import PinakleanCore

struct ScanResults {
    var items: [CleanableItem] = []
    var safeTotalSize: Int64 = 0
}

struct PinakleanNotification {
    var title: String
    var message: String
    var type: NotificationType
}

enum NotificationType {
    case success
    case error
    case info
}

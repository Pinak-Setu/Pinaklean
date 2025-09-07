// NotificationManager.swift - Notification system for Pinaklean (app target)
import Foundation
import UserNotifications

public class NotificationManager: NSObject, ObservableObject {
    public static let shared = NotificationManager()
    
    @Published public var pendingNotifications: [SystemNotificationPayload] = []
    @Published public var notificationSettings: NotificationSettings = .default
    
    private let center = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        center.delegate = self
        requestAuthorization()
        loadSettings()
    }
    
    // Request notification permissions
    public func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission denied: \(error)")
            }
        }
    }
    
    // Send cleanup completion notification
    public func notifyCleanupComplete(spaceFreed: Int64, itemsCleaned: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Cleanup Complete"
        content.body = "Freed \(formatBytes(spaceFreed)) in \(itemsCleaned) items"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "cleanup-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    public func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "notificationSettings"),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            notificationSettings = settings
        }
    }
    
    public func saveSettings() {
        if let data = try? JSONEncoder().encode(notificationSettings) {
            UserDefaults.standard.set(data, forKey: "notificationSettings")
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     willPresent notification: UNNotification,
                                     withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     didReceive response: UNNotificationResponse,
                                     withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Notification tapped: \(response.notification.request.identifier)")
        completionHandler()
    }
}

public struct SystemNotificationPayload: Identifiable, Codable {
    public var id = UUID()
    public let title: String
    public let message: String
    public var timestamp = Date()
    public let type: NotificationType
    public let actionURL: String?
    
    public enum NotificationType: String, Codable {
        case cleanupComplete = "cleanup_complete"
        case hourlyMaintenance = "hourly_maintenance"
        case safetyAlert = "safety_alert"
        case lowDiskSpace = "low_disk_space"
        case error = "error"
    }
}

public struct NotificationSettings: Codable {
    public var cleanupCompleteEnabled = true
    public var hourlyMaintenanceEnabled = true
    public var safetyAlertsEnabled = true
    public var lowDiskSpaceEnabled = true
    public var soundEnabled = true
    public var badgeEnabled = true
    
    public static let `default` = NotificationSettings()
}



import Foundation
import SwiftUI

// Note: Notification names are now managed by KeyboardShortcutManager
// This file maintains existing notification names for backward compatibility
extension Notification.Name {
    static let newTab = Notification.Name("newTab")
    static let closeTab = Notification.Name("closeTab")
    static let reload = Notification.Name("reload")
    static let openSettings = Notification.Name("openSettings")
}

class AppManager: ObservableObject {
    static let shared = AppManager()
    private let appCoordinator = AppCoordinator()
    
    private init() {
        setupNotificationObservers()
        appCoordinator.start()
    }
    
    private func setupNotificationObservers() {
        let shortcutManager = KeyboardShortcutManager.shared
        
        // Set up observers for all keyboard shortcuts
        for shortcut in shortcutManager.shortcuts {
            if let notificationName = shortcut.notificationName {
                NotificationCenter.default.addObserver(
                    forName: notificationName,
                    object: nil,
                    queue: .main
                ) { [weak self] notification in
                    self?.appCoordinator.handleNotification(notification)
                }
            }
        }
        
        // Keep the settings observer
        NotificationCenter.default.addObserver(
            forName: .openSettings,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.appCoordinator.handleNotification(notification)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        appCoordinator.finish()
    }
}

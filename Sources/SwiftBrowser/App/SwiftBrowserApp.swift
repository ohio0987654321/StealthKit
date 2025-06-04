import Foundation
import SwiftUI

extension Notification.Name {
    static let newTab = Notification.Name("newTab")
    static let closeTab = Notification.Name("closeTab")
    static let reload = Notification.Name("reload")
    static let focusAddressBar = Notification.Name("focusAddressBar")
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
        NotificationCenter.default.addObserver(
            forName: .newTab,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.appCoordinator.handleNotification(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: .closeTab,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.appCoordinator.handleNotification(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: .reload,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.appCoordinator.handleNotification(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: .focusAddressBar,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.appCoordinator.handleNotification(notification)
        }
        
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

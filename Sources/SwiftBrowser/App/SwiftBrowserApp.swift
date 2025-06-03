import SwiftUI
import AppKit

// Browser commands for menu bar integration
// Note: Commands are now registered directly in PanelAppDelegate
struct BrowserCommands: Commands {
    var body: some Commands {
        // Replace default "New" behavior with "New Tab"
        CommandGroup(replacing: .newItem) {
            Button("New Tab") {
                NotificationCenter.default.post(name: .newTab, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        
        CommandGroup(after: .newItem) {
            Button("Close Tab") {
                NotificationCenter.default.post(name: .closeTab, object: nil)
            }
            .keyboardShortcut("w", modifiers: .command)
        }
        
        CommandGroup(after: .sidebar) {
            Button("Reload") {
                NotificationCenter.default.post(name: .reload, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)
            
            Button("Select Address Bar") {
                NotificationCenter.default.post(name: .focusAddressBar, object: nil)
            }
            .keyboardShortcut("l", modifiers: .command)
        }
    }
}


// Notification names for keyboard shortcuts
extension Notification.Name {
    static let newTab = Notification.Name("newTab")
    static let closeTab = Notification.Name("closeTab")
    static let reload = Notification.Name("reload")
    static let focusAddressBar = Notification.Name("focusAddressBar")
    static let openSettings = Notification.Name("openSettings")
}

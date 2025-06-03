import SwiftUI

@main
struct SwiftBrowserApp: App {
    @NSApplicationDelegateAdaptor(PanelAppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty scene - actual panel is created by PanelAppDelegate
        WindowGroup {
            EmptyView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 0, height: 0)
        .windowResizability(.contentSize)
        .commands {
            BrowserCommands()
        }
    }
}
struct BrowserCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Tab") {
                NotificationCenter.default.post(name: .newTab, object: nil)
            }
            .keyboardShortcut("t", modifiers: .command)
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

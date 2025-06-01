//
//  SwiftBrowserApp.swift
//  SwiftBrowser
//
//  SwiftUI app entry point for modern browser implementation.
//  Replaces the Objective-C AppDelegate pattern.
//

import SwiftUI

@main
struct SwiftBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            BrowserView()
                .onAppear {
                    // Initialize stealth features after UI is ready
                    DispatchQueue.main.async {
                        _ = StealthManager.shared
                    }
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
        .commands {
            BrowserCommands()
        }
    }
}

// Browser keyboard shortcuts and menu commands
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
}

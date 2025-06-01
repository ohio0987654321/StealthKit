//
//  StatusBarController.swift
//  SwiftBrowser
//
//  Manages the status bar item and menu for background operation.
//  Provides discrete access to browser functionality when the app is hidden from the dock.
//

import Foundation
import AppKit

class StatusBarController {
    static let shared = StatusBarController()
    
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    
    var isStatusBarActive: Bool {
        return statusItem != nil
    }
    
    init() {}
    
    // MARK: - Status Bar Management
    
    func setupStatusBar() {
        guard statusItem == nil else { return }
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        // Configure the status item
        if let statusButton = statusItem?.button {
            statusButton.image = NSImage(systemSymbolName: "network.badge.shield.half.filled", accessibilityDescription: "Stealth Browser")
            statusButton.toolTip = "Stealth Browser"
        }
        
        // Create and set the menu
        setupStatusBarMenu()
        statusItem?.menu = menu
    }
    
    func removeStatusBar() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
            self.menu = nil
        }
    }
    
    private func setupStatusBarMenu() {
        menu = NSMenu()
        
        // New Tab
        let newTabItem = NSMenuItem(title: "New Tab", action: #selector(createNewTab), keyEquivalent: "t")
        newTabItem.target = self
        newTabItem.keyEquivalentModifierMask = [.command]
        menu?.addItem(newTabItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Stealth Browser", action: #selector(quitApplication), keyEquivalent: "q")
        quitItem.target = self
        quitItem.keyEquivalentModifierMask = [.command]
        menu?.addItem(quitItem)
    }
    
    func updateStatusBarMenu() {
        // Update menu items based on current browser state
        setupStatusBarMenu()
        statusItem?.menu = menu
    }
    
    // MARK: - Menu Actions
    
    @objc private func createNewTab() {
        // Post notification to create new tab
        NotificationCenter.default.post(name: .newTab, object: nil)
        
        // Bring the main browser window to front
        NSApp.activate(ignoringOtherApps: true)
        
        // Find and show the main browser window
        if let window = NSApp.windows.first(where: { !$0.isKind(of: NSPanel.self) }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func quitApplication() {
        NSApp.terminate(nil)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let openStealthSettings = Notification.Name("openStealthSettings")
}

import Foundation
import AppKit
import WebKit

// MARK: - Notification Extensions
extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}

@Observable
class StealthManager {
    static let shared = StealthManager()
    
    var isStealthModeActive: Bool = true
    var isWindowCloakingEnabled: Bool = true
    var isAlwaysOnTop: Bool = false
    var isWindowTransparencyEnabled: Bool = false
    var windowTransparencyLevel: Double = 0.9
    
    // New window utility settings
    var isPinnedToCurrentDesktop: Bool = true
    var isAccessoryApp: Bool = false
    
    // Menu bar icon for accessory mode
    private var statusItem: NSStatusItem?
    
    private init() {
        initializeStealthFeatures()
    }
    
    func initializeStealthFeatures() {
        if isWindowCloakingEnabled {
            setWindowCloakingEnabled(true)
        }
    }
    
    // MARK: - Window Management
    
    func applyStealthToWindow(_ window: NSWindow) {
        if isWindowCloakingEnabled {
            WindowCloaking.applyCloakingToWindow(window, isPinnedToCurrentDesktop: isPinnedToCurrentDesktop)
        }
    }
    
    func configureWebViewForStealth(_ webView: WKWebView) {
        WindowCloaking.configureWebViewForStealth(webView)
    }
    
    private func applyWindowCloakingToAllWindows() {
        for window in NSApp.windows {
            if isWindowCloakingEnabled {
                WindowCloaking.applyCloakingToWindow(window, isPinnedToCurrentDesktop: isPinnedToCurrentDesktop)
            } else {
                WindowCloaking.removeCloakingFromWindow(window)
            }
        }
    }
    
    // MARK: - Stealth Mode Control
    
    func setStealthModeEnabled(_ enabled: Bool) {
        isStealthModeActive = enabled
        
        if enabled {
            // Enable all stealth features
            setWindowCloakingEnabled(true)
        } else {
            // Disable stealth features
            setWindowCloakingEnabled(false)
        }
    }
    
    func setWindowCloakingEnabled(_ enabled: Bool) {
        isWindowCloakingEnabled = enabled
        applyWindowCloakingToAllWindows()
        
        // IMPORTANT: After changing NSPanel setting, reapply Always on Top if it was enabled
        // This fixes the bug where Always on Top breaks when NSPanel is toggled
        if isAlwaysOnTop {
            applyAlwaysOnTopToAllWindows()
        }
        
        // Sync with WindowManager
        WindowManager.shared.isCloakingEnabled = enabled
    }
    
    // MARK: - Always On Top Management
    
    func setAlwaysOnTop(_ enabled: Bool) {
        isAlwaysOnTop = enabled
        applyAlwaysOnTopToAllWindows()
        
        // Sync with WindowManager
        WindowManager.shared.isAlwaysOnTop = enabled
    }
    
    private func applyAlwaysOnTopToAllWindows() {
        for window in NSApp.windows {
            if !window.isKind(of: NSPanel.self) {
                if isAlwaysOnTop {
                    // Simple always on top - accepts that it hides in Mission Control
                    window.level = .floating
                } else {
                    window.level = .normal
                    // Restore normal collection behavior
                    var behavior = window.collectionBehavior
                    behavior.remove(.ignoresCycle)
                    behavior.insert(.participatesInCycle)
                    window.collectionBehavior = behavior
                }
            }
        }
    }
    
    // MARK: - Window Transparency Management
    
    func setWindowTransparencyEnabled(_ enabled: Bool) {
        isWindowTransparencyEnabled = enabled
        applyTransparencyToAllWindows()
        
        // Sync with WindowManager
        WindowManager.shared.isTranslucencyEnabled = enabled
    }
    
    func setWindowTransparencyLevel(_ level: Double) {
        windowTransparencyLevel = level
        if isWindowTransparencyEnabled {
            applyTransparencyToAllWindows()
        }
    }
    
    private func applyTransparencyToAllWindows() {
        for window in NSApp.windows {
            if !window.isKind(of: NSPanel.self) {
                if isWindowTransparencyEnabled {
                    WindowCloaking.setWindowTransparency(window, alpha: windowTransparencyLevel)
                } else {
                    WindowCloaking.setWindowTransparency(window, alpha: 1.0)
                }
            }
        }
    }
    
    // MARK: - New Window Utility Settings
    
    func setPinnedToCurrentDesktop(_ enabled: Bool) {
        isPinnedToCurrentDesktop = enabled
        applyWindowCloakingToAllWindows()
        
        // Update WindowManager to avoid circular dependency
        WindowManager.shared.updatePinnedToCurrentDesktop(enabled)
    }
    
    func setAccessoryApp(_ enabled: Bool) {
        isAccessoryApp = enabled
        applyAccessoryAppPolicy()
    }
    
    private func applyAccessoryAppPolicy() {
        DispatchQueue.main.async {
            if self.isAccessoryApp {
                NSApp.setActivationPolicy(.accessory)  // No dock icon, no menu bar switching
                self.setupMenuBarIcon()
            } else {
                self.removeMenuBarIcon()
                NSApp.setActivationPolicy(.regular)     // Normal dock icon and menu bar
            }
        }
    }
    
    // MARK: - Menu Bar Icon Management
    
    private func setupMenuBarIcon() {
        guard statusItem == nil else { return }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Browser")
        
        let menu = NSMenu()
        
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func removeMenuBarIcon() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }
    
    @objc private func openSettings() {
        // Post notification to open settings
        NotificationCenter.default.post(name: .openSettings, object: nil)
        
        // Also bring the app to front if needed
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Window Creation
    
    func createStealthBrowserWindow() -> NSWindow {
        // Create a basic window for now
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // Apply stealth configuration
        applyStealthToWindow(window)
        
        return window
    }
}

import Foundation
import AppKit
import WebKit

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
    var hideInMissionControl: Bool = false
    var isAccessoryApp: Bool = false
    var showDockIcon: Bool = true
    
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
                    // Choose window level based on Mission Control visibility preference
                    if hideInMissionControl {
                        window.level = .floating  // Floating level hides in Mission Control
                    } else {
                        window.level = .statusBar  // StatusBar level stays visible in Mission Control
                    }
                } else {
                    window.level = .normal
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
    
    func setHideInMissionControl(_ enabled: Bool) {
        hideInMissionControl = enabled
        applyAlwaysOnTopToAllWindows()
        
        // Update WindowManager to avoid circular dependency
        WindowManager.shared.updateHideInMissionControl(enabled)
    }
    
    func setAccessoryApp(_ enabled: Bool) {
        isAccessoryApp = enabled
        applyAccessoryAppPolicy()
    }
    
    func setShowDockIcon(_ enabled: Bool) {
        showDockIcon = enabled
        applyDockIconVisibility()
    }
    
    private func applyAccessoryAppPolicy() {
        if isAccessoryApp {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
            // When switching back to regular, apply dock icon setting
            applyDockIconVisibility()
        }
    }
    
    private func applyDockIconVisibility() {
        // Only apply dock icon visibility when not in accessory mode
        if !isAccessoryApp {
            if showDockIcon {
                NSApp.setActivationPolicy(.regular)
            } else {
                NSApp.setActivationPolicy(.prohibited)
            }
        }
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

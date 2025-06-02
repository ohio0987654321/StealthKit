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
            WindowCloaking.applyCloakingToWindow(window)
        }
    }
    
    func configureWebViewForStealth(_ webView: WKWebView) {
        WindowCloaking.configureWebViewForStealth(webView)
    }
    
    private func applyWindowCloakingToAllWindows() {
        for window in NSApp.windows {
            if isWindowCloakingEnabled {
                WindowCloaking.applyCloakingToWindow(window)
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
    }
    
    // MARK: - Always On Top Management
    
    func setAlwaysOnTop(_ enabled: Bool) {
        isAlwaysOnTop = enabled
        applyAlwaysOnTopToAllWindows()
    }
    
    private func applyAlwaysOnTopToAllWindows() {
        for window in NSApp.windows {
            if !window.isKind(of: NSPanel.self) {
                if isAlwaysOnTop {
                    window.level = .floating
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

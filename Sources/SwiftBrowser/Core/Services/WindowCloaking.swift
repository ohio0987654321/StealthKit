import Foundation
import AppKit
import WebKit

class WindowCloaking {
    
    // MARK: - Window Transparency
    
    static func setWindowTransparency(_ window: NSWindow, alpha: Double) {
        let clampedAlpha = max(0.1, min(1.0, alpha))
        window.alphaValue = clampedAlpha
        
        // If making window more transparent, also add background material
        if clampedAlpha < 1.0 {
            window.backgroundColor = NSColor.clear
            window.isOpaque = false
        } else {
            window.isOpaque = true
        }
    }
    
    static func getWindowTransparency(_ window: NSWindow) -> Double {
        return window.alphaValue
    }
    
    static func applyCloakingToWindow(_ window: NSWindow, isPinnedToCurrentDesktop: Bool = true) {
        configureStealthCollectionBehavior(window, isPinnedToCurrentDesktop: isPinnedToCurrentDesktop)
        applyStealthWindowLevel(window)
        configureAdvancedStealth(window)
    }
    
    static func removeCloakingFromWindow(_ window: NSWindow) {
        // Restore normal window behavior
        window.collectionBehavior = [.managed, .participatesInCycle]
        window.level = .normal
        window.sharingType = .readWrite
        
        // Remove any custom properties that were set for stealth
        window.ignoresMouseEvents = false
    }
    
    static func windowHasCloaking(_ window: NSWindow) -> Bool {
        // Check if window has stealth collection behavior applied
        return window.collectionBehavior.contains(.stationary) ||
               window.collectionBehavior.contains(.ignoresCycle) ||
               window.level != .normal
    }
    
    // MARK: - Window Level Configuration
    
    static func applyStealthWindowLevel(_ window: NSWindow) {
        // Set window level for stealth operation
        // Using normal level but with special collection behavior
        window.level = .normal
        
        // Ensure window appears correctly but with stealth properties
        window.hidesOnDeactivate = false
        window.canHide = true
    }
    
    // MARK: - Collection Behavior Configuration
    
    static func configureStealthCollectionBehavior(_ window: NSWindow, isPinnedToCurrentDesktop: Bool = true) {
        // Configure window collection behavior for stealth operation
        var behavior: NSWindow.CollectionBehavior = []
        
        // Make window invisible to screen capture but preserve Mission Control behavior
        // Check if pinned to current desktop setting is disabled
        if !isPinnedToCurrentDesktop {
            behavior.insert(.canJoinAllSpaces)
        }
        
        // Exclude from screenshots and screen recordings
        if #available(macOS 11.0, *) {
            behavior.insert(.auxiliary)
        }
        
        // Don't use .stationary or .ignoresCycle as they cause Mission Control issues
        // Instead rely on sharing type and other properties for screen capture protection
        
        window.collectionBehavior = behavior
        
        // Additional stealth configurations
        window.sharingType = .none
        window.displaysWhenScreenProfileChanges = false
    }
    
    // MARK: - Advanced Stealth Configuration
    
    static func configureAdvancedStealth(_ window: NSWindow) {
        // Apply advanced stealth features
        
        // Disable window animations that might be captured
        window.animationBehavior = .none
        
        // Configure window shadow (shadows can be captured)
        window.hasShadow = false
        
        // Additional low-level window configuration could go here
        // For now, we rely on collection behavior for window server exclusion
        
        // Set up window delegate for additional stealth handling
        if window.delegate == nil {
            window.delegate = StealthWindowDelegate.shared
        }
    }
    
    // MARK: - WebView Configuration
    
    static func configureWebViewForStealth(_ webView: WKWebView) {
        // Configure web view for maximum privacy
        let configuration = webView.configuration
        
        // Use stealth data store
        configuration.websiteDataStore = createStealthDataStore()
        
        // Note: Camera and microphone capture states are read-only
        // Privacy is handled through the non-persistent data store
        
        // Additional privacy configurations
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.preferences.isElementFullscreenEnabled = false
        
        // Disable media capture
        configuration.mediaTypesRequiringUserActionForPlayback = [.all]
    }
    
    static func createStealthDataStore() -> WKWebsiteDataStore {
        // Create a non-persistent website data store for maximum privacy
        let dataStore = WKWebsiteDataStore.nonPersistent()
        
        // Configure for enhanced privacy
        return dataStore
    }
    
    // MARK: - Accessory Window Configuration
    
    static func applyAccessoryWindow(_ window: NSWindow) {
        var behavior = window.collectionBehavior
        behavior.insert(.auxiliary)
        window.collectionBehavior = behavior
    }
    
    static func removeAccessoryWindow(_ window: NSWindow) {
        var behavior = window.collectionBehavior
        behavior.remove(.auxiliary)
        window.collectionBehavior = behavior
    }
    
}

// MARK: - Stealth Window Delegate

class StealthWindowDelegate: NSObject, NSWindowDelegate {
    static let shared = StealthWindowDelegate()
    
    private override init() {
        super.init()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Ensure stealth properties are maintained when window becomes key
        if let window = notification.object as? NSWindow {
            let isPinnedToCurrentDesktop = StealthManager.shared.isPinnedToCurrentDesktop
            WindowCloaking.configureStealthCollectionBehavior(window, isPinnedToCurrentDesktop: isPinnedToCurrentDesktop)
        }
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // Maintain stealth properties when window loses key status
        if let window = notification.object as? NSWindow {
            let isPinnedToCurrentDesktop = StealthManager.shared.isPinnedToCurrentDesktop
            WindowCloaking.configureStealthCollectionBehavior(window, isPinnedToCurrentDesktop: isPinnedToCurrentDesktop)
        }
    }
    
    func windowWillMiniaturize(_ notification: Notification) {
        // Handle window miniaturization in stealth mode
        if let window = notification.object as? NSWindow {
            // Ensure stealth properties are maintained during miniaturization
            window.collectionBehavior.insert(.stationary)
        }
    }
}

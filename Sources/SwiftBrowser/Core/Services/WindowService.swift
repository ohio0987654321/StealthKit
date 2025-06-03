// Fixed version - preserves toolbar functionality
import SwiftUI
import AppKit
import WebKit

/// Unified window management service that handles all window-related functionality
/// Replaces the fragmented StealthManager + WindowManager + WindowCloaking architecture
@Observable
class WindowService {
    static let shared = WindowService()
    
    // MARK: - Window State
    private var managedWindows: Set<NSWindow> = []
    private var statusItem: NSStatusItem?
    
    // MARK: - Window Properties
    var isTransparencyEnabled: Bool = false {
        didSet { applyTransparencyToAllWindows() }
    }
    
    var transparencyLevel: Double = 0.9 {
        didSet { if isTransparencyEnabled { applyTransparencyToAllWindows() } }
    }
    
    var isAlwaysOnTop: Bool = false {
        didSet { applyAlwaysOnTopToAllWindows() }
    }
    
    // MARK: - Separated Feature Controls
    
    // Screen Recording Bypass - applies dynamically (no reinitilization needed)
    var isScreenRecordingBypassEnabled: Bool = false {
        didSet { 
            applyScreenRecordingBypassToAllWindows()
        }
    }
    
    // Feature A: Traffic Light Prevention - requires reinitilization
    var isTrafficLightPreventionEnabled: Bool = false {
        didSet { 
            updateTrafficLightPrevention()
        }
    }
    
    var isPinnedToCurrentDesktop: Bool = true {
        didSet { applyCloakingToAllWindows() }
    }
    
    var isAccessoryApp: Bool = false {
        didSet { applyAccessoryAppPolicy() }
    }
    
    private init() {}
    
    // MARK: - Window Registration
    func registerWindow(_ window: NSWindow) {
        managedWindows.insert(window)
        configureWindow(window)
        
        // Set up window delegate
        if window.delegate == nil {
            window.delegate = WindowServiceDelegate.shared
        }
    }
    
    func registerPanel(_ panel: NSPanel) {
        managedWindows.insert(panel)
        configurePanel(panel)
        
        // Set up panel delegate
        if panel.delegate == nil {
            panel.delegate = WindowServiceDelegate.shared
        }
    }
    
    func unregisterWindow(_ window: NSWindow) {
        managedWindows.remove(window)
    }
    
    // MARK: - Window Configuration
    private func configureWindow(_ window: NSWindow) {
        // Apply unified window styling
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .hidden
        window.toolbarStyle = .unified
        window.hidesOnDeactivate = false
        window.canHide = true
        window.animationBehavior = .documentWindow
        window.isOpaque = false
        
        // Apply current settings
        if isTransparencyEnabled {
            setWindowTransparency(window, level: transparencyLevel)
        }
        
        if isAlwaysOnTop {
            setWindowAlwaysOnTop(window)
        }
        
        if isScreenRecordingBypassEnabled {
            applyCloaking(to: window)
        }
    }
    
    private func configurePanel(_ panel: NSPanel) {
        // Configure panel while preserving non-activating behavior
        panel.titlebarAppearsTransparent = false
        panel.titleVisibility = .visible  // Keep title visible for toolbar
        panel.toolbarStyle = .unified     // This is crucial for toolbar
        panel.hidesOnDeactivate = false
        panel.canHide = true
        panel.animationBehavior = .documentWindow
        panel.isOpaque = false
        
        // For non-activating panels, we need special toolbar handling
        panel.becomesKeyOnlyIfNeeded = true  // Preserve non-activating behavior
        panel.worksWhenModal = false
        
        // CRITICAL: Force toolbar to be visible on non-activating panels
        // This is a workaround for NSPanel toolbar visibility issues
        DispatchQueue.main.async {
            if let toolbar = panel.toolbar {
                toolbar.isVisible = true
                // Force toolbar to display properly
                panel.toggleToolbarShown(nil)
                panel.toggleToolbarShown(nil)
            }
        }
        
        // Apply current settings
        if isTransparencyEnabled {
            setWindowTransparency(panel, level: transparencyLevel)
        }
        
        if isAlwaysOnTop {
            setPanelAlwaysOnTop(panel)
        }
        
        if isScreenRecordingBypassEnabled {
            applyCloaking(to: panel)
        }
    }
    
    // MARK: - Transparency Management
    private func setWindowTransparency(_ window: NSWindow, level: Double) {
        let clampedLevel = max(0.3, min(1.0, level))
        window.alphaValue = clampedLevel
        
        // Ensure content remains readable
        if let contentView = window.contentView {
            contentView.alphaValue = 1.0
        }
    }
    
    private func applyTransparencyToAllWindows() {
        for window in managedWindows {
            setWindowTransparency(window, level: isTransparencyEnabled ? transparencyLevel : 1.0)
        }
    }
    
    // MARK: - Always On Top Management
    private func setWindowAlwaysOnTop(_ window: NSWindow) {
        if !window.isKind(of: NSPanel.self) {
            window.level = isAlwaysOnTop ? .floating : .normal
            
            if !isAlwaysOnTop {
                var behavior = window.collectionBehavior
                behavior.remove(.ignoresCycle)
                behavior.insert(.participatesInCycle)
                window.collectionBehavior = behavior
            }
        }
    }
    
    private func setPanelAlwaysOnTop(_ panel: NSPanel) {
        // For panels, use different level management while preserving toolbar
        panel.level = isAlwaysOnTop ? .floating : .normal
        
        // Preserve non-activating behavior while ensuring toolbar works
        if !isAlwaysOnTop {
            var behavior = panel.collectionBehavior
            behavior.remove(.ignoresCycle)
            behavior.insert(.participatesInCycle)
            panel.collectionBehavior = behavior
        }
    }
    
    private func applyAlwaysOnTopToAllWindows() {
        for window in managedWindows {
            if let panel = window as? NSPanel {
                setPanelAlwaysOnTop(panel)
            } else {
                setWindowAlwaysOnTop(window)
            }
        }
    }
    
    // MARK: - Cloaking Management
    private func applyCloaking(to window: NSWindow) {
        var behavior: NSWindow.CollectionBehavior = []
        
        if !isPinnedToCurrentDesktop {
            behavior.insert(.canJoinAllSpaces)
        }
        
        if #available(macOS 11.0, *) {
            behavior.insert(.auxiliary)
        }
        
        // Preserve managed behavior for proper window management
        behavior.insert(.managed)
        
        window.collectionBehavior = behavior
        window.sharingType = .none
        window.displaysWhenScreenProfileChanges = false
        window.hasShadow = false
        
        // Special handling for panels to ensure toolbar remains visible
        if let panel = window as? NSPanel, let toolbar = panel.toolbar {
            DispatchQueue.main.async {
                toolbar.isVisible = true
            }
        }
    }
    
    private func removeCloaking(from window: NSWindow) {
        window.collectionBehavior = [.managed, .participatesInCycle]
        window.sharingType = .readWrite
        window.displaysWhenScreenProfileChanges = true
        window.hasShadow = true
    }
    
    // MARK: - Screen Recording Bypass Management
    private func applyScreenRecordingBypassToAllWindows() {
        for window in managedWindows {
            if isScreenRecordingBypassEnabled {
                applyCloaking(to: window)
            } else {
                removeCloaking(from: window)
            }
        }
        
        // Reapply always on top if needed (fixes interaction bugs)
        if isAlwaysOnTop {
            applyAlwaysOnTopToAllWindows()
        }
    }
    
    // Legacy method for desktop pinning compatibility
    private func applyCloakingToAllWindows() {
        // This method now just delegates to the screen recording bypass
        applyScreenRecordingBypassToAllWindows()
    }
    
    // MARK: - Accessory App Management
    private func applyAccessoryAppPolicy() {
        DispatchQueue.main.async {
            if self.isAccessoryApp {
                NSApp.setActivationPolicy(.accessory)
                self.setupMenuBarIcon()
            } else {
                self.removeMenuBarIcon()
                NSApp.setActivationPolicy(.regular)
            }
        }
    }
    
    private func setupMenuBarIcon() {
        guard statusItem == nil else { return }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Browser")
        
        let menu = NSMenu()
        
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
    
    // MARK: - Traffic Light Prevention (Feature A)
    private func updateTrafficLightPrevention() {
        print("Traffic light prevention update triggered. Enabled: \(isTrafficLightPreventionEnabled)")
        
        // Update all managed panels with new style mask
        let panelsToUpdate = Array(managedWindows.compactMap { $0 as? NSPanel })
        
        for panel in panelsToUpdate {
            reinitilizePanelWithNewStyleMask(panel)
        }
    }
    
    private func reinitilizePanelWithNewStyleMask(_ panel: NSPanel) {
        // Preserve panel state
        let frame = panel.frame
        let contentView = panel.contentView
        let toolbar = panel.toolbar
        let isKeyWindow = panel.isKeyWindow
        let isMainWindow = panel.isMainWindow
        let alphaValue = panel.alphaValue
        let level = panel.level
        
        // Determine new style mask based on traffic light prevention state
        let newStyleMask: NSPanel.StyleMask = isTrafficLightPreventionEnabled ? 
            [.nonactivatingPanel, .titled, .closable, .resizable, .fullSizeContentView] :
            [.titled, .closable, .resizable, .fullSizeContentView]
        
        // Create new panel with updated style mask
        let newPanel = NSPanel(
            contentRect: frame,
            styleMask: newStyleMask,
            backing: .buffered,
            defer: false
        )
        
        // Transfer all properties safely
        if let existingToolbar = toolbar {
            newPanel.toolbar = existingToolbar
        }
        
        if let content = contentView {
            newPanel.contentView = content
        }
        
        // Restore panel properties
        newPanel.setFrame(frame, display: false)
        newPanel.alphaValue = alphaValue
        newPanel.level = level
        
        // Apply current configuration
        configurePanel(newPanel)
        
        // Replace the old panel
        if isKeyWindow || isMainWindow {
            newPanel.makeKeyAndOrderFront(nil)
        } else {
            newPanel.orderFront(nil)
        }
        
        // Clean up - unregister old panel and register new one
        unregisterWindow(panel)
        registerPanel(newPanel)
        
        panel.orderOut(nil)
        
        // Safe cleanup
        DispatchQueue.main.async {
            panel.close()
            
            // Ensure toolbar visibility
            if let toolbar = newPanel.toolbar {
                toolbar.isVisible = true
            }
        }
    }
    
    // MARK: - WebView Configuration
    func configureWebViewForStealth(_ webView: WKWebView) {
        let configuration = webView.configuration
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.preferences.isElementFullscreenEnabled = false
        configuration.mediaTypesRequiringUserActionForPlayback = [.all]
    }
    
    // MARK: - Window Creation
    func createWindow(
        contentRect: NSRect = NSRect(x: 100, y: 100, width: 1200, height: 800),
        styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
    ) -> NSWindow {
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        registerWindow(window)
        return window
    }
    
    func createPanel(
        contentRect: NSRect = NSRect(x: 100, y: 100, width: 1200, height: 800),
        styleMask: NSPanel.StyleMask = [.nonactivatingPanel, .titled, .closable, .resizable, .fullSizeContentView]
    ) -> NSPanel {
        let panel = NSPanel(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        registerPanel(panel)
        return panel
    }
}

// MARK: - Window Delegate
class WindowServiceDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowServiceDelegate()
    
    private override init() {
        super.init()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        WindowService.shared.registerWindow(window)
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        WindowService.shared.unregisterWindow(window)
    }
    
    func windowDidMiniaturize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        if WindowService.shared.isScreenRecordingBypassEnabled {
            window.collectionBehavior.insert(.stationary)
        }
    }
    
    func windowDidDeminiaturize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        if WindowService.shared.isScreenRecordingBypassEnabled {
            window.collectionBehavior.remove(.stationary)
        }
    }
}

import SwiftUI
import AppKit
import WebKit

protocol WindowServicePanelDelegate: AnyObject {
    func windowService(_ service: WindowService, didRecreatePanel oldPanel: NSPanel, newPanel: NSPanel)
    func windowService(_ service: WindowService, willChangeActivationPolicy isAccessory: Bool)
    func windowService(_ service: WindowService, didChangeActivationPolicy isAccessory: Bool)
}

@Observable
class WindowService {
    static let shared = WindowService()
    
    // MARK: - Window State
    private var managedWindows: Set<NSWindow> = []
    private var statusItem: NSStatusItem?
    weak var panelDelegate: WindowServicePanelDelegate?
    
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
    
    var isScreenRecordingBypassEnabled: Bool = false {
        didSet { 
            applyScreenRecordingBypassToAllWindows()
        }
    }
    
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
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .hidden
        window.toolbarStyle = .unified
        window.hidesOnDeactivate = false
        window.canHide = true
        window.animationBehavior = .documentWindow
        window.isOpaque = false
        
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
        panel.titlebarAppearsTransparent = false
        panel.titleVisibility = .visible
        panel.toolbarStyle = .unified
        panel.hidesOnDeactivate = false
        panel.canHide = true
        panel.animationBehavior = .documentWindow
        panel.isOpaque = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.worksWhenModal = false
        
        if isTransparencyEnabled {
            setWindowTransparency(panel, level: transparencyLevel)
        }
        
        if isAlwaysOnTop {
            setPanelAlwaysOnTop(panel)
        }
        
        if isScreenRecordingBypassEnabled {
            applyCloaking(to: panel)
        }
        
        // Only apply toolbar fixes for initial panel setup, not during recreation
        // Recreation process handles toolbar separately to avoid conflicts
        ensureToolbarVisibility(panel)
    }
    
    private func ensureToolbarVisibility(_ panel: NSPanel) {
        // Simplified toolbar management without double toggles
        DispatchQueue.main.async {
            if let toolbar = panel.toolbar {
                // Direct approach - just ensure it's visible
                if !toolbar.isVisible {
                    toolbar.isVisible = true
                }
            }
        }
    }
    
    // MARK: - Transparency Management
    private func setWindowTransparency(_ window: NSWindow, level: Double) {
        let clampedLevel = max(UIConstants.Transparency.minLevel, min(UIConstants.Transparency.maxLevel, level))
        window.alphaValue = clampedLevel
        
        // Ensure content remains readable
        if let contentView = window.contentView {
            contentView.alphaValue = UIConstants.Transparency.maxLevel
        }
    }
    
    private func applyTransparencyToAllWindows() {
        for window in managedWindows {
            setWindowTransparency(window, level: isTransparencyEnabled ? transparencyLevel : UIConstants.Transparency.maxLevel)
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
        
        // For panels, use centralized toolbar management to avoid conflicts
        if let panel = window as? NSPanel {
            // Small delay to let collection behavior settle before toolbar fixes
            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.Window.toolbarConfigurationDelay) {
                self.ensureToolbarVisibility(panel)
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
            self.panelDelegate?.windowService(self, willChangeActivationPolicy: self.isAccessoryApp)
            
            if self.isAccessoryApp {
                self.setupMenuBarIcon()
                NSApp.setActivationPolicy(.accessory)
                self.panelDelegate?.windowService(self, didChangeActivationPolicy: self.isAccessoryApp)
            } else {
                self.removeMenuBarIcon()
                DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.Window.panelShowDelay) {
                    NSApp.setActivationPolicy(.regular)
                    self.panelDelegate?.windowService(self, didChangeActivationPolicy: self.isAccessoryApp)
                }
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
    
    private func updateTrafficLightPrevention() {
        let panelsToUpdate = Array(managedWindows.compactMap { $0 as? NSPanel })
        
        for panel in panelsToUpdate {
            reinitilizePanelWithNewStyleMask(panel)
        }
    }
    
    private func reinitilizePanelWithNewStyleMask(_ panel: NSPanel) {
        // Preserve panel state
        let frame = panel.frame
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
        
        // DON'T transfer toolbar - let SwiftUI reconfigure it properly on the new panel
        // This prevents UI positioning issues with toolbar items
        
        // DON'T transfer content view here - PanelAppDelegate will handle it
        // This prevents double assignment that confuses NSHostingController
        
        // Restore panel properties
        newPanel.setFrame(frame, display: false)
        newPanel.alphaValue = alphaValue
        newPanel.level = level
        
        // Apply basic panel configuration WITHOUT toolbar manipulation
        newPanel.titlebarAppearsTransparent = false
        newPanel.titleVisibility = .visible
        newPanel.toolbarStyle = .unified
        newPanel.hidesOnDeactivate = false
        newPanel.canHide = true
        newPanel.animationBehavior = .documentWindow
        newPanel.isOpaque = false
        newPanel.becomesKeyOnlyIfNeeded = true
        newPanel.worksWhenModal = false
        
        // Apply window effects
        if isTransparencyEnabled {
            setWindowTransparency(newPanel, level: transparencyLevel)
        }
        
        if isAlwaysOnTop {
            setPanelAlwaysOnTop(newPanel)
        }
        
        // Replace the old panel
        if isKeyWindow || isMainWindow {
            newPanel.makeKeyAndOrderFront(nil)
        } else {
            newPanel.orderFront(nil)
        }
        
        // Register new panel BEFORE notifying delegate (delegate needs it registered)
        unregisterWindow(panel)
        managedWindows.insert(newPanel)
        
        // Set up panel delegate
        if newPanel.delegate == nil {
            newPanel.delegate = WindowServiceDelegate.shared
        }
        
        // Notify delegate about panel recreation - delegate handles content transfer
        panelDelegate?.windowService(self, didRecreatePanel: panel, newPanel: newPanel)
        
        // SINGLE cleanup point - close old panel AFTER delegate finishes content transfer
        DispatchQueue.main.async {
            panel.orderOut(nil)
            
            // Apply final configurations AFTER cleanup is complete
            DispatchQueue.main.async {
                // Apply screen recording bypass if needed
                if self.isScreenRecordingBypassEnabled {
                    self.applyCloaking(to: newPanel)
                } else {
                    // Only fix toolbar if no screen recording bypass (which handles it separately)
                    self.ensureToolbarVisibility(newPanel)
                }
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

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
    
    var isCloakingEnabled: Bool = true {
        didSet { applyCloakingToAllWindows() }
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
        
        if isCloakingEnabled {
            applyCloaking(to: window)
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
    
    private func applyAlwaysOnTopToAllWindows() {
        for window in managedWindows {
            setWindowAlwaysOnTop(window)
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
        
        window.collectionBehavior = behavior
        window.sharingType = .none
        window.displaysWhenScreenProfileChanges = false
        window.hasShadow = false
    }
    
    private func removeCloaking(from window: NSWindow) {
        window.collectionBehavior = [.managed, .participatesInCycle]
        window.sharingType = .readWrite
        window.displaysWhenScreenProfileChanges = true
        window.hasShadow = true
    }
    
    private func applyCloakingToAllWindows() {
        for window in managedWindows {
            if isCloakingEnabled {
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
        
        if WindowService.shared.isCloakingEnabled {
            window.collectionBehavior.insert(.stationary)
        }
    }
    
    func windowDidDeminiaturize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        if WindowService.shared.isCloakingEnabled {
            window.collectionBehavior.remove(.stationary)
        }
    }
}

// MARK: - SwiftUI Integration
struct WindowServiceModifier: ViewModifier {
    @State private var windowService = WindowService.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if let window = NSApp.keyWindow {
                    windowService.registerWindow(window)
                }
            }
    }
}

extension View {
    func managedWindow() -> some View {
        self.modifier(WindowServiceModifier())
    }
}

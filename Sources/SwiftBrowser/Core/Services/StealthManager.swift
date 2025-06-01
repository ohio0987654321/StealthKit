//
//  StealthManager.swift
//  SwiftBrowser
//
//  Central coordinator for all stealth functionality.
//  Manages window cloaking, background operation, and privacy features.
//

import Foundation
import AppKit
import WebKit

@Observable
class StealthManager {
    static let shared = StealthManager()
    
    var isStealthModeActive: Bool = true
    var isBackgroundOperationEnabled: Bool = true
    var isWindowCloakingEnabled: Bool = true
    var isDockHidden: Bool = true
    var isStatusBarVisible: Bool = true
    var isAlwaysOnTop: Bool = false
    
    private var statusBarController: StatusBarController?
    private var originalActivationPolicy: NSApplication.ActivationPolicy = .regular
    
    private init() {
        initializeStealthFeatures()
    }
    
    // MARK: - Initialization
    
    func initializeStealthFeatures() {
        // Store original activation policy
        originalActivationPolicy = NSApp.activationPolicy()
        
        // Initialize status bar controller
        statusBarController = StatusBarController()
        
        // Apply default stealth settings safely
        if isDockHidden {
            setDockHidden(true)
        }
        
        if isStatusBarVisible {
            setStatusBarVisible(true)
        }
        
        if isWindowCloakingEnabled {
            setWindowCloakingEnabled(true)
        }
        
        print("StealthManager initialized successfully")
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
    
    // MARK: - Background Operation
    
    func enableBackgroundOperation() {
        guard !isBackgroundOperationEnabled else { return }
        
        isBackgroundOperationEnabled = true
        
        // Hide from dock
        setDockHidden(true)
        
        // Show status bar
        setStatusBarVisible(true)
    }
    
    func disableBackgroundOperation() {
        guard isBackgroundOperationEnabled else { return }
        
        isBackgroundOperationEnabled = false
        
        // Show in dock
        setDockHidden(false)
        
        // Hide status bar
        setStatusBarVisible(false)
    }
    
    // MARK: - Dock Management
    
    func setDockHidden(_ hidden: Bool) {
        isDockHidden = hidden
        
        if hidden {
            // Use .accessory for background operation and menu bar app functionality
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(originalActivationPolicy)
        }
    }
    
    // MARK: - Status Bar Management
    
    func setStatusBarVisible(_ visible: Bool) {
        isStatusBarVisible = visible
        
        if visible {
            statusBarController?.setupStatusBar()
        } else {
            statusBarController?.removeStatusBar()
        }
    }
    
    // MARK: - Stealth Mode Control
    
    func setStealthModeEnabled(_ enabled: Bool) {
        isStealthModeActive = enabled
        
        if enabled {
            // Enable all stealth features
            setWindowCloakingEnabled(true)
            enableBackgroundOperation()
        } else {
            // Disable stealth features
            setWindowCloakingEnabled(false)
            disableBackgroundOperation()
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

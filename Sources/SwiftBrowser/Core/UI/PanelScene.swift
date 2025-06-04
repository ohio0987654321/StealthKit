import SwiftUI
import AppKit

class PanelAppDelegate: NSObject, NSApplicationDelegate, WindowServicePanelDelegate {
    private var mainPanel: NSPanel?
    private var hostingController: NSHostingController<BrowserView>?
    private var isPanelRecreationInProgress = false
    private var isActivationPolicyChangeInProgress = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize app manager and coordinator
        _ = AppManager.shared
        
        // Set up menu bar
        setupMenuBar()
        WindowService.shared.panelDelegate = self
        createMainPanel()
        
        // Observe activation policy changes to handle menu conflicts
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActivationPolicyChange),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Ensure panel is visible after startup
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.Window.panelShowDelay) {
            if let panel = self.mainPanel, !panel.isVisible {
                panel.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    @objc private func handleActivationPolicyChange() {
        DispatchQueue.main.async {
            if NSApp.activationPolicy() == .regular && NSApp.mainMenu == nil {
                self.setupMenuBar()
            }
        }
    }
    
    private func setupMenuBar() {
        // Create main menu
        let mainMenu = NSMenu()
        
        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Quit Swift Browser", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // File menu
        let fileMenuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(NSMenuItem(title: "New Tab", action: #selector(newTab), keyEquivalent: "n"))
        fileMenu.addItem(NSMenuItem(title: "Close Tab", action: #selector(closeTab), keyEquivalent: "w"))
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)
        
        // View menu
        let viewMenuItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(NSMenuItem(title: "Reload", action: #selector(reload), keyEquivalent: "r"))
        let addressBarItem = NSMenuItem(title: "Select Address Bar", action: #selector(focusAddressBar), keyEquivalent: "l")
        viewMenu.addItem(addressBarItem)
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)
        
        NSApp.mainMenu = mainMenu
    }
    
    @objc private func newTab() {
        NotificationCenter.default.post(name: .newTab, object: nil)
    }
    
    @objc private func closeTab() {
        NotificationCenter.default.post(name: .closeTab, object: nil)
    }
    
    @objc private func reload() {
        NotificationCenter.default.post(name: .reload, object: nil)
    }
    
    @objc private func focusAddressBar() {
        NotificationCenter.default.post(name: .focusAddressBar, object: nil)
    }
    
    private func createMainPanel() {
        // Determine style mask based on WindowService settings
        let windowService = WindowService.shared
        let styleMask: NSPanel.StyleMask = windowService.isTrafficLightPreventionEnabled ? 
            [.nonactivatingPanel, .titled, .closable, .resizable, .fullSizeContentView] :
            [.titled, .closable, .resizable, .fullSizeContentView]
        
        // Create the panel with proper dimensions
        let contentRect = NSRect(
            x: UIConstants.Window.defaultX, 
            y: UIConstants.Window.defaultY, 
            width: UIConstants.Window.defaultWidth, 
            height: UIConstants.Window.defaultHeight
        )
        
        mainPanel = NSPanel(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        guard let panel = mainPanel else {
            return
        }
        
        // Register immediately to prevent app termination
        windowService.registerPanel(panel)
        
        // Configure panel properties
        panel.title = "Swift Browser"
        panel.center()
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = false
        panel.titleVisibility = .visible
        panel.toolbarStyle = .unified
        panel.hidesOnDeactivate = false
        panel.canHide = true
        panel.animationBehavior = .documentWindow
        panel.isOpaque = false
        
        // Ensure panel doesn't close app when minimized
        panel.hidesOnDeactivate = false
        panel.canHide = false  // Prevent hiding that might trigger termination
        
        // Create hosting controller with the browser view
        let browserView = BrowserView()
        hostingController = NSHostingController(rootView: browserView)
        
        if let hostingController = hostingController {
            panel.contentView = hostingController.view
            hostingController.view.frame = panel.contentView?.bounds ?? .zero
            hostingController.view.autoresizingMask = [.width, .height]
        }
        
        // Show the panel and ensure it becomes key
        panel.makeKeyAndOrderFront(nil)
        
        // Ensure panel becomes key window to prevent app termination
        DispatchQueue.main.async {
            panel.makeKey()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Never auto-terminate during panel operations
        if isPanelRecreationInProgress || isActivationPolicyChangeInProgress {
            return false
        }
        
        // If main panel still exists and is visible, don't terminate
        if let panel = mainPanel, panel.isVisible {
            return false
        }
        
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up notifications
        NotificationCenter.default.removeObserver(self)
        
        if let panel = mainPanel {
            WindowService.shared.unregisterWindow(panel)
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            mainPanel?.makeKeyAndOrderFront(nil)
        }
        return true
    }
    
    // MARK: - WindowServicePanelDelegate
    func windowService(_ service: WindowService, didRecreatePanel oldPanel: NSPanel, newPanel: NSPanel) {
        if mainPanel === oldPanel {
            isPanelRecreationInProgress = true
            
            // Preserve existing hosting controller and its state to avoid losing tabs/navigation
            if let existingHostingController = hostingController {
                // Remove from old panel first
                existingHostingController.view.removeFromSuperview()
                
                // Transfer to new panel
                newPanel.contentView = existingHostingController.view
                existingHostingController.view.frame = newPanel.contentView?.bounds ?? .zero
                existingHostingController.view.autoresizingMask = [.width, .height]
                
                // Update reference
                mainPanel = newPanel
                
                // Force SwiftUI to reconfigure toolbar on new panel
                existingHostingController.view.needsLayout = true
                existingHostingController.view.layoutSubtreeIfNeeded()
            } else {
                // Fallback: create new hosting controller if none exists
                mainPanel = newPanel
                let browserView = BrowserView()
                hostingController = NSHostingController(rootView: browserView)
                
                if let hostingController = hostingController {
                    newPanel.contentView = hostingController.view
                    hostingController.view.frame = newPanel.contentView?.bounds ?? .zero
                    hostingController.view.autoresizingMask = [.width, .height]
                }
            }
            
            // DON'T close old panel here - WindowService handles cleanup
            // This prevents double cleanup and crashes
            isPanelRecreationInProgress = false
        }
    }
    
    func windowService(_ service: WindowService, willChangeActivationPolicy isAccessory: Bool) {
        isActivationPolicyChangeInProgress = true
    }
    
    func windowService(_ service: WindowService, didChangeActivationPolicy isAccessory: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.Window.activationPolicyChangeDelay) {
            self.isActivationPolicyChangeInProgress = false
        }
    }
}

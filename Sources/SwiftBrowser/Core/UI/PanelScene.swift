import SwiftUI
import AppKit

class PanelAppDelegate: NSObject, NSApplicationDelegate, WindowServicePanelDelegate {
    private var mainPanel: NSPanel?
    private var hostingController: NSHostingController<BrowserView>?
    private var isPanelRecreationInProgress = false
    private var isActivationPolicyChangeInProgress = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("DEBUG: applicationDidFinishLaunching started")
        
        // Set up menu bar
        print("DEBUG: Setting up menu bar...")
        setupMenuBar()
        print("DEBUG: Menu bar setup complete")
        
        // Set up WindowService delegate
        print("DEBUG: Setting up WindowService delegate...")
        WindowService.shared.panelDelegate = self
        print("DEBUG: WindowService delegate set")
        
        // Create the main panel immediately
        print("DEBUG: About to create main panel...")
        createMainPanel()
        print("DEBUG: Main panel creation initiated")
        
        // Observe activation policy changes to handle menu conflicts
        print("DEBUG: Setting up notification observers...")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActivationPolicyChange),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        print("DEBUG: Notification observers set up")
        
        print("DEBUG: applicationDidFinishLaunching completed")
        
        // Additional safety check to ensure panel exists
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let panel = self.mainPanel {
                print("DEBUG: Panel verification - panel exists and visible: \(panel.isVisible)")
                if !panel.isVisible {
                    print("DEBUG: Panel not visible, forcing it to show...")
                    panel.makeKeyAndOrderFront(nil)
                }
            } else {
                print("ERROR: No main panel exists after startup!")
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
        print("DEBUG: Starting panel creation...")
        
        // Determine style mask based on WindowService settings
        let windowService = WindowService.shared
        let styleMask: NSPanel.StyleMask = windowService.isTrafficLightPreventionEnabled ? 
            [.nonactivatingPanel, .titled, .closable, .resizable, .fullSizeContentView] :
            [.titled, .closable, .resizable, .fullSizeContentView]
        
        // Create the panel with proper dimensions
        let contentRect = NSRect(
            x: 100, 
            y: 100, 
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
            print("ERROR: Failed to create main panel")
            return
        }
        
        print("DEBUG: Panel created successfully")
        
        // EARLY REGISTRATION: Register immediately to prevent app termination
        windowService.registerPanel(panel)
        print("DEBUG: Panel registered with WindowService")
        
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
        
        print("DEBUG: Panel content configured")
        
        // Show the panel and ensure it becomes key
        panel.makeKeyAndOrderFront(nil)
        
        // Force the panel to become key window to prevent app termination
        DispatchQueue.main.async {
            panel.makeKey()
            print("DEBUG: Panel made key window")
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("DEBUG: applicationShouldTerminateAfterLastWindowClosed called")
        print("DEBUG: isPanelRecreationInProgress: \(isPanelRecreationInProgress)")
        print("DEBUG: isActivationPolicyChangeInProgress: \(isActivationPolicyChangeInProgress)")
        print("DEBUG: mainPanel exists: \(mainPanel != nil)")
        print("DEBUG: mainPanel visible: \(mainPanel?.isVisible ?? false)")
        
        // Never auto-terminate during panel operations
        if isPanelRecreationInProgress || isActivationPolicyChangeInProgress {
            print("DEBUG: Preventing termination - operations in progress")
            return false
        }
        
        // If main panel still exists and is visible, don't terminate
        if let panel = mainPanel, panel.isVisible {
            print("DEBUG: Preventing termination - main panel is visible")
            return false
        }
        
        print("DEBUG: Allowing termination")
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isActivationPolicyChangeInProgress = false
        }
    }
}

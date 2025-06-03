import SwiftUI
import AppKit

/// Main app delegate for pure AppKit architecture
/// Creates NSPanel directly at launch without SwiftUI window conflicts
class PanelAppDelegate: NSObject, NSApplicationDelegate, WindowServicePanelDelegate {
    private var mainPanel: NSPanel?
    private var hostingController: NSHostingController<BrowserView>?
    private var isPanelRecreationInProgress = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up menu bar
        setupMenuBar()
        
        // Set up WindowService delegate
        WindowService.shared.panelDelegate = self
        
        // Create the main panel immediately
        createMainPanel()
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
        
        guard let panel = mainPanel else { return }
        
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
        
        // Create hosting controller with the browser view
        let browserView = BrowserView()
        hostingController = NSHostingController(rootView: browserView)
        
        if let hostingController = hostingController {
            panel.contentView = hostingController.view
            hostingController.view.frame = panel.contentView?.bounds ?? .zero
            hostingController.view.autoresizingMask = [.width, .height]
        }
        
        // Register with WindowService AFTER content is set up
        windowService.registerPanel(panel)
        
        // Show the panel
        panel.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't terminate during panel recreation
        if isPanelRecreationInProgress {
            print("PanelAppDelegate: Preventing termination during panel recreation")
            return false
        }
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
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
        // Update our reference to the main panel when it's recreated
        if mainPanel === oldPanel {
            print("PanelAppDelegate: Panel recreation detected, updating references...")
            
            // Set flag to prevent app termination during recreation
            isPanelRecreationInProgress = true
            
            // Update panel reference FIRST
            mainPanel = newPanel
            
            // Set up content view properly - this is the ONLY place content is assigned
            if let hostingController = hostingController {
                // Clean assignment - no double setting
                newPanel.contentView = hostingController.view
                hostingController.view.frame = newPanel.contentView?.bounds ?? .zero
                hostingController.view.autoresizingMask = [.width, .height]
                
                print("PanelAppDelegate: Hosting controller reconnected successfully")
            }
            
            // Ensure new panel is fully established before closing old one
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Double-check that we still have a valid main panel
                if self.mainPanel === newPanel && newPanel.isVisible {
                    oldPanel.close()
                    print("PanelAppDelegate: Old panel closed safely after delay")
                } else {
                    print("PanelAppDelegate: Skipping old panel closure - new panel not established")
                }
                
                // Re-enable app termination after recreation is complete
                self.isPanelRecreationInProgress = false
                print("PanelAppDelegate: Panel recreation complete, app termination re-enabled")
            }
        }
    }
}

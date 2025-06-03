import SwiftUI
import AppKit

/// App delegate to handle custom panel creation directly from app launch
class PanelAppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var mainPanel: NSPanel?
    private var hostingController: NSHostingController<BrowserView>?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide any automatically created windows
        for window in NSApp.windows {
            if window.identifier?.rawValue.contains("_hidden_") == true {
                window.orderOut(nil)
            }
        }
        
        // Create the main panel immediately
        createMainPanel()
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
}

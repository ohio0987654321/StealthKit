import SwiftUI
import AppKit

class DownloadPanelManager: NSObject, ObservableObject {
    static let shared = DownloadPanelManager()
    
    private var downloadPanel: NSPanel?
    private var hostingController: NSHostingController<DownloadPopover>?
    @Published var isVisible = false
    
    private override init() {
        super.init()
    }
    
    func showDownloadPanel(relativeTo button: NSView, preferredEdge: NSRectEdge = .minY) {
        guard !isVisible else { return }
        
        createDownloadPanel()
        guard let panel = downloadPanel, let buttonWindow = button.window else { return }
        
        // Calculate position relative to button
        let buttonFrame = button.convert(button.bounds, to: nil)
        let buttonScreenFrame = buttonWindow.convertToScreen(buttonFrame)
        
        let panelSize = NSSize(width: UIConstants.DownloadPopover.width, height: 200)
        let panelOrigin = calculatePanelOrigin(
            buttonFrame: buttonScreenFrame,
            panelSize: panelSize,
            preferredEdge: preferredEdge
        )
        
        panel.setFrame(NSRect(origin: panelOrigin, size: panelSize), display: false)
        
        // Register with WindowService
        WindowService.shared.registerPanel(panel)
        
        // Show panel with animation
        panel.alphaValue = 0.0
        panel.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = AnimationConstants.Timing.medium
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1.0
        }
        
        isVisible = true
        
        // Auto-hide after delay if no downloads
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if DownloadManager.shared.activeDownloads.isEmpty {
                self.hideDownloadPanel()
            }
        }
    }
    
    func hideDownloadPanel() {
        guard let panel = downloadPanel, isVisible else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = AnimationConstants.Timing.fast
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0.0
        } completionHandler: {
            panel.orderOut(nil)
            WindowService.shared.unregisterWindow(panel)
            self.isVisible = false
        }
    }
    
    func toggleDownloadPanel(relativeTo button: NSView) {
        if isVisible {
            hideDownloadPanel()
        } else {
            showDownloadPanel(relativeTo: button)
        }
    }
    
    private func createDownloadPanel() {
        // Create popover-style panel without window decorations
        let styleMask: NSPanel.StyleMask = [.nonactivatingPanel, .fullSizeContentView]
        
        downloadPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: UIConstants.DownloadPopover.width, height: 200),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        guard let panel = downloadPanel else { return }
        
        // Configure panel as true popover
        panel.title = ""
        panel.isMovableByWindowBackground = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.hidesOnDeactivate = true
        panel.canHide = true
        panel.animationBehavior = .alertPanel
        panel.isOpaque = false
        panel.backgroundColor = NSColor.clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.isFloatingPanel = true
        
        // Create hosting controller
        let downloadPopover = DownloadPopover()
        hostingController = NSHostingController(rootView: downloadPopover)
        
        if let hostingController = hostingController {
            panel.contentView = hostingController.view
            hostingController.view.frame = panel.contentView?.bounds ?? .zero
            hostingController.view.autoresizingMask = [.width, .height]
            
            // Apply popover styling
            hostingController.view.wantsLayer = true
            hostingController.view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            hostingController.view.layer?.cornerRadius = UIConstants.CornerRadius.medium
            hostingController.view.layer?.borderColor = NSColor.separatorColor.cgColor
            hostingController.view.layer?.borderWidth = 1.0
            hostingController.view.layer?.masksToBounds = true
        }
    }
    
    private func calculatePanelOrigin(buttonFrame: NSRect, panelSize: NSSize, preferredEdge: NSRectEdge) -> NSPoint {
        var origin = NSPoint.zero
        
        switch preferredEdge {
        case .minY: // Below button
            origin.x = buttonFrame.midX - panelSize.width / 2
            origin.y = buttonFrame.minY - panelSize.height - 8
        case .maxY: // Above button
            origin.x = buttonFrame.midX - panelSize.width / 2
            origin.y = buttonFrame.maxY + 8
        case .minX: // Left of button
            origin.x = buttonFrame.minX - panelSize.width - 8
            origin.y = buttonFrame.midY - panelSize.height / 2
        case .maxX: // Right of button
            origin.x = buttonFrame.maxX + 8
            origin.y = buttonFrame.midY - panelSize.height / 2
        @unknown default:
            origin.x = buttonFrame.midX - panelSize.width / 2
            origin.y = buttonFrame.minY - panelSize.height - 8
        }
        
        // Ensure panel stays on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            
            if origin.x < screenFrame.minX {
                origin.x = screenFrame.minX + 8
            } else if origin.x + panelSize.width > screenFrame.maxX {
                origin.x = screenFrame.maxX - panelSize.width - 8
            }
            
            if origin.y < screenFrame.minY {
                origin.y = buttonFrame.maxY + 8 // Flip to above button
            } else if origin.y + panelSize.height > screenFrame.maxY {
                origin.y = screenFrame.maxY - panelSize.height - 8
            }
        }
        
        return origin
    }
    
    deinit {
        if let panel = downloadPanel {
            WindowService.shared.unregisterWindow(panel)
        }
    }
}

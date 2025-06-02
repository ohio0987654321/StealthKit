import SwiftUI
import AppKit

// MARK: - Unified Window Manager
@Observable
class WindowManager {
    static let shared = WindowManager()
    
    // MARK: - Window State
    private var managedWindows: Set<NSWindow> = []
    
    // MARK: - Window Properties
    var isTranslucencyEnabled: Bool = true {
        didSet { applyTranslucencyToAllWindows() }
    }
    
    var translucencyLevel: Double = 0.95 {
        didSet { applyTranslucencyToAllWindows() }
    }
    
    var isAlwaysOnTop: Bool = false {
        didSet { applyAlwaysOnTopToAllWindows() }
    }
    
    var isCloakingEnabled: Bool = true {
        didSet { applyCloakingToAllWindows() }
    }
    
    var windowMaterial: UITheme.MaterialType = .content {
        didSet { applyMaterialToAllWindows() }
    }
    

    
    // Store settings to avoid singleton access during initialization
    private var currentIsPinnedToCurrentDesktop: Bool = true
    private var currentHideInMissionControl: Bool = false
    
    private init() {}
    
    // MARK: - Window Registration
    func registerWindow(_ window: NSWindow) {
        managedWindows.insert(window)
        configureWindow(window)
    }
    
    func unregisterWindow(_ window: NSWindow) {
        managedWindows.remove(window)
    }
    
    // MARK: - Window Configuration
    private func configureWindow(_ window: NSWindow) {
        // Apply unified window styling
        applyUnifiedStyling(to: window)
        
        // Apply current settings
        if isTranslucencyEnabled {
            setWindowTranslucency(window, level: translucencyLevel)
        }
        
        if isAlwaysOnTop {
            setWindowAlwaysOnTop(window, enabled: true)
        }
        
        if isCloakingEnabled {
            applyCloaking(to: window)
        }
        
        // Apply unified material to entire window including titlebar
        applyMaterial(to: window, material: .content)
    }
    
    // MARK: - Unified Window Styling
    private func applyUnifiedStyling(to window: NSWindow) {
        // Configure window appearance for native macOS look with proper material
        window.titlebarAppearsTransparent = false  // Keep titlebar visible but styled
        window.titleVisibility = .hidden
        window.toolbarStyle = .unified
        
        // Configure window behavior
        window.hidesOnDeactivate = false
        window.canHide = true
        window.animationBehavior = .documentWindow
        window.isOpaque = false
        
        // Set up window delegate for unified management
        if window.delegate == nil {
            window.delegate = UnifiedWindowDelegate.shared
        }
    }
    
    // MARK: - Translucency Management
    private func setWindowTranslucency(_ window: NSWindow, level: Double) {
        let clampedLevel = max(0.3, min(1.0, level))
        
        // Apply transparency only to the window chrome, not content
        window.alphaValue = clampedLevel
        
        // Ensure content view remains fully opaque to preserve web content readability
        if let contentView = window.contentView {
            contentView.alphaValue = 1.0
            contentView.layer?.opacity = 1.0
            
            // Only adjust the material background's opacity if it exists
            if let materialView = contentView.subviews.first(where: { view in
                view.identifier?.rawValue == "UnifiedMaterialBackground"
            }) {
                materialView.alphaValue = clampedLevel
            }
        }
    }
    
    private func applyTranslucencyToAllWindows() {
        for window in managedWindows {
            if isTranslucencyEnabled {
                setWindowTranslucency(window, level: translucencyLevel)
            } else {
                setWindowTranslucency(window, level: 1.0)
            }
        }
    }
    
    // MARK: - Always On Top Management
    private func setWindowAlwaysOnTop(_ window: NSWindow, enabled: Bool) {
        if !window.isKind(of: NSPanel.self) {
            if enabled {
                // Choose window level based on Mission Control visibility preference
                if currentHideInMissionControl {
                    window.level = .floating  // Floating level hides in Mission Control
                } else {
                    // Use a level that stays visible in Mission Control
                    window.level = .tornOffMenu  // This level stays visible in Mission Control
                    // Also ensure collection behavior supports Mission Control visibility
                    var behavior = window.collectionBehavior
                    behavior.remove(.ignoresCycle)
                    behavior.insert(.participatesInCycle)
                    window.collectionBehavior = behavior
                }
            } else {
                window.level = .normal
                // Restore normal collection behavior
                var behavior = window.collectionBehavior
                behavior.remove(.ignoresCycle)
                behavior.insert(.participatesInCycle)
                window.collectionBehavior = behavior
            }
        }
    }
    
    private func applyAlwaysOnTopToAllWindows() {
        for window in managedWindows {
            setWindowAlwaysOnTop(window, enabled: isAlwaysOnTop)
        }
    }
    
    // MARK: - Cloaking Management
    private func applyCloaking(to window: NSWindow) {
        // Configure collection behavior for screen recording protection
        var behavior: NSWindow.CollectionBehavior = []
        
        // Check if pinned to current desktop setting is disabled
        if !currentIsPinnedToCurrentDesktop {
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
    }
    
    // MARK: - Material Management
    private func applyMaterial(to window: NSWindow, material: UITheme.MaterialType) {
        guard let contentView = window.contentView else { return }
        
        // Remove existing material background if any
        contentView.subviews.removeAll { view in
            view.identifier?.rawValue == "UnifiedMaterialBackground"
        }
        
        // Create NSVisualEffectView for proper material coverage including titlebar
        let effectView = NSVisualEffectView()
        effectView.identifier = NSUserInterfaceItemIdentifier("UnifiedMaterialBackground")
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.wantsLayer = true
        
        // Configure material based on UITheme material type
        switch material {
        case .content, .sidebar, .toolbar:
            effectView.material = .titlebar  // Native titlebar material includes content area
            effectView.blendingMode = .behindWindow
        case .overlay:
            effectView.material = .popover
            effectView.blendingMode = .withinWindow
        case .popup:
            effectView.material = .menu
            effectView.blendingMode = .withinWindow
        }
        
        effectView.state = .active
        
        // Add to content view with full coverage
        contentView.addSubview(effectView, positioned: .below, relativeTo: nil)
        
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: contentView.topAnchor),
            effectView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func applyMaterialToAllWindows() {
        for window in managedWindows {
            applyMaterial(to: window, material: windowMaterial)
        }
    }
    

    
    // MARK: - Window Creation Helpers
    func createUnifiedWindow(
        contentRect: NSRect = NSRect(x: 100, y: 100, width: 1200, height: 800),
        styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
        backing: NSWindow.BackingStoreType = .buffered
    ) -> NSWindow {
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: backing,
            defer: false
        )
        
        registerWindow(window)
        return window
    }
    
    // MARK: - Settings Integration
    func updateFromStealthManager(_ stealthManager: StealthManager) {
        isTranslucencyEnabled = stealthManager.isWindowTransparencyEnabled
        translucencyLevel = stealthManager.windowTransparencyLevel
        isAlwaysOnTop = stealthManager.isAlwaysOnTop
        isCloakingEnabled = stealthManager.isWindowCloakingEnabled

        
        // Update private settings to avoid circular dependency
        currentIsPinnedToCurrentDesktop = stealthManager.isPinnedToCurrentDesktop
        currentHideInMissionControl = stealthManager.hideInMissionControl
    }
    
    func syncToStealthManager(_ stealthManager: StealthManager) {
        stealthManager.setWindowTransparencyEnabled(isTranslucencyEnabled)
        stealthManager.setWindowTransparencyLevel(translucencyLevel)
        stealthManager.setAlwaysOnTop(isAlwaysOnTop)
        stealthManager.setWindowCloakingEnabled(isCloakingEnabled)

        stealthManager.setPinnedToCurrentDesktop(currentIsPinnedToCurrentDesktop)
        stealthManager.setHideInMissionControl(currentHideInMissionControl)
    }
    
    // Methods to update settings without triggering circular dependency
    func updatePinnedToCurrentDesktop(_ enabled: Bool) {
        currentIsPinnedToCurrentDesktop = enabled
        applyCloakingToAllWindows()
    }
    
    func updateHideInMissionControl(_ enabled: Bool) {
        currentHideInMissionControl = enabled
        applyAlwaysOnTopToAllWindows()
    }
}

// MARK: - Unified Window Delegate
class UnifiedWindowDelegate: NSObject, NSWindowDelegate {
    static let shared = UnifiedWindowDelegate()
    
    private override init() {
        super.init()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // Ensure unified styling is maintained
        WindowManager.shared.registerWindow(window)
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // Maintain window properties when losing key status
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        WindowManager.shared.unregisterWindow(window)
    }
    
    func windowDidMiniaturize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // Ensure properties are maintained during miniaturization
        if WindowManager.shared.isCloakingEnabled {
            window.collectionBehavior.insert(.stationary)
        }
    }
    
    func windowDidDeminiaturize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // Restore normal collection behavior
        if WindowManager.shared.isCloakingEnabled {
            window.collectionBehavior.remove(.stationary)
        }
    }
}

// MARK: - SwiftUI Integration
struct UnifiedWindowModifier: ViewModifier {
    @State private var windowManager = WindowManager.shared
    
    func body(content: Content) -> some View {
        content
            .background(WindowManagerView())
            .onAppear {
                // Register current window when view appears
                if let window = NSApp.keyWindow {
                    windowManager.registerWindow(window)
                }
            }
    }
}

struct WindowManagerView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        DispatchQueue.main.async {
            if let window = view.window {
                WindowManager.shared.registerWindow(window)
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    func unifiedWindow() -> some View {
        self.modifier(UnifiedWindowModifier())
    }
}

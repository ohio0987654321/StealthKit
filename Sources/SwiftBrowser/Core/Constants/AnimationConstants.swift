import Foundation

struct AnimationConstants {
    
    // MARK: - Timing
    struct Timing {
        static let instant: Double = 0.0
        static let veryFast: Double = 0.05
        static let fast: Double = 0.1
        static let normal: Double = 0.15
        static let medium: Double = 0.2
        static let slow: Double = 0.25
        static let verySlow: Double = 0.35
    }
    
    // MARK: - Window Management
    struct Window {
        static let panelShowDelay: Double = 0.1
        static let activationPolicyChangeDelay: Double = 0.2
        static let toolbarConfigurationDelay: Double = 0.05
        static let cleanupDelay: Double = 0.1
    }
    
    // MARK: - UI Transitions
    struct Transition {
        static let tabSwitch: Double = 0.15
        static let sidebarToggle: Double = 0.25
        static let settingsChange: Double = 0.2
        static let addressBarFocus: Double = 0.1
    }
    
    // MARK: - WebView
    struct WebView {
        static let navigationStart: Double = 0.1
        static let loadingIndicator: Double = 0.2
        static let faviconLoad: Double = 0.15
    }
}

import Foundation

struct UIConstants {
    
    // MARK: - Window Dimensions
    struct Window {
        static let minWidth: CGFloat = 900
        static let minHeight: CGFloat = 600
        static let defaultWidth: CGFloat = 1200
        static let defaultHeight: CGFloat = 800
        static let defaultX: CGFloat = 100
        static let defaultY: CGFloat = 100
    }
    
    // MARK: - Sidebar Dimensions
    struct Sidebar {
        static let minWidth: CGFloat = 250
        static let idealWidth: CGFloat = 280
        static let maxWidth: CGFloat = 350
    }
    
    // MARK: - Tab Bar
    struct TabBar {
        static let height: CGFloat = 36
        static let borderWidth: CGFloat = 1.0
    }
    
    // MARK: - Address Bar
    struct AddressBar {
        static let minWidth: CGFloat = 300
        static let maxWidth: CGFloat = 300
    }
    
    // MARK: - Transparency
    struct Transparency {
        static let minLevel: Double = 0.3
        static let maxLevel: Double = 1.0
        static let defaultLevel: Double = 0.9
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 6
        static let large: CGFloat = 8
        static let button: CGFloat = 6
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let tiny: CGFloat = 2
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xlarge: CGFloat = 16
        static let xxlarge: CGFloat = 20
    }
    
    // MARK: - Layout
    struct Layout {
        static let toolbarHeight: CGFloat = 44
        static let statusBarHeight: CGFloat = 22
        static let minimumTouchTarget: CGFloat = 44
    }
}

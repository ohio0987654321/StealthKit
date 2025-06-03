import Foundation

struct UIConstants {
    
    // MARK: - Window Dimensions
    struct Window {
        static let minWidth: CGFloat = 900
        static let minHeight: CGFloat = 600
        static let defaultWidth: CGFloat = 1200
        static let defaultHeight: CGFloat = 800
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
        static let minLevel: Double = 0.1
        static let maxLevel: Double = 0.7
    }
    
    // MARK: - Animation Durations
    struct Animation {
        static let quick: Double = 0.15
        static let standard: Double = 0.25
        static let slow: Double = 0.35
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
}

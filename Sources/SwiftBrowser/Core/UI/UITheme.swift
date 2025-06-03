import SwiftUI
import AppKit

struct UITheme {
    
    struct Colors {
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let tertiary = Color(.tertiaryLabelColor)
        
        static let accent = Color.accentColor
        static let accentSecondary = Color.accentColor.opacity(0.7)
        
        static let backgroundPrimary = Color(.windowBackgroundColor)
        static let backgroundSecondary = Color(.controlBackgroundColor)
        static let backgroundTertiary = Color(.quaternarySystemFill)
        
        static let hover = Color.accentColor.opacity(0.05)
        static let selected = Color.accentColor.opacity(0.15)
        static let pressed = Color.accentColor.opacity(0.25)
        
        static let separator = Color(.separatorColor)
        static let border = Color(.separatorColor).opacity(0.3)
        static let shadow = Color.black.opacity(0.1)
    }
    
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title2.weight(.semibold)
        static let headline = Font.headline.weight(.medium)
        
        static let body = Font.body
        static let bodyEmphasized = Font.body.weight(.medium)
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        static let toolbarButton = Font.system(size: 14, weight: .medium)
        static let sidebarHeader = Font.caption.weight(.semibold)
        static let sidebarItem = Font.system(size: 13)
        static let addressBar = Font.body.monospaced()
    }
    
    struct Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        
        static let sidebarPadding: CGFloat = 16
        static let toolbarPadding: CGFloat = 12
        static let contentPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
    }
    
    struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 6
        static let large: CGFloat = 8
        static let xlarge: CGFloat = 12
        static let button: CGFloat = 6
        static let card: CGFloat = 8
        static let overlay: CGFloat = 12
    }
    
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: UIConstants.Animation.quick)
        static let standard = SwiftUI.Animation.easeInOut(duration: UIConstants.Animation.standard)
        static let slow = SwiftUI.Animation.easeInOut(duration: UIConstants.Animation.slow)
        
        static let spring = SwiftUI.Animation.spring(
            response: 0.5,
            dampingFraction: 0.8,
            blendDuration: 0
        )
    }
    
    private init() {}
}

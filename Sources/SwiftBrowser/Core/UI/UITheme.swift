import SwiftUI
import AppKit

// MARK: - UI Theme Manager
@Observable
class UITheme {
    static let shared = UITheme()
    
    // MARK: - Material Strategy
    enum MaterialType {
        case sidebar
        case content
        case toolbar
        case overlay
        case popup
        
        var material: Material {
            switch self {
            case .sidebar:
                return .thinMaterial // Unified: same as content
            case .content:
                return .thinMaterial // Unified: consistent across all main areas
            case .toolbar:
                return .thinMaterial // Unified: same as content for consistency
            case .overlay:
                return .thickMaterial // Keep distinct for overlays
            case .popup:
                return .ultraThickMaterial // Keep distinct for popups
            }
        }
        
        var blendMode: BlendMode {
            switch self {
            case .sidebar, .content:
                return .normal
            case .toolbar, .overlay, .popup:
                return .overlay
            }
        }
    }
    
    // MARK: - Color Palette
    struct Colors {
        // Primary Colors
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let tertiary = Color(.tertiaryLabelColor)
        
        // Accent Colors
        static let accent = Color.accentColor
        static let accentSecondary = Color.accentColor.opacity(0.7)
        
        // Background Colors
        static let backgroundPrimary = Color(.windowBackgroundColor)
        static let backgroundSecondary = Color(.controlBackgroundColor)
        static let backgroundTertiary = Color(.quaternarySystemFill)
        
        // Interactive States
        static let hover = Color.accentColor.opacity(0.05)
        static let selected = Color.accentColor.opacity(0.15)
        static let pressed = Color.accentColor.opacity(0.25)
        
        // Semantic Colors
        static let separator = Color(.separatorColor)
        static let border = Color(.separatorColor).opacity(0.3)
        static let shadow = Color.black.opacity(0.1)
    }
    
    // MARK: - Typography System
    struct Typography {
        // Title Styles
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title2.weight(.semibold)
        static let headline = Font.headline.weight(.medium)
        
        // Body Styles
        static let body = Font.body
        static let bodyEmphasized = Font.body.weight(.medium)
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        // UI Specific
        static let toolbarButton = Font.system(size: 14, weight: .medium)
        static let sidebarHeader = Font.caption.weight(.semibold)
        static let sidebarItem = Font.system(size: 13)
        static let addressBar = Font.body.monospaced()
    }
    
    // MARK: - Spacing System
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
        
        // Component Specific
        static let sidebarPadding: CGFloat = 16
        static let toolbarPadding: CGFloat = 12
        static let contentPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 6
        static let large: CGFloat = 8
        static let xlarge: CGFloat = 12
        static let button: CGFloat = 6
        static let card: CGFloat = 8
        static let overlay: CGFloat = 12
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let small = DropShadow(
            color: Colors.shadow,
            radius: 2,
            xOffset: 0,
            yOffset: 1
        )
        
        static let medium = DropShadow(
            color: Colors.shadow,
            radius: 4,
            xOffset: 0,
            yOffset: 2
        )
        
        static let large = DropShadow(
            color: Colors.shadow,
            radius: 8,
            xOffset: 0,
            yOffset: 4
        )
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.35)
        
        static let spring = SwiftUI.Animation.spring(
            response: 0.5,
            dampingFraction: 0.8,
            blendDuration: 0
        )
    }
    
    private init() {}
}

// MARK: - Drop Shadow Helper
struct DropShadow {
    let color: Color
    let radius: CGFloat
    let xOffset: CGFloat
    let yOffset: CGFloat
}

// MARK: - View Extensions for Theme
extension View {
    func themedMaterial(_ type: UITheme.MaterialType) -> some View {
        self.background(type.material, in: Rectangle())
    }
    
    func themedCard() -> some View {
        self
            .background(UITheme.MaterialType.content.material, in: RoundedRectangle(cornerRadius: UITheme.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: UITheme.CornerRadius.card)
                    .stroke(UITheme.Colors.border, lineWidth: 0.5)
            )
    }
    
    func themedButton(style: ThemedButtonStyle = .primary) -> some View {
        self.buttonStyle(style)
    }
    
    func themedShadow(_ shadow: DropShadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.xOffset,
            y: shadow.yOffset
        )
    }
}

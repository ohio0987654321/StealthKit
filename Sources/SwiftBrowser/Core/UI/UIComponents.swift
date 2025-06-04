import SwiftUI
import AppKit

struct ThemedButtonStyle: ButtonStyle {
    enum Style {
        case primary
        case secondary
        case toolbar
        case destructive
        case plain
    }
    
    let style: Style
    
    init(_ style: Style = .primary) {
        self.style = style
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(fontForStyle)
            .foregroundColor(foregroundColor(for: configuration))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(background(for: configuration))
            .overlay(overlay(for: configuration))
            .clipShape(RoundedRectangle(cornerRadius: UITheme.CornerRadius.button))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(UITheme.Animation.quick, value: configuration.isPressed)
    }
    
    private var fontForStyle: Font {
        switch style {
        case .primary, .secondary, .destructive:
            return UITheme.Typography.bodyEmphasized
        case .toolbar:
            return UITheme.Typography.toolbarButton
        case .plain:
            return UITheme.Typography.body
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch style {
        case .primary, .secondary, .destructive:
            return UITheme.Spacing.large
        case .toolbar:
            return UITheme.Spacing.small
        case .plain:
            return UITheme.Spacing.xs
        }
    }
    
    private var verticalPadding: CGFloat {
        switch style {
        case .primary, .secondary, .destructive:
            return UITheme.Spacing.small
        case .toolbar:
            return UITheme.Spacing.xs
        case .plain:
            return UITheme.Spacing.xxs
        }
    }
    
    private func foregroundColor(for configuration: Configuration) -> Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return UITheme.Colors.primary
        case .toolbar:
            return UITheme.Colors.primary
        case .destructive:
            return .white
        case .plain:
            return UITheme.Colors.primary
        }
    }
    
    private func background(for configuration: Configuration) -> some View {
        Group {
            switch style {
            case .primary:
                RoundedRectangle(cornerRadius: UITheme.CornerRadius.button)
                    .fill(UITheme.Colors.accent)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            case .secondary:
                RoundedRectangle(cornerRadius: UITheme.CornerRadius.button)
                    .fill(UITheme.Colors.backgroundSecondary)
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            case .toolbar:
                RoundedRectangle(cornerRadius: UITheme.CornerRadius.button)
                    .fill(Color.clear)
            case .destructive:
                RoundedRectangle(cornerRadius: UITheme.CornerRadius.button)
                    .fill(Color.red)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            case .plain:
                RoundedRectangle(cornerRadius: UITheme.CornerRadius.button)
                    .fill(Color.clear)
            }
        }
    }
    
    private func overlay(for configuration: Configuration) -> some View {
        Group {
            switch style {
            case .primary, .destructive:
                EmptyView()
            case .secondary:
                RoundedRectangle(cornerRadius: UITheme.CornerRadius.button)
                    .stroke(UITheme.Colors.border, lineWidth: 0.5)
            case .toolbar:
                EmptyView()
            case .plain:
                EmptyView()
            }
        }
    }
}

struct ThemedToolbarButton: View {
    let icon: String
    let action: () -> Void
    let isDisabled: Bool
    let iconColor: Color?
    @State private var isHovered = false
    
    init(icon: String, isDisabled: Bool = false, iconColor: Color? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.isDisabled = isDisabled
        self.iconColor = iconColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(UITheme.Typography.toolbarButton)
                .foregroundStyle(iconColor ?? (isDisabled ? UITheme.Colors.tertiary : UITheme.Colors.primary))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: UITheme.CornerRadius.button)
                        .fill(backgroundFill)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(ThemedToolbarButtonStyle(isHovered: isHovered))
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(UITheme.Animation.quick) {
                isHovered = hovering && !isDisabled
            }
        }
    }
    
    private var backgroundFill: Color {
        if isDisabled {
            return Color.clear
        } else if isHovered {
            return UITheme.Colors.hover
        } else {
            return Color.clear
        }
    }
}

struct ThemedToolbarButtonStyle: ButtonStyle {
    let isHovered: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .background(
                RoundedRectangle(cornerRadius: UITheme.CornerRadius.button)
                    .fill(configuration.isPressed ? UITheme.Colors.pressed : Color.clear)
            )
            .animation(UITheme.Animation.quick, value: configuration.isPressed)
    }
}

struct ThemedToolbarButtonWithBadge: View {
    let icon: String
    let action: () -> Void
    let isDisabled: Bool
    let iconColor: Color?
    let badgeCount: Int
    let showBadge: Bool
    @State private var isHovered = false
    
    init(icon: String, isDisabled: Bool = false, iconColor: Color? = nil, badgeCount: Int = 0, showBadge: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.isDisabled = isDisabled
        self.iconColor = iconColor
        self.badgeCount = badgeCount
        self.showBadge = showBadge
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Image(systemName: icon)
                    .font(UITheme.Typography.toolbarButton)
                    .foregroundStyle(iconColor ?? (isDisabled ? UITheme.Colors.tertiary : UITheme.Colors.primary))
                
                if showBadge {
                    Text("\(badgeCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(2)
                        .background(Circle().fill(Color.red))
                        .offset(x: 8, y: -8)
                }
            }
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: UITheme.CornerRadius.button)
                    .fill(backgroundFill)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(ThemedToolbarButtonStyle(isHovered: isHovered))
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(UITheme.Animation.quick) {
                isHovered = hovering && !isDisabled
            }
        }
    }
    
    private var backgroundFill: Color {
        if isDisabled {
            return Color.clear
        } else if isHovered {
            return UITheme.Colors.hover
        } else {
            return Color.clear
        }
    }
}

struct ThemedCloseButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 18, height: 18)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(backgroundFill)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(ThemedCloseButtonStyle(isHovered: isHovered))
        .onHover { hovering in
            withAnimation(UITheme.Animation.quick) {
                isHovered = hovering
            }
        }
    }
    
    private var backgroundFill: Color {
        if isHovered {
            return Color.white.opacity(0.2)
        } else {
            return Color.clear
        }
    }
}

struct ThemedCloseButtonStyle: ButtonStyle {
    let isHovered: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isPressed ? Color.white.opacity(0.3) : Color.clear)
            )
            .animation(UITheme.Animation.quick, value: configuration.isPressed)
    }
}

extension ThemedButtonStyle {
    static let primary = ThemedButtonStyle(.primary)
    static let secondary = ThemedButtonStyle(.secondary)
    static let toolbar = ThemedButtonStyle(.toolbar)
    static let destructive = ThemedButtonStyle(.destructive)
    static let plain = ThemedButtonStyle(.plain)
}

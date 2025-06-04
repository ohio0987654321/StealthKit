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
    @State private var isHovered = false
    
    init(icon: String, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(UITheme.Typography.toolbarButton)
                .foregroundStyle(UITheme.Colors.primary)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .frame(width: 28, height: 28)
        .background(
            RoundedRectangle(cornerRadius: UITheme.CornerRadius.button)
                .fill(isHovered ? Color.white.opacity(0.15) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: AnimationConstants.Timing.fast)) {
                isHovered = hovering && !isDisabled
            }
        }
    }
}

extension ThemedButtonStyle {
    static let primary = ThemedButtonStyle(.primary)
    static let secondary = ThemedButtonStyle(.secondary)
    static let toolbar = ThemedButtonStyle(.toolbar)
    static let destructive = ThemedButtonStyle(.destructive)
    static let plain = ThemedButtonStyle(.plain)
}

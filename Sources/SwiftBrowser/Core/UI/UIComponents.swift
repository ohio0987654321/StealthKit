import SwiftUI
import AppKit

// MARK: - Themed Button Styles
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
                    .fill(UITheme.Colors.backgroundTertiary)
                    .opacity(configuration.isPressed ? 0.5 : 0.6)
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
            case .secondary, .toolbar:
                RoundedRectangle(cornerRadius: UITheme.CornerRadius.button)
                    .stroke(UITheme.Colors.border, lineWidth: 0.5)
            case .plain:
                EmptyView()
            }
        }
    }
}

// MARK: - Themed Container Views
struct ThemedCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    
    init(padding: CGFloat = UITheme.Spacing.large, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .themedCard()
    }
}

struct ThemedSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: UITheme.Spacing.medium) {
            Text(title)
                .font(UITheme.Typography.headline)
                .foregroundColor(UITheme.Colors.primary)
            
            content
        }
    }
}

// MARK: - Themed Input Components
struct ThemedTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    
    init(_ title: String, text: Binding<String>, placeholder: String = "", isSecure: Bool = false) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.isSecure = isSecure
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: UITheme.Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(UITheme.Typography.caption)
                    .foregroundColor(UITheme.Colors.secondary)
            }
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.roundedBorder)
            .font(UITheme.Typography.body)
        }
    }
}

// MARK: - Themed Toolbar Components
struct ThemedToolbarButton: View {
    let icon: String
    let action: () -> Void
    let isDisabled: Bool
    
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
        .themedButton(style: .toolbar)
        .disabled(isDisabled)
        .frame(width: 28, height: 28)
    }
}

// MARK: - Themed Sidebar Components
struct ThemedSidebarSection<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    let hasAddButton: Bool
    let onAdd: (() -> Void)?
    let content: Content
    
    init(
        title: String,
        icon: String,
        isExpanded: Binding<Bool>,
        hasAddButton: Bool = false,
        onAdd: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self._isExpanded = isExpanded
        self.hasAddButton = hasAddButton
        self.onAdd = onAdd
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ThemedSidebarHeader(
                title: title,
                icon: icon,
                isExpanded: $isExpanded,
                hasAddButton: hasAddButton,
                onAdd: onAdd
            )
            
            if isExpanded {
                content
                    .themedMaterial(.content)
                    .clipShape(RoundedRectangle(cornerRadius: UITheme.CornerRadius.card))
                    .padding(.horizontal, UITheme.Spacing.small)
                    .padding(.bottom, UITheme.Spacing.small)
            }
        }
    }
}

struct ThemedSidebarHeader: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    let hasAddButton: Bool
    let onAdd: (() -> Void)?
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation(UITheme.Animation.standard) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: UITheme.Spacing.xs) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(UITheme.Typography.caption)
                        .foregroundColor(UITheme.Colors.secondary)
                    
                    Image(systemName: icon)
                        .font(UITheme.Typography.caption)
                        .foregroundColor(UITheme.Colors.secondary)
                    
                    Text(title)
                        .font(UITheme.Typography.sidebarHeader)
                        .foregroundColor(UITheme.Colors.secondary)
                        .textCase(.uppercase)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            if hasAddButton, let onAdd = onAdd {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(UITheme.Typography.caption)
                        .foregroundColor(UITheme.Colors.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, UITheme.Spacing.sidebarPadding)
        .padding(.vertical, UITheme.Spacing.small)
    }
}

// MARK: - Convenience Extensions
extension ThemedButtonStyle {
    static let primary = ThemedButtonStyle(.primary)
    static let secondary = ThemedButtonStyle(.secondary)
    static let toolbar = ThemedButtonStyle(.toolbar)
    static let destructive = ThemedButtonStyle(.destructive)
    static let plain = ThemedButtonStyle(.plain)
}

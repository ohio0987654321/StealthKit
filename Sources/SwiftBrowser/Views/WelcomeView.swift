import SwiftUI

struct WelcomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 40)
                
                // Hero section
                heroSection
                    .padding(.bottom, 40)
                
                // Keyboard shortcuts section
                shortcutsSection
                
                Spacer()
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 24) {
            // App icon
            Image(systemName: "safari")
                .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [UITheme.Colors.accent, UITheme.Colors.accent.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Title and subtitle
            VStack(spacing: 8) {
                Text("SwiftBrowser")
                    .font(.system(.largeTitle, design: .rounded, weight: .thin))
                    .foregroundStyle(.primary)
                
                Text("Fast, Private, Secure")
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Shortcuts Section
    private var shortcutsSection: some View {
        let shortcutManager = KeyboardShortcutManager.shared
        let shortcutsByCategory = shortcutManager.shortcutsByCategory()
        
        return VStack(spacing: 16) {
            Text("Keyboard Shortcuts")
                .font(.system(.headline, design: .rounded, weight: .medium))
                .foregroundStyle(.primary)
            
            VStack(spacing: 12) {
                ForEach(ShortcutCategory.allCases, id: \.self) { category in
                    if let shortcuts = shortcutsByCategory[category], !shortcuts.isEmpty {
                        shortcutCategorySection(category: category, shortcuts: shortcuts)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: UITheme.CornerRadius.large)
                .fill(Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: UITheme.CornerRadius.large)
                        .stroke(UITheme.Colors.border.opacity(0.1), lineWidth: 0.5)
                }
        )
    }
    
    // MARK: - Shortcut Category Section
    private func shortcutCategorySection(category: ShortcutCategory, shortcuts: [KeyboardShortcut]) -> some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(UITheme.Colors.accent)
                
                Text(category.rawValue)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 4) {
                ForEach(shortcuts.prefix(4), id: \.id) { shortcut in
                    shortcutRow(shortcut.displayKeyEquivalent, shortcut.title, getIconForShortcut(shortcut))
                }
            }
        }
    }
    
    // MARK: - Shortcut Row
    private func shortcutRow(_ shortcut: String, _ description: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(UITheme.Colors.accent)
                .frame(width: 16, height: 16)
            
            Text(shortcut)
                .font(.system(.caption, design: .monospaced, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(minWidth: 60, alignment: .leading)
            
            Text(description)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }
    
    // MARK: - Icon Helper
    private func getIconForShortcut(_ shortcut: KeyboardShortcut) -> String {
        switch shortcut.id {
        case "newTab":
            return "plus"
        case "closeTab":
            return "xmark"
        case "reload", "hardReload":
            return "arrow.clockwise"
        case "focusAddressBar":
            return "magnifyingglass"
        case "navigateBack":
            return "chevron.left"
        case "navigateForward":
            return "chevron.right"
        case "zoomIn":
            return "plus.magnifyingglass"
        case "zoomOut":
            return "minus.magnifyingglass"
        case "resetZoom":
            return "magnifyingglass"
        case "findInPage":
            return "doc.text.magnifyingglass"
        case "closeWindow":
            return "xmark.square"
        case "minimizeWindow":
            return "minus.square"
        case "nextTab", "previousTab":
            return "arrow.left.arrow.right"
        default:
            return "keyboard"
        }
    }
}

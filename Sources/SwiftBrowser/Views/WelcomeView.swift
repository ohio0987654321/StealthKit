import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hero section
            heroSection
                .padding(.bottom, 40)
            
            // Keyboard shortcuts section
            shortcutsSection
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
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
        VStack(spacing: 16) {
            Text("Keyboard Shortcuts")
                .font(.system(.headline, design: .rounded, weight: .medium))
                .foregroundStyle(.primary)
            
            VStack(spacing: 8) {
                shortcutRow("⌘T", "New Tab", "plus")
                shortcutRow("⌘W", "Close Tab", "xmark")
                shortcutRow("⌘R", "Reload", "arrow.clockwise")
                shortcutRow("⌘L", "Address Bar", "magnifyingglass")
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
                .frame(width: 24, alignment: .leading)
            
            Text(description)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

import SwiftUI

struct TabBarView: View {
    let tabs: [Tab]
    let selectedTabId: UUID?
    let onTabSelect: (UUID) -> Void
    let onTabClose: (Tab) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                TabItemView(
                    tab: tab,
                    isSelected: selectedTabId == tab.id,
                    onSelect: { onTabSelect(tab.id) },
                    onClose: { onTabClose(tab) }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: UIConstants.TabBar.height)
        .clipped()
        .background(UITheme.Colors.backgroundSecondary)
        .overlay(
            Rectangle()
                .fill(Color.black)
                .frame(height: UIConstants.TabBar.borderWidth),
            alignment: .bottom
        )
    }
}

struct TabItemView: View {
    let tab: Tab
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    @State private var isHovered = false
    @State private var isCloseHovered = false
    
    var body: some View {
        HStack(spacing: 6) {
            // Dynamic favicon with fallback
            Group {
                if let favicon = tab.favicon {
                    favicon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 12, height: 12)
            .clipped()
            
            Text(tab.title.isEmpty ? "New Tab" : tab.title)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isHovered || isSelected {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .frame(width: 18, height: 18)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isCloseHovered ? Color.white.opacity(0.2) : Color.clear)
                )
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isCloseHovered = hovering
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(isSelected ? UITheme.Colors.backgroundPrimary : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Close Tab") {
                onClose()
            }
        }
    }
}

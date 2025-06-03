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
        .frame(height: 36)
        .clipped()
        .background(UITheme.Colors.backgroundSecondary)
        .overlay(
            Rectangle()
                .fill(UITheme.Colors.border)
                .frame(height: 0.5),
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
                .frame(width: 12, height: 12)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
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
            
            Button("Duplicate Tab") {
                // TODO: Implement duplicate functionality
            }
            
            Divider()
            
            Button("Close Other Tabs") {
                // TODO: Implement close others functionality
            }
        }
    }
}

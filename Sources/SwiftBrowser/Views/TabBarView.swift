import SwiftUI

struct TabBarView: View {
    let tabs: [Tab]
    let selectedTabId: UUID?
    let onTabSelect: (UUID) -> Void
    let onTabClose: (Tab) -> Void
    let onTabMove: (Int, Int) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                TabItemView(
                    tab: tab,
                    isSelected: selectedTabId == tab.id,
                    onSelect: { onTabSelect(tab.id) },
                    onClose: { onTabClose(tab) },
                    onMove: onTabMove,
                    tabIndex: index
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

struct TabDragData: Transferable, Codable {
    let tabId: UUID
    let tabIndex: Int
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

struct TabItemView: View {
    let tab: Tab
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onMove: (Int, Int) -> Void
    let tabIndex: Int
    
    @State private var isHovered = false
    @State private var isDragging = false
    @State private var isDropTarget = false
    
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
                ThemedCloseButton {
                    onClose()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(isSelected ? UITheme.Colors.backgroundPrimary : (isDropTarget ? Color.blue.opacity(0.2) : Color.clear))
        )
        .overlay(
            Rectangle()
                .fill(Color.black)
                .frame(width: UIConstants.TabBar.borderWidth),
            alignment: .trailing
        )
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .opacity(isDragging ? 0.6 : 1.0)
        .contentShape(Rectangle())
        .draggable(TabDragData(tabId: tab.id, tabIndex: tabIndex)) {
            // Drag preview
            HStack(spacing: 6) {
                if let favicon = tab.favicon {
                    favicon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                } else {
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .frame(width: 12, height: 12)
                }
                
                Text(tab.title.isEmpty ? "New Tab" : tab.title)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .shadow(radius: 4)
        }
        .dropDestination(for: TabDragData.self) { items, location in
            if let draggedTab = items.first {
                let sourceIndex = draggedTab.tabIndex
                let targetIndex = tabIndex
                
                let destinationIndex: Int
                if sourceIndex < targetIndex {
                    // Moving forward: insert AFTER target (account for removal shift)
                    destinationIndex = targetIndex + 1
                } else {
                    // Moving backward: insert AT target
                    destinationIndex = targetIndex
                }
                
                onMove(sourceIndex, destinationIndex)
            }
            return true
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isDropTarget = targeted
            }
        }
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(UITheme.Animation.quick) {
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

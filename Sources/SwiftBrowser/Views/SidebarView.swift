import SwiftUI

enum ContentType {
    case settingsSearchEngine
    case settingsWindowUtilities
    case webTab(Tab)
    case welcome
}

enum SidebarItem: Hashable {
    case settingsSearchEngine
    case settingsWindowUtilities
    case tab(UUID)
}

struct HierarchicalSidebarView: View {
    @Bindable var viewModel: BrowserViewModel
    @Binding var selectedItem: SidebarItem?
    let onSelectionChange: (SidebarItem) -> Void
    let onCloseTab: (Tab) -> Void
    
    @State private var settingsExpanded = true
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                SidebarSectionHeader(
                    title: "SETTINGS",
                    icon: "gear",
                    isExpanded: $settingsExpanded
                )
                
                if settingsExpanded {
                    SidebarSettingsItems(
                        selectedItem: $selectedItem,
                        onSelectionChange: onSelectionChange
                    )
                }
            }
        }
        .navigationTitle("")
    }
}

struct SidebarSectionHeader: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    var hasAddButton: Bool = false
    var onAdd: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            if hasAddButton, let onAdd = onAdd {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct SidebarSettingsItems: View {
    @Binding var selectedItem: SidebarItem?
    let onSelectionChange: (SidebarItem) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SidebarRowView(
                icon: "magnifyingglass",
                title: "Search Engine",
                isSelected: selectedItem == .settingsSearchEngine,
                onSelect: { onSelectionChange(.settingsSearchEngine) },
                indentLevel: 1
            )
            
            SidebarRowView(
                icon: "macwindow",
                title: "Window Utilities",
                isSelected: selectedItem == .settingsWindowUtilities,
                onSelect: { onSelectionChange(.settingsWindowUtilities) },
                indentLevel: 1
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: UITheme.CornerRadius.card))
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}

struct SidebarRowView: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let onSelect: () -> Void
    var indentLevel: Int = 1
    @State private var isHovered = false
    
    private var horizontalPadding: CGFloat {
        return 16 + CGFloat(indentLevel) * 16
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 16, height: 16)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 6)
        .background(
            Rectangle()
                .fill(isSelected ? Color.accentColor.opacity(0.15) : (isHovered ? Color(.controlAccentColor).opacity(0.05) : Color.clear))
        )
        .overlay(
            Rectangle()
                .fill(isSelected ? Color.accentColor : Color.clear)
                .frame(width: 3),
            alignment: .leading
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

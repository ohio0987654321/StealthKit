import SwiftUI

// ContentType removed - everything is now a unified web tab

enum SidebarItem: Hashable {
    case settingsBrowserUtilities
    case settingsWindowUtilities
    case tab(UUID)
}

struct HierarchicalSidebarView: View {
    @Bindable var viewModel: BrowserViewModel
    @Binding var selectedItem: SidebarItem?
    let onSelectionChange: (SidebarItem) -> Void
    let onCloseTab: (Tab) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Settings header
                HStack {
                    Text("Settings")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(.tertiaryLabelColor))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                SidebarSettingsItems(
                    selectedItem: $selectedItem,
                    onSelectionChange: onSelectionChange
                )
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
                    
                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
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
                title: "Browser Utilities",
                isSelected: selectedItem == .settingsBrowserUtilities,
                onSelect: { onSelectionChange(.settingsBrowserUtilities) },
                indentLevel: 0
            )
            
            SidebarRowView(
                icon: "macwindow",
                title: "Window Utilities",
                isSelected: selectedItem == .settingsWindowUtilities,
                onSelect: { onSelectionChange(.settingsWindowUtilities) },
                indentLevel: 0
            )
        }

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
                .foregroundColor(Color.blue)
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
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.white.opacity(0.15) : (isHovered ? Color.white.opacity(0.08) : Color.clear))
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

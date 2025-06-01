import SwiftUI

enum ContentType {
    case settingsSearchEngine
    case settingsWindowUtilities
    case webTab(Tab)
    case welcome
}

enum SidebarItem: Hashable {
    case settingsSection
    case settingsBrowserUtilities
    case settingsSearchEngine
    case settingsWindowUtilities
    case settingsScreenRecording
    case settingsAlwaysOnTop
    case tabsSection
    case tab(UUID)
}

struct HierarchicalSidebarView: View {
    @Bindable var viewModel: BrowserViewModel
    @Binding var selectedItem: SidebarItem?
    let onSelectionChange: (SidebarItem) -> Void
    let onCloseTab: (Tab) -> Void
    
    @State private var settingsExpanded = true
    @State private var tabsExpanded = true
    
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
                
                SidebarSectionHeader(
                    title: "TABS",
                    icon: "folder",
                    isExpanded: $tabsExpanded,
                    hasAddButton: true,
                    onAdd: {
                        let newTab = viewModel.createNewTab()
                        selectedItem = .tab(newTab.id)
                        onSelectionChange(.tab(newTab.id))
                    }
                )
                
                if tabsExpanded {
                    SidebarTabItems(
                        tabs: viewModel.tabs,
                        selectedItem: $selectedItem,
                        onSelectionChange: onSelectionChange,
                        onCloseTab: onCloseTab
                    )
                }
            }
        }
        .navigationTitle("")
        .background(Color(.controlBackgroundColor))
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
        .background(Color(.controlBackgroundColor))
    }
}

struct SidebarSettingsItems: View {
    @Binding var selectedItem: SidebarItem?
    let onSelectionChange: (SidebarItem) -> Void
    @State private var browserUtilitiesExpanded = true
    @State private var windowUtilitiesExpanded = true
    
    var body: some View {
        VStack(spacing: 0) {
            SidebarGroupHeaderView(
                title: "Browser Utilities",
                isExpanded: $browserUtilitiesExpanded
            )
            
            if browserUtilitiesExpanded {
                SidebarRowView(
                    icon: "magnifyingglass",
                    title: "Search Engine",
                    isSelected: selectedItem == .settingsSearchEngine,
                    onSelect: { onSelectionChange(.settingsSearchEngine) },
                    indentLevel: 2
                )
            }
            
            SidebarGroupHeaderView(
                title: "Window Utilities",
                isExpanded: $windowUtilitiesExpanded
            )
            
            if windowUtilitiesExpanded {
                SidebarRowView(
                    icon: "rectangle.on.rectangle",
                    title: "Screen Recording Bypass",
                    isSelected: selectedItem == .settingsScreenRecording,
                    onSelect: { onSelectionChange(.settingsScreenRecording) },
                    indentLevel: 2
                )
                
                SidebarRowView(
                    icon: "pin",
                    title: "Always on Top",
                    isSelected: selectedItem == .settingsAlwaysOnTop,
                    onSelect: { onSelectionChange(.settingsAlwaysOnTop) },
                    indentLevel: 2
                )
            }
        }
    }
}

struct SidebarTabItems: View {
    let tabs: [Tab]
    @Binding var selectedItem: SidebarItem?
    let onSelectionChange: (SidebarItem) -> Void
    let onCloseTab: (Tab) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(tabs) { tab in
                SidebarTabRowView(
                    tab: tab,
                    isSelected: selectedItem == .tab(tab.id),
                    onSelect: { onSelectionChange(.tab(tab.id)) },
                    onClose: { onCloseTab(tab) }
                )
            }
        }
    }
}

struct SidebarGroupHeaderView: View {
    let title: String
    @Binding var isExpanded: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .frame(width: 10, height: 10)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 4)
        .background(Color(.controlBackgroundColor))
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

struct SidebarTabRowView: View {
    let tab: Tab
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "globe")
                .foregroundColor(.secondary)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tab.title.isEmpty ? "New Tab" : tab.title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if let url = tab.url {
                    Text(url.host ?? url.absoluteString)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer()
            
            if isHovered || isSelected {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 16, height: 16)
                .opacity(isHovered ? 1.0 : 0.7)
            }
        }
        .padding(.horizontal, 32)
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
        .contextMenu {
            Button("Close Tab") {
                onClose()
            }
            
            Button("Duplicate Tab") {
                
            }
            
            Divider()
            
            Button("Close Other Tabs") {
                
            }
        }
    }
}

//
//  BrowserView.swift
//  SwiftBrowser
//
//  Finder-like browser interface with toolbar in title bar and always-open hierarchical sidebar.
//

import SwiftUI
import WebKit
import AppKit

// MARK: - Sidebar Item Types

enum SidebarItem: Hashable {
    case settingsSection
    case settingsSearchEngine
    case settingsStealth
    case tabsSection
    case tab(UUID)
}

enum ContentType {
    case settingsSearchEngine
    case settingsStealth
    case webTab(Tab)
    case noSelection
}

struct BrowserView: View {
    @State private var viewModel = BrowserViewModel()
    @State private var addressText: String = ""
    @FocusState private var isAddressBarFocused: Bool
    @State private var currentWebView: WKWebView?
    @State private var selectedSidebarItem: SidebarItem? = nil
    @State private var currentContent: ContentType = .noSelection
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationSplitView {
            // Hierarchical sidebar with settings and tabs
            HierarchicalSidebarView(
                viewModel: viewModel,
                selectedItem: $selectedSidebarItem,
                onSelectionChange: handleSidebarSelection
            )
            .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 350)
        } detail: {
            // Main content area - either settings or web content
            ZStack {
                switch currentContent {
                case .settingsSearchEngine:
                    SettingsSearchEngineView()
                case .settingsStealth:
                    SettingsStealthView()
                case .webTab(let tab):
                    WebView(
                        tab: .constant(tab),
                        onNavigationChange: { updatedTab in
                            if let index = viewModel.tabs.firstIndex(where: { $0.id == updatedTab.id }) {
                                viewModel.tabs[index] = updatedTab
                            }
                        },
                        onWebViewCreated: { webView in
                            currentWebView = webView
                        }
                    )
                case .noSelection:
                    VStack(spacing: 16) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No selection")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Select an item from the sidebar")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("") // Remove app name from title bar
            .toolbar {
                // Only show navigation controls when viewing web content
                if case .webTab = currentContent {
                    // Back/Forward/Reload in leading area of title bar
                    ToolbarItemGroup(placement: .navigation) {
                        HStack(spacing: 8) {
                            Button(action: {
                                if let webView = getCurrentWebView() {
                                    webView.goBack()
                                }
                            }) {
                                Image(systemName: "chevron.left")
                            }
                            .disabled(!(getCurrentTab()?.canGoBack ?? false))
                            
                            Button(action: {
                                if let webView = getCurrentWebView() {
                                    webView.goForward()
                                }
                            }) {
                                Image(systemName: "chevron.right")
                            }
                            .disabled(!(getCurrentTab()?.canGoForward ?? false))
                            
                            Button(action: {
                                if let webView = getCurrentWebView() {
                                    if getCurrentTab()?.isLoading == true {
                                        webView.stopLoading()
                                    } else {
                                        webView.reload()
                                    }
                                }
                            }) {
                                Image(systemName: getCurrentTab()?.isLoading == true ? "xmark" : "arrow.clockwise")
                            }
                        }
                    }
                    
                    // Address bar in center of title bar
                    ToolbarItem(placement: .principal) {
                        TextField("Enter URL or search", text: $addressText)
                            .textFieldStyle(.roundedBorder)
                            .focused($isAddressBarFocused)
                            .onSubmit {
                                handleAddressSubmit()
                            }
                            .onChange(of: getCurrentTab()?.url) { _, newURL in
                                if !isAddressBarFocused {
                                    addressText = newURL?.absoluteString ?? ""
                                }
                            }
                    }
                }
            }
        }
        .navigationSplitViewStyle(.prominentDetail) // Force sidebar always visible
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            setupKeyboardShortcuts()
            // Select the first tab by default if available
            if let firstTab = viewModel.tabs.first {
                selectedSidebarItem = .tab(firstTab.id)
                currentContent = .webTab(firstTab)
            }
        }
        .onDisappear {
            removeKeyboardShortcuts()
        }
    }
    
    private func getCurrentWebView() -> WKWebView? {
        return currentWebView
    }
    
    private func getCurrentTab() -> Tab? {
        if case .webTab(let tab) = currentContent {
            return tab
        }
        return nil
    }
    
    private func handleSidebarSelection(_ item: SidebarItem) {
        selectedSidebarItem = item
        
        switch item {
        case .settingsSearchEngine:
            currentContent = .settingsSearchEngine
        case .settingsStealth:
            currentContent = .settingsStealth
        case .tab(let tabId):
            if let tab = viewModel.tabs.first(where: { $0.id == tabId }) {
                currentContent = .webTab(tab)
                viewModel.selectTab(at: viewModel.tabs.firstIndex(where: { $0.id == tabId }) ?? 0)
            }
        default:
            currentContent = .noSelection
        }
    }
    
    private func handleAddressSubmit() {
        isAddressBarFocused = false
        
        if let url = createURL(from: addressText) {
            if case .webTab(let currentTab) = currentContent {
                currentTab.url = url
            } else {
                // Create new tab and navigate to it
                let newTab = viewModel.createNewWebTab(with: url)
                selectedSidebarItem = .tab(newTab.id)
                currentContent = .webTab(newTab)
            }
        }
    }
    
    private func createURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return nil
        }
        
        // Try as direct URL first
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        
        // Add https:// if it looks like a domain
        if trimmed.contains(".") && !trimmed.contains(" ") {
            if let url = URL(string: "https://\(trimmed)") {
                return url
            }
        }
        
        // Fall back to configured search engine
        let searchQuery = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchEngine = AppSettings.shared.defaultSearchEngine
        return URL(string: "\(searchEngine.searchURL)\(searchQuery)")
    }
    
    private func setupKeyboardShortcuts() {
        NotificationCenter.default.addObserver(
            forName: .newTab,
            object: nil,
            queue: .main
        ) { _ in
            let newTab = viewModel.createNewTab()
            selectedSidebarItem = .tab(newTab.id)
            currentContent = .webTab(newTab)
        }
        
        NotificationCenter.default.addObserver(
            forName: .closeTab,
            object: nil,
            queue: .main
        ) { _ in
            handleCloseTab()
        }
        
        NotificationCenter.default.addObserver(
            forName: .reload,
            object: nil,
            queue: .main
        ) { _ in
            if let webView = getCurrentWebView() {
                if getCurrentTab()?.isLoading == true {
                    webView.stopLoading()
                } else {
                    webView.reload()
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .focusAddressBar,
            object: nil,
            queue: .main
        ) { _ in
            isAddressBarFocused = true
        }
    }
    
    private func removeKeyboardShortcuts() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func handleCloseTab() {
        if case .webTab(let currentTab) = currentContent {
            if let index = viewModel.tabs.firstIndex(where: { $0.id == currentTab.id }) {
                viewModel.closeTab(at: index)
                
                // Select another tab or show no selection
                if viewModel.tabs.isEmpty {
                    selectedSidebarItem = nil
                    currentContent = .noSelection
                } else {
                    let newIndex = min(index, viewModel.tabs.count - 1)
                    let newTab = viewModel.tabs[newIndex]
                    selectedSidebarItem = .tab(newTab.id)
                    currentContent = .webTab(newTab)
                    viewModel.selectTab(at: newIndex)
                }
            }
        }
        
        // Close window if no tabs left
        if viewModel.tabs.isEmpty {
            if let window = NSApp.keyWindow {
                window.close()
            }
        }
    }
}

// MARK: - Hierarchical Sidebar

struct HierarchicalSidebarView: View {
    @Bindable var viewModel: BrowserViewModel
    @Binding var selectedItem: SidebarItem?
    let onSelectionChange: (SidebarItem) -> Void
    
    @State private var settingsExpanded = true
    @State private var tabsExpanded = true
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // SETTINGS Section
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
                
                // TABS Section
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
                        onCloseTab: { tab in
                            if let index = viewModel.tabs.firstIndex(where: { $0.id == tab.id }) {
                                viewModel.closeTab(at: index)
                            }
                        }
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
    @State private var generalGroupExpanded = true
    @State private var extensionsGroupExpanded = true
    
    var body: some View {
        VStack(spacing: 0) {
            // General Group Header (non-clickable)
            SidebarGroupHeaderView(
                title: "General",
                isExpanded: $generalGroupExpanded
            )
            
            if generalGroupExpanded {
                SidebarRowView(
                    icon: "magnifyingglass",
                    title: "Search Engine",
                    isSelected: selectedItem == .settingsSearchEngine,
                    onSelect: { onSelectionChange(.settingsSearchEngine) },
                    indentLevel: 2
                )
            }
            
            // Extensions Group Header (non-clickable)
            SidebarGroupHeaderView(
                title: "Extensions",
                isExpanded: $extensionsGroupExpanded
            )
            
            if extensionsGroupExpanded {
                SidebarRowView(
                    icon: "eye.slash",
                    title: "Stealth",
                    isSelected: selectedItem == .settingsStealth,
                    onSelect: { onSelectionChange(.settingsStealth) },
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

// MARK: - New Group Header View (Non-clickable)

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
        .padding(.horizontal, 32) // Level 1 indentation under SETTINGS
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
        return 16 + CGFloat(indentLevel) * 16 // Base 16 + 16 per level
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
        .padding(.horizontal, 32) // Level 1 indentation under TABS
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
                // Handle duplication
            }
            
            Divider()
            
            Button("Close Other Tabs") {
                // Handle closing other tabs
            }
        }
    }
}

// MARK: - Settings Views

struct SettingsSearchEngineView: View {
    @State private var settings = AppSettings.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Search Engine")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Choose your default search engine and configure search preferences.")
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Default Search Engine")
                        .font(.headline)
                    
                    Picker("Search Engine", selection: $settings.defaultSearchEngine) {
                        ForEach(SearchEngine.allCases) { engine in
                            Text(engine.name).tag(engine)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SettingsStealthView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Stealth Mode")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Configure privacy and stealth features to protect your browsing.")
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox("Privacy Protection") {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Block tracking cookies", isOn: .constant(true))
                            Toggle("Hide browser fingerprint", isOn: .constant(false))
                            Toggle("Clear browsing data on exit", isOn: .constant(false))
                        }
                        .padding(.vertical, 4)
                    }
                    
                    GroupBox("Window Management") {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Hide from Dock when minimized", isOn: .constant(false))
                            Toggle("Stealth window cloaking", isOn: .constant(false))
                            Toggle("Disable window screenshots", isOn: .constant(true))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

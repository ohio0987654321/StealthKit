import SwiftUI
import WebKit
import AppKit

struct BrowserView: View {
    @State private var viewModel = BrowserViewModel()
    @State private var addressText: String = ""
    @FocusState private var isAddressBarFocused: Bool
    @State private var currentWebView: WKWebView?
    @State private var selectedSidebarItem: SidebarItem? = nil
    @State private var currentContent: ContentType = .welcome
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationSplitView {
            HierarchicalSidebarView(
                viewModel: viewModel,
                selectedItem: $selectedSidebarItem,
                onSelectionChange: handleSidebarSelection,
                onCloseTab: handleCloseSpecificTab
            )
            .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 350)
        } detail: {
            VStack(spacing: 0) {
                // Tab bar
                if !viewModel.tabs.isEmpty {
                    TabBarView(
                        tabs: viewModel.tabs,
                        selectedTabId: getCurrentTab()?.id,
                        onTabSelect: handleTabSelection,
                        onTabClose: handleCloseSpecificTab
                    )
                }
                
                // Main content area
                ZStack {
                switch currentContent {
                case .settingsSearchEngine:
                    SettingsSearchEngineView()
                case .settingsWindowUtilities:
                    SettingsWindowUtilitiesView()

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
                    .id(tab.id)
                case .welcome:
                    WelcomeView(onCreateNewTab: {
                        let newTab = viewModel.createNewTab()
                        selectedSidebarItem = .tab(newTab.id)
                        currentContent = .webTab(newTab)
                        currentWebView = nil
                        addressText = ""
                    })
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    HStack(spacing: UITheme.Spacing.xs) {
                        ThemedToolbarButton(
                            icon: "chevron.left",
                            isDisabled: !(getCurrentTab()?.canGoBack ?? false) || !isWebContentActive()
                        ) {
                            if let webView = getCurrentWebView() {
                                webView.goBack()
                            }
                        }
                        
                        ThemedToolbarButton(
                            icon: "chevron.right",
                            isDisabled: !(getCurrentTab()?.canGoForward ?? false) || !isWebContentActive()
                        ) {
                            if let webView = getCurrentWebView() {
                                webView.goForward()
                            }
                        }
                        
                        ThemedToolbarButton(
                            icon: getCurrentTab()?.isLoading == true ? "xmark" : "arrow.clockwise",
                            isDisabled: !isWebContentActive()
                        ) {
                            if let webView = getCurrentWebView() {
                                if getCurrentTab()?.isLoading == true {
                                    webView.stopLoading()
                                } else {
                                    webView.reload()
                                }
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    HStack(spacing: UITheme.Spacing.small) {
                        TextField("Enter URL or search", text: $addressText)
                            .textFieldStyle(.roundedBorder)
                            .font(UITheme.Typography.addressBar)
                            .focused($isAddressBarFocused)
                            .onSubmit {
                                handleAddressSubmit()
                            }
                            .onChange(of: getCurrentTab()?.url) { _, newURL in
                                if !isAddressBarFocused && isWebContentActive() {
                                    addressText = newURL?.absoluteString ?? ""
                                }
                            }
                            .frame(minWidth: 300, maxWidth: 300)
                            .layoutPriority(1)
                        
                        ThemedToolbarButton(
                            icon: "plus"
                        ) {
                            let newTab = viewModel.createNewTab()
                            selectedSidebarItem = .tab(newTab.id)
                            currentContent = .webTab(newTab)
                            currentWebView = nil
                            addressText = ""
                        }
                    }
                }
            }
            }
        }
        .navigationSplitViewStyle(.prominentDetail)

        .frame(minWidth: 900, minHeight: 600)
        .managedWindow()
        .onAppear {
            setupKeyboardShortcuts()
            setupWindowManager()
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
    
    private func isWebContentActive() -> Bool {
        if case .webTab = currentContent {
            return true
        }
        return false
    }
    
    private func handleTabSelection(_ tabId: UUID) {
        if let tab = viewModel.tabs.first(where: { $0.id == tabId }) {
            selectedSidebarItem = .tab(tabId)
            currentContent = .webTab(tab)
            viewModel.selectTab(at: viewModel.tabs.firstIndex(where: { $0.id == tabId }) ?? 0)
            addressText = tab.url?.absoluteString ?? ""
        }
    }
    
    private func handleSidebarSelection(_ item: SidebarItem) {
        selectedSidebarItem = item
        
        switch item {
        case .settingsSearchEngine:
            currentContent = .settingsSearchEngine
            currentWebView = nil
        case .settingsWindowUtilities:
            currentContent = .settingsWindowUtilities
            currentWebView = nil
        case .tab(let tabId):
            if let tab = viewModel.tabs.first(where: { $0.id == tabId }) {
                currentContent = .webTab(tab)
                viewModel.selectTab(at: viewModel.tabs.firstIndex(where: { $0.id == tabId }) ?? 0)
                addressText = tab.url?.absoluteString ?? ""
            }
        }
    }
    
    private func handleAddressSubmit() {
        isAddressBarFocused = false
        
        if let url = createURL(from: addressText) {
            if case .webTab(let currentTab) = currentContent {
                currentTab.url = url
                if let webView = getCurrentWebView() {
                    webView.load(URLRequest(url: url))
                }
            } else {
                let newTab = viewModel.createNewTab(with: url)
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
        
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        
        if trimmed.contains(".") && !trimmed.contains(" ") {
            if let url = URL(string: "https://\(trimmed)") {
                return url
            }
        }
        
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
            currentWebView = nil
            addressText = ""
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
    
    private func setupWindowManager() {
        // Initialize the unified window service
        _ = WindowService.shared
    }
    
    private func handleCloseTab() {
        if case .webTab(let currentTab) = currentContent {
            if let index = viewModel.tabs.firstIndex(where: { $0.id == currentTab.id }) {
                viewModel.closeTab(at: index)
                
                if viewModel.tabs.isEmpty {
                    selectedSidebarItem = nil
                    currentContent = .welcome
                    currentWebView = nil
                    addressText = ""
                } else {
                    let newIndex = min(index, viewModel.tabs.count - 1)
                    let newTab = viewModel.tabs[newIndex]
                    selectedSidebarItem = .tab(newTab.id)
                    currentContent = .webTab(newTab)
                    addressText = newTab.url?.absoluteString ?? ""
                    viewModel.selectTab(at: newIndex)
                }
            }
        } else if case .welcome = currentContent {
            // If we're on the Welcome page and Cmd+W is pressed, close the window
            if let window = NSApp.keyWindow {
                window.close()
            }
        }
    }
    
    private func handleCloseSpecificTab(_ tab: Tab) {
        if let index = viewModel.tabs.firstIndex(where: { $0.id == tab.id }) {
            viewModel.closeTab(at: index)
            
            if viewModel.tabs.isEmpty {
                selectedSidebarItem = nil
                currentContent = .welcome
                currentWebView = nil
            } else {
                if case .webTab(let currentTab) = currentContent, currentTab.id == tab.id {
                    let newIndex = min(index, viewModel.tabs.count - 1)
                    let newTab = viewModel.tabs[newIndex]
                    selectedSidebarItem = .tab(newTab.id)
                    currentContent = .webTab(newTab)
                    addressText = newTab.url?.absoluteString ?? ""
                    viewModel.selectTab(at: newIndex)
                }
            }
        }
    }
}

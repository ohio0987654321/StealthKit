import SwiftUI
import WebKit
import AppKit

struct BrowserView: View {
    @State private var viewModel = BrowserViewModel()
    @State private var addressText: String = ""
    @FocusState private var isAddressBarFocused: Bool
    @State private var currentWebView: WKWebView?
    @State private var selectedSidebarItem: SidebarItem? = nil
    @State private var currentTab: Tab? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationSplitView {
            HierarchicalSidebarView(
                viewModel: viewModel,
                selectedItem: $selectedSidebarItem,
                onSelectionChange: handleSidebarSelection,
                onCloseTab: handleCloseSpecificTab
            )
            .navigationSplitViewColumnWidth(min: UIConstants.Sidebar.minWidth, ideal: UIConstants.Sidebar.idealWidth, max: UIConstants.Sidebar.maxWidth)
        } detail: {
            VStack(spacing: 0) {
                // Tab bar
                if !viewModel.tabs.isEmpty {
                    TabBarView(
                        tabs: viewModel.tabs,
                        selectedTabId: currentTab?.id,
                        onTabSelect: handleTabSelection,
                        onTabClose: handleCloseSpecificTab
                    )
                }
                
                // Main content area
                ZStack {
                    if let tab = currentTab {
                        switch tab.tabType {
                        case .empty:
                            EmptyTabView()
                                .id(tab.id)
                        case .web:
                            WebView(
                                tab: .constant(tab),
                                onNavigationChange: { updatedTab in
                                    if let index = viewModel.tabs.firstIndex(where: { $0.id == updatedTab.id }) {
                                        viewModel.tabs[index] = updatedTab
                                        currentTab = updatedTab
                                    }
                                },
                                onWebViewCreated: { webView in
                                    currentWebView = webView
                                }
                            )
                            .id(tab.id)
                        case .settings(let settingsType):
                            switch settingsType {
                            case .browserUtilities:
                                SettingsBrowserUtilitiesView()
                            case .windowUtilities:
                                SettingsWindowUtilitiesView()
                            case .securityPrivacy:
                                SettingsSecurityPrivacyView()
                            case .history:
                                HistoryView()
                            case .cookies:
                                CookieManagementView()
                            case .welcome:
                                WelcomeView()
                            }
                        }
                    } else {
                        // No tabs - show welcome as fallback
                        WelcomeView()
                    }
                }
                .navigationTitle("")
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        HStack(spacing: UIConstants.Spacing.medium) {
                            ThemedToolbarButton(
                                icon: "chevron.left",
                                isDisabled: !(currentTab?.canGoBack ?? false) || !isWebContentActive()
                            ) {
                                if let webView = getCurrentWebView() {
                                    webView.goBack()
                                }
                            }
                            
                            ThemedToolbarButton(
                                icon: "chevron.right",
                                isDisabled: !(currentTab?.canGoForward ?? false) || !isWebContentActive()
                            ) {
                                if let webView = getCurrentWebView() {
                                    webView.goForward()
                                }
                            }
                            
                            ThemedToolbarButton(
                                icon: currentTab?.isLoading == true ? "xmark" : "arrow.clockwise",
                                isDisabled: !isWebContentActive()
                            ) {
                                if let webView = getCurrentWebView() {
                                    if currentTab?.isLoading == true {
                                        webView.stopLoading()
                                    } else {
                                        webView.reload()
                                    }
                                }
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        TextField("Enter URL or search", text: $addressText)
                            .textFieldStyle(.roundedBorder)
                            .font(UITheme.Typography.addressBar)
                            .focused($isAddressBarFocused)
                            .onSubmit {
                                handleAddressSubmit()
                            }
                            .onChange(of: currentTab?.url) { _, newURL in
                                if !isAddressBarFocused && isWebContentActive() {
                                    addressText = newURL?.absoluteString ?? ""
                                }
                            }
                            .frame(minWidth: UIConstants.AddressBar.minWidth, maxWidth: UIConstants.AddressBar.maxWidth)
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        ThemedToolbarButton(
                            icon: "plus"
                        ) {
                            let newTab = viewModel.createNewTab()
                            selectedSidebarItem = .tab(newTab.id)
                            currentTab = newTab
                            currentWebView = nil
                            addressText = ""
                        }
                    }
                }
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .frame(minWidth: UIConstants.Window.minWidth, minHeight: UIConstants.Window.minHeight)
        .managedWindow()
        .onAppear {
            setupKeyboardShortcuts()
            setupWindowManager()
            // Initialize with welcome tab if no tabs exist
            if viewModel.tabs.isEmpty {
                let welcomeTab = Tab(settingsType: .welcome)
                viewModel.tabs.append(welcomeTab)
                currentTab = welcomeTab
                selectedSidebarItem = .tab(welcomeTab.id)
            } else if let firstTab = viewModel.tabs.first {
                currentTab = firstTab
                selectedSidebarItem = .tab(firstTab.id)
            }
        }
        .onDisappear {
            removeKeyboardShortcuts()
        }
    }
    
    private func getCurrentWebView() -> WKWebView? {
        return currentWebView
    }
    
    private func isWebContentActive() -> Bool {
        if let tab = currentTab,
           case .web = tab.tabType {
            return true
        }
        return false
    }
    
    private func handleTabSelection(_ tabId: UUID) {
        if let tab = viewModel.tabs.first(where: { $0.id == tabId }) {
            // Set sidebar selection based on tab type
            switch tab.tabType {
            case .empty:
                selectedSidebarItem = .tab(tabId)
            case .web:
                selectedSidebarItem = .tab(tabId)
            case .settings(let settingsType):
                switch settingsType {
                case .browserUtilities:
                    selectedSidebarItem = .settingsBrowserUtilities
                case .windowUtilities:
                    selectedSidebarItem = .settingsWindowUtilities
                case .securityPrivacy:
                    selectedSidebarItem = .settingsSecurityPrivacy
                case .history:
                    selectedSidebarItem = .settingsHistory
                case .cookies:
                    selectedSidebarItem = .settingsCookies
                case .welcome:
                    selectedSidebarItem = .tab(tabId)
                }
            }
            
            currentTab = tab
            viewModel.selectTab(at: viewModel.tabs.firstIndex(where: { $0.id == tabId }) ?? 0)
            addressText = tab.url?.absoluteString ?? ""
        }
    }
    
    private func handleSidebarSelection(_ item: SidebarItem) {
        selectedSidebarItem = item
        
        switch item {
        case .settingsBrowserUtilities:
            let tab = viewModel.createSettingsTab(type: .browserUtilities)
            currentTab = tab
            currentWebView = nil
            addressText = ""
        case .settingsWindowUtilities:
            let tab = viewModel.createSettingsTab(type: .windowUtilities)
            currentTab = tab
            currentWebView = nil
            addressText = ""
        case .settingsSecurityPrivacy:
            let tab = viewModel.createSettingsTab(type: .securityPrivacy)
            currentTab = tab
            currentWebView = nil
            addressText = ""
        case .settingsHistory:
            let tab = viewModel.createSettingsTab(type: .history)
            currentTab = tab
            currentWebView = nil
            addressText = ""
        case .settingsCookies:
            let tab = viewModel.createSettingsTab(type: .cookies)
            currentTab = tab
            currentWebView = nil
            addressText = ""
        case .tab(let tabId):
            if let tab = viewModel.tabs.first(where: { $0.id == tabId }) {
                currentTab = tab
                viewModel.selectTab(at: viewModel.tabs.firstIndex(where: { $0.id == tabId }) ?? 0)
                addressText = tab.url?.absoluteString ?? ""
            }
        }
    }
    
    private func handleAddressSubmit() {
        isAddressBarFocused = false
        
        if let url = createURL(from: addressText) {
            // If current tab is empty or settings, convert it to a web tab
            if let tab = currentTab {
                if case .empty = tab.tabType {
                    // Convert empty tab to web tab
                    let newWebTab = Tab(url: url)
                    if let index = viewModel.tabs.firstIndex(where: { $0.id == tab.id }) {
                        viewModel.tabs[index] = newWebTab
                        currentTab = newWebTab
                        selectedSidebarItem = .tab(newWebTab.id)
                    }
                } else if case .settings = tab.tabType {
                    // Convert settings tab to web tab
                    let newWebTab = Tab(url: url)
                    if let index = viewModel.tabs.firstIndex(where: { $0.id == tab.id }) {
                        viewModel.tabs[index] = newWebTab
                        currentTab = newWebTab
                        selectedSidebarItem = .tab(newWebTab.id)
                    }
                } else {
                    // Current tab is already a web tab, just navigate
                    tab.url = url
                    if let webView = getCurrentWebView() {
                        webView.load(URLRequest(url: url))
                    }
                }
            } else {
                // No current tab, create a new one
                let newTab = viewModel.createNewTab(with: url)
                selectedSidebarItem = .tab(newTab.id)
                currentTab = newTab
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
            currentTab = newTab
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
                if currentTab?.isLoading == true {
                    webView.stopLoading()
                } else {
                    webView.reload()
                }
            }
        }
        
        // ⌘L shortcut functionality removed for simplification
    }
    
    private func removeKeyboardShortcuts() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupWindowManager() {
        // Initialize the unified window service
        _ = WindowService.shared
    }
    
    private func handleCloseTab() {
        if let tab = currentTab {
            if let index = viewModel.tabs.firstIndex(where: { $0.id == tab.id }) {
                viewModel.closeTab(at: index)
                
                if viewModel.tabs.isEmpty {
                    // Create a new welcome tab when all tabs are closed
                    let welcomeTab = Tab(settingsType: .welcome)
                    viewModel.tabs.append(welcomeTab)
                    selectedSidebarItem = .tab(welcomeTab.id)
                    currentTab = welcomeTab
                    currentWebView = nil
                    addressText = ""
                } else {
                    let newIndex = min(index, viewModel.tabs.count - 1)
                    let newTab = viewModel.tabs[newIndex]
                    selectedSidebarItem = .tab(newTab.id)
                    currentTab = newTab
                    addressText = newTab.url?.absoluteString ?? ""
                    viewModel.selectTab(at: newIndex)
                }
            }
        }
    }
    
    private func handleCloseSpecificTab(_ tab: Tab) {
        if let index = viewModel.tabs.firstIndex(where: { $0.id == tab.id }) {
            viewModel.closeTab(at: index)
            
            if viewModel.tabs.isEmpty {
                // Create a new welcome tab when all tabs are closed
                let welcomeTab = Tab(settingsType: .welcome)
                viewModel.tabs.append(welcomeTab)
                selectedSidebarItem = .tab(welcomeTab.id)
                currentTab = welcomeTab
                currentWebView = nil
            } else {
                if currentTab?.id == tab.id {
                    let newIndex = min(index, viewModel.tabs.count - 1)
                    let newTab = viewModel.tabs[newIndex]
                    selectedSidebarItem = .tab(newTab.id)
                    currentTab = newTab
                    addressText = newTab.url?.absoluteString ?? ""
                    viewModel.selectTab(at: newIndex)
                }
            }
        }
    }
}

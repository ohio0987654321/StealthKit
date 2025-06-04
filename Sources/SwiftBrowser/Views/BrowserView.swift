import SwiftUI
import WebKit
import AppKit

struct BrowserView: View {
    @State private var tabManager = TabManager()
    @State private var addressText: String = ""
    @FocusState private var isAddressBarFocused: Bool
    @State private var currentWebView: WKWebView?
    @State private var selectedSidebarItem: SidebarItem? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationSplitView {
            HierarchicalSidebarView(
                tabManager: tabManager,
                selectedItem: $selectedSidebarItem,
                onSelectionChange: handleSidebarSelection,
                onCloseTab: handleCloseSpecificTab
            )
            .navigationSplitViewColumnWidth(min: UIConstants.Sidebar.minWidth, ideal: UIConstants.Sidebar.idealWidth, max: UIConstants.Sidebar.maxWidth)
        } detail: {
            VStack(spacing: 0) {
                // Tab bar
                if !tabManager.tabs.isEmpty {
                    TabBarView(
                        tabs: tabManager.tabs,
                        selectedTabId: tabManager.currentTab?.id,
                        onTabSelect: handleTabSelection,
                        onTabClose: handleCloseSpecificTab
                    )
                }
                
                // Main content area
                ZStack {
                    if let tab = tabManager.currentTab {
                        switch tab.tabType {
                        case .empty:
                            EmptyTabView()
                                .id(tab.id)
                        case .web:
                            WebView(
                                tab: .constant(tab),
                                onNavigationChange: { updatedTab in
                                    tabManager.updateTab(updatedTab)
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
                        WelcomeView()
                    }
                }
                .navigationTitle("")
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        BrowserNavigationButtons(
                            currentTab: .constant(tabManager.currentTab),
                            onNavigateBack: {
                                currentWebView?.goBack()
                            },
                            onNavigateForward: {
                                currentWebView?.goForward()
                            },
                            onReloadOrStop: {
                                if let webView = currentWebView {
                                    if tabManager.currentTab?.isLoading == true {
                                        webView.stopLoading()
                                    } else {
                                        webView.reload()
                                    }
                                }
                            },
                            isWebContentActive: tabManager.isWebContentActive(for: tabManager.currentTab)
                        )
                    }
                    
                    ToolbarItem(placement: .principal) {
                        BrowserAddressField(
                            addressText: $addressText,
                            isAddressBarFocused: $isAddressBarFocused,
                            currentTab: .constant(tabManager.currentTab),
                            onSubmit: handleAddressSubmit,
                            isWebContentActive: tabManager.isWebContentActive(for: tabManager.currentTab)
                        )
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        BrowserNewTabButton {
                            let newTab = tabManager.createNewTab()
                            selectedSidebarItem = .tab(newTab.id)
                            currentWebView = nil
                            addressText = ""
                        }
                    }
                }
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .frame(minWidth: UIConstants.Window.minWidth, minHeight: UIConstants.Window.minHeight)
        .onAppear {
            setupKeyboardShortcuts()
            setupWindowManager()
            tabManager.ensureWelcomeTab()
            updateUIFromCurrentTab()
        }
        .onDisappear {
            removeKeyboardShortcuts()
        }
        .onChange(of: tabManager.currentTab) { _, newTab in
            updateUIFromCurrentTab()
        }
    }
    
    private func updateUIFromCurrentTab() {
        if let tab = tabManager.currentTab {
            selectedSidebarItem = .tab(tab.id)
            addressText = tab.url?.absoluteString ?? ""
        }
    }
    
    private func handleTabSelection(_ tabId: UUID) {
        tabManager.selectTab(withId: tabId)
        currentWebView = nil // Reset web view reference when switching tabs
    }
    
    private func handleSidebarSelection(_ item: SidebarItem) {
        selectedSidebarItem = item
        
        switch item {
        case .settingsBrowserUtilities:
            tabManager.createSettingsTab(type: .browserUtilities)
            currentWebView = nil
            addressText = ""
        case .settingsWindowUtilities:
            tabManager.createSettingsTab(type: .windowUtilities)
            currentWebView = nil
            addressText = ""
        case .settingsSecurityPrivacy:
            tabManager.createSettingsTab(type: .securityPrivacy)
            currentWebView = nil
            addressText = ""
        case .settingsHistory:
            tabManager.createSettingsTab(type: .history)
            currentWebView = nil
            addressText = ""
        case .settingsCookies:
            tabManager.createSettingsTab(type: .cookies)
            currentWebView = nil
            addressText = ""
        case .tab(let tabId):
            tabManager.selectTab(withId: tabId)
            currentWebView = nil
        }
        
        updateUIFromCurrentTab()
    }
    
    private func handleAddressSubmit() {
        isAddressBarFocused = false
        
        guard let url = tabManager.createURL(from: addressText) else { return }
        
        if let currentTab = tabManager.currentTab {
            if case .empty = currentTab.tabType {
                // Convert empty tab to web tab
                let newWebTab = Tab(url: url)
                tabManager.replaceCurrentTab(with: newWebTab)
                selectedSidebarItem = .tab(newWebTab.id)
                currentWebView = nil // Reset web view to force recreation
            } else if case .settings = currentTab.tabType {
                // Convert settings tab to web tab
                let newWebTab = Tab(url: url)
                tabManager.replaceCurrentTab(with: newWebTab)
                selectedSidebarItem = .tab(newWebTab.id)
                currentWebView = nil // Reset web view to force recreation
            } else {
                // Navigate current web tab
                currentTab.url = url
                currentWebView?.load(URLRequest(url: url))
            }
        } else {
            // Create new tab
            let newTab = tabManager.createNewTab(with: url)
            selectedSidebarItem = .tab(newTab.id)
            currentWebView = nil
        }
    }
    
    private func setupKeyboardShortcuts() {
        NotificationCenter.default.addObserver(
            forName: .newTab,
            object: nil,
            queue: .main
        ) { _ in
            let newTab = tabManager.createNewTab()
            selectedSidebarItem = .tab(newTab.id)
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
            if let webView = currentWebView {
                if tabManager.currentTab?.isLoading == true {
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
        _ = WindowService.shared
    }
    
    private func handleCloseTab() {
        tabManager.closeCurrentTab()
        
        if tabManager.tabs.isEmpty {
            tabManager.ensureWelcomeTab()
        }
        
        currentWebView = nil
        updateUIFromCurrentTab()
    }
    
    private func handleCloseSpecificTab(_ tab: Tab) {
        let wasCurrentTab = tabManager.currentTab?.id == tab.id
        tabManager.closeTab(withId: tab.id)
        
        if tabManager.tabs.isEmpty {
            tabManager.ensureWelcomeTab()
        }
        
        if wasCurrentTab {
            currentWebView = nil
        }
        
        updateUIFromCurrentTab()
    }
}

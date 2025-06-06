import Foundation
import SwiftUI
import WebKit

class BrowserCoordinator: NavigationCoordinatorProtocol {
    var childCoordinators: [CoordinatorProtocol] = []
    weak var parentCoordinator: CoordinatorProtocol?
    
    private let tabService = TabService.shared
    private var currentWebView: WKWebView?
    private var closedTabs: [Tab] = [] // Track closed tabs
    
    // Events for communication with views
    @Published var shouldFocusAddressBar = false
    @Published var selectedSidebarItem: SidebarItem?
    
    func start() {
        tabService.ensureWelcomeTab()
        updateSelectedSidebarItem()
    }
    
    // MARK: - NavigationCoordinatorProtocol
    func navigateToTab(with url: URL?) {
        if let currentTab = tabService.currentTab {
            if case .empty = currentTab.tabType {
                // Convert empty tab to web tab
                let newWebTab = Tab(url: url)
                tabService.replaceCurrentTab(with: newWebTab)
                selectedSidebarItem = nil
                currentWebView = nil
            } else if case .settings = currentTab.tabType {
                // Convert settings tab to web tab
                let newWebTab = Tab(url: url)
                tabService.replaceCurrentTab(with: newWebTab)
                selectedSidebarItem = nil
                currentWebView = nil
            } else if let url = url {
                // Navigate current web tab
                currentTab.url = url
                currentWebView?.load(URLRequest(url: url))
            }
        } else if let url = url {
            // Create new tab
            let newTab = tabService.createTab(with: url)
            selectedSidebarItem = nil
            currentWebView = nil
        }
    }
    
    func navigateToSettings(_ settingsType: SettingsType) {
        tabService.createSettingsTab(type: settingsType)
        currentWebView = nil
        updateSelectedSidebarItem()
    }
    
    func closeTab(withId tabId: UUID) {
        // Find and save the tab before closing it (all tab types)
        if let tabToClose = tabService.tabs.first(where: { $0.id == tabId }) {
            closedTabs.append(tabToClose)
            // Keep only the last 10 closed tabs
            if closedTabs.count > 10 {
                closedTabs.removeFirst()
            }
        }
        
        let wasCurrentTab = tabService.currentTab?.id == tabId
        tabService.closeTab(withId: tabId)
        
        if tabService.tabs.isEmpty {
            tabService.ensureWelcomeTab()
        }
        
        if wasCurrentTab {
            currentWebView = nil
        }
        
        updateSelectedSidebarItem()
    }
    
    @discardableResult
    func createNewTab() -> UUID {
        let newTab = tabService.createTab()
        selectedSidebarItem = nil
        currentWebView = nil
        return newTab.id
    }
    
    // MARK: - Tab Management
    func selectTab(withId tabId: UUID) {
        tabService.selectTab(withId: tabId)
        // Don't reset currentWebView - let the new WebView update it
        updateSelectedSidebarItem()
    }
    
    func closeCurrentTab() {
        // Save current tab before closing (all tab types)
        if let currentTab = tabService.currentTab {
            closedTabs.append(currentTab)
            // Keep only the last 10 closed tabs
            if closedTabs.count > 10 {
                closedTabs.removeFirst()
            }
        }
        
        tabService.closeCurrentTab()
        
        if tabService.tabs.isEmpty {
            tabService.ensureWelcomeTab()
        }
        
        // Only reset currentWebView if no tabs remain
        if tabService.tabs.isEmpty {
            currentWebView = nil
        }
        updateSelectedSidebarItem()
    }
    
    func reloadCurrentTab() {
        if let webView = currentWebView {
            if tabService.currentTab?.isLoading == true {
                webView.stopLoading()
            } else {
                webView.reload()
            }
        }
    }
    
    func focusAddressBar() {
        shouldFocusAddressBar = true
    }
    
    func reopenClosedTab() {
        guard let lastClosedTab = closedTabs.popLast() else { return }
        
        // Create new tab based on the closed tab's type
        let newTab: Tab
        switch lastClosedTab.tabType {
        case .empty:
            newTab = tabService.createTab()
        case .web:
            newTab = tabService.createTab(with: lastClosedTab.url)
        case .settings(let settingsType):
            newTab = tabService.createSettingsTab(type: settingsType)
        }
        
        // Restore the original title
        newTab.title = lastClosedTab.title
        
        selectedSidebarItem = nil
        currentWebView = nil
    }
    
    func selectNextTab() {
        let tabs = tabService.tabs
        guard let currentTab = tabService.currentTab,
              let currentIndex = tabs.firstIndex(where: { $0.id == currentTab.id }) else { return }
        
        let nextIndex = (currentIndex + 1) % tabs.count
        selectTab(withId: tabs[nextIndex].id)
    }
    
    func selectPreviousTab() {
        let tabs = tabService.tabs
        guard let currentTab = tabService.currentTab,
              let currentIndex = tabs.firstIndex(where: { $0.id == currentTab.id }) else { return }
        
        let previousIndex = currentIndex > 0 ? currentIndex - 1 : tabs.count - 1
        selectTab(withId: tabs[previousIndex].id)
    }
    
    func selectTab(at index: Int) {
        let tabs = tabService.tabs
        guard index >= 0 && index < tabs.count else { return }
        selectTab(withId: tabs[index].id)
    }
    
    // MARK: - WebView Management
    func setCurrentWebView(_ webView: WKWebView) {
        currentWebView = webView
    }
    
    func navigateBack() {
        currentWebView?.goBack()
    }
    
    func navigateForward() {
        currentWebView?.goForward()
    }
    
    // MARK: - Sidebar Management
    func handleSidebarSelection(_ item: SidebarItem) {
        selectedSidebarItem = item
        
        switch item {
        case .settingsBrowserUtilities:
            navigateToSettings(.browserUtilities)
        case .settingsWindowUtilities:
            navigateToSettings(.windowUtilities)
        case .settingsSecurityPrivacy:
            navigateToSettings(.securityPrivacy)
        case .settingsHistory:
            navigateToSettings(.history)
        case .settingsCookies:
            navigateToSettings(.cookies)
        case .settingsDownloads:
            navigateToSettings(.downloads)
        }
    }
    
    private func updateSelectedSidebarItem() {
        // Sidebar only tracks settings now, not tabs
        // Clear selection when switching to web content
        if let currentTab = tabService.currentTab {
            switch currentTab.tabType {
            case .settings(let settingsType):
                // Keep settings selection when showing settings
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
                case .downloads:
                    selectedSidebarItem = .settingsDownloads
                case .welcome:
                    selectedSidebarItem = nil
                }
            case .web, .empty:
                // Clear sidebar selection for web content
                selectedSidebarItem = nil
            }
        }
    }
    
    // MARK: - URL Creation
    func createURL(from text: String) -> URL? {
        return tabService.createURL(from: text)
    }
}

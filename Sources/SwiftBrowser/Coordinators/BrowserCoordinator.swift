import Foundation
import SwiftUI
import WebKit

class BrowserCoordinator: NavigationCoordinatorProtocol {
    var childCoordinators: [CoordinatorProtocol] = []
    weak var parentCoordinator: CoordinatorProtocol?
    
    private let tabService = TabService.shared
    private var currentWebView: WKWebView?
    
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
                selectedSidebarItem = .tab(newWebTab.id)
                currentWebView = nil
            } else if case .settings = currentTab.tabType {
                // Convert settings tab to web tab
                let newWebTab = Tab(url: url)
                tabService.replaceCurrentTab(with: newWebTab)
                selectedSidebarItem = .tab(newWebTab.id)
                currentWebView = nil
            } else if let url = url {
                // Navigate current web tab
                currentTab.url = url
                currentWebView?.load(URLRequest(url: url))
            }
        } else if let url = url {
            // Create new tab
            let newTab = tabService.createTab(with: url)
            selectedSidebarItem = .tab(newTab.id)
            currentWebView = nil
        }
    }
    
    func navigateToSettings(_ settingsType: SettingsType) {
        tabService.createSettingsTab(type: settingsType)
        currentWebView = nil
        updateSelectedSidebarItem()
    }
    
    func closeTab(withId tabId: UUID) {
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
        selectedSidebarItem = .tab(newTab.id)
        currentWebView = nil
        return newTab.id
    }
    
    // MARK: - Tab Management
    func selectTab(withId tabId: UUID) {
        tabService.selectTab(withId: tabId)
        currentWebView = nil // Reset web view reference when switching tabs
        updateSelectedSidebarItem()
    }
    
    func closeCurrentTab() {
        tabService.closeCurrentTab()
        
        if tabService.tabs.isEmpty {
            tabService.ensureWelcomeTab()
        }
        
        currentWebView = nil
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
        case .tab(let tabId):
            selectTab(withId: tabId)
        }
    }
    
    private func updateSelectedSidebarItem() {
        if let currentTab = tabService.currentTab {
            selectedSidebarItem = .tab(currentTab.id)
        }
    }
    
    // MARK: - URL Creation
    func createURL(from text: String) -> URL? {
        return tabService.createURL(from: text)
    }
}

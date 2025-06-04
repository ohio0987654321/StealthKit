import Foundation
import SwiftUI
import WebKit
import Combine

@Observable
class BrowserViewModel {
    let coordinator: BrowserCoordinator
    private let tabService = TabService.shared
    var cancellables = Set<AnyCancellable>()
    
    // UI State
    var addressText: String = ""
    var isAddressBarFocused: Bool = false
    var currentWebView: WKWebView?
    var selectedSidebarItem: SidebarItem?
    var showingDownloadOverlay: Bool = false
    var showingScreenshotOverlay: Bool = false
    
    // Computed Properties
    var currentTab: Tab? {
        tabService.currentTab
    }
    
    var tabs: [Tab] {
        tabService.tabs
    }
    
    var isWebContentActive: Bool {
        tabService.isWebContentActive(for: currentTab)
    }
    
    init(coordinator: BrowserCoordinator) {
        self.coordinator = coordinator
        setupObservers()
        updateUIFromCurrentTab()
    }
    
    private func setupObservers() {
        // Observe coordinator events
        coordinator.$shouldFocusAddressBar
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldFocus in
                if shouldFocus {
                    self?.isAddressBarFocused = true
                    self?.coordinator.shouldFocusAddressBar = false
                }
            }
            .store(in: &cancellables)
        
        coordinator.$selectedSidebarItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                self?.selectedSidebarItem = item
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Tab Management
    func handleTabSelection(_ tabId: UUID) {
        coordinator.selectTab(withId: tabId)
        // Don't reset currentWebView - it will be updated when the new WebView is created
        updateUIFromCurrentTab()
    }
    
    func handleNewTab() {
        let _ = coordinator.createNewTab()
        // Don't reset currentWebView here - it will be updated when the new WebView is created
        addressText = ""
        updateUIFromCurrentTab()
    }
    
    func handleCloseTab(_ tab: Tab) {
        coordinator.closeTab(withId: tab.id)
        updateUIFromCurrentTab()
    }
    
    func handleCloseCurrentTab() {
        coordinator.closeCurrentTab()
        updateUIFromCurrentTab()
    }
    
    func handleTabMove(from sourceIndex: Int, to destinationIndex: Int) {
        tabService.moveTab(from: IndexSet([sourceIndex]), to: destinationIndex)
        updateUIFromCurrentTab()
    }
    
    // MARK: - Navigation
    func handleAddressSubmit() {
        isAddressBarFocused = false
        
        guard let url = coordinator.createURL(from: addressText) else { return }
        coordinator.navigateToTab(with: url)
    }
    
    func handleNavigateBack() {
        coordinator.navigateBack()
    }
    
    func handleNavigateForward() {
        coordinator.navigateForward()
    }
    
    func handleReloadOrStop() {
        coordinator.reloadCurrentTab()
    }
    
    // MARK: - Sidebar
    func handleSidebarSelection(_ item: SidebarItem) {
        coordinator.handleSidebarSelection(item)
        currentWebView = nil
        addressText = ""
        updateUIFromCurrentTab()
    }
    
    // MARK: - WebView Management
    func handleWebViewCreated(_ webView: WKWebView) {
        currentWebView = webView
        coordinator.setCurrentWebView(webView)
    }
    
    func handleNavigationChange(_ updatedTab: Tab) {
        tabService.updateTab(updatedTab)
        updateUIFromCurrentTab()
    }
    
    // MARK: - State Updates
    func updateUIFromCurrentTab() {
        if let tab = currentTab {
            addressText = tab.url?.absoluteString ?? ""
            selectedSidebarItem = coordinator.selectedSidebarItem
        }
    }
    
    func onAppear() {
        coordinator.start()
        updateUIFromCurrentTab()
    }
    
    func onDisappear() {
        // Cleanup if needed
    }
    
    // MARK: - Download Management
    func toggleDownloadOverlay() {
        showingDownloadOverlay.toggle()
    }
    
    func hideDownloadOverlay() {
        showingDownloadOverlay = false
    }
    
    // MARK: - Screenshot Management
    func toggleScreenshotOverlay() {
        showingScreenshotOverlay.toggle()
    }
    
    func hideScreenshotOverlay() {
        showingScreenshotOverlay = false
    }
}

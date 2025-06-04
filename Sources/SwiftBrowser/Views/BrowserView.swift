import SwiftUI
import WebKit
import AppKit

struct BrowserView: View {
    @State private var viewModel: BrowserViewModel
    @FocusState private var isAddressBarFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    init() {
        let coordinator = BrowserCoordinator()
        _viewModel = State(initialValue: BrowserViewModel(coordinator: coordinator))
    }
    
    var body: some View {
        NavigationSplitView {
            HierarchicalSidebarView(
                tabs: viewModel.tabs,
                selectedItem: $viewModel.selectedSidebarItem,
                onSelectionChange: viewModel.handleSidebarSelection,
                onCloseTab: viewModel.handleCloseTab
            )
            .navigationSplitViewColumnWidth(min: UIConstants.Sidebar.minWidth, ideal: UIConstants.Sidebar.idealWidth, max: UIConstants.Sidebar.maxWidth)
        } detail: {
            VStack(spacing: 0) {
                // Tab bar
                if !viewModel.tabs.isEmpty {
                    TabBarView(
                        tabs: viewModel.tabs,
                        selectedTabId: viewModel.currentTab?.id,
                        onTabSelect: viewModel.handleTabSelection,
                        onTabClose: viewModel.handleCloseTab
                    )
                }
                
                // Main content area
                ZStack {
                    if let tab = viewModel.currentTab {
                        switch tab.tabType {
                        case .empty:
                            EmptyTabView()
                                .id(tab.id)
                        case .web:
                            WebView(
                                tab: .constant(tab),
                                onNavigationChange: viewModel.handleNavigationChange,
                                onWebViewCreated: viewModel.handleWebViewCreated
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
                            currentTab: .constant(viewModel.currentTab),
                            onNavigateBack: viewModel.handleNavigateBack,
                            onNavigateForward: viewModel.handleNavigateForward,
                            onReloadOrStop: viewModel.handleReloadOrStop,
                            isWebContentActive: viewModel.isWebContentActive
                        )
                    }
                    
                    ToolbarItem(placement: .principal) {
                        BrowserAddressField(
                            addressText: $viewModel.addressText,
                            isAddressBarFocused: $isAddressBarFocused,
                            currentTab: .constant(viewModel.currentTab),
                            onSubmit: viewModel.handleAddressSubmit,
                            isWebContentActive: viewModel.isWebContentActive
                        )
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        BrowserNewTabButton {
                            viewModel.handleNewTab()
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
            viewModel.onAppear()
        }
        .onDisappear {
            removeKeyboardShortcuts()
            viewModel.onDisappear()
        }
    }
    
    private func setupKeyboardShortcuts() {
        NotificationCenter.default.addObserver(
            forName: .newTab,
            object: nil,
            queue: .main
        ) { _ in
            viewModel.handleNewTab()
        }
        
        NotificationCenter.default.addObserver(
            forName: .closeTab,
            object: nil,
            queue: .main
        ) { _ in
            viewModel.handleCloseCurrentTab()
        }
        
        NotificationCenter.default.addObserver(
            forName: .reload,
            object: nil,
            queue: .main
        ) { _ in
            viewModel.handleReloadOrStop()
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
}

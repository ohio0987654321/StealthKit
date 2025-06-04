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
                        onTabClose: viewModel.handleCloseTab,
                        onTabMove: viewModel.handleTabMove
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
                            case .downloads:
                                DownloadManagementView()
                            case .welcome:
                                WelcomeView()
                            }
                        }
                    } else {
                        WelcomeView()
                    }
                    
                    // Download overlay - integrated within the main window
                    if viewModel.showingDownloadOverlay {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.hideDownloadOverlay()
                            }
                            .zIndex(999)
                        
                        VStack {
                            HStack {
                                Spacer()
                                DownloadPopover()
                                    .frame(width: UIConstants.DownloadPopover.width)
                                    .background(
                                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                                            .fill(Color(NSColor.controlBackgroundColor))
                                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                    )
                                    .padding(.trailing, 16)
                            }
                            Spacer()
                        }
                        .padding(.top, 8)
                        .zIndex(1000)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing)),
                            removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing))
                        ))
                        .animation(.easeInOut(duration: AnimationConstants.Timing.medium), value: viewModel.showingDownloadOverlay)
                    }
                    
                    // Screenshot overlay - integrated within the main window
                    if viewModel.showingScreenshotOverlay {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.hideScreenshotOverlay()
                            }
                            .zIndex(1001)
                        
                        VStack {
                            HStack {
                                Spacer()
                                ScreenshotPopover(onDismiss: viewModel.hideScreenshotOverlay)
                                    .frame(width: UIConstants.ScreenshotPopover.width)
                                    .background(
                                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                                            .fill(Color(NSColor.controlBackgroundColor))
                                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                    )
                                    .padding(.trailing, 16)
                            }
                            Spacer()
                        }
                        .padding(.top, 8)
                        .zIndex(1002)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing)),
                            removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing))
                        ))
                        .animation(.easeInOut(duration: AnimationConstants.Timing.medium), value: viewModel.showingScreenshotOverlay)
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
                    
                    ToolbarItemGroup(placement: .primaryAction) {
                        ScreenshotToolbarButton(onToggleScreenshotPopover: viewModel.toggleScreenshotOverlay)
                        
                        BrowserDownloadButton(onToggleDownloadOverlay: viewModel.toggleDownloadOverlay)
                        
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

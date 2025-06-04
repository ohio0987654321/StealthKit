import Foundation
import SwiftUI

@Observable
class TabService {
    static let shared = TabService()
    
    private(set) var tabs: [Tab] = []
    private(set) var currentTabIndex: Int = 0
    
    var currentTab: Tab? {
        guard !tabs.isEmpty && currentTabIndex < tabs.count else { return nil }
        return tabs[currentTabIndex]
    }
    
    private init() {}
    
    // MARK: - Tab Creation
    @discardableResult
    func createTab(with url: URL? = nil) -> Tab {
        let newTab = Tab(url: url)
        tabs.append(newTab)
        currentTabIndex = tabs.count - 1
        return newTab
    }
    
    @discardableResult
    func createSettingsTab(type: SettingsType) -> Tab {
        // Check if this settings tab already exists
        if let existingIndex = tabs.firstIndex(where: {
            if case .settings(let settingsType) = $0.tabType {
                return settingsType == type
            }
            return false
        }) {
            // Switch to existing tab instead of creating duplicate
            currentTabIndex = existingIndex
            return tabs[existingIndex]
        }
        
        let newTab = Tab(settingsType: type)
        tabs.append(newTab)
        currentTabIndex = tabs.count - 1
        return newTab
    }
    
    // MARK: - Tab Navigation
    func selectTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        currentTabIndex = index
    }
    
    func selectTab(withId id: UUID) {
        if let index = tabs.firstIndex(where: { $0.id == id }) {
            selectTab(at: index)
        }
    }
    
    func nextTab() {
        if !tabs.isEmpty {
            currentTabIndex = (currentTabIndex + 1) % tabs.count
        }
    }
    
    func previousTab() {
        if !tabs.isEmpty {
            currentTabIndex = currentTabIndex > 0 ? currentTabIndex - 1 : tabs.count - 1
        }
    }
    
    // MARK: - Tab Management
    func closeTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        
        let tabToClose = tabs[index]
        tabToClose.cleanup()
        tabs.remove(at: index)
        
        if !tabs.isEmpty {
            if currentTabIndex >= tabs.count {
                currentTabIndex = tabs.count - 1
            } else if index <= currentTabIndex && currentTabIndex > 0 {
                currentTabIndex -= 1
            }
        } else {
            currentTabIndex = 0
        }
    }
    
    func closeTab(withId id: UUID) {
        if let index = tabs.firstIndex(where: { $0.id == id }) {
            closeTab(at: index)
        }
    }
    
    func closeCurrentTab() {
        closeTab(at: currentTabIndex)
    }
    
    func moveTab(from source: IndexSet, to destination: Int) {
        tabs.move(fromOffsets: source, toOffset: destination)
        if let sourceIndex = source.first {
            if sourceIndex == currentTabIndex {
                if destination > sourceIndex {
                    currentTabIndex = destination - 1
                } else {
                    currentTabIndex = destination
                }
            } else if sourceIndex < currentTabIndex && destination > currentTabIndex {
                currentTabIndex -= 1
            } else if sourceIndex > currentTabIndex && destination <= currentTabIndex {
                currentTabIndex += 1
            }
        }
    }
    
    // MARK: - Tab State Management
    func updateTab(_ updatedTab: Tab) {
        if let index = tabs.firstIndex(where: { $0.id == updatedTab.id }) {
            tabs[index] = updatedTab
        }
    }
    
    func replaceCurrentTab(with newTab: Tab) {
        guard !tabs.isEmpty && currentTabIndex < tabs.count else { return }
        
        // Clean up the old tab
        tabs[currentTabIndex].cleanup()
        
        // Replace with new tab
        tabs[currentTabIndex] = newTab
    }
    
    func ensureWelcomeTab() {
        if tabs.isEmpty {
            let welcomeTab = Tab(settingsType: .welcome)
            tabs.append(welcomeTab)
            currentTabIndex = 0
        }
    }
    
    // MARK: - Utility
    func isWebContentActive(for tab: Tab?) -> Bool {
        guard let tab = tab else { return false }
        if case .web = tab.tabType {
            return true
        }
        return false
    }
    
    func createURL(from text: String) -> URL? {
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
}

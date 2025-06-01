import Foundation
import SwiftUI
import WebKit

@Observable
class BrowserViewModel {
    var tabs: [Tab] = []
    var currentTabIndex: Int = 0
    
    var currentTab: Tab? {
        guard !tabs.isEmpty && currentTabIndex < tabs.count else { return nil }
        return tabs[currentTabIndex]
    }
    
    init() {}
    
    @discardableResult
    func createNewTab(with url: URL? = nil) -> Tab {
        let newTab = Tab(url: url)
        tabs.append(newTab)
        currentTabIndex = tabs.count - 1
        return newTab
    }
    
    @discardableResult
    func createNewWebTab(with url: URL? = nil) -> Tab {
        return createNewTab(with: url)
    }
    
    func closeTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        
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
    
    func selectTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        currentTabIndex = index
    }
    
    func closeCurrentTab() {
        closeTab(at: currentTabIndex)
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
}

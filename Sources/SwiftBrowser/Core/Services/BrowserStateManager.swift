import Foundation
import SwiftUI
import WebKit

@Observable
class BrowserStateManager {
    static let shared = BrowserStateManager()
    
    // MARK: - Tab Management Properties
    private(set) var tabs: [Tab] = []
    private(set) var currentTabIndex: Int = 0
    
    var currentTab: Tab? {
        guard !tabs.isEmpty && currentTabIndex < tabs.count else { return nil }
        return tabs[currentTabIndex]
    }
    
    // MARK: - History Management Properties
    private(set) var historyItems: [HistoryItem] = []
    
    // MARK: - Cookie Management Properties
    private(set) var cookiesByDomain: [String: [CookieItem]] = [:]
    
    // MARK: - Favicon Cache Properties
    private var faviconCache: [String: String] = [:]
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let historyKey = "browserHistory"
    private let faviconCacheKey = "faviconCache"
    
    private init() {
        loadHistory()
        loadFaviconCache()
    }
    
    // MARK: - Tab Management
    
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
    
    // MARK: - History Management
    
    func addHistoryItem(title: String, url: URL, faviconData: String? = nil) {
        let domain = Self.domain(from: url)
        let favicon = faviconData ?? getFaviconData(for: domain)
        
        // Check if item already exists
        if let existingIndex = historyItems.firstIndex(where: { $0.url == url }) {
            let existingItem = historyItems[existingIndex]
            historyItems.remove(at: existingIndex)
            let updatedItem = HistoryItem(title: title, url: url, visitDate: Date(), visitCount: existingItem.visitCount + 1, faviconData: favicon)
            historyItems.insert(updatedItem, at: 0)
        } else {
            let historyItem = HistoryItem(title: title, url: url, visitDate: Date(), faviconData: favicon)
            historyItems.insert(historyItem, at: 0)
        }
        
        // Limit history to last 1000 items
        if historyItems.count > 1000 {
            historyItems = Array(historyItems.prefix(1000))
        }
        
        saveHistory()
    }
    
    func searchHistory(query: String) -> [HistoryItem] {
        guard !query.isEmpty else { return historyItems }
        
        let lowercaseQuery = query.lowercased()
        return historyItems.filter { item in
            item.title.lowercased().contains(lowercaseQuery) ||
            item.url.absoluteString.lowercased().contains(lowercaseQuery)
        }
    }
    
    func clearHistory() {
        historyItems.removeAll()
        saveHistory()
    }
    
    func removeHistoryItem(withId id: UUID) {
        historyItems.removeAll { $0.id == id }
        saveHistory()
    }
    
    // MARK: - Cookie Management
    
    @MainActor
    func loadCookies() async {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        
        let cookies = await withCheckedContinuation { continuation in
            cookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
        
        var groupedCookies: [String: [CookieItem]] = [:]
        
        for cookie in cookies {
            let cookieItem = CookieItem(
                name: cookie.name,
                value: cookie.value,
                domain: cookie.domain,
                path: cookie.path,
                expiresDate: cookie.expiresDate
            )
            
            if groupedCookies[cookie.domain] == nil {
                groupedCookies[cookie.domain] = []
            }
            groupedCookies[cookie.domain]?.append(cookieItem)
        }
        
        self.cookiesByDomain = groupedCookies
    }
    
    @MainActor
    func clearAllCookies() async {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        
        let cookies = await withCheckedContinuation { continuation in
            cookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
        
        for cookie in cookies {
            await withCheckedContinuation { continuation in
                cookieStore.delete(cookie) {
                    continuation.resume()
                }
            }
        }
        
        self.cookiesByDomain.removeAll()
    }
    
    @MainActor
    func clearCookiesForDomain(_ domain: String) async {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        
        let cookies = await withCheckedContinuation { continuation in
            cookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
        
        let domainCookies = cookies.filter { $0.domain == domain }
        
        for cookie in domainCookies {
            await withCheckedContinuation { continuation in
                cookieStore.delete(cookie) {
                    continuation.resume()
                }
            }
        }
        
        self.cookiesByDomain.removeValue(forKey: domain)
    }
    
    func getAllDomains() -> [String] {
        return Array(cookiesByDomain.keys).sorted()
    }
    
    func getCookies(for domain: String) -> [CookieItem] {
        return cookiesByDomain[domain] ?? []
    }
    
    func refreshCookies() {
        Task { @MainActor in
            await loadCookies()
        }
    }
    
    func deleteAllCookies() {
        Task { @MainActor in
            await clearAllCookies()
        }
    }
    
    func deleteCookies(for domain: String) {
        Task { @MainActor in
            await clearCookiesForDomain(domain)
        }
    }
    
    // MARK: - Favicon Management
    
    func getFavicon(for domain: String) -> NSImage? {
        guard let base64String = faviconCache[domain],
              let data = Data(base64Encoded: base64String) else {
            return nil
        }
        return NSImage(data: data)
    }
    
    func setFavicon(_ image: NSImage, for domain: String) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return
        }
        
        let base64String = pngData.base64EncodedString()
        faviconCache[domain] = base64String
        saveFaviconCache()
    }
    
    func setFaviconData(_ data: Data, for domain: String) {
        guard let image = NSImage(data: data) else { return }
        setFavicon(image, for: domain)
    }
    
    func getFaviconData(for domain: String) -> String? {
        return faviconCache[domain]
    }
    
    func setFaviconBase64(_ base64String: String, for domain: String) {
        faviconCache[domain] = base64String
        saveFaviconCache()
    }
    
    func clearFaviconCache() {
        faviconCache.removeAll()
        saveFaviconCache()
    }
    
    func removeFavicon(for domain: String) {
        faviconCache.removeValue(forKey: domain)
        saveFaviconCache()
    }
    
    // MARK: - Utility Methods
    
    static func domain(from url: URL) -> String {
        return url.host ?? url.absoluteString
    }
    
    // MARK: - Private Methods
    
    private func loadHistory() {
        guard let data = userDefaults.data(forKey: historyKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let savedItems = try decoder.decode([SavedHistoryItem].self, from: data)
            
            historyItems = savedItems.compactMap { savedItem in
                guard let url = URL(string: savedItem.urlString) else { return nil }
                return HistoryItem(
                    title: savedItem.title,
                    url: url,
                    visitDate: savedItem.visitDate,
                    visitCount: savedItem.visitCount,
                    faviconData: savedItem.faviconData
                )
            }
        } catch {
            // Failed to load history - start with empty array
        }
    }
    
    private func saveHistory() {
        let savedItems = historyItems.map { item in
            SavedHistoryItem(
                title: item.title,
                urlString: item.url.absoluteString,
                visitDate: item.visitDate,
                visitCount: item.visitCount,
                faviconData: item.faviconData
            )
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(savedItems)
            userDefaults.set(data, forKey: historyKey)
        } catch {
            // Failed to save history - will retry on next save
        }
    }
    
    private func loadFaviconCache() {
        if let data = userDefaults.data(forKey: faviconCacheKey),
           let savedCache = try? JSONDecoder().decode([String: String].self, from: data) {
            faviconCache = savedCache
        }
    }
    
    private func saveFaviconCache() {
        if let data = try? JSONEncoder().encode(faviconCache) {
            userDefaults.set(data, forKey: faviconCacheKey)
        }
    }
}

// MARK: - Supporting Types

private struct SavedHistoryItem: Codable {
    let title: String
    let urlString: String
    let visitDate: Date
    let visitCount: Int
    let faviconData: String?
}

import Foundation

@Observable
class HistoryManager {
    static let shared = HistoryManager()
    
    private(set) var historyItems: [HistoryItem] = []
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "browserHistory"
    
    private init() {
        loadHistory()
    }
    
    func addHistoryItem(title: String, url: URL, faviconData: String? = nil) {
        let domain = FaviconCache.domain(from: url)
        let favicon = faviconData ?? FaviconCache.shared.getFaviconData(for: domain)
        
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
}

// Helper struct for JSON encoding/decoding
private struct SavedHistoryItem: Codable {
    let title: String
    let urlString: String
    let visitDate: Date
    let visitCount: Int
    let faviconData: String?
}

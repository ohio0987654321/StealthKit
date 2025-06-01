import Foundation

@Observable
class AppSettings {
    static let shared = AppSettings()
    
    var defaultSearchEngine: SearchEngine = .google {
        didSet { saveSettings() }
    }
    
    private init() {
        loadSettings()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        defaultSearchEngine = SearchEngine(rawValue: defaults.string(forKey: "defaultSearchEngine") ?? "google") ?? .google
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(defaultSearchEngine.rawValue, forKey: "defaultSearchEngine")
    }
}

enum SearchEngine: String, CaseIterable, Identifiable {
    case google = "google"
    case bing = "bing"
    case duckduckgo = "duckduckgo"
    case yahoo = "yahoo"
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .google: return "Google"
        case .bing: return "Bing"
        case .duckduckgo: return "DuckDuckGo"
        case .yahoo: return "Yahoo"
        }
    }
    
    var searchURL: String {
        switch self {
        case .google: return "https://www.google.com/search?q="
        case .bing: return "https://www.bing.com/search?q="
        case .duckduckgo: return "https://duckduckgo.com/?q="
        case .yahoo: return "https://search.yahoo.com/search?p="
        }
    }
}

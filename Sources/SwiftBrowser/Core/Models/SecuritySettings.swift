import Foundation

@Observable
class SecuritySettings {
    static let shared = SecuritySettings()
    
    var isJavaScriptEnabled: Bool = true {
        didSet { saveSettings() }
    }
    
    var isHTTPSEnforcementEnabled: Bool = true {
        didSet { saveSettings() }
    }
    
    private init() {
        loadSettings()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        isJavaScriptEnabled = defaults.object(forKey: "isJavaScriptEnabled") as? Bool ?? true
        isHTTPSEnforcementEnabled = defaults.object(forKey: "isHTTPSEnforcementEnabled") as? Bool ?? true
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isJavaScriptEnabled, forKey: "isJavaScriptEnabled")
        defaults.set(isHTTPSEnforcementEnabled, forKey: "isHTTPSEnforcementEnabled")
    }
}

struct HistoryItem: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
    let visitDate: Date
    let visitCount: Int
    let faviconData: String?
    
    init(title: String, url: URL, visitDate: Date, visitCount: Int = 1, faviconData: String? = nil) {
        self.title = title
        self.url = url
        self.visitDate = visitDate
        self.visitCount = visitCount
        self.faviconData = faviconData
    }
}

struct CookieItem: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let domain: String
    let path: String
    let expiresDate: Date?
}

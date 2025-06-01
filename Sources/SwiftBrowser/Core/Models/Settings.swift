//
//  Settings.swift
//  SwiftBrowser
//
//  Application settings and preferences management.
//  Foundation for Phase 3 settings system.
//

import Foundation

@Observable
class AppSettings {
    static let shared = AppSettings()
    
    // General Settings
    var homepage: String = "https://www.google.com" {
        didSet { saveSettings() }
    }
    var defaultSearchEngine: SearchEngine = .google {
        didSet { saveSettings() }
    }
    var showTabBar: Bool = true {
        didSet { saveSettings() }
    }
    var enableExtensions: Bool = true {
        didSet { saveSettings() }
    }
    
    // Privacy Settings
    var enableStealthMode: Bool = true {
        didSet { saveSettings() }
    }
    var clearDataOnExit: Bool = false {
        didSet { saveSettings() }
    }
    var blockTrackers: Bool = true {
        didSet { saveSettings() }
    }
    
    // Advanced Settings
    var enableDeveloperMode: Bool = false {
        didSet { saveSettings() }
    }
    var customUserAgent: String = "" {
        didSet { saveSettings() }
    }
    
    private init() {
        loadSettings()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Load values without triggering auto-save
        
        homepage = defaults.string(forKey: "homepage") ?? "https://www.google.com"
        defaultSearchEngine = SearchEngine(rawValue: defaults.string(forKey: "defaultSearchEngine") ?? "google") ?? .google
        showTabBar = defaults.object(forKey: "showTabBar") != nil ? defaults.bool(forKey: "showTabBar") : true
        enableExtensions = defaults.object(forKey: "enableExtensions") != nil ? defaults.bool(forKey: "enableExtensions") : true
        enableStealthMode = defaults.object(forKey: "enableStealthMode") != nil ? defaults.bool(forKey: "enableStealthMode") : true
        clearDataOnExit = defaults.object(forKey: "clearDataOnExit") != nil ? defaults.bool(forKey: "clearDataOnExit") : false
        blockTrackers = defaults.object(forKey: "blockTrackers") != nil ? defaults.bool(forKey: "blockTrackers") : true
        enableDeveloperMode = defaults.object(forKey: "enableDeveloperMode") != nil ? defaults.bool(forKey: "enableDeveloperMode") : false
        customUserAgent = defaults.string(forKey: "customUserAgent") ?? ""
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        
        defaults.set(homepage, forKey: "homepage")
        defaults.set(defaultSearchEngine.rawValue, forKey: "defaultSearchEngine")
        defaults.set(showTabBar, forKey: "showTabBar")
        defaults.set(enableExtensions, forKey: "enableExtensions")
        defaults.set(enableStealthMode, forKey: "enableStealthMode")
        defaults.set(clearDataOnExit, forKey: "clearDataOnExit")
        defaults.set(blockTrackers, forKey: "blockTrackers")
        defaults.set(enableDeveloperMode, forKey: "enableDeveloperMode")
        defaults.set(customUserAgent, forKey: "customUserAgent")
    }
    
    func resetToDefaults() {
        let defaults = UserDefaults.standard
        
        // Remove all keys
        let keys = ["homepage", "defaultSearchEngine", "showTabBar", "enableExtensions", 
                   "enableStealthMode", "clearDataOnExit", "blockTrackers", 
                   "enableDeveloperMode", "customUserAgent"]
        
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        
        // Reset to default values
        homepage = "https://www.google.com"
        defaultSearchEngine = .google
        showTabBar = true
        enableExtensions = true
        enableStealthMode = true
        clearDataOnExit = false
        blockTrackers = true
        enableDeveloperMode = false
        customUserAgent = ""
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

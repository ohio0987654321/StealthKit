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
    var homepage: String = "https://www.google.com"
    var defaultSearchEngine: SearchEngine = .google
    var showTabBar: Bool = true
    var enableExtensions: Bool = true
    
    // Privacy Settings
    var enableStealthMode: Bool = false
    var clearDataOnExit: Bool = false
    var blockTrackers: Bool = true
    
    // Advanced Settings
    var enableDeveloperMode: Bool = false
    var customUserAgent: String = ""
    
    private init() {
        loadSettings()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        homepage = defaults.string(forKey: "homepage") ?? "https://www.google.com"
        defaultSearchEngine = SearchEngine(rawValue: defaults.string(forKey: "defaultSearchEngine") ?? "google") ?? .google
        showTabBar = defaults.bool(forKey: "showTabBar")
        enableExtensions = defaults.bool(forKey: "enableExtensions")
        enableStealthMode = defaults.bool(forKey: "enableStealthMode")
        clearDataOnExit = defaults.bool(forKey: "clearDataOnExit")
        blockTrackers = defaults.bool(forKey: "blockTrackers")
        enableDeveloperMode = defaults.bool(forKey: "enableDeveloperMode")
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

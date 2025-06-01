//
//  Tab.swift
//  SwiftBrowser
//
//  Data model representing a browser tab with its state and content.
//

import Foundation
import WebKit

enum TabType {
    case web
    case settings
}

@Observable
class Tab: Identifiable {
    let id = UUID()
    var title: String = "New Tab"
    var url: URL?
    var isLoading: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var estimatedProgress: Double = 0.0
    var type: TabType = .web
    
    init(url: URL? = nil) {
        self.url = url
        if let url = url {
            self.title = url.host ?? url.absoluteString
        }
    }
    
    func updateFromWebView(_ webView: WKWebView) {
        self.title = webView.title ?? "New Tab"
        self.url = webView.url
        self.isLoading = webView.isLoading
        self.canGoBack = webView.canGoBack
        self.canGoForward = webView.canGoForward
        self.estimatedProgress = webView.estimatedProgress
    }
    
    static func settingsTab() -> Tab {
        let tab = Tab()
        tab.title = "Settings"
        tab.type = .settings
        return tab
    }
}

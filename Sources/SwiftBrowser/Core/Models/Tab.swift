import Foundation
import WebKit
import SwiftUI

enum TabType {
    case empty
    case web(URL?)
    case settings(SettingsType)
}

enum SettingsType {
    case browserUtilities
    case windowUtilities
    case securityPrivacy
    case history
    case cookies
    case welcome
}

@Observable
class Tab: Identifiable, Equatable {
    static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.id == rhs.id
    }
    let id = UUID()
    var title: String = "New Tab"
    var url: URL?
    var isLoading: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var estimatedProgress: Double = 0.0
    var webView: WKWebView?
    var favicon: Image?
    let tabType: TabType
    
    init(url: URL? = nil) {
        if url == nil {
            self.tabType = .empty
        } else {
            self.tabType = .web(url)
        }
        self.url = url
        if let url = url {
            self.title = url.host ?? url.absoluteString
        }
    }
    
    init(settingsType: SettingsType) {
        self.tabType = .settings(settingsType)
        switch settingsType {
        case .browserUtilities:
            self.title = "Browser Utilities"
            self.favicon = Image(systemName: "magnifyingglass")
        case .windowUtilities:
            self.title = "Window Utilities"
            self.favicon = Image(systemName: "macwindow")
        case .securityPrivacy:
            self.title = "Security & Privacy"
            self.favicon = Image(systemName: "shield")
        case .history:
            self.title = "History"
            self.favicon = Image(systemName: "clock")
        case .cookies:
            self.title = "Cookie Management"
            self.favicon = Image(systemName: "list.bullet.rectangle")
        case .welcome:
            self.title = "Welcome"
            self.favicon = Image(systemName: "safari")
        }
    }
    
    func updateFromWebView(_ webView: WKWebView) {
        self.title = webView.title ?? "New Tab"
        
        if let webViewURL = webView.url,
           !webViewURL.absoluteString.hasPrefix("about:") &&
           !webViewURL.absoluteString.hasPrefix("data:") {
            self.url = webViewURL
        }
        
        self.isLoading = webView.isLoading
        self.canGoBack = webView.canGoBack
        self.canGoForward = webView.canGoForward
        self.estimatedProgress = webView.estimatedProgress
        
        // Load favicon when page finishes loading
        if !webView.isLoading {
            loadFavicon(from: webView)
        }
    }
    
    private func loadFavicon(from webView: WKWebView) {
        let script = """
            var link = document.querySelector("link[rel*='icon']") ||
                      document.querySelector("link[rel='shortcut icon']") ||
                      document.querySelector("link[rel='apple-touch-icon']");
            if (link) {
                link.href;
            } else {
                window.location.origin + '/favicon.ico';
            }
        """
        
        webView.evaluateJavaScript(script) { [weak self] result, error in
            DispatchQueue.main.async {
                if let urlString = result as? String,
                   let url = URL(string: urlString) {
                    self?.downloadFavicon(from: url)
                }
            }
        }
    }
    
    private func downloadFavicon(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  error == nil,
                  let nsImage = NSImage(data: data) else {
                return
            }
            
            DispatchQueue.main.async {
                self?.favicon = Image(nsImage: nsImage)
            }
        }.resume()
    }
    
    func cleanup() {
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        webView = nil
    }
}

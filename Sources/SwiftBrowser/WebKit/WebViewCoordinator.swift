//
//  WebViewCoordinator.swift
//  SwiftBrowser
//
//  SwiftUI-WebKit bridge coordinator.
//  Handles WebKit integration and delegate methods for browser functionality.
//

import SwiftUI
import WebKit

// WebView cache to prevent reloads when switching tabs
class WebViewCache {
    static let shared = WebViewCache()
    private var webViews: [UUID: WKWebView] = [:]
    
    private init() {}
    
    func getWebView(for tabId: UUID) -> WKWebView? {
        return webViews[tabId]
    }
    
    func setWebView(_ webView: WKWebView, for tabId: UUID) {
        webViews[tabId] = webView
    }
    
    func removeWebView(for tabId: UUID) {
        webViews.removeValue(forKey: tabId)
    }
    
    func clearCache() {
        webViews.removeAll()
    }
}

struct WebView: NSViewRepresentable {
    @Binding var tab: Tab
    let onNavigationChange: (Tab) -> Void
    let onWebViewCreated: ((WKWebView) -> Void)?
    
    func makeNSView(context: Context) -> WKWebView {
        // Check if we have a cached WebView for this tab
        if let cachedWebView = WebViewCache.shared.getWebView(for: tab.id) {
            // Use existing WebView for tab switching
            context.coordinator.tab = tab
            cachedWebView.navigationDelegate = context.coordinator
            cachedWebView.uiDelegate = context.coordinator
            onWebViewCreated?(cachedWebView)
            return cachedWebView
        }
        
        // Create fresh WebView for new tabs
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Cache the WebView for future tab switches
        WebViewCache.shared.setWebView(webView, for: tab.id)
        
        // Notify parent about WebView creation
        onWebViewCreated?(webView)
        
        // Load initial content for new tabs
        if let url = tab.url {
            webView.load(URLRequest(url: url))
        } else {
            // For new empty tabs, always load custom new tab page
            loadNewTabPage(in: webView)
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.tab = tab
        
        // Check if this is a cached WebView - if so, don't reload
        let cachedWebView = WebViewCache.shared.getWebView(for: tab.id)
        if cachedWebView === nsView {
            // This is a cached WebView being displayed, don't reload
            return
        }
        
        // Only load URL if it's genuinely different from current URL
        if let url = tab.url, nsView.url != url {
            nsView.load(URLRequest(url: url))
        }
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(tab: tab, onNavigationChange: onNavigationChange)
    }
}

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var tab: Tab
    let onNavigationChange: (Tab) -> Void
    private var lastLoadedURL: URL?
    
    init(tab: Tab, onNavigationChange: @escaping (Tab) -> Void) {
        self.tab = tab
        self.onNavigationChange = onNavigationChange
    }
    
    func shouldLoadURL(_ url: URL, in webView: WKWebView) -> Bool {
        // Don't reload if this URL was just loaded
        if lastLoadedURL == url {
            return false
        }
        
        // Allow loading if it's a genuine new navigation
        lastLoadedURL = url
        return true
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        tab.isLoading = true
        tab.updateFromWebView(webView)
        onNavigationChange(tab)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        tab.isLoading = false
        tab.updateFromWebView(webView)
        onNavigationChange(tab)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        tab.isLoading = false
        tab.updateFromWebView(webView)
        onNavigationChange(tab)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, 
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
}

// MARK: - New Tab Page

func loadNewTabPage(in webView: WKWebView) {
    let html = createNewTabHTML()
    webView.loadHTMLString(html, baseURL: nil)
}

func createNewTabHTML() -> String {
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>New Tab</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 0; padding: 2rem; background: #f5f5f5; }
            .container { max-width: 600px; margin: 0 auto; text-align: center; }
            h1 { color: #333; margin-bottom: 2rem; }
            .search { width: 100%; padding: 1rem; font-size: 1.1rem; border: 1px solid #ddd; border-radius: 8px; margin-bottom: 2rem; }
            .links { display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); gap: 1rem; }
            .link { background: white; padding: 1rem; border-radius: 8px; text-decoration: none; color: #333; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>New Tab</h1>
            <input type="text" class="search" placeholder="Search or enter URL..." id="search">
            <div class="links">
                <a href="https://www.google.com" class="link">Google</a>
                <a href="https://github.com" class="link">GitHub</a>
                <a href="https://stackoverflow.com" class="link">Stack Overflow</a>
                <a href="https://news.ycombinator.com" class="link">Hacker News</a>
            </div>
        </div>
        <script>
            document.getElementById('search').addEventListener('keypress', function(e) {
                if (e.key === 'Enter') {
                    const query = e.target.value.trim();
                    if (query.includes('.') && !query.includes(' ')) {
                        window.location.href = query.startsWith('http') ? query : 'https://' + query;
                    } else {
                        window.location.href = 'https://www.google.com/search?q=' + encodeURIComponent(query);
                    }
                }
            });
        </script>
    </body>
    </html>
    """
}

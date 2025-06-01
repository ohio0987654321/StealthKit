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
        // Try to get existing WebView from cache first
        if let cachedWebView = WebViewCache.shared.getWebView(for: tab.id) {
            // Update coordinator reference
            context.coordinator.tab = tab
            cachedWebView.navigationDelegate = context.coordinator
            cachedWebView.uiDelegate = context.coordinator
            
            // Notify parent about WebView
            onWebViewCreated?(cachedWebView)
            
            return cachedWebView
        }
        
        // Create new WebView if not in cache
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Cache the WebView
        WebViewCache.shared.setWebView(webView, for: tab.id)
        
        // Notify parent about WebView creation
        onWebViewCreated?(webView)
        
        // Load initial URL only for new WebViews that have a URL
        // New tabs without URL should show empty content
        if let url = tab.url {
            webView.load(URLRequest(url: url))
        } else {
            // For new empty tabs, load about:blank to ensure clean state
            webView.loadHTMLString("", baseURL: nil)
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.tab = tab
        
        // Don't reload when switching to cached WebViews
        // Only load if this is a genuine new navigation request
        if let url = tab.url {
            let cachedWebView = WebViewCache.shared.getWebView(for: tab.id)
            
            // If this is a cached WebView being reused, don't reload
            if cachedWebView === nsView {
                return
            }
            
            // Only load if URL is genuinely different and this isn't just tab switching
            if nsView.url != url && context.coordinator.shouldLoadURL(url, in: nsView) {
                nsView.load(URLRequest(url: url))
            }
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

import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    @Binding var tab: Tab
    let onNavigationChange: (Tab) -> Void
    let onWebViewCreated: ((WKWebView) -> Void)?
    
    func makeNSView(context: Context) -> WKWebView {
        // Always create fresh WebView - no caching
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Notify parent about WebView creation
        onWebViewCreated?(webView)
        
        // Load initial content
        if let url = tab.url {
            webView.load(URLRequest(url: url))
        } else {
            // For new empty tabs, load custom new tab page
            loadNewTabPage(in: webView)
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.tab = tab
        
        // Only load URL if tab has a URL and it's different from current URL
        if let url = tab.url, nsView.url != url {
            nsView.load(URLRequest(url: url))
        }
        // Note: New tab page loading is handled by makeNSView, not here
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
    
    // MARK: - WKUIDelegate Methods
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, 
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Prevent new windows/popups - handle navigation in the current tab instead
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        // Handle webview close events - prevent unwanted UI changes
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, 
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        // Handle JavaScript alerts properly
        let alert = NSAlert()
        alert.messageText = "Alert"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, 
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        // Handle JavaScript confirms properly
        let alert = NSAlert()
        alert.messageText = "Confirm"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn)
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

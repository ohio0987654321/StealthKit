import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct WebView: NSViewRepresentable {
    @Binding var tab: Tab
    let onNavigationChange: (Tab) -> Void
    let onWebViewCreated: ((WKWebView) -> Void)?
    
    func makeNSView(context: Context) -> WKWebView {
        // Reuse existing WebView if available, otherwise create new one
        if let existingWebView = tab.webView {
            existingWebView.navigationDelegate = context.coordinator
            existingWebView.uiDelegate = context.coordinator
            context.coordinator.updateWebViewConfiguration(existingWebView)
            onWebViewCreated?(existingWebView)
            return existingWebView
        }
        
        // Create new WebView with security configuration
        let configuration = WKWebViewConfiguration()
        context.coordinator.applySecuritySettings(to: configuration)
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Store WebView in tab for reuse
        tab.webView = webView
        
        // Notify parent about WebView creation
        onWebViewCreated?(webView)
        
        // Load initial content only for new WebViews
        if let url = tab.url {
            webView.load(URLRequest(url: url))
        }
        // For new empty tabs, leave WebView empty (no content loading)
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.tab = tab
        
        // Only load URL if it's a programmatic navigation request
        // and different from current URL (avoid reloads on tab switches)
        if let url = tab.url, 
           nsView.url != url,
           !context.coordinator.isTabSwitch {
            nsView.load(URLRequest(url: url))
        }
        
        // Reset tab switch flag
        context.coordinator.isTabSwitch = false
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(tab: tab, onNavigationChange: onNavigationChange)
    }
}

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var tab: Tab
    let onNavigationChange: (Tab) -> Void
    private var lastLoadedURL: URL?
    var isTabSwitch: Bool = false
    
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
        
        // Add to history when navigation completes
        if let url = webView.url,
           !url.absoluteString.hasPrefix("about:") &&
           !url.absoluteString.hasPrefix("data:") {
            let title = webView.title ?? url.host ?? "Untitled"
            
            // Extract and cache favicon
            extractFavicon(from: webView) { faviconData in
                HistoryManager.shared.addHistoryItem(title: title, url: url, faviconData: faviconData)
            }
        }
        
        onNavigationChange(tab)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        tab.isLoading = false
        tab.updateFromWebView(webView)
        onNavigationChange(tab)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, 
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        // Handle HTTPS enforcement
        if let url = navigationAction.request.url,
           SecuritySettings.shared.isHTTPSEnforcementEnabled,
           url.scheme == "http" {
            
            // Try to redirect to HTTPS
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.scheme = "https"
            
            if let httpsURL = components?.url {
                decisionHandler(.cancel)
                webView.load(URLRequest(url: httpsURL))
                return
            }
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, 
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        guard let response = navigationResponse.response as? HTTPURLResponse,
              let url = response.url else {
            decisionHandler(.allow)
            return
        }
        
        // Check if this should be treated as a download
        if shouldDownload(response: response, for: url) {
            // Only start download if not already downloading
            if !DownloadManager.shared.isAlreadyDownloading(url) {
                let suggestedFilename = response.suggestedFilename ?? url.lastPathComponent
                let mimeType = response.mimeType
                
                DownloadManager.shared.startDownload(from: url, suggestedFilename: suggestedFilename, mimeType: mimeType)
            }
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
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
    
    func applySecuritySettings(to configuration: WKWebViewConfiguration) {
        configuration.defaultWebpagePreferences.allowsContentJavaScript = SecuritySettings.shared.isJavaScriptEnabled
        configuration.websiteDataStore = WKWebsiteDataStore.default()
    }
    
    func updateWebViewConfiguration(_ webView: WKWebView) {
        let script = SecuritySettings.shared.isJavaScriptEnabled ? "" : 
            "document.documentElement.style.pointerEvents = 'none';"
        
        if !script.isEmpty {
            let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            webView.configuration.userContentController.addUserScript(userScript)
        }
    }
    
    private func extractFavicon(from webView: WKWebView, completion: @escaping (String?) -> Void) {
        guard let url = webView.url else {
            completion(nil)
            return
        }
        
        let domain = FaviconCache.domain(from: url)
        
        // Check if we already have a favicon cached
        if let cachedFavicon = FaviconCache.shared.getFaviconData(for: domain) {
            completion(cachedFavicon)
            return
        }
        
        // Extract favicon URL using JavaScript
        let faviconScript = """
        (function() {
            var favicon = document.querySelector('link[rel*="icon"]');
            if (favicon) {
                return favicon.href;
            }
            
            // Fallback to default favicon location
            return window.location.origin + '/favicon.ico';
        })();
        """
        
        webView.evaluateJavaScript(faviconScript) { result, error in
            guard let faviconURLString = result as? String,
                  let faviconURL = URL(string: faviconURLString) else {
                completion(nil)
                return
            }
            
            // Download favicon
            self.downloadFavicon(from: faviconURL, domain: domain, completion: completion)
        }
    }
    
    private func downloadFavicon(from url: URL, domain: String, completion: @escaping (String?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                completion(nil)
                return
            }
            
            // Store in cache
            FaviconCache.shared.setFaviconData(data, for: domain)
            
            // Return base64 string
            let base64String = data.base64EncodedString()
            completion(base64String)
        }.resume()
    }
    
    private func shouldDownload(response: HTTPURLResponse, for url: URL) -> Bool {
        // Check Content-Disposition header for attachment
        if let contentDisposition = response.value(forHTTPHeaderField: "Content-Disposition"),
           contentDisposition.contains("attachment") {
            return true
        }
        
        // Check MIME type for downloadable content
        if let mimeType = response.mimeType {
            return shouldDownloadMimeType(mimeType)
        }
        
        // Check file extension
        let pathExtension = url.pathExtension.lowercased()
        return shouldDownloadFileExtension(pathExtension)
    }
    
    private func shouldDownloadMimeType(_ mimeType: String) -> Bool {
        let downloadableMimeTypes: Set<String> = [
            // Archives
            "application/zip",
            "application/x-zip-compressed",
            "application/x-rar-compressed",
            "application/x-7z-compressed",
            "application/x-tar",
            "application/gzip",
            
            // Documents
            "application/pdf",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/vnd.ms-excel",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "application/vnd.ms-powerpoint",
            "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            
            // Media
            "application/octet-stream",
            "video/mp4",
            "video/mpeg",
            "video/quicktime",
            "audio/mpeg",
            "audio/wav",
            "audio/mp4",
            
            // Software
            "application/x-apple-diskimage",
            "application/vnd.apple.installer+xml",
            "application/x-ms-dos-executable",
            "application/x-msdownload"
        ]
        
        return downloadableMimeTypes.contains(mimeType.lowercased())
    }
    
    private func shouldDownloadFileExtension(_ fileExtension: String) -> Bool {
        let downloadableExtensions: Set<String> = [
            // Archives
            "zip", "rar", "7z", "tar", "gz", "bz2",
            
            // Documents
            "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
            
            // Media
            "mp4", "avi", "mov", "wmv", "mp3", "wav", "aac",
            
            // Software
            "dmg", "pkg", "exe", "msi", "deb", "rpm"
        ]
        
        return downloadableExtensions.contains(fileExtension)
    }
}

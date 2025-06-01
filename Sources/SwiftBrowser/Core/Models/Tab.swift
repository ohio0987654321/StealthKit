import Foundation
import WebKit

@Observable
class Tab: Identifiable {
    let id = UUID()
    var title: String = "New Tab"
    var url: URL?
    var isLoading: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var estimatedProgress: Double = 0.0
    
    init(url: URL? = nil) {
        self.url = url
        if let url = url {
            self.title = url.host ?? url.absoluteString
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
    }
}

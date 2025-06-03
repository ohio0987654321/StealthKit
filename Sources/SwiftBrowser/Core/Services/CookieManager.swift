import Foundation
import WebKit

@Observable
class CookieManager {
    static let shared = CookieManager()
    
    private(set) var cookiesByDomain: [String: [CookieItem]] = [:]
    
    private init() {}
    
    func loadCookies() async {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        
        let cookies = await withCheckedContinuation { continuation in
            cookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
        
        var groupedCookies: [String: [CookieItem]] = [:]
        
        for cookie in cookies {
            let cookieItem = CookieItem(
                name: cookie.name,
                value: cookie.value,
                domain: cookie.domain,
                path: cookie.path,
                expiresDate: cookie.expiresDate
            )
            
            if groupedCookies[cookie.domain] == nil {
                groupedCookies[cookie.domain] = []
            }
            groupedCookies[cookie.domain]?.append(cookieItem)
        }
        
        await MainActor.run {
            self.cookiesByDomain = groupedCookies
        }
    }
    
    func clearAllCookies() async {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        
        let cookies = await withCheckedContinuation { continuation in
            cookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
        
        for cookie in cookies {
            await withCheckedContinuation { continuation in
                cookieStore.delete(cookie) {
                    continuation.resume()
                }
            }
        }
        
        await MainActor.run {
            self.cookiesByDomain.removeAll()
        }
    }
    
    func clearCookiesForDomain(_ domain: String) async {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        
        let cookies = await withCheckedContinuation { continuation in
            cookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
        
        let domainCookies = cookies.filter { $0.domain == domain }
        
        for cookie in domainCookies {
            await withCheckedContinuation { continuation in
                cookieStore.delete(cookie) {
                    continuation.resume()
                }
            }
        }
        
        await MainActor.run {
            self.cookiesByDomain.removeValue(forKey: domain)
        }
    }
    
    func getAllDomains() -> [String] {
        return Array(cookiesByDomain.keys).sorted()
    }
    
    func getCookies(for domain: String) -> [CookieItem] {
        return cookiesByDomain[domain] ?? []
    }
}

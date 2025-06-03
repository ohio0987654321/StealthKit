import Foundation
import AppKit

@Observable
class FaviconCache {
    static let shared = FaviconCache()
    
    private var cache: [String: String] = [:]
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "faviconCache"
    
    private init() {
        loadCache()
    }
    
    func getFavicon(for domain: String) -> NSImage? {
        guard let base64String = cache[domain],
              let data = Data(base64Encoded: base64String) else {
            return nil
        }
        return NSImage(data: data)
    }
    
    func setFavicon(_ image: NSImage, for domain: String) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return
        }
        
        let base64String = pngData.base64EncodedString()
        cache[domain] = base64String
        saveCache()
    }
    
    func setFaviconData(_ data: Data, for domain: String) {
        guard let image = NSImage(data: data) else { return }
        setFavicon(image, for: domain)
    }
    
    func getFaviconData(for domain: String) -> String? {
        return cache[domain]
    }
    
    func setFaviconBase64(_ base64String: String, for domain: String) {
        cache[domain] = base64String
        saveCache()
    }
    
    func clearCache() {
        cache.removeAll()
        saveCache()
    }
    
    func removeFavicon(for domain: String) {
        cache.removeValue(forKey: domain)
        saveCache()
    }
    
    private func loadCache() {
        if let data = userDefaults.data(forKey: cacheKey),
           let savedCache = try? JSONDecoder().decode([String: String].self, from: data) {
            cache = savedCache
        }
    }
    
    private func saveCache() {
        if let data = try? JSONEncoder().encode(cache) {
            userDefaults.set(data, forKey: cacheKey)
        }
    }
    
    // Extract domain from URL for consistent caching
    static func domain(from url: URL) -> String {
        return url.host ?? url.absoluteString
    }
}

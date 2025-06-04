import Foundation
import AppKit
import CoreGraphics

@Observable
class ScreenshotService {
    static let shared = ScreenshotService()
    
    private var thumbnailCache: [CGWindowID: (image: NSImage, timestamp: Date)] = [:]
    private let thumbnailCacheTTL: TimeInterval = 10.0 // 10 seconds
    private let thumbnailMaxSize = CGSize(width: 80, height: 60)
    
    private init() {}
    
    // MARK: - Window Listing
    
    func getAvailableWindows() -> [WindowInfo] {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        
        return windowList.compactMap { windowDict in
            guard let windowInfo = WindowInfo(from: windowDict) else { return nil }
            return windowInfo.isValidForScreenshot ? windowInfo : nil
        }
        .filter { windowInfo in
            // Additional filtering to exclude system windows and hidden apps
            !isSystemWindow(windowInfo.ownerName)
        }
        .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
    
    private func isSystemWindow(_ ownerName: String) -> Bool {
        let systemApps = [
            "Window Server",
            "Dock",
            "ControlCenter",
            "SystemUIServer",
            "NotificationCenter",
            "WindowManager",
            "Spotlight",
            "loginwindow"
        ]
        return systemApps.contains(ownerName)
    }
    
    // MARK: - Screenshot Capture
    
    func captureWindow(_ windowInfo: WindowInfo) -> Result<Data, ScreenshotError> {
        guard checkScreenRecordingPermission() else {
            return .failure(.permissionDenied)
        }
        
        // Create screenshot using CGWindowListCreateImage
        let windowID = windowInfo.id
        guard let cgImage = CGWindowListCreateImage(
            windowInfo.bounds,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .bestResolution]
        ) else {
            return .failure(.captureFailure)
        }
        
        // Convert CGImage to PNG data
        guard let imageData = convertCGImageToPNG(cgImage) else {
            return .failure(.conversionFailure)
        }
        
        return .success(imageData)
    }
    
    private func convertCGImageToPNG(_ cgImage: CGImage) -> Data? {
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmapRep.representation(using: .png, properties: [:])
    }
    
    // MARK: - Permission Handling
    
    func checkScreenRecordingPermission() -> Bool {
        // Create a small test image to check if we have permission
        let testRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let testImage = CGWindowListCreateImage(testRect, .optionOnScreenOnly, kCGNullWindowID, [])
        return testImage != nil
    }
    
    func requestScreenRecordingPermission() {
        // On macOS, we need to trigger a permission request by attempting to capture
        // This will show the system permission dialog
        _ = checkScreenRecordingPermission()
    }
    
    // MARK: - Filename Generation
    
    func generateScreenshotFilename(for windowInfo: WindowInfo) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let sanitizedTitle = sanitizeFilename(windowInfo.title)
        let sanitizedOwner = sanitizeFilename(windowInfo.ownerName)
        
        if sanitizedTitle.isEmpty || sanitizedTitle == sanitizedOwner {
            return "Screenshot of \(sanitizedOwner) \(timestamp).png"
        } else {
            return "Screenshot of \(sanitizedTitle) \(timestamp).png"
        }
    }
    
    private func sanitizeFilename(_ filename: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?<>|*\"")
        return filename.components(separatedBy: invalidCharacters).joined(separator: "")
    }
    
    // MARK: - Thumbnail Generation
    
    func getAvailableWindowsWithThumbnails() async -> [WindowInfo] {
        let windows = getAvailableWindows()
        
        // Generate thumbnails for each window
        var windowsWithThumbnails: [WindowInfo] = []
        
        for var window in windows {
            // Check cache first
            if let cachedThumbnail = getCachedThumbnail(for: window.id) {
                window.thumbnailImage = cachedThumbnail
            } else {
                // Generate thumbnail asynchronously
                if let thumbnail = await generateThumbnail(for: window) {
                    window.thumbnailImage = thumbnail
                    cacheThumbnail(thumbnail, for: window.id)
                }
            }
            windowsWithThumbnails.append(window)
        }
        
        return windowsWithThumbnails
    }
    
    private func getCachedThumbnail(for windowID: CGWindowID) -> NSImage? {
        guard let cached = thumbnailCache[windowID] else { return nil }
        
        // Check if cache is still valid
        let age = Date().timeIntervalSince(cached.timestamp)
        if age > thumbnailCacheTTL {
            thumbnailCache.removeValue(forKey: windowID)
            return nil
        }
        
        return cached.image
    }
    
    private func cacheThumbnail(_ image: NSImage, for windowID: CGWindowID) {
        thumbnailCache[windowID] = (image: image, timestamp: Date())
        
        // Clean up old cache entries
        cleanupThumbnailCache()
    }
    
    private func cleanupThumbnailCache() {
        let now = Date()
        thumbnailCache = thumbnailCache.filter { _, value in
            now.timeIntervalSince(value.timestamp) <= thumbnailCacheTTL
        }
    }
    
    private func generateThumbnail(for windowInfo: WindowInfo) async -> NSImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let thumbnail = self.captureThumbnail(for: windowInfo)
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    private func captureThumbnail(for windowInfo: WindowInfo) -> NSImage? {
        guard checkScreenRecordingPermission() else { return nil }
        
        // Calculate thumbnail bounds while maintaining aspect ratio
        let thumbnailBounds = calculateThumbnailBounds(for: windowInfo.bounds)
        
        // Capture thumbnail using CGWindowListCreateImage
        guard let cgImage = CGWindowListCreateImage(
            thumbnailBounds,
            .optionIncludingWindow,
            windowInfo.id,
            [.boundsIgnoreFraming]
        ) else {
            return nil
        }
        
        // Convert to NSImage and resize if needed
        let fullImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return resizeImage(fullImage, to: thumbnailMaxSize)
    }
    
    private func calculateThumbnailBounds(for windowBounds: CGRect) -> CGRect {
        // Use a smaller region for thumbnail to improve performance
        let scale: CGFloat = 0.3  // Capture at 30% size for thumbnail
        let scaledWidth = windowBounds.width * scale
        let scaledHeight = windowBounds.height * scale
        
        return CGRect(
            x: windowBounds.origin.x,
            y: windowBounds.origin.y,
            width: max(scaledWidth, 60),  // Minimum width
            height: max(scaledHeight, 45) // Minimum height
        )
    }
    
    private func resizeImage(_ image: NSImage, to targetSize: CGSize) -> NSImage {
        // Calculate aspect ratio preserving size
        let imageSize = image.size
        let widthRatio = targetSize.width / imageSize.width
        let heightRatio = targetSize.height / imageSize.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        let scaledSize = CGSize(
            width: imageSize.width * scaleFactor,
            height: imageSize.height * scaleFactor
        )
        
        let resizedImage = NSImage(size: scaledSize)
        resizedImage.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: scaledSize))
        
        resizedImage.unlockFocus()
        return resizedImage
    }
}

// MARK: - Error Types

enum ScreenshotError: LocalizedError {
    case permissionDenied
    case captureFailure
    case conversionFailure
    case windowNotFound
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen recording permission is required to capture screenshots. Please enable it in System Preferences > Security & Privacy > Screen Recording."
        case .captureFailure:
            return "Failed to capture the selected window. The window may have been closed or moved."
        case .conversionFailure:
            return "Failed to process the screenshot image."
        case .windowNotFound:
            return "The selected window could not be found."
        }
    }
}

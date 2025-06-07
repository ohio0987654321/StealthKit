import Foundation
import AppKit
import UniformTypeIdentifiers

// MARK: - Screenshot Error Types

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

@Observable
class BrowserFileManager: NSObject {
    static let shared = BrowserFileManager()
    
    // MARK: - Download Management Properties
    private var urlSession: URLSession!
    private(set) var activeDownloads: [Download] = []
    private(set) var recentDownloads: [Download] = []
    private(set) var downloadHistory: [Download] = []
    private var downloadedURLs: Set<URL> = []
    private var recentDownloadTimers: [UUID: Timer] = [:]
    private let maxConcurrentDownloads = 5
    
    // MARK: - Screenshot Management Properties
    private var thumbnailCache: [CGWindowID: (image: NSImage, timestamp: Date)] = [:]
    private let thumbnailCacheTTL: TimeInterval = 10.0
    private let thumbnailMaxSize = CGSize(width: 80, height: 60)
    
    private override init() {
        super.init()
        setupURLSession()
    }
    
    // MARK: - Download Management
    
    private func setupURLSession() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 0
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func isAlreadyDownloading(_ url: URL) -> Bool {
        return activeDownloads.contains { $0.url == url } || downloadedURLs.contains(url)
    }
    
    func startDownload(from url: URL, suggestedFilename: String? = nil, mimeType: String? = nil) {
        guard !isAlreadyDownloading(url) else { return }
        guard activeDownloads.count < maxConcurrentDownloads else { return }
        
        let filename = suggestedFilename ?? (url.lastPathComponent.isEmpty ? "download" : url.lastPathComponent)
        let download = Download(url: url, filename: filename, mimeType: mimeType)
        
        let task = urlSession.downloadTask(with: url)
        download.downloadTask = task
        
        downloadedURLs.insert(url)
        activeDownloads.append(download)
        
        task.resume()
    }
    
    func pauseDownload(_ download: Download) {
        download.pause()
    }
    
    func resumeDownload(_ download: Download) {
        download.resume()
    }
    
    func cancelDownload(_ download: Download) {
        download.cancel()
        cleanupDownload(download)
        removeFromActiveDownloads(download)
        addToHistory(download)
    }
    
    func removeFromHistory(_ download: Download) {
        downloadHistory.removeAll { $0.id == download.id }
    }
    
    func clearHistory() {
        downloadHistory.removeAll()
    }
    
    func addScreenshot(_ download: Download) {
        recentDownloads.append(download)
        addToHistory(download)
        
        let delay: TimeInterval = 60.0
        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.removeFromRecentDownloads(download)
            }
        }
        recentDownloadTimers[download.id] = timer
    }
    
    func openInFinder(_ download: Download) {
        guard let localURL = download.localURL else { return }
        NSWorkspace.shared.selectFile(localURL.path, inFileViewerRootedAtPath: "")
    }
    
    func openFile(_ download: Download) {
        guard let localURL = download.localURL else { return }
        NSWorkspace.shared.open(localURL)
    }
    
    var hasActiveDownloads: Bool {
        return !activeDownloads.isEmpty
    }
    
    var activeDownloadCount: Int {
        return activeDownloads.count
    }
    
    var hasDownloadsToShow: Bool {
        return !activeDownloads.isEmpty || !recentDownloads.isEmpty
    }
    
    func dismissRecentDownload(_ download: Download) {
        guard recentDownloads.contains(where: { $0.id == download.id }) else { return }
        removeFromRecentDownloads(download)
    }
    
    // MARK: - File Type Detection
    
    func getUTI(for url: URL) -> String {
        if let uti = UTType(filenameExtension: url.pathExtension) {
            return uti.identifier
        }
        return getUTIFromExtension(url.pathExtension.lowercased())
    }
    
    func getMIMEType(for url: URL) -> String {
        let uti = getUTI(for: url)
        
        if let utType = UTType(uti) {
            return utType.preferredMIMEType ?? "application/octet-stream"
        }
        
        return getMIMETypeFromExtension(url.pathExtension.lowercased())
    }
    
    func isImage(_ url: URL) -> Bool {
        let uti = getUTI(for: url)
        return UTType(uti)?.conforms(to: .image) ?? false
    }
    
    func isDocument(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        let documentExtensions = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "rtf", "txt"]
        return documentExtensions.contains(fileExtension)
    }
    
    func isArchive(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        let archiveExtensions = ["zip", "rar", "7z", "tar", "gz"]
        return archiveExtensions.contains(fileExtension)
    }
    
    func isMedia(_ url: URL) -> Bool {
        let uti = getUTI(for: url)
        guard let utType = UTType(uti) else { return false }
        return utType.conforms(to: .audiovisualContent) || utType.conforms(to: .audio) || utType.conforms(to: .movie)
    }
    
    // MARK: - Screenshot Management
    
    func getAvailableWindows() -> [WindowInfo] {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        
        return windowList.compactMap { windowDict in
            guard let windowInfo = WindowInfo(from: windowDict) else { return nil }
            return windowInfo.isValidForScreenshot && !isSystemWindow(windowInfo.ownerName) ? windowInfo : nil
        }
    }
    
    func captureWindow(_ windowInfo: WindowInfo) -> Result<Data, ScreenshotError> {
        guard checkScreenRecordingPermission() else {
            return .failure(.permissionDenied)
        }
        
        let windowID = windowInfo.id
        
        guard let cgImage = CGWindowListCreateImage(
            CGRect.null,
            .optionIncludingWindow,
            windowID,
            .bestResolution
        ) else {
            return .failure(.captureFailure)
        }
        
        guard let pngData = convertCGImageToPNG(cgImage) else {
            return .failure(.conversionFailure)
        }
        
        return .success(pngData)
    }
    
    func checkScreenRecordingPermission() -> Bool {
        let testRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let testImage = CGWindowListCreateImage(testRect, .optionOnScreenOnly, kCGNullWindowID, [])
        return testImage != nil
    }
    
    func requestScreenRecordingPermission() {
        let _ = CGWindowListCreateImage(CGRect.null, .optionOnScreenOnly, kCGNullWindowID, [])
    }
    
    func generateScreenshotFilename(for windowInfo: WindowInfo) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let sanitizedTitle = sanitizeFilename(windowInfo.title)
        let sanitizedOwner = sanitizeFilename(windowInfo.ownerName)
        
        return "Screenshot_\(sanitizedOwner)_\(sanitizedTitle)_\(timestamp).png"
    }
    
    func getAvailableWindowsWithThumbnails() async -> [WindowInfo] {
        let windows = getAvailableWindows()
        var windowsWithThumbnails: [WindowInfo] = []
        
        for var window in windows {
            if let cachedThumbnail = getCachedThumbnail(for: window.id) {
                window.thumbnailImage = cachedThumbnail
            } else if let thumbnail = await generateThumbnail(for: window) {
                window.thumbnailImage = thumbnail
                cacheThumbnail(thumbnail, for: window.id)
            }
            windowsWithThumbnails.append(window)
        }
        
        cleanupThumbnailCache()
        return windowsWithThumbnails
    }
    
    // MARK: - Private Download Methods
    
    private func removeFromActiveDownloads(_ download: Download) {
        activeDownloads.removeAll { $0.id == download.id }
    }
    
    private func addToHistory(_ download: Download) {
        downloadHistory.removeAll { $0.id == download.id }
        downloadHistory.insert(download, at: 0)
    }
    
    private func cleanupDownload(_ download: Download) {
        downloadedURLs.remove(download.url)
    }
    
    private func moveToRecentDownloads(_ download: Download) {
        removeFromActiveDownloads(download)
        addToHistory(download)
        recentDownloads.append(download)
        
        let delay: TimeInterval = 60.0
        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.removeFromRecentDownloads(download)
            }
        }
        recentDownloadTimers[download.id] = timer
    }
    
    private func removeFromRecentDownloads(_ download: Download) {
        recentDownloads.removeAll { $0.id == download.id }
        recentDownloadTimers[download.id]?.invalidate()
        recentDownloadTimers.removeValue(forKey: download.id)
        // Only cleanup cancelled/failed downloads, keep completed ones tracked to prevent re-downloads
        if download.state == .cancelled || download.state == .failed {
            cleanupDownload(download)
        }
    }
    
    private func getDownloadsDirectory() -> URL {
        let fileManager = Foundation.FileManager.default
        let urls = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)
        return urls.first ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
    }
    
    private func getUniqueFilename(for originalName: String, in directory: URL) -> String {
        let fileManager = Foundation.FileManager.default
        var filename = originalName
        var counter = 1
        
        while fileManager.fileExists(atPath: directory.appendingPathComponent(filename).path) {
            let nameWithoutExtension = (originalName as NSString).deletingPathExtension
            let fileExtension = (originalName as NSString).pathExtension
            
            if fileExtension.isEmpty {
                filename = "\(nameWithoutExtension) (\(counter))"
            } else {
                filename = "\(nameWithoutExtension) (\(counter)).\(fileExtension)"
            }
            counter += 1
        }
        
        return filename
    }
    
    private func findDownload(for task: URLSessionDownloadTask) -> Download? {
        return activeDownloads.first { $0.downloadTask === task }
    }
    
    // MARK: - Private File Type Methods
    
    private func getUTIFromExtension(_ extension: String) -> String {
        switch `extension` {
        case "jpg", "jpeg": return UTType.jpeg.identifier
        case "png": return UTType.png.identifier
        case "gif": return UTType.gif.identifier
        case "webp": return UTType.webP.identifier
        case "tiff", "tif": return UTType.tiff.identifier
        case "bmp": return UTType.bmp.identifier
        case "ico": return UTType.ico.identifier
        case "svg": return UTType.svg.identifier
        case "pdf": return UTType.pdf.identifier
        case "doc": return "com.microsoft.word.doc"
        case "docx": return "org.openxmlformats.wordprocessingml.document"
        case "xls": return "com.microsoft.excel.xls"
        case "xlsx": return "org.openxmlformats.spreadsheetml.sheet"
        case "ppt": return "com.microsoft.powerpoint.ppt"
        case "pptx": return "org.openxmlformats.presentationml.presentation"
        case "rtf": return UTType.rtf.identifier
        case "txt": return UTType.plainText.identifier
        case "zip": return UTType.zip.identifier
        case "rar": return "com.rarlab.rar-archive"
        case "7z": return "org.7-zip.7-zip-archive"
        case "tar": return "public.tar-archive"
        case "gz": return UTType.gzip.identifier
        case "mp3": return UTType.mp3.identifier
        case "wav": return UTType.wav.identifier
        case "m4a": return UTType.mpeg4Audio.identifier
        case "flac": return "org.xiph.flac"
        case "aac": return "public.aac-audio"
        case "mp4": return UTType.mpeg4Movie.identifier
        case "mov": return UTType.quickTimeMovie.identifier
        case "avi": return UTType.avi.identifier
        case "mkv": return "org.matroska.mkv"
        case "webm": return "org.webmproject.webm"
        case "html", "htm": return UTType.html.identifier
        case "css": return "public.css"
        case "js": return UTType.javaScript.identifier
        case "json": return UTType.json.identifier
        case "xml": return UTType.xml.identifier
        case "csv": return UTType.commaSeparatedText.identifier
        default: return UTType.data.identifier
        }
    }
    
    private func getMIMETypeFromExtension(_ extension: String) -> String {
        switch `extension` {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "tiff", "tif": return "image/tiff"
        case "bmp": return "image/bmp"
        case "svg": return "image/svg+xml"
        case "pdf": return "application/pdf"
        case "doc": return "application/msword"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls": return "application/vnd.ms-excel"
        case "xlsx": return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "ppt": return "application/vnd.ms-powerpoint"
        case "pptx": return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case "txt": return "text/plain"
        case "rtf": return "application/rtf"
        case "zip": return "application/zip"
        case "rar": return "application/vnd.rar"
        case "7z": return "application/x-7z-compressed"
        case "tar": return "application/x-tar"
        case "gz": return "application/gzip"
        case "mp3": return "audio/mpeg"
        case "wav": return "audio/wav"
        case "m4a": return "audio/mp4"
        case "flac": return "audio/flac"
        case "aac": return "audio/aac"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "avi": return "video/x-msvideo"
        case "mkv": return "video/x-matroska"
        case "webm": return "video/webm"
        case "html", "htm": return "text/html"
        case "css": return "text/css"
        case "js": return "application/javascript"
        case "json": return "application/json"
        case "xml": return "application/xml"
        case "csv": return "text/csv"
        default: return "application/octet-stream"
        }
    }
    
    // MARK: - Private Screenshot Methods
    
    private func isSystemWindow(_ ownerName: String) -> Bool {
        let systemApps = [
            "WindowServer", "Dock", "SystemUIServer", "Control Center",
            "Notification Center", "Spotlight", "Finder", "loginwindow"
        ]
        return systemApps.contains(ownerName)
    }
    
    private func convertCGImageToPNG(_ cgImage: CGImage) -> Data? {
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapRep.representation(using: .png, properties: [:])
    }
    
    private func getCachedThumbnail(for windowID: CGWindowID) -> NSImage? {
        guard let cached = thumbnailCache[windowID] else { return nil }
        let age = Date().timeIntervalSince(cached.timestamp)
        return age < thumbnailCacheTTL ? cached.image : nil
    }
    
    private func cacheThumbnail(_ image: NSImage, for windowID: CGWindowID) {
        thumbnailCache[windowID] = (image: image, timestamp: Date())
    }
    
    private func cleanupThumbnailCache() {
        let now = Date()
        thumbnailCache = thumbnailCache.filter { _, value in
            now.timeIntervalSince(value.timestamp) < thumbnailCacheTTL
        }
    }
    
    private func generateThumbnail(for windowInfo: WindowInfo) async -> NSImage? {
        return await withUnsafeContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let thumbnail = self.captureThumbnail(for: windowInfo)
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    private func captureThumbnail(for windowInfo: WindowInfo) -> NSImage? {
        guard let cgImage = CGWindowListCreateImage(
            CGRect.null,
            .optionIncludingWindow,
            windowInfo.id,
            .bestResolution
        ) else { return nil }
        
        let thumbnailBounds = calculateThumbnailBounds(for: windowInfo.bounds)
        
        let fullImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return resizeImage(fullImage, to: thumbnailBounds.size)
    }
    
    private func calculateThumbnailBounds(for windowBounds: CGRect) -> CGRect {
        let scale: CGFloat = 0.3
        let scaledWidth = windowBounds.width * scale
        let scaledHeight = windowBounds.height * scale
        
        return CGRect(x: 0, y: 0, width: min(scaledWidth, thumbnailMaxSize.width), height: min(scaledHeight, thumbnailMaxSize.height))
    }
    
    private func resizeImage(_ image: NSImage, to targetSize: CGSize) -> NSImage {
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
        image.draw(in: NSRect(origin: .zero, size: scaledSize))
        resizedImage.unlockFocus()
        
        return resizedImage
    }
    
    private func sanitizeFilename(_ filename: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?<>|*\"")
        return filename.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

// MARK: - URLSessionDownloadDelegate

extension BrowserFileManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let download = findDownload(for: downloadTask) else { return }
        
        let downloadsDirectory = getDownloadsDirectory()
        let uniqueFilename = getUniqueFilename(for: download.filename, in: downloadsDirectory)
        let destinationURL = downloadsDirectory.appendingPathComponent(uniqueFilename)
        
        do {
            try Foundation.FileManager.default.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true)
            
            if Foundation.FileManager.default.fileExists(atPath: destinationURL.path) {
                try Foundation.FileManager.default.removeItem(at: destinationURL)
            }
            try Foundation.FileManager.default.moveItem(at: location, to: destinationURL)
            
            DispatchQueue.main.async {
                download.filename = uniqueFilename
                download.markCompleted(at: destinationURL)
                self.moveToRecentDownloads(download)
            }
        } catch {
            DispatchQueue.main.async {
                download.markFailed(with: error)
                self.moveToRecentDownloads(download)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                   didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                   totalBytesExpectedToWrite: Int64) {
        guard let download = findDownload(for: downloadTask) else { return }
        
        DispatchQueue.main.async {
            download.updateProgress(
                bytesWritten: bytesWritten,
                totalBytesWritten: totalBytesWritten,
                totalBytesExpectedToWrite: totalBytesExpectedToWrite
            )
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = task as? URLSessionDownloadTask,
              let download = findDownload(for: downloadTask) else { return }
        
        if let error = error {
            DispatchQueue.main.async {
                download.markFailed(with: error)
                self.moveToRecentDownloads(download)
            }
        }
    }
}

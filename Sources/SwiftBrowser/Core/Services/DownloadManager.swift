import Foundation
import AppKit

@Observable
class DownloadManager: NSObject {
    static let shared = DownloadManager()
    
    private var urlSession: URLSession!
    private(set) var activeDownloads: [Download] = []
    private(set) var downloadHistory: [Download] = []
    private var downloadedURLs: Set<URL> = []
    
    private override init() {
        super.init()
        setupURLSession()
    }
    
    private func setupURLSession() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 0 // No timeout for downloads
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Public Interface
    
    func isAlreadyDownloading(_ url: URL) -> Bool {
        return activeDownloads.contains { $0.url == url } || downloadedURLs.contains(url)
    }
    
    func startDownload(from url: URL, suggestedFilename: String? = nil, mimeType: String? = nil) {
        // Prevent duplicate downloads
        guard !isAlreadyDownloading(url) else {
            return
        }
        
        let filename = suggestedFilename ?? (url.lastPathComponent.isEmpty ? "download" : url.lastPathComponent)
        let download = Download(url: url, filename: filename, mimeType: mimeType)
        
        // Create URLSessionDownloadTask
        let task = urlSession.downloadTask(with: url)
        download.downloadTask = task
        
        // Track URL to prevent duplicates
        downloadedURLs.insert(url)
        
        // Add to active downloads
        activeDownloads.append(download)
        
        // Start download
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
    
    // MARK: - Private Helpers
    
    private func removeFromActiveDownloads(_ download: Download) {
        activeDownloads.removeAll { $0.id == download.id }
    }
    
    private func addToHistory(_ download: Download) {
        downloadHistory.insert(download, at: 0) // Most recent first
    }
    
    private func cleanupDownload(_ download: Download) {
        downloadedURLs.remove(download.url)
    }
    
    private func moveToHistory(_ download: Download) {
        cleanupDownload(download)
        removeFromActiveDownloads(download)
        addToHistory(download)
    }
    
    private func getDownloadsDirectory() -> URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)
        return urls.first ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
    }
    
    private func getUniqueFilename(for originalName: String, in directory: URL) -> String {
        let fileManager = FileManager.default
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
}

// MARK: - URLSessionDownloadDelegate

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let download = findDownload(for: downloadTask) else { return }
        
        let downloadsDirectory = getDownloadsDirectory()
        let uniqueFilename = getUniqueFilename(for: download.filename, in: downloadsDirectory)
        let destinationURL = downloadsDirectory.appendingPathComponent(uniqueFilename)
        
        do {
            // Ensure downloads directory exists
            try FileManager.default.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true)
            
            // Move file from temporary location to downloads directory
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
            
            DispatchQueue.main.async {
                download.filename = uniqueFilename
                download.markCompleted(at: destinationURL)
                self.moveToHistory(download)
            }
        } catch {
            DispatchQueue.main.async {
                download.markFailed(with: error)
                self.moveToHistory(download)
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
                self.moveToHistory(download)
            }
        }
    }
}

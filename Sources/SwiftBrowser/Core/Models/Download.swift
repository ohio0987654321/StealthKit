import Foundation

enum DownloadState: String, CaseIterable {
    case downloading = "downloading"
    case paused = "paused"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .downloading: return "Downloading"
        case .paused: return "Paused"
        case .completed: return "Complete"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var isActive: Bool {
        return self == .downloading || self == .paused
    }
}

@Observable
class Download: Identifiable {
    let id = UUID()
    let url: URL
    let originalFilename: String
    let mimeType: String?
    let expectedContentLength: Int64
    
    var filename: String
    var localURL: URL?
    var state: DownloadState = .downloading
    var downloadedBytes: Int64 = 0
    var error: Error?
    var startDate: Date
    var completionDate: Date?
    
    // URLSessionDownloadTask reference for control
    var downloadTask: URLSessionDownloadTask?
    
    init(url: URL, filename: String, mimeType: String? = nil, expectedContentLength: Int64 = 0) {
        self.url = url
        self.originalFilename = filename
        self.filename = filename
        self.mimeType = mimeType
        self.expectedContentLength = expectedContentLength
        self.startDate = Date()
    }
    
    var progress: Double {
        guard expectedContentLength > 0 else { return 0.0 }
        return Double(downloadedBytes) / Double(expectedContentLength)
    }
    
    var formattedFileSize: String {
        if expectedContentLength > 0 {
            return ByteCountFormatter.string(fromByteCount: expectedContentLength, countStyle: .file)
        } else if downloadedBytes > 0 {
            return ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
        }
        return "Unknown"
    }
    
    var formattedProgress: String {
        let downloaded = ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
        if expectedContentLength > 0 {
            let total = ByteCountFormatter.string(fromByteCount: expectedContentLength, countStyle: .file)
            return "\(downloaded) of \(total)"
        }
        return downloaded
    }
    
    func updateProgress(bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        self.downloadedBytes = totalBytesWritten
        if totalBytesExpectedToWrite > 0 && self.expectedContentLength != totalBytesExpectedToWrite {
            // Update expected content length if we get better information
        }
    }
    
    func markCompleted(at localURL: URL) {
        self.localURL = localURL
        self.state = .completed
        self.completionDate = Date()
        self.downloadTask = nil
    }
    
    func markFailed(with error: Error) {
        self.error = error
        self.state = .failed
        self.downloadTask = nil
    }
    
    func pause() {
        guard state == .downloading else { return }
        downloadTask?.suspend()
        state = .paused
    }
    
    func resume() {
        guard state == .paused else { return }
        downloadTask?.resume()
        state = .downloading
    }
    
    func cancel() {
        downloadTask?.cancel()
        state = .cancelled
        downloadTask = nil
    }
}

extension Download: Hashable {
    static func == (lhs: Download, rhs: Download) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

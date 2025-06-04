import Foundation
import UniformTypeIdentifiers

class FileTypeService {
    static let shared = FileTypeService()
    
    private init() {}
    
    // MARK: - UTI Detection
    
    func getUTI(for url: URL) -> String {
        // First try to get UTI from file extension
        if let uti = UTType(filenameExtension: url.pathExtension) {
            return uti.identifier
        }
        
        // Fallback to extension-based mapping
        return getUTIFromExtension(url.pathExtension.lowercased())
    }
    
    func getMIMEType(for url: URL) -> String {
        let uti = getUTI(for: url)
        
        if let utType = UTType(uti) {
            return utType.preferredMIMEType ?? "application/octet-stream"
        }
        
        // Fallback MIME type mapping
        return getMIMETypeFromExtension(url.pathExtension.lowercased())
    }
    
    private func getUTIFromExtension(_ extension: String) -> String {
        switch `extension` {
        // Images
        case "jpg", "jpeg":
            return UTType.jpeg.identifier
        case "png":
            return UTType.png.identifier
        case "gif":
            return UTType.gif.identifier
        case "webp":
            return UTType.webP.identifier
        case "tiff", "tif":
            return UTType.tiff.identifier
        case "bmp":
            return UTType.bmp.identifier
        case "ico":
            return UTType.ico.identifier
        case "svg":
            return UTType.svg.identifier
            
        // Documents
        case "pdf":
            return UTType.pdf.identifier
        case "doc":
            return "com.microsoft.word.doc"
        case "docx":
            return "org.openxmlformats.wordprocessingml.document"
        case "xls":
            return "com.microsoft.excel.xls"
        case "xlsx":
            return "org.openxmlformats.spreadsheetml.sheet"
        case "ppt":
            return "com.microsoft.powerpoint.ppt"
        case "pptx":
            return "org.openxmlformats.presentationml.presentation"
        case "rtf":
            return UTType.rtf.identifier
        case "txt":
            return UTType.plainText.identifier
            
        // Archives
        case "zip":
            return UTType.zip.identifier
        case "rar":
            return "com.rarlab.rar-archive"
        case "7z":
            return "org.7-zip.7-zip-archive"
        case "tar":
            return "public.tar-archive"
        case "gz":
            return UTType.gzip.identifier
            
        // Audio
        case "mp3":
            return UTType.mp3.identifier
        case "wav":
            return UTType.wav.identifier
        case "m4a":
            return UTType.mpeg4Audio.identifier
        case "flac":
            return "org.xiph.flac"
        case "aac":
            return "public.aac-audio"
            
        // Video
        case "mp4":
            return UTType.mpeg4Movie.identifier
        case "mov":
            return UTType.quickTimeMovie.identifier
        case "avi":
            return UTType.avi.identifier
        case "mkv":
            return "org.matroska.mkv"
        case "webm":
            return "org.webmproject.webm"
            
        // Code/Text
        case "html", "htm":
            return UTType.html.identifier
        case "css":
            return "public.css"
        case "js":
            return UTType.javaScript.identifier
        case "json":
            return UTType.json.identifier
        case "xml":
            return UTType.xml.identifier
        case "csv":
            return UTType.commaSeparatedText.identifier
            
        // Default
        default:
            return UTType.data.identifier
        }
    }
    
    private func getMIMETypeFromExtension(_ extension: String) -> String {
        switch `extension` {
        // Images
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "tiff", "tif":
            return "image/tiff"
        case "bmp":
            return "image/bmp"
        case "svg":
            return "image/svg+xml"
            
        // Documents
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls":
            return "application/vnd.ms-excel"
        case "xlsx":
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "ppt":
            return "application/vnd.ms-powerpoint"
        case "pptx":
            return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case "txt":
            return "text/plain"
        case "rtf":
            return "application/rtf"
            
        // Archives
        case "zip":
            return "application/zip"
        case "rar":
            return "application/vnd.rar"
        case "7z":
            return "application/x-7z-compressed"
        case "tar":
            return "application/x-tar"
        case "gz":
            return "application/gzip"
            
        // Audio
        case "mp3":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        case "m4a":
            return "audio/mp4"
        case "flac":
            return "audio/flac"
        case "aac":
            return "audio/aac"
            
        // Video
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "avi":
            return "video/x-msvideo"
        case "mkv":
            return "video/x-matroska"
        case "webm":
            return "video/webm"
            
        // Code/Text
        case "html", "htm":
            return "text/html"
        case "css":
            return "text/css"
        case "js":
            return "application/javascript"
        case "json":
            return "application/json"
        case "xml":
            return "application/xml"
        case "csv":
            return "text/csv"
            
        // Default
        default:
            return "application/octet-stream"
        }
    }
    
    // MARK: - File Information
    
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
}

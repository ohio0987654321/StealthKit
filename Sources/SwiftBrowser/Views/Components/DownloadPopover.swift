import SwiftUI

struct DownloadPopover: View {
    @State private var downloadManager = DownloadManager.shared
    
    var allDownloads: [Download] {
        return downloadManager.activeDownloads + downloadManager.recentDownloads
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if allDownloads.isEmpty {
                EmptyDownloadsView()
            } else {
                ActiveDownloadsView(downloads: allDownloads)
            }
        }
        .frame(width: UIConstants.DownloadPopover.width)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct EmptyDownloadsView: View {
    var body: some View {
        VStack(spacing: UIConstants.Spacing.medium) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No Active Downloads")
                .font(UITheme.Typography.body)
                .foregroundColor(.secondary)
        }
        .padding(UIConstants.Spacing.large)
        .frame(height: 120)
    }
}

struct ActiveDownloadsView: View {
    let downloads: [Download]
    
    private var activeCount: Int {
        downloads.filter { $0.state.isActive }.count
    }
    
    private var headerText: String {
        if activeCount > 0 {
            return "\(activeCount) active"
        } else {
            return "\(downloads.count) recent"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Downloads")
                    .font(UITheme.Typography.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(headerText)
                    .font(UITheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, UIConstants.Spacing.medium)
            .padding(.vertical, UIConstants.Spacing.small)
            .background(Color(NSColor.separatorColor).opacity(0.1))
            
            // Downloads list
            ScrollView {
                LazyVStack(spacing: UIConstants.Spacing.small) {
                    ForEach(downloads) { download in
                        DownloadRowView(download: download)
                    }
                }
                .padding(UIConstants.Spacing.small)
            }
            .frame(maxHeight: UIConstants.DownloadPopover.maxHeight)
        }
    }
}

struct DownloadRowView: View {
    let download: Download
    @State private var downloadManager = DownloadManager.shared
    @State private var isDragging = false
    
    private var statusText: String {
        switch download.state {
        case .downloading, .paused:
            return download.formattedProgress
        case .completed:
            return "\(download.state.displayName) • \(download.formattedFileSize)"
        case .failed, .cancelled:
            return download.state.displayName
        }
    }
    
    private var statusIcon: String? {
        switch download.state {
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .cancelled:
            return "minus.circle.fill"
        default:
            return nil
        }
    }
    
    private var statusColor: Color {
        switch download.state {
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .orange
        default:
            return .secondary
        }
    }
    
    var body: some View {
        VStack(spacing: UIConstants.Spacing.small) {
            HStack {
                // Status icon for completed/failed downloads
                if let icon = statusIcon {
                    Image(systemName: icon)
                        .foregroundColor(statusColor)
                        .font(.system(size: 14))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(download.filename)
                        .font(UITheme.Typography.body)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(statusText)
                        .font(UITheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: UIConstants.Spacing.small) {
                    // Active download controls
                    if download.state == .downloading {
                        ThemedToolbarButton(
                            icon: "pause.fill",
                            iconColor: .blue
                        ) {
                            downloadManager.pauseDownload(download)
                        }
                    } else if download.state == .paused {
                        ThemedToolbarButton(
                            icon: "play.fill",
                            iconColor: .blue
                        ) {
                            downloadManager.resumeDownload(download)
                        }
                    }
                    
                    // Actions for completed downloads
                    if download.state == .completed {
                        ThemedToolbarButton(
                            icon: "doc.text.fill",
                            iconColor: .blue
                        ) {
                            downloadManager.openFile(download)
                        }
                        
                        ThemedToolbarButton(
                            icon: "folder.fill",
                            iconColor: .blue
                        ) {
                            downloadManager.openInFinder(download)
                        }
                    }
                    
                    // Dismiss/Cancel button
                    if download.state.isActive {
                        ThemedToolbarButton(
                            icon: "xmark",
                            iconColor: .red
                        ) {
                            downloadManager.cancelDownload(download)
                        }
                    } else {
                        ThemedToolbarButton(
                            icon: "xmark",
                            iconColor: .secondary
                        ) {
                            downloadManager.dismissRecentDownload(download)
                        }
                    }
                }
            }
            
            if download.state == .downloading || download.state == .paused {
                ProgressView(value: download.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(y: 0.8)
            }
        }
        .padding(UIConstants.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                .fill(isDragging ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                        .stroke(isDragging ? Color.blue.opacity(0.3) : Color(NSColor.separatorColor), lineWidth: 0.5)
                )
        )
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
        .onDrag {
            isDragging = true
            return createDragContent()
        }
        .simultaneousGesture(
            DragGesture()
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
    
    private func createDragContent() -> NSItemProvider {
        let itemProvider = NSItemProvider()
        
        // Only allow dragging completed downloads
        guard download.state == .completed, let localURL = download.localURL else {
            return itemProvider
        }
        
        // Add the file URL to the item provider
        itemProvider.registerFileRepresentation(forTypeIdentifier: "public.item", fileOptions: [], visibility: .all) { completion in
            completion(localURL, true, nil)
            return nil
        }
        
        // Also register as a URL for compatibility
        itemProvider.registerDataRepresentation(forTypeIdentifier: "public.url", visibility: .all) { completion in
            let urlData = localURL.absoluteString.data(using: .utf8) ?? Data()
            completion(urlData, nil)
            return nil
        }
        
        // Register as plain text (file path)
        itemProvider.registerDataRepresentation(forTypeIdentifier: "public.plain-text", visibility: .all) { completion in
            let pathData = localURL.path.data(using: .utf8) ?? Data()
            completion(pathData, nil)
            return nil
        }
        
        return itemProvider
    }
}

extension UIConstants {
    enum DownloadPopover {
        static let width: CGFloat = 320
        static let maxHeight: CGFloat = 400
    }
}

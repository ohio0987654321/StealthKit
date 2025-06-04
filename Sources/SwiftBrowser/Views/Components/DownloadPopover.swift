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
                        Button(action: { downloadManager.pauseDownload(download) }) {
                            Image(systemName: "pause.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    } else if download.state == .paused {
                        Button(action: { downloadManager.resumeDownload(download) }) {
                            Image(systemName: "play.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Actions for completed downloads
                    if download.state == .completed {
                        Button(action: { downloadManager.openFile(download) }) {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { downloadManager.openInFinder(download) }) {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Dismiss/Cancel button
                    if download.state.isActive {
                        Button(action: { downloadManager.cancelDownload(download) }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: { downloadManager.dismissRecentDownload(download) }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
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
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
        )
    }
}

extension UIConstants {
    enum DownloadPopover {
        static let width: CGFloat = 320
        static let maxHeight: CGFloat = 400
    }
}

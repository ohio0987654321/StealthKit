import SwiftUI

struct DownloadPopover: View {
    @State private var downloadManager = DownloadManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            if downloadManager.activeDownloads.isEmpty {
                EmptyDownloadsView()
            } else {
                ActiveDownloadsView(downloads: downloadManager.activeDownloads)
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Downloads")
                    .font(UITheme.Typography.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(downloads.count) active")
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
    @State var download: Download
    @State private var downloadManager = DownloadManager.shared
    
    var body: some View {
        VStack(spacing: UIConstants.Spacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(download.filename)
                        .font(UITheme.Typography.body)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(download.formattedProgress)
                        .font(UITheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: UIConstants.Spacing.small) {
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
                    
                    Button(action: { downloadManager.cancelDownload(download) }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
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

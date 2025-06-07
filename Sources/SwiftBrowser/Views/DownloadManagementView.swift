import SwiftUI
import AppKit

struct DownloadManagementView: View {
    @State private var fileManager = BrowserFileManager.shared
    @State private var searchText = ""
    @State private var selectedDownloads = Set<Download.ID>()
    @State private var showingDeleteAlert = false
    
    var filteredDownloads: [Download] {
        if searchText.isEmpty {
            return fileManager.downloadHistory
        } else {
            return fileManager.downloadHistory.filter { download in
                download.filename.localizedCaseInsensitiveContains(searchText) ||
                download.url.absoluteString.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: UIConstants.Spacing.medium) {
                HStack {
                    Text("Download Management")
                        .font(UITheme.Typography.title)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !fileManager.downloadHistory.isEmpty {
                        Button("Clear All") {
                            showingDeleteAlert = true
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.red)
                    }
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search downloads", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(UIConstants.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                )
            }
            .padding(UIConstants.Spacing.large)
            
            Divider()
            
            // Content
            if filteredDownloads.isEmpty {
                EmptyDownloadHistoryView(hasSearchText: !searchText.isEmpty)
            } else {
                DownloadHistoryListView(
                    downloads: filteredDownloads,
                    selectedDownloads: $selectedDownloads
                )
            }
        }
        .alert("Clear Download History", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                fileManager.clearHistory()
            }
        } message: {
            Text("This will permanently remove all download history. This action cannot be undone.")
        }
    }
}

struct EmptyDownloadHistoryView: View {
    let hasSearchText: Bool
    
    var body: some View {
        VStack(spacing: UIConstants.Spacing.large) {
            Image(systemName: hasSearchText ? "magnifyingglass" : "arrow.down.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: UIConstants.Spacing.small) {
                Text(hasSearchText ? "No Matching Downloads" : "No Download History")
                    .font(UITheme.Typography.headline)
                    .foregroundColor(.primary)
                
                Text(hasSearchText ? 
                     "Try adjusting your search terms." :
                     "Downloaded files will appear here for easy access.")
                    .font(UITheme.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(UIConstants.Spacing.xlarge)
    }
}

struct DownloadHistoryListView: View {
    let downloads: [Download]
    @Binding var selectedDownloads: Set<Download.ID>
    @State private var fileManager = BrowserFileManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: UIConstants.Spacing.small) {
                ForEach(downloads) { download in
                    DownloadHistoryRowView(download: download)
                }
            }
            .padding(UIConstants.Spacing.medium)
        }
    }
}

struct DownloadHistoryRowView: View {
    let download: Download
    @State private var fileManager = BrowserFileManager.shared
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: UIConstants.Spacing.medium) {
            // File icon and info
            VStack(alignment: .leading, spacing: UIConstants.Spacing.tiny) {
                HStack {
                    ThemedToolbarButton(
                        icon: "trash",
                        iconColor: .red
                    ) {
                        fileManager.removeFromHistory(download)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(download.filename)
                            .font(UITheme.Typography.body)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Text(download.url.host ?? download.url.absoluteString)
                            .font(UITheme.Typography.caption)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(download.state.displayName)
                            .font(UITheme.Typography.caption)
                            .foregroundColor(colorForState(download.state))
                        
                        if let date = download.completionDate ?? Optional(download.startDate) {
                            Text(relativeDateString(for: date))
                                .font(UITheme.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                HStack {
                    Text(download.formattedFileSize)
                        .font(UITheme.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if isHovered {
                        HStack(spacing: UIConstants.Spacing.small) {
                            if download.state == .completed {
                                Button("Open") {
                                    fileManager.openFile(download)
                                }
                                .buttonStyle(.borderless)
                                .font(UITheme.Typography.caption)
                                
                                Button("Show in Finder") {
                                    fileManager.openInFinder(download)
                                }
                                .buttonStyle(.borderless)
                                .font(UITheme.Typography.caption)
                            }
                        }
                    }
                }
            }
        }
        .padding(UIConstants.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                .fill(isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
        )
        .onHover { hovering in
            withAnimation(UITheme.Animation.quick) {
                isHovered = hovering
            }
        }
    }
    
    private func iconForFile(_ filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        
        switch ext {
        case "pdf":
            return "doc.richtext"
        case "zip", "rar", "7z", "tar", "gz":
            return "archivebox"
        case "dmg", "pkg":
            return "shippingbox"
        case "mp3", "wav", "aac", "m4a":
            return "music.note"
        case "mp4", "mov", "avi", "mkv":
            return "play.rectangle"
        case "jpg", "jpeg", "png", "gif", "bmp":
            return "photo"
        case "doc", "docx":
            return "doc.text"
        case "xls", "xlsx":
            return "tablecells"
        case "ppt", "pptx":
            return "slider.horizontal.below.rectangle"
        default:
            return "doc"
        }
    }
    
    private func colorForState(_ state: DownloadState) -> Color {
        switch state {
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .orange
        case .downloading, .paused:
            return .blue
        }
    }
    
    private func relativeDateString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

import SwiftUI

struct DownloadPopover: View {
    @State private var fileManager = BrowserFileManager.shared
    
    var allDownloads: [Download] {
        return fileManager.activeDownloads + fileManager.recentDownloads
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
    @State private var fileManager = BrowserFileManager.shared
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
                            fileManager.pauseDownload(download)
                        }
                    } else if download.state == .paused {
                        ThemedToolbarButton(
                            icon: "play.fill",
                            iconColor: .blue
                        ) {
                            fileManager.resumeDownload(download)
                        }
                    }
                    
                    // Actions for completed downloads
                    if download.state == .completed {
                        ThemedToolbarButton(
                            icon: "doc.text.fill",
                            iconColor: .blue
                        ) {
                            fileManager.openFile(download)
                        }
                        
                        ThemedToolbarButton(
                            icon: "folder.fill",
                            iconColor: .blue
                        ) {
                            fileManager.openInFinder(download)
                        }
                    }
                    
                    // Dismiss/Cancel button
                    if download.state.isActive {
                        ThemedToolbarButton(
                            icon: "xmark",
                            iconColor: .red
                        ) {
                            fileManager.cancelDownload(download)
                        }
                    } else {
                        ThemedToolbarButton(
                            icon: "xmark",
                            iconColor: .secondary
                        ) {
                            fileManager.dismissRecentDownload(download)
                        }
                    }
                }
            }
            
            if download.state == .downloading || download.state == .paused {
                if download.isIndeterminate {
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(y: 0.8)
                } else {
                    ProgressView(value: download.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(y: 0.8)
                }
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
        
        let specificUTI = fileManager.getUTI(for: localURL)
        
        // 1. Register file representation with specific UTI (primary)
        itemProvider.registerFileRepresentation(
            forTypeIdentifier: specificUTI,
            fileOptions: .openInPlace,
            visibility: .all
        ) { completion in
            completion(localURL, true, nil)
            return nil
        }
        
        // 2. Register file representation with generic data UTI (fallback)
        itemProvider.registerFileRepresentation(
            forTypeIdentifier: "public.data",
            fileOptions: .openInPlace,
            visibility: .all
        ) { completion in
            completion(localURL, true, nil)
            return nil
        }
        
        // 3. Register file URL for browser compatibility
        itemProvider.registerDataRepresentation(
            forTypeIdentifier: "public.file-url",
            visibility: .all
        ) { completion in
            Task { @MainActor in
                let urlData = localURL.absoluteString.data(using: .utf8) ?? Data()
                completion(urlData, nil)
            }
            return nil
        }
        
        // 4. Register as URL for web drag-and-drop
        itemProvider.registerDataRepresentation(
            forTypeIdentifier: "public.url",
            visibility: .all
        ) { completion in
            Task { @MainActor in
                let urlData = localURL.absoluteString.data(using: .utf8) ?? Data()
                completion(urlData, nil)
            }
            return nil
        }
        
        // 5. Register file data directly for maximum compatibility
        if FileManager.default.fileExists(atPath: localURL.path) {
            itemProvider.registerDataRepresentation(
                forTypeIdentifier: specificUTI,
                visibility: .all
            ) { completion in
                Task { @MainActor in
                    do {
                        let fileData = try Data(contentsOf: localURL)
                        completion(fileData, nil)
                    } catch {
                        completion(nil, error)
                    }
                }
                return nil
            }
        }
        
        // 6. Set suggested name for the drag session
        itemProvider.suggestedName = localURL.lastPathComponent
        
        return itemProvider
    }
}

extension UIConstants {
    enum DownloadPopover {
        static let width: CGFloat = 320
        static let maxHeight: CGFloat = 400
    }
}

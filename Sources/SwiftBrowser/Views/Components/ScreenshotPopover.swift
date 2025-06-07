import SwiftUI

struct ScreenshotPopover: View {
    @State private var fileManager = BrowserFileManager.shared
    @State private var availableWindows: [WindowInfo] = []
    @State private var selectedWindow: WindowInfo?
    @State private var isCapturing = false
    @State private var isLoadingThumbnails = false
    @State private var errorMessage: String?
    
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Screenshot")
                    .font(UITheme.Typography.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if availableWindows.isEmpty {
                    Text("No windows")
                        .font(UITheme.Typography.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(availableWindows.count) windows")
                        .font(UITheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, UIConstants.Spacing.medium)
            .padding(.vertical, UIConstants.Spacing.small)
            .background(Color(NSColor.separatorColor).opacity(0.1))
            
            if availableWindows.isEmpty {
                EmptyWindowsView()
            } else {
                WindowListView(
                    windows: availableWindows,
                    selectedWindow: $selectedWindow,
                    onCapture: captureSelectedWindow,
                    onRefresh: refreshWindowList,
                    isCapturing: isCapturing
                )
            }
            
            if let errorMessage = errorMessage {
                ErrorMessageView(message: errorMessage) {
                    self.errorMessage = nil
                }
            }
        }
        .frame(width: UIConstants.ScreenshotPopover.width)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            refreshWindowList()
        }
    }
    
    private func refreshWindowList() {
        isLoadingThumbnails = true
        
        Task {
            let windowsWithThumbnails = await fileManager.getAvailableWindowsWithThumbnails()
            
            await MainActor.run {
                availableWindows = windowsWithThumbnails
                selectedWindow = availableWindows.first
                isLoadingThumbnails = false
            }
        }
    }
    
    private func captureSelectedWindow() {
        guard let window = selectedWindow else { return }
        
        isCapturing = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = fileManager.captureWindow(window)
            
            DispatchQueue.main.async {
                isCapturing = false
                
                switch result {
                case .success(let imageData):
                    saveScreenshot(imageData: imageData, windowInfo: window)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func saveScreenshot(imageData: Data, windowInfo: WindowInfo) {
        let filename = fileManager.generateScreenshotFilename(for: windowInfo)
        let downloadsDirectory = getDownloadsDirectory()
        let fileURL = downloadsDirectory.appendingPathComponent(filename)
        
        do {
            try FileManager.default.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true)
            try imageData.write(to: fileURL)
            
            // Create a Download object for the screenshot
            let screenshotDownload = Download(
                url: fileURL,
                filename: filename,
                mimeType: "image/png"
            )
            screenshotDownload.markCompleted(at: fileURL)
            
            // Add to download manager
            fileManager.addScreenshot(screenshotDownload)
            
            // Dismiss the popover
            onDismiss()
            
        } catch {
            errorMessage = "Failed to save screenshot: \(error.localizedDescription)"
        }
    }
    
    private func getDownloadsDirectory() -> URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)
        return urls.first ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
    }
}

struct EmptyWindowsView: View {
    var body: some View {
        VStack(spacing: UIConstants.Spacing.medium) {
            Image(systemName: "camera")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            VStack(spacing: UIConstants.Spacing.small) {
                Text("No Windows Available")
                    .font(UITheme.Typography.body)
                    .foregroundColor(.secondary)
                
                Text("Make sure other apps are open and visible")
                    .font(UITheme.Typography.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(UIConstants.Spacing.large)
        .frame(height: 140)
    }
}

struct WindowListView: View {
    let windows: [WindowInfo]
    @Binding var selectedWindow: WindowInfo?
    let onCapture: () -> Void
    let onRefresh: () -> Void
    let isCapturing: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Window list
            ScrollView {
                LazyVStack(spacing: UIConstants.Spacing.small) {
                    ForEach(windows) { window in
                        WindowRowView(
                            window: window,
                            isSelected: selectedWindow?.id == window.id
                        ) {
                            selectedWindow = window
                        }
                    }
                }
                .padding(UIConstants.Spacing.small)
            }
            .frame(maxHeight: UIConstants.ScreenshotPopover.maxHeight)
            
            // Action button
            Divider()
            
            HStack {
                Button("Refresh") {
                    onRefresh()
                }
                .buttonStyle(ThemedButtonStyle(.secondary))
                .disabled(isCapturing)
                
                Spacer()
                
                Button(isCapturing ? "Capturing..." : "Screenshot") {
                    onCapture()
                }
                .buttonStyle(ThemedButtonStyle(.primary))
                .disabled(selectedWindow == nil || isCapturing)
            }
            .padding(UIConstants.Spacing.medium)
        }
    }
}

struct WindowRowView: View {
    let window: WindowInfo
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: UIConstants.Spacing.medium) {
            // Window thumbnail or placeholder
            Group {
                if let thumbnail = window.thumbnailImage {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 45)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                        )
                } else {
                    // Loading placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(NSColor.placeholderTextColor).opacity(0.2))
                        .frame(width: 60, height: 45)
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "photo")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                Text("Loading")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                        )
                }
            }
            
            // Window information
            VStack(alignment: .leading, spacing: 2) {
                Text(window.displayName)
                    .font(UITheme.Typography.body)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                HStack {
                    Text("\(Int(window.bounds.width))×\(Int(window.bounds.height))")
                        .font(UITheme.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // App name if different from title
                    if window.title != window.ownerName && !window.title.isEmpty {
                        Text(window.ownerName)
                            .font(UITheme.Typography.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                    }
                }
            }
            
            Spacer()
            
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            }
        }
        .padding(UIConstants.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                        .stroke(isSelected ? Color.blue.opacity(0.3) : Color(NSColor.separatorColor), lineWidth: 0.5)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

struct ErrorMessageView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(UITheme.Typography.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button("×") {
                onDismiss()
            }
            .foregroundColor(.secondary)
        }
        .padding(UIConstants.Spacing.small)
        .background(Color.red.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.red.opacity(0.3)),
            alignment: .top
        )
    }
}

extension UIConstants {
    enum ScreenshotPopover {
        static let width: CGFloat = 320
        static let maxHeight: CGFloat = 300
    }
}

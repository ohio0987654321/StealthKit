import SwiftUI
import AppKit

// MARK: - Simple Utility Views

struct EmptyTabView: View {
    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FaviconView: View {
    let faviconData: String?
    let url: URL
    @State private var faviconImage: NSImage?
    
    var body: some View {
        Group {
            if let image = faviconImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        Image(systemName: "globe")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    )
            }
        }
        .onAppear {
            loadFavicon()
        }
        .onChange(of: faviconData) { _, _ in
            loadFavicon()
        }
    }
    
    private func loadFavicon() {
        if let faviconData = faviconData,
           let data = Data(base64Encoded: faviconData),
           let image = NSImage(data: data) {
            faviconImage = image
        } else {
            // Try to load from cache
            let domain = BrowserStateManager.domain(from: url)
            faviconImage = BrowserStateManager.shared.getFavicon(for: domain)
        }
    }
}

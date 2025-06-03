import SwiftUI
import AppKit

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
            let domain = FaviconCache.domain(from: url)
            faviconImage = FaviconCache.shared.getFavicon(for: domain)
        }
    }
}

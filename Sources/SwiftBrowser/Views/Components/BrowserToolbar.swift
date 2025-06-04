import SwiftUI
import WebKit

struct BrowserNavigationButtons: View {
    @Binding var currentTab: Tab?
    let onNavigateBack: () -> Void
    let onNavigateForward: () -> Void
    let onReloadOrStop: () -> Void
    let isWebContentActive: Bool
    
    var body: some View {
        HStack(spacing: UIConstants.Spacing.medium) {
            ThemedToolbarButton(
                icon: "chevron.left",
                isDisabled: !(currentTab?.canGoBack ?? false) || !isWebContentActive
            ) {
                onNavigateBack()
            }
            
            ThemedToolbarButton(
                icon: "chevron.right",
                isDisabled: !(currentTab?.canGoForward ?? false) || !isWebContentActive
            ) {
                onNavigateForward()
            }
            
            ThemedToolbarButton(
                icon: currentTab?.isLoading == true ? "xmark" : "arrow.clockwise",
                isDisabled: !isWebContentActive
            ) {
                onReloadOrStop()
            }
        }
    }
}

struct BrowserAddressField: View {
    @Binding var addressText: String
    @FocusState.Binding var isAddressBarFocused: Bool
    @Binding var currentTab: Tab?
    
    let onSubmit: () -> Void
    let isWebContentActive: Bool
    
    var body: some View {
        TextField("Enter URL or search", text: $addressText)
            .textFieldStyle(.roundedBorder)
            .font(UITheme.Typography.addressBar)
            .focused($isAddressBarFocused)
            .onSubmit {
                onSubmit()
            }
            .onChange(of: currentTab?.url) { _, newURL in
                if !isAddressBarFocused && isWebContentActive {
                    addressText = newURL?.absoluteString ?? ""
                }
            }
            .frame(minWidth: UIConstants.AddressBar.minWidth, maxWidth: UIConstants.AddressBar.maxWidth)
    }
}

struct BrowserDownloadButton: View {
    @State private var downloadManager = DownloadManager.shared
    @State private var showingDownloadPopover = false
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            showingDownloadPopover.toggle()
        }) {
            ZStack {
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(downloadManager.hasActiveDownloads ? .blue : .secondary)
                
                if downloadManager.hasActiveDownloads {
                    Text("\(downloadManager.activeDownloadCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(2)
                        .background(Circle().fill(Color.red))
                        .offset(x: 8, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
        .animation(.easeInOut(duration: AnimationConstants.Timing.fast), value: isPressed)
        .animation(.easeInOut(duration: AnimationConstants.Timing.medium), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .popover(isPresented: $showingDownloadPopover, arrowEdge: Edge.bottom) {
            DownloadPopover()
        }
    }
}

struct BrowserNewTabButton: View {
    let onNewTab: () -> Void
    
    var body: some View {
        ThemedToolbarButton(
            icon: "plus"
        ) {
            onNewTab()
        }
    }
}

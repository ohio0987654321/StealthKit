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

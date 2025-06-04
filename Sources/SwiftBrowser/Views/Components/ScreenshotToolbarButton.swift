import SwiftUI

struct ScreenshotToolbarButton: View {
    let onToggleScreenshotPopover: () -> Void
    @State private var screenshotService = ScreenshotService.shared
    
    var body: some View {
        ThemedToolbarButton(
            icon: "camera",
            isDisabled: false
        ) {
            onToggleScreenshotPopover()
        }
    }
}

import SwiftUI

@main
struct SwiftBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            BrowserView()
                .onAppear {
                    DispatchQueue.main.async {
                        _ = WindowService.shared
                    }
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: UIConstants.Window.defaultWidth, height: UIConstants.Window.defaultHeight)
    }
}


// Notification names for keyboard shortcuts
extension Notification.Name {
    static let newTab = Notification.Name("newTab")
    static let closeTab = Notification.Name("closeTab")
    static let reload = Notification.Name("reload")
    static let focusAddressBar = Notification.Name("focusAddressBar")
    static let openSettings = Notification.Name("openSettings")
}

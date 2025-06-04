import Foundation
import SwiftUI

class AppCoordinator: CoordinatorProtocol {
    var childCoordinators: [CoordinatorProtocol] = []
    weak var parentCoordinator: CoordinatorProtocol?
    
    private var browserCoordinator: BrowserCoordinator?
    
    func start() {
        setupBrowserCoordinator()
    }
    
    private func setupBrowserCoordinator() {
        let browserCoordinator = BrowserCoordinator()
        self.browserCoordinator = browserCoordinator
        addChildCoordinator(browserCoordinator)
        browserCoordinator.start()
    }
    
    func handleNotification(_ notification: Notification) {
        switch notification.name {
        case .newTab:
            browserCoordinator?.createNewTab()
        case .closeTab:
            browserCoordinator?.closeCurrentTab()
        case .reload:
            browserCoordinator?.reloadCurrentTab()
        case .focusAddressBar:
            browserCoordinator?.focusAddressBar()
        case .openSettings:
            browserCoordinator?.navigateToSettings(.browserUtilities)
        default:
            break
        }
    }
}

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
        // Tab Management
        case .newTab:
            browserCoordinator?.createNewTab()
        case .closeTab:
            browserCoordinator?.closeCurrentTab()
        case .reopenClosedTab:
            browserCoordinator?.reopenClosedTab()
        case .nextTab:
            browserCoordinator?.selectNextTab()
        case .previousTab:
            browserCoordinator?.selectPreviousTab()
        case .selectTab1:
            browserCoordinator?.selectTab(at: 0)
        case .selectTab2:
            browserCoordinator?.selectTab(at: 1)
        case .selectTab3:
            browserCoordinator?.selectTab(at: 2)
        case .selectTab4:
            browserCoordinator?.selectTab(at: 3)
        case .selectTab5:
            browserCoordinator?.selectTab(at: 4)
        case .selectTab6:
            browserCoordinator?.selectTab(at: 5)
        case .selectTab7:
            browserCoordinator?.selectTab(at: 6)
        case .selectTab8:
            browserCoordinator?.selectTab(at: 7)
        case .selectTab9:
            browserCoordinator?.selectTab(at: 8)
        // Navigation
        case .reload:
            browserCoordinator?.reloadCurrentTab()
        case .navigateBack:
            browserCoordinator?.navigateBack()
        case .navigateForward:
            browserCoordinator?.navigateForward()
        // View
        case .findInPage:
            browserCoordinator?.showFindInPage()
        // Settings
        case .openSettings:
            browserCoordinator?.navigateToSettings(.browserUtilities)
        default:
            break
        }
    }
}

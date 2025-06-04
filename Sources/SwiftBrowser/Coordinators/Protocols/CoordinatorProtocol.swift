import Foundation

protocol CoordinatorProtocol: AnyObject {
    var childCoordinators: [CoordinatorProtocol] { get set }
    var parentCoordinator: CoordinatorProtocol? { get set }
    
    func start()
    func finish()
    func addChildCoordinator(_ coordinator: CoordinatorProtocol)
    func removeChildCoordinator(_ coordinator: CoordinatorProtocol)
}

extension CoordinatorProtocol {
    func addChildCoordinator(_ coordinator: CoordinatorProtocol) {
        childCoordinators.append(coordinator)
        coordinator.parentCoordinator = self
    }
    
    func removeChildCoordinator(_ coordinator: CoordinatorProtocol) {
        childCoordinators.removeAll { $0 === coordinator }
        coordinator.parentCoordinator = nil
    }
    
    func finish() {
        childCoordinators.forEach { $0.finish() }
        childCoordinators.removeAll()
        parentCoordinator?.removeChildCoordinator(self)
    }
}

protocol NavigationCoordinatorProtocol: CoordinatorProtocol {
    func navigateToTab(with url: URL?)
    func navigateToSettings(_ settingsType: SettingsType)
    func closeTab(withId tabId: UUID)
    func createNewTab() -> UUID
}

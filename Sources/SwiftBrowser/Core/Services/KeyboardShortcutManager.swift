import Foundation
import AppKit

struct KeyboardShortcut {
    let id: String
    let keyEquivalent: String
    let modifierMask: NSEvent.ModifierFlags
    let title: String
    let description: String
    let category: ShortcutCategory
    let notificationName: Notification.Name?
    let action: (() -> Void)?
    
    init(
        id: String,
        keyEquivalent: String,
        modifierMask: NSEvent.ModifierFlags,
        title: String,
        description: String,
        category: ShortcutCategory,
        notificationName: Notification.Name? = nil,
        action: (() -> Void)? = nil
    ) {
        self.id = id
        self.keyEquivalent = keyEquivalent
        self.modifierMask = modifierMask
        self.title = title
        self.description = description
        self.category = category
        self.notificationName = notificationName
        self.action = action
    }
    
    var displayKeyEquivalent: String {
        var result = ""
        
        if modifierMask.contains(.command) {
            result += "⌘"
        }
        if modifierMask.contains(.shift) {
            result += "⇧"
        }
        if modifierMask.contains(.option) {
            result += "⌥"
        }
        if modifierMask.contains(.control) {
            result += "⌃"
        }
        
        switch keyEquivalent {
        case "\u{7F}": // Delete key
            result += "⌫"
        case "\u{F700}": // Up arrow
            result += "↑"
        case "\u{F701}": // Down arrow
            result += "↓"
        case "\u{F702}": // Left arrow
            result += "←"
        case "\u{F703}": // Right arrow
            result += "→"
        case " ":
            result += "Space"
        default:
            result += keyEquivalent.uppercased()
        }
        
        return result
    }
}

enum ShortcutCategory: String, CaseIterable {
    case tab = "Tab Management"
    case window = "Window Management"
    case navigation = "Navigation"
    case view = "View"
    
    var icon: String {
        switch self {
        case .tab:
            return "square.stack"
        case .window:
            return "macwindow"
        case .navigation:
            return "arrow.left.arrow.right"
        case .view:
            return "eye"
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let reopenClosedTab = Notification.Name("reopenClosedTab")
    static let navigateBack = Notification.Name("navigateBack")
    static let navigateForward = Notification.Name("navigateForward")
    static let nextTab = Notification.Name("nextTab")
    static let previousTab = Notification.Name("previousTab")
    static let selectTab1 = Notification.Name("selectTab1")
    static let selectTab2 = Notification.Name("selectTab2")
    static let selectTab3 = Notification.Name("selectTab3")
    static let selectTab4 = Notification.Name("selectTab4")
    static let selectTab5 = Notification.Name("selectTab5")
    static let selectTab6 = Notification.Name("selectTab6")
    static let selectTab7 = Notification.Name("selectTab7")
    static let selectTab8 = Notification.Name("selectTab8")
    static let selectTab9 = Notification.Name("selectTab9")
}

class KeyboardShortcutManager: ObservableObject {
    static let shared = KeyboardShortcutManager()
    
    private init() {}
    
    lazy var shortcuts: [KeyboardShortcut] = [
        // Tab Management
        KeyboardShortcut(
            id: "newTab",
            keyEquivalent: "t",
            modifierMask: .command,
            title: "New Tab",
            description: "Create a new tab",
            category: .tab,
            notificationName: .newTab
        ),
        KeyboardShortcut(
            id: "closeTab",
            keyEquivalent: "w",
            modifierMask: .command,
            title: "Close Tab",
            description: "Close the current tab",
            category: .tab,
            notificationName: .closeTab
        ),
        KeyboardShortcut(
            id: "reopenClosedTab",
            keyEquivalent: "t",
            modifierMask: [.command, .shift],
            title: "Reopen Closed Tab",
            description: "Reopen the last closed tab",
            category: .tab,
            notificationName: .reopenClosedTab
        ),
        KeyboardShortcut(
            id: "nextTab",
            keyEquivalent: "\u{F703}", // Right arrow
            modifierMask: [.command, .option],
            title: "Next Tab",
            description: "Switch to the next tab",
            category: .tab,
            notificationName: .nextTab
        ),
        KeyboardShortcut(
            id: "previousTab",
            keyEquivalent: "\u{F702}", // Left arrow
            modifierMask: [.command, .option],
            title: "Previous Tab",
            description: "Switch to the previous tab",
            category: .tab,
            notificationName: .previousTab
        ),
        
        // Tab selection shortcuts (1-9)
        KeyboardShortcut(
            id: "selectTab1",
            keyEquivalent: "1",
            modifierMask: .command,
            title: "Switch to Tab 1",
            description: "Switch to the first tab",
            category: .tab,
            notificationName: .selectTab1
        ),
        KeyboardShortcut(
            id: "selectTab2",
            keyEquivalent: "2",
            modifierMask: .command,
            title: "Switch to Tab 2",
            description: "Switch to the second tab",
            category: .tab,
            notificationName: .selectTab2
        ),
        KeyboardShortcut(
            id: "selectTab3",
            keyEquivalent: "3",
            modifierMask: .command,
            title: "Switch to Tab 3",
            description: "Switch to the third tab",
            category: .tab,
            notificationName: .selectTab3
        ),
        KeyboardShortcut(
            id: "selectTab4",
            keyEquivalent: "4",
            modifierMask: .command,
            title: "Switch to Tab 4",
            description: "Switch to the fourth tab",
            category: .tab,
            notificationName: .selectTab4
        ),
        KeyboardShortcut(
            id: "selectTab5",
            keyEquivalent: "5",
            modifierMask: .command,
            title: "Switch to Tab 5",
            description: "Switch to the fifth tab",
            category: .tab,
            notificationName: .selectTab5
        ),
        KeyboardShortcut(
            id: "selectTab6",
            keyEquivalent: "6",
            modifierMask: .command,
            title: "Switch to Tab 6",
            description: "Switch to the sixth tab",
            category: .tab,
            notificationName: .selectTab6
        ),
        KeyboardShortcut(
            id: "selectTab7",
            keyEquivalent: "7",
            modifierMask: .command,
            title: "Switch to Tab 7",
            description: "Switch to the seventh tab",
            category: .tab,
            notificationName: .selectTab7
        ),
        KeyboardShortcut(
            id: "selectTab8",
            keyEquivalent: "8",
            modifierMask: .command,
            title: "Switch to Tab 8",
            description: "Switch to the eighth tab",
            category: .tab,
            notificationName: .selectTab8
        ),
        KeyboardShortcut(
            id: "selectTab9",
            keyEquivalent: "9",
            modifierMask: .command,
            title: "Switch to Tab 9",
            description: "Switch to the ninth tab",
            category: .tab,
            notificationName: .selectTab9
        ),
        
        // Navigation
        KeyboardShortcut(
            id: "reload",
            keyEquivalent: "r",
            modifierMask: .command,
            title: "Reload",
            description: "Reload the current page",
            category: .navigation,
            notificationName: .reload
        ),
        KeyboardShortcut(
            id: "navigateBack",
            keyEquivalent: "\u{F702}", // Left arrow
            modifierMask: .command,
            title: "Go Back",
            description: "Navigate to the previous page",
            category: .navigation,
            notificationName: .navigateBack
        ),
        KeyboardShortcut(
            id: "navigateForward",
            keyEquivalent: "\u{F703}", // Right arrow
            modifierMask: .command,
            title: "Go Forward",
            description: "Navigate to the next page",
            category: .navigation,
            notificationName: .navigateForward
        )
    ]
    
    func shortcutsByCategory() -> [ShortcutCategory: [KeyboardShortcut]] {
        return Dictionary(grouping: shortcuts, by: { $0.category })
    }
    
    func shortcut(withId id: String) -> KeyboardShortcut? {
        return shortcuts.first { $0.id == id }
    }
    
    func shortcuts(for category: ShortcutCategory) -> [KeyboardShortcut] {
        return shortcuts.filter { $0.category == category }
    }
}

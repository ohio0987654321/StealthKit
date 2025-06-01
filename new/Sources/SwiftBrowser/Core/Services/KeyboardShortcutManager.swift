//
//  KeyboardShortcutManager.swift
//  SwiftBrowser
//
//  Service for managing browser keyboard shortcuts.
//  Replaces the Objective-C ShortcutManager implementation.
//

import SwiftUI

// MARK: - Keyboard Shortcut Definitions

struct BrowserKeyboardShortcuts {
    // Common browser shortcuts
    static let newTab = KeyboardShortcut("t", modifiers: .command)
    static let closeTab = KeyboardShortcut("w", modifiers: .command)
    static let nextTab = KeyboardShortcut("]", modifiers: [.command, .shift])
    static let previousTab = KeyboardShortcut("[", modifiers: [.command, .shift])
    static let refresh = KeyboardShortcut("r", modifiers: .command)
    static let addressBar = KeyboardShortcut("l", modifiers: .command)
    static let addBookmark = KeyboardShortcut("d", modifiers: .command)
    static let goBack = KeyboardShortcut("[", modifiers: .command)
    static let goForward = KeyboardShortcut("]", modifiers: .command)
}

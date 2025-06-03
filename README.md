# SwiftBrowser

A clean, fast macOS browser built with SwiftUI and WebKit.

## Features

- **Tabbed Browsing**: Multiple tabs with visual indicators and easy management
- **Native macOS Design**: Clean interface that follows macOS design principles
- **Fast Navigation**: Back, forward, and reload functionality
- **Search Integration**: Built-in search with customizable search engines
- **Settings Panel**: Browser and window utilities
- **Keyboard Shortcuts**: Standard browser shortcuts (⌘T, ⌘W, ⌘R, ⌘L)

## Requirements

- macOS 13.0+
- Xcode 14.0+
- Swift 5.7+

## Installation

1. Clone the repository
2. Open `Package.swift` in Xcode
3. Build and run the project

## Usage

- **New Tab**: ⌘T or click the + button
- **Close Tab**: ⌘W or click the X on a tab
- **Reload**: ⌘R
- **Address Bar**: ⌘L or click in the address field
- **Navigate**: Use back/forward buttons or standard gestures

## Architecture

- **SwiftUI**: Modern declarative UI framework
- **WebKit**: Apple's web rendering engine
- **MVVM Pattern**: Clean separation of concerns
- **Observable**: State management with @Observable

The app features a sidebar for navigation, tabbed browsing interface, and integrates seamlessly with macOS.

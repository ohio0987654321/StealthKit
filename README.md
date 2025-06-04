# SwiftBrowser

A clean, fast macOS browser built with SwiftUI and WebKit. This browser focuses on a minimal but effective security & privacy layer, with comprehensive settings management unified under an organized control panel.

## Features

### Core Browsing
- **Tabbed Browsing**: Full tab management with visual indicators, easy switching, and proper state preservation
- **Smart Address Bar**: Intelligent URL detection, domain completion, and integrated search functionality
- **Fast Navigation**: Back, forward, reload, and stop functionality with keyboard shortcuts
- **Native macOS Design**: Clean interface following macOS design principles and conventions

### Settings & Management
- **Browser Utilities**: Core browser configuration and preferences
- **Window Utilities**: Window management and display options including Traffic Light Prevention
- **Security & Privacy**: Comprehensive privacy controls and security settings
- **History Management**: Browse and manage browsing history with search capabilities
- **Cookie Management**: View, organize, and delete cookies by domain with detailed information

### Search & Navigation
- **Multiple Search Engines**: Support for Google, Bing, DuckDuckGo, and Yahoo
- **Smart URL Handling**: Automatic protocol detection and search query conversion
- **Keyboard Shortcuts**: Full support for standard browser shortcuts

## Requirements

- macOS 13.0+
- Xcode 14.0+
- Swift 5.7+

## Installation

1. Clone the repository
2. Open `Package.swift` in Xcode
3. Build and run the project

## Usage

### Navigation
- **New Tab**: ⌘T or click the + button
- **Close Tab**: ⌘W or click the X on a tab
- **Reload/Stop**: ⌘R or click the reload/stop button
- **Address Bar**: ⌘L or click in the address field
- **Back/Forward**: Use navigation buttons or standard gestures

### Address Bar
Type any of the following in the address bar:
- **URLs**: `https://example.com` → Direct navigation
- **Domains**: `example.com` → Adds https:// automatically
- **Search Terms**: `swift programming` → Uses selected search engine

### Settings Access
Access different settings categories through the sidebar:
- Browser configuration and preferences
- Window management options
- Security and privacy controls
- History browsing and management
- Cookie viewing and management

## Architecture

### Core Components
- **TabManager**: Centralized tab state management and operations
- **SwiftUI Views**: Modern declarative UI with proper state binding
- **WebKit Integration**: Apple's web rendering engine with custom coordination
- **Settings Services**: Modular services for different browser functions

### Project Structure
```
Sources/SwiftBrowser/
├── App/                    # Application entry point
├── Core/
│   ├── Constants/          # UI constants and configuration
│   ├── Managers/           # TabManager and other core managers
│   ├── Models/             # Data models (Tab, Settings, etc.)
│   ├── Services/           # Core services (History, Cookies, etc.)
│   └── UI/                 # UI components and theming
├── Views/
│   ├── Components/         # Reusable UI components
│   └── [Various Views]     # Main application views
├── WebKit/                 # WebView coordination and integration
└── Resources/              # Assets, entitlements, and configuration
```

### Key Design Principles
- **Modular Architecture**: Clean separation of concerns with focused responsibilities
- **State Management**: Centralized tab state with proper SwiftUI binding
- **Reusable Components**: Modular UI components for consistent design
- **Native Integration**: Deep macOS integration with proper window management

## Technical Highlights

- **Tab State Preservation**: Maintains active tab selection during window recreation
- **Smart Address Processing**: Intelligent handling of URLs, domains, and search queries
- **Comprehensive Settings**: Organized settings with dedicated management interfaces
- **Privacy-Focused**: Built-in cookie management and privacy controls
- **Performance Optimized**: Efficient tab switching and memory management

The app features a sidebar-based navigation system, comprehensive tab management, and seamless integration with macOS window management systems.

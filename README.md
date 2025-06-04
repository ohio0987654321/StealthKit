# SwiftBrowser

A clean, fast macOS browser built with SwiftUI and WebKit using MVVM + Coordinator architecture. This browser focuses on a minimal but effective security & privacy layer, with comprehensive settings management unified under an organized control panel.

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

```bash
# Quick build
make

# Or using Swift Package Manager directly
swift build -c release
```

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

SwiftBrowser follows a clean **MVVM + Coordinator** architecture pattern for maintainability, testability, and scalability.

### Architecture Pattern

```
┌─────────────────┐
│   AppCoordinator │ ◄── Handles app-level notifications
└─────────────────┘
         │
         ▼
┌─────────────────┐
│BrowserCoordinator│ ◄── Manages navigation logic
└─────────────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│ BrowserViewModel │ ◄── │  BrowserView    │
└─────────────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│   TabService    │ ◄── Business logic
└─────────────────┘
         │
         ▼
┌─────────────────┐
│   Tab Models    │ ◄── Data layer
└─────────────────┘
```

### Core Components

#### Coordinators
- **AppCoordinator**: Manages app-level navigation and notifications
- **BrowserCoordinator**: Handles browser-specific navigation flows
- **CoordinatorProtocol**: Base protocol for all coordinators

#### ViewModels
- **BrowserViewModel**: Contains business logic for the main browser interface
- Uses `@Observable` for reactive state management
- Delegates navigation to coordinators

#### Services
- **TabService**: Centralized tab state management and operations
- **WindowService**: Window management and display coordination
- **HistoryManager**: Browsing history management
- **CookieManager**: Cookie storage and privacy controls
- **FaviconCache**: Website icon caching

#### Views
- Pure SwiftUI views focused only on UI rendering
- Receive state from ViewModels via data binding
- Delegate user actions to ViewModels

### Project Structure

```
Sources/SwiftBrowser/
├── App/                          # Application entry point
│   └── SwiftBrowserApp.swift
├── Coordinators/                 # Navigation logic
│   ├── Protocols/
│   │   └── CoordinatorProtocol.swift
│   ├── AppCoordinator.swift
│   └── BrowserCoordinator.swift
├── ViewModels/                   # Business logic
│   └── BrowserViewModel.swift
├── Core/
│   ├── Constants/                # All constants consolidated
│   │   ├── UIConstants.swift
│   │   └── AnimationConstants.swift
│   ├── Models/                   # Data models
│   │   ├── Tab.swift
│   │   ├── Settings.swift
│   │   └── SecuritySettings.swift
│   ├── Services/                 # Business services
│   │   ├── TabService.swift
│   │   ├── WindowService.swift
│   │   ├── HistoryManager.swift
│   │   ├── CookieManager.swift
│   │   └── FaviconCache.swift
│   └── UI/                       # UI components and theming
│       ├── UIComponents.swift
│       ├── UITheme.swift
│       └── PanelScene.swift
├── Views/                        # Pure UI views
│   ├── BrowserView.swift
│   ├── SidebarView.swift
│   ├── Components/
│   │   └── BrowserToolbar.swift
│   └── [Other Views]
├── WebKit/                       # WebView coordination
│   └── WebViewCoordinator.swift
└── Resources/                    # Assets and configuration
    ├── App.icns
    ├── Entitlements.plist
    └── Info.plist
```

## Development Guidelines

### Architecture Principles

#### 1. MVVM + Coordinator Pattern
- **Views**: Handle only UI rendering and user interaction
- **ViewModels**: Contain business logic and state management
- **Coordinators**: Manage navigation flows and screen transitions
- **Services**: Provide business logic and data management

#### 2. Separation of Concerns
- Each component has a single, well-defined responsibility
- Business logic stays in ViewModels and Services
- Navigation logic stays in Coordinators
- UI logic stays in Views

#### 3. Dependency Direction
```
Views → ViewModels → Coordinators → Services → Models
```

### Adding New Features

#### 1. New View + ViewModel
```swift
// 1. Create the ViewModel
@Observable
class NewFeatureViewModel {
    private let coordinator: SomeCoordinator
    private let service: SomeService
    
    init(coordinator: SomeCoordinator, service: SomeService) {
        self.coordinator = coordinator
        self.service = service
    }
    
    func handleUserAction() {
        // Business logic here
        coordinator.navigate(to: .somewhere)
    }
}

// 2. Create the View
struct NewFeatureView: View {
    @State private var viewModel: NewFeatureViewModel
    
    var body: some View {
        // UI code only
    }
}

// 3. Wire up in Coordinator
func showNewFeature() {
    let viewModel = NewFeatureViewModel(coordinator: self, service: someService)
    let view = NewFeatureView(viewModel: viewModel)
    // Present view
}
```

#### 2. New Service
```swift
@Observable
class NewService {
    static let shared = NewService()
    private init() {}
    
    // Service implementation
}
```

#### 3. New Coordinator
```swift
class NewCoordinator: CoordinatorProtocol {
    func start() {
        // Navigation logic
    }
}
```

### Code Organization

#### Constants Management
- **UI Constants**: Use `UIConstants` for dimensions, colors, etc.
- **Animation Constants**: Use `AnimationConstants.Timing.*` for all timing values
- **No Magic Numbers**: Always use semantic constant names

```swift
// ✅ Good
withAnimation(.easeInOut(duration: AnimationConstants.Timing.fast)) {
    // animation code
}

// ❌ Bad
withAnimation(.easeInOut(duration: 0.1)) {
    // animation code
}
```

#### File Organization
- Group related files in appropriate directories
- Follow the established folder structure
- Use clear, descriptive naming conventions

#### SwiftUI Best Practices
- Keep Views focused on UI only
- Use `@State` for local UI state
- Use `@Observable` ViewModels for business state
- Prefer `@Observable` over `@ObservableObject` for new code

### Testing Strategy

#### ViewModels Testing
```swift
class BrowserViewModelTests: XCTestCase {
    func testAddressSubmission() {
        // Test business logic in isolation
        let mockCoordinator = MockBrowserCoordinator()
        let viewModel = BrowserViewModel(coordinator: mockCoordinator)
        
        viewModel.handleAddressSubmit("https://example.com")
        
        XCTAssertTrue(mockCoordinator.didNavigate)
    }
}
```

#### Services Testing
```swift
class TabServiceTests: XCTestCase {
    func testCreateTab() {
        let service = TabService.shared
        let initialCount = service.tabs.count
        
        service.createTab(with: URL(string: "https://example.com"))
        
        XCTAssertEqual(service.tabs.count, initialCount + 1)
    }
}
```

#### Coordinators Testing
```swift
class BrowserCoordinatorTests: XCTestCase {
    func testNavigationFlow() {
        let coordinator = BrowserCoordinator()
        
        coordinator.navigateToTab(with: URL(string: "https://example.com"))
        
        // Assert navigation occurred
    }
}
```

### Code Style Guidelines

#### Swift Conventions
- Use `camelCase` for variables and functions
- Use `PascalCase` for types and protocols
- Use meaningful names that describe intent
- Prefer explicit types when clarity improves

#### Documentation
- Document public APIs with Swift documentation comments
- Include usage examples for complex functions
- Document architectural decisions in code comments

#### Error Handling
- Use proper Swift error handling (`throws`, `try`, `catch`)
- Provide meaningful error messages
- Handle errors at appropriate architectural levels

### Performance Guidelines

#### State Management
- Use `@Observable` for reactive state updates
- Minimize unnecessary view updates
- Keep ViewModels focused and lightweight

#### Memory Management
- Properly manage coordinator lifecycle
- Clean up resources in deinit methods
- Use weak references to prevent retain cycles

#### Build Performance
- Keep build times fast by avoiding unnecessary dependencies
- Use proper access control (`private`, `internal`, `public`)
- Minimize cross-module dependencies

## Contributing

### Development Setup
1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes following the architecture guidelines
4. Write tests for new functionality
5. Ensure all tests pass: `swift test`
6. Build successfully: `make` or `swift build`
7. Submit a pull request

### Code Review Process
- All changes require code review
- Follow the established architecture patterns
- Include tests for new features
- Update documentation as needed
- Ensure build passes without warnings

### Commit Guidelines
- Use clear, descriptive commit messages
- Follow conventional commit format when possible
- Keep commits focused and atomic
- Reference issues in commit messages when applicable

## Technical Highlights

- **Modern Architecture**: Clean MVVM + Coordinator pattern for maintainability
- **Reactive State**: Uses `@Observable` for efficient state management
- **Tab State Preservation**: Maintains active tab selection during window recreation
- **Smart Address Processing**: Intelligent handling of URLs, domains, and search queries
- **Comprehensive Settings**: Organized settings with dedicated management interfaces
- **Privacy-Focused**: Built-in cookie management and privacy controls
- **Performance Optimized**: Efficient tab switching and memory management
- **Swift 6 Ready**: Full concurrency support with proper actor isolation

The app features a sidebar-based navigation system, comprehensive tab management, and seamless integration with macOS window management systems.

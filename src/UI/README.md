# UIManager - Centralized UI Management System

The UIManager is a comprehensive UI management system designed to provide consistent styling, theming, and component creation throughout the StealthKit browser application.

## Overview

The UIManager solves common UI consistency problems by providing:

- **Centralized styling** - All UI components use the same styling rules
- **Theme management** - Easy switching between light/dark themes
- **Component factories** - Consistent creation of UI elements
- **Layout utilities** - Standard spacing and sizing constants
- **Automatic theme updates** - Components automatically update when themes change

## Architecture

```
UIManager (Singleton)
├── Theme System
│   ├── Light/Dark/Auto themes
│   ├── Color definitions
│   └── System appearance tracking
├── Component Factory
│   ├── Button creation
│   ├── Text field creation
│   └── Container creation
├── Style Application
│   ├── Button styling
│   ├── Text field styling
│   └── Container styling
└── Layout Utilities
    ├── Dimension constants
    ├── Spacing helpers
    └── Constraint utilities
```

## Key Features

### 1. Theme Management

```objc
UIManager *uiManager = [UIManager sharedManager];

// Set theme
[uiManager setTheme:UIThemeDark];    // Force dark
[uiManager setTheme:UIThemeLight];   // Force light
[uiManager setTheme:UIThemeAuto];    // Follow system

// Check current theme
BOOL isDark = [uiManager isDarkMode];
```

### 2. Component Creation

```objc
// Create buttons with consistent styling
NSButton *actionButton = [uiManager createButtonWithTitle:@"Download"
                                                    style:UIButtonStyleAction
                                                   target:self
                                                   action:@selector(download:)];

NSButton *navButton = [uiManager createButtonWithTitle:@"←"
                                                  style:UIButtonStyleNavigation
                                                 target:self
                                                 action:@selector(goBack:)];

// Create text fields
NSTextField *addressBar = [uiManager createTextFieldWithPlaceholder:@"Enter URL"
                                                               style:UITextFieldStyleAddressBar];

NSTextField *searchField = [uiManager createTextFieldWithPlaceholder:@"Search..."
                                                                style:UITextFieldStyleSearch];
```

### 3. Style Application

```objc
// Apply styles to existing components
[uiManager styleButton:existingButton withStyle:UIButtonStyleSecondary];
[uiManager styleTextField:existingField withStyle:UITextFieldStyleForm];
[uiManager styleAsToolbar:containerView];
```

### 4. Layout Constants

```objc
// Use consistent dimensions
CGFloat toolbarHeight = uiManager.toolbarHeight;        // 44.0
CGFloat spacing = uiManager.standardSpacing;            // 8.0
CGFloat smallSpacing = uiManager.smallSpacing;          // 4.0
CGFloat largeSpacing = uiManager.largeSpacing;          // 16.0

// Apply consistent button sizing
[uiManager applyNavigationButtonConstraints:button];
```

### 5. Theme-Aware Colors

```objc
// Colors automatically adjust to current theme
NSColor *primaryBg = uiManager.primaryBackgroundColor;
NSColor *secondaryBg = uiManager.secondaryBackgroundColor;
NSColor *textColor = uiManager.primaryTextColor;
NSColor *accent = uiManager.accentColor;
NSColor *border = uiManager.borderColor;
```

## Component Styles

### Button Styles

- **UIButtonStyleNavigation** - Back, forward, reload buttons
- **UIButtonStyleTab** - Tab buttons with close functionality
- **UIButtonStyleAction** - Primary action buttons (blue accent)
- **UIButtonStyleSecondary** - Secondary buttons (gray)
- **UIButtonStyleClose** - Close/dismiss buttons (circular)

### Text Field Styles

- **UITextFieldStyleAddressBar** - URL/search input with rounded corners
- **UITextFieldStyleSearch** - General search fields
- **UITextFieldStyleForm** - Form input fields with square borders

## Theme Integration

Components automatically respond to theme changes by registering for the `StealthKitThemeChanged` notification:

```objc
// In your view setup
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(themeChanged:)
                                             name:@"StealthKitThemeChanged"
                                           object:nil];

// Theme change handler
- (void)themeChanged:(NSNotification *)notification {
    UIManager *uiManager = [UIManager sharedManager];
    [uiManager styleButton:self.button withStyle:UIButtonStyleAction];
    // Reapply other styles as needed
}
```

## Refactored Components

The following components have been updated to use UIManager:

### AddressBarView
- Uses `UITextFieldStyleAddressBar` for consistent styling
- Automatically updates on theme changes
- Eliminates hard-coded colors and fonts

### ToolbarView
- Creates navigation buttons using UIManager factory methods
- Uses UIManager layout constants for spacing
- Applies toolbar styling through UIManager

### Future Components
All new UI components should use UIManager for:
- Component creation
- Style application
- Layout constants
- Theme integration

## Best Practices

1. **Always use UIManager** for creating new UI components
2. **Register for theme notifications** in views that need to update
3. **Use dimension constants** instead of hard-coded values
4. **Apply consistent styling** using the provided style enums
5. **Test with different themes** to ensure proper appearance

## Example Usage

See `UIManagerDemo.m` for comprehensive examples of:
- Component creation
- Style application
- Layout using constants
- Theme management
- Custom dialog creation

## Benefits

✅ **Consistency** - All UI elements have the same look and feel
✅ **Maintainability** - Changes in one place affect the entire app
✅ **Theme Support** - Easy dark/light mode implementation
✅ **Cleaner Code** - Views focus on logic, not styling
✅ **Scalability** - Easy to add new components with consistent styling
✅ **Accessibility** - Centralized place to implement accessibility features

The UIManager system transforms scattered, inconsistent UI code into a cohesive, maintainable system that provides a professional, polished appearance throughout the StealthKit browser.

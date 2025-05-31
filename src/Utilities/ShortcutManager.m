//
//  ShortcutManager.m
//  StealthKit
//
//  Created on Multi-Window & Multi-Tab Implementation
//

#import "ShortcutManager.h"
#import "BrowserWindow.h"
#import "TabManager.h"
#import "ToolbarView.h"
#import "AddressBarView.h"

@interface ShortcutManager ()
@property (nonatomic, strong) id localEventMonitor;
@property (nonatomic, weak) id windowManager;
@property (nonatomic, weak) id tabManager;
@property (nonatomic) BOOL shortcutsActive;
@end

@implementation ShortcutManager

+ (instancetype)shared {
    static ShortcutManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ShortcutManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _shortcutsActive = NO;
    }
    return self;
}

- (void)registerAllShortcuts {
    if (self.shortcutsActive) {
        NSLog(@"ShortcutManager: Shortcuts already registered");
        return;
    }
    
    NSLog(@"ShortcutManager: Registering keyboard shortcuts...");
    
    // Register local event monitor for key events
    self.localEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown
                                                                   handler:^NSEvent *(NSEvent *event) {
        return [self handleKeyEvent:event];
    }];
    
    self.shortcutsActive = YES;
    NSLog(@"ShortcutManager: All shortcuts registered successfully");
}

- (void)unregisterAllShortcuts {
    if (!self.shortcutsActive) {
        return;
    }
    
    NSLog(@"ShortcutManager: Unregistering keyboard shortcuts...");
    
    if (self.localEventMonitor) {
        [NSEvent removeMonitor:self.localEventMonitor];
        self.localEventMonitor = nil;
    }
    
    self.shortcutsActive = NO;
    NSLog(@"ShortcutManager: All shortcuts unregistered");
}

- (void)setWindowManager:(id)windowManager {
    _windowManager = windowManager;
    NSLog(@"ShortcutManager: Window manager connected");
}

- (void)setTabManager:(id)tabManager {
    _tabManager = tabManager;
    NSLog(@"ShortcutManager: Tab manager connected");
}

#pragma mark - Event Handling

- (NSEvent *)handleKeyEvent:(NSEvent *)event {
    NSString *shortcutKey = [self shortcutKeyFromEvent:event];
    
    if (shortcutKey && [self handleShortcut:shortcutKey withEvent:event]) {
        // Shortcut was handled, consume the event
        return nil;
    }
    
    // Let the event continue to its normal destination
    return event;
}

- (NSString *)shortcutKeyFromEvent:(NSEvent *)event {
    NSEventModifierFlags modifiers = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
    NSString *key = event.charactersIgnoringModifiers.lowercaseString;
    
    // Tab Management Shortcuts
    if (modifiers == NSEventModifierFlagCommand) {
        if ([key isEqualToString:@"t"]) return @"newTab";
        if ([key isEqualToString:@"w"]) return @"closeTab";
        if ([key isEqualToString:@"n"]) return @"newWindow";
        if ([key isEqualToString:@"m"]) return @"minimizeWindow";
        if ([key isEqualToString:@"`"]) return @"cycleWindows";
        if ([key isEqualToString:@"l"]) return @"focusAddressBar";
        if ([key isEqualToString:@"r"]) return @"reload";
        if ([key isEqualToString:@"f"]) return @"findInPage";
        if ([key isEqualToString:@"g"]) return @"findNext";
        if ([key isEqualToString:@"e"]) return @"useSelectionForFind";
        
        // Check for number keys (1-9) for tab switching
        if (key.length == 1) {
            unichar c = [key characterAtIndex:0];
            if (c >= '1' && c <= '9') {
                return [NSString stringWithFormat:@"switchToTab%d", c - '0'];
            }
        }
        
        // Arrow keys for navigation
        if (event.keyCode == 123) return @"goBack";    // Left arrow
        if (event.keyCode == 124) return @"goForward"; // Right arrow
    }
    
    // Cmd+Shift combinations
    else if (modifiers == (NSEventModifierFlagCommand | NSEventModifierFlagShift)) {
        if ([key isEqualToString:@"t"]) return @"reopenClosedTab";
        if ([key isEqualToString:@"w"]) return @"closeWindow";
        if ([key isEqualToString:@"n"]) return @"newStealthWindow";
        if ([key isEqualToString:@"r"]) return @"hardReload";
        if ([key isEqualToString:@"g"]) return @"findPrevious";
    }
    
    // Cmd+Option combinations
    else if (modifiers == (NSEventModifierFlagCommand | NSEventModifierFlagOption)) {
        if (event.keyCode == 124) return @"nextTab";     // Right arrow
        if (event.keyCode == 123) return @"previousTab"; // Left arrow
    }
    
    return nil;
}

- (BOOL)handleShortcut:(NSString *)shortcutKey withEvent:(NSEvent *)event {
    NSLog(@"ShortcutManager: Handling shortcut: %@", shortcutKey);
    
    // Tab Management
    if ([shortcutKey isEqualToString:@"newTab"]) {
        return [self handleNewTab];
    } else if ([shortcutKey isEqualToString:@"closeTab"]) {
        return [self handleCloseTab];
    } else if ([shortcutKey isEqualToString:@"reopenClosedTab"]) {
        return [self handleReopenClosedTab];
    } else if ([shortcutKey isEqualToString:@"nextTab"]) {
        return [self handleNextTab];
    } else if ([shortcutKey isEqualToString:@"previousTab"]) {
        return [self handlePreviousTab];
    } else if ([shortcutKey hasPrefix:@"switchToTab"]) {
        int tabNumber = [[shortcutKey substringFromIndex:11] intValue];
        return [self handleSwitchToTab:tabNumber];
    }
    
    // Window Management
    else if ([shortcutKey isEqualToString:@"newWindow"]) {
        return [self handleNewWindow];
    } else if ([shortcutKey isEqualToString:@"newStealthWindow"]) {
        return [self handleNewStealthWindow];
    } else if ([shortcutKey isEqualToString:@"closeWindow"]) {
        return [self handleCloseWindow];
    } else if ([shortcutKey isEqualToString:@"minimizeWindow"]) {
        return [self handleMinimizeWindow];
    } else if ([shortcutKey isEqualToString:@"cycleWindows"]) {
        return [self handleCycleWindows];
    }
    
    // Navigation
    else if ([shortcutKey isEqualToString:@"focusAddressBar"]) {
        return [self handleFocusAddressBar];
    } else if ([shortcutKey isEqualToString:@"reload"]) {
        return [self handleReload];
    } else if ([shortcutKey isEqualToString:@"hardReload"]) {
        return [self handleHardReload];
    } else if ([shortcutKey isEqualToString:@"goBack"]) {
        return [self handleGoBack];
    } else if ([shortcutKey isEqualToString:@"goForward"]) {
        return [self handleGoForward];
    }
    
    // Search & Find
    else if ([shortcutKey isEqualToString:@"findInPage"]) {
        return [self handleFindInPage];
    } else if ([shortcutKey isEqualToString:@"findNext"]) {
        return [self handleFindNext];
    } else if ([shortcutKey isEqualToString:@"findPrevious"]) {
        return [self handleFindPrevious];
    } else if ([shortcutKey isEqualToString:@"useSelectionForFind"]) {
        return [self handleUseSelectionForFind];
    }
    
    return NO;
}

#pragma mark - Tab Management Handlers

- (BOOL)handleNewTab {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        BrowserWindow *browserWindow = (BrowserWindow *)currentWindow;
        [browserWindow.tabManager createNewTab:YES];
        return YES;
    }
    
    // Fallback: Post notification for AppDelegate
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StealthKitNewTab" object:nil];
    return YES;
}

- (BOOL)handleCloseTab {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        BrowserWindow *browserWindow = (BrowserWindow *)currentWindow;
        [browserWindow.tabManager closeCurrentTab];
        return YES;
    }
    
    return NO;
}

- (BOOL)handleReopenClosedTab {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        BrowserWindow *browserWindow = (BrowserWindow *)currentWindow;
        [browserWindow.tabManager reopenLastClosedTab];
        return YES;
    }
    
    return NO;
}

- (BOOL)handleNextTab {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        BrowserWindow *browserWindow = (BrowserWindow *)currentWindow;
        [browserWindow.tabManager selectNextTab];
        return YES;
    }
    
    return NO;
}

- (BOOL)handlePreviousTab {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        BrowserWindow *browserWindow = (BrowserWindow *)currentWindow;
        [browserWindow.tabManager selectPreviousTab];
        return YES;
    }
    
    return NO;
}

- (BOOL)handleSwitchToTab:(int)tabNumber {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        BrowserWindow *browserWindow = (BrowserWindow *)currentWindow;
        [browserWindow.tabManager selectTabAtIndex:(tabNumber - 1)];
        return YES;
    }
    
    return NO;
}

#pragma mark - Window Management Handlers

- (BOOL)handleNewWindow {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StealthKitCreateNewWindow" object:nil];
    return YES;
}

- (BOOL)handleNewStealthWindow {
    // All windows are stealth windows in StealthKit
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StealthKitCreateNewWindow" object:nil];
    return YES;
}

- (BOOL)handleCloseWindow {
    NSWindow *currentWindow = [NSApp keyWindow];
    if (currentWindow) {
        [currentWindow performClose:nil];
        return YES;
    }
    return NO;
}

- (BOOL)handleMinimizeWindow {
    NSWindow *currentWindow = [NSApp keyWindow];
    if (currentWindow) {
        [currentWindow miniaturize:nil];
        return YES;
    }
    return NO;
}

- (BOOL)handleCycleWindows {
    if ([self.windowManager respondsToSelector:@selector(cycleToNextWindow)]) {
        [self.windowManager performSelector:@selector(cycleToNextWindow)];
        return YES;
    }
    
    // Fallback: Use standard window cycling
    [[NSApp keyWindow] selectNextKeyView:nil];
    return YES;
}

#pragma mark - Navigation Handlers

- (BOOL)handleFocusAddressBar {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        BrowserWindow *browserWindow = (BrowserWindow *)currentWindow;
        [browserWindow.toolbarView.addressBar focusAddressField];
        return YES;
    }
    
    NSLog(@"ShortcutManager: No browser window found to focus address bar");
    return NO;
}

- (BOOL)handleReload {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        [(BrowserWindow *)currentWindow reload];
        return YES;
    }
    return NO;
}

- (BOOL)handleHardReload {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        BrowserWindow *browserWindow = (BrowserWindow *)currentWindow;
        // Hard reload: reload ignoring cache
        [browserWindow.webView reloadFromOrigin];
        return YES;
    }
    return NO;
}

- (BOOL)handleGoBack {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        [(BrowserWindow *)currentWindow goBack];
        return YES;
    }
    return NO;
}

- (BOOL)handleGoForward {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        [(BrowserWindow *)currentWindow goForward];
        return YES;
    }
    return NO;
}

#pragma mark - Search & Find Handlers

- (BOOL)handleFindInPage {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        [(BrowserWindow *)currentWindow showFindInterface];
        return YES;
    }
    return NO;
}

- (BOOL)handleFindNext {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        [(BrowserWindow *)currentWindow findNext];
        return YES;
    }
    return NO;
}

- (BOOL)handleFindPrevious {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        [(BrowserWindow *)currentWindow findPrevious];
        return YES;
    }
    return NO;
}

- (BOOL)handleUseSelectionForFind {
    NSWindow *currentWindow = [NSApp keyWindow];
    if ([currentWindow isKindOfClass:[BrowserWindow class]]) {
        [(BrowserWindow *)currentWindow useSelectionForFind];
        return YES;
    }
    return NO;
}

@end

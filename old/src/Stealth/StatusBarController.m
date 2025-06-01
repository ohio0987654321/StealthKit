//
//  StatusBarController.m
//  StealthKit
//
//  Created on Phase 4: Stealth Features Implementation
//

#import "StatusBarController.h"
#import "BrowserWindow.h"
#import "SearchEngineManager.h"

@interface StatusBarController ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, weak) BrowserWindow *mainBrowserWindow;
@property (nonatomic, strong) NSMenu *statusMenu;
@end

@implementation StatusBarController

+ (instancetype)shared {
    static StatusBarController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[StatusBarController alloc] init];
    });
    return instance;
}

- (void)setupStatusBar {
    if (self.statusItem) {
        NSLog(@"StealthKit: Status bar already set up");
        return;
    }
    
    NSLog(@"StealthKit: Setting up status bar...");
    
    // Create status item
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    // Configure status item appearance
    NSImage *statusImage = [NSImage imageWithSystemSymbolName:@"network.badge.shield.half.filled" accessibilityDescription:@"StealthKit"];
    if (statusImage) {
        [statusImage setTemplate:YES];
        self.statusItem.button.image = statusImage;
    } 
    self.statusItem.button.toolTip = @"StealthKit - Privacy Browser";
    
    // Create and set menu
    [self createStatusMenu];
    self.statusItem.menu = self.statusMenu;
    
    NSLog(@"StealthKit: Status bar setup complete");
}

- (void)removeStatusBar {
    if (!self.statusItem) {
        return;
    }
    
    NSLog(@"StealthKit: Removing status bar...");
    
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
    self.statusItem = nil;
    self.statusMenu = nil;
    
    NSLog(@"StealthKit: Status bar removed");
}

- (BOOL)isStatusBarActive {
    return self.statusItem != nil;
}

- (void)updateStatusBarMenu {
    if (!self.statusItem) {
        return;
    }
    
    [self createStatusMenu];
    self.statusItem.menu = self.statusMenu;
}

- (void)setMainBrowserWindow:(BrowserWindow *)window {
    _mainBrowserWindow = window;
    [self updateStatusBarMenu];
}

#pragma mark - Menu Creation

- (void)createStatusMenu {
    self.statusMenu = [[NSMenu alloc] init];
    
    // Header
    NSMenuItem *headerItem = [[NSMenuItem alloc] initWithTitle:@"StealthKit Browser"
                                                        action:nil
                                                 keyEquivalent:@""];
    headerItem.enabled = NO;
    [self.statusMenu addItem:headerItem];
    
    [self.statusMenu addItem:[NSMenuItem separatorItem]];
    
    // Search Engine Selection
    [self addSearchEngineMenuToMenu];
    
    [self.statusMenu addItem:[NSMenuItem separatorItem]];
    
    // Application Controls
    [self addApplicationControlsToMenu];
}

- (void)addBrowserControlsToMenu {
    // Show/Hide Browser Window
    if (self.mainBrowserWindow) {
        NSString *windowTitle = self.mainBrowserWindow.isVisible ? @"Hide Browser" : @"Show Browser";
        NSMenuItem *windowItem = [[NSMenuItem alloc] initWithTitle:windowTitle
                                                            action:@selector(toggleBrowserWindow:)
                                                     keyEquivalent:@""];
        windowItem.target = self;
        [self.statusMenu addItem:windowItem];
        
        // Navigation controls (only if window exists)
        if (self.mainBrowserWindow.isVisible) {
            NSMenuItem *backItem = [[NSMenuItem alloc] initWithTitle:@"Back"
                                                              action:@selector(goBack:)
                                                       keyEquivalent:@""];
            backItem.target = self;
            [self.statusMenu addItem:backItem];
            
            NSMenuItem *forwardItem = [[NSMenuItem alloc] initWithTitle:@"Forward"
                                                                 action:@selector(goForward:)
                                                          keyEquivalent:@""];
            forwardItem.target = self;
            [self.statusMenu addItem:forwardItem];
            
            NSMenuItem *reloadItem = [[NSMenuItem alloc] initWithTitle:@"Reload"
                                                                action:@selector(reload:)
                                                         keyEquivalent:@""];
            reloadItem.target = self;
            [self.statusMenu addItem:reloadItem];
        }
    } else {
        NSMenuItem *newWindowItem = [[NSMenuItem alloc] initWithTitle:@"New Browser Window"
                                                               action:@selector(createNewWindow:)
                                                        keyEquivalent:@""];
        newWindowItem.target = self;
        [self.statusMenu addItem:newWindowItem];
    }
}

- (void)addSearchEngineMenuToMenu {
    // Search Engine submenu
    NSMenuItem *searchEngineItem = [[NSMenuItem alloc] initWithTitle:@"Search Engine"
                                                              action:nil
                                                       keyEquivalent:@""];
    NSMenu *searchEngineMenu = [[NSMenu alloc] init];
    
    SearchEngineManager *searchManager = [SearchEngineManager shared];
    NSArray<NSString *> *engineNames = [searchManager availableSearchEngineDisplayNames];
    
    for (NSString *engineName in engineNames) {
        NSMenuItem *engineItem = [[NSMenuItem alloc] initWithTitle:engineName
                                                            action:@selector(selectSearchEngine:)
                                                     keyEquivalent:@""];
        engineItem.target = self;
        engineItem.representedObject = engineName;
        
        // Mark current search engine
        if ([engineName isEqualToString:searchManager.currentSearchEngine.displayName]) {
            engineItem.state = NSControlStateValueOn;
        }
        
        [searchEngineMenu addItem:engineItem];
    }
    
    searchEngineItem.submenu = searchEngineMenu;
    [self.statusMenu addItem:searchEngineItem];
}

- (void)addWindowManagementToMenu {
    NSMenuItem *windowsItem = [[NSMenuItem alloc] initWithTitle:@"Windows"
                                                         action:nil
                                                  keyEquivalent:@""];
    NSMenu *windowsMenu = [[NSMenu alloc] init];
    
    // Add items for window management
    NSMenuItem *minimizeAllItem = [[NSMenuItem alloc] initWithTitle:@"Minimize All"
                                                             action:@selector(minimizeAllWindows:)
                                                      keyEquivalent:@""];
    minimizeAllItem.target = self;
    [windowsMenu addItem:minimizeAllItem];
    
    NSMenuItem *showAllItem = [[NSMenuItem alloc] initWithTitle:@"Show All"
                                                         action:@selector(showAllWindows:)
                                                  keyEquivalent:@""];
    showAllItem.target = self;
    [windowsMenu addItem:showAllItem];
    
    windowsItem.submenu = windowsMenu;
    [self.statusMenu addItem:windowsItem];
}

- (void)addApplicationControlsToMenu {
    // About
    NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:@"About StealthKit"
                                                       action:@selector(showAbout:)
                                                keyEquivalent:@""];
    aboutItem.target = self;
    [self.statusMenu addItem:aboutItem];
    
    // Preferences (placeholder)
    NSMenuItem *preferencesItem = [[NSMenuItem alloc] initWithTitle:@"Preferences..."
                                                             action:@selector(showPreferences:)
                                                      keyEquivalent:@""];
    preferencesItem.target = self;
    [self.statusMenu addItem:preferencesItem];
    
    [self.statusMenu addItem:[NSMenuItem separatorItem]];
    
    // Quit
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit StealthKit"
                                                      action:@selector(quit:)
                                               keyEquivalent:@""];
    quitItem.target = self;
    [self.statusMenu addItem:quitItem];
}

#pragma mark - Menu Actions

- (void)toggleBrowserWindow:(NSMenuItem *)sender {
    if (!self.mainBrowserWindow) {
        [self createNewWindow:sender];
        return;
    }
    
    if (self.mainBrowserWindow.isVisible) {
        [self.mainBrowserWindow orderOut:nil];
        NSLog(@"StealthKit: Browser window hidden");
    } else {
        [self.mainBrowserWindow makeKeyAndOrderFront:nil];
        NSLog(@"StealthKit: Browser window shown");
    }
    
    [self updateStatusBarMenu];
}

- (void)createNewWindow:(NSMenuItem *)sender {
    NSLog(@"StealthKit: Creating new browser window from status bar");
    
    // Post notification to app delegate to create new window
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StealthKitCreateNewWindow"
                                                        object:nil];
}

- (void)goBack:(NSMenuItem *)sender {
    if (self.mainBrowserWindow) {
        [self.mainBrowserWindow goBack];
        NSLog(@"StealthKit: Navigation back triggered from status bar");
    }
}

- (void)goForward:(NSMenuItem *)sender {
    if (self.mainBrowserWindow) {
        [self.mainBrowserWindow goForward];
        NSLog(@"StealthKit: Navigation forward triggered from status bar");
    }
}

- (void)reload:(NSMenuItem *)sender {
    if (self.mainBrowserWindow) {
        [self.mainBrowserWindow reload];
        NSLog(@"StealthKit: Reload triggered from status bar");
    }
}

- (void)selectSearchEngine:(NSMenuItem *)sender {
    NSString *engineDisplayName = sender.representedObject;
    if (engineDisplayName) {
        SearchEngineManager *searchManager = [SearchEngineManager shared];
        [searchManager setCurrentSearchEngineByDisplayName:engineDisplayName];
        [self updateStatusBarMenu];
        NSLog(@"StealthKit: Search engine changed to: %@", engineDisplayName);
    }
}

- (void)minimizeAllWindows:(NSMenuItem *)sender {
    for (NSWindow *window in [NSApp windows]) {
        if ([window isKindOfClass:[BrowserWindow class]]) {
            [window miniaturize:nil];
        }
    }
    NSLog(@"StealthKit: All browser windows minimized");
}

- (void)showAllWindows:(NSMenuItem *)sender {
    for (NSWindow *window in [NSApp windows]) {
        if ([window isKindOfClass:[BrowserWindow class]]) {
            [window deminiaturize:nil];
            [window makeKeyAndOrderFront:nil];
        }
    }
    NSLog(@"StealthKit: All browser windows shown");
}

- (void)showAbout:(NSMenuItem *)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"StealthKit";
    alert.informativeText = @"Version 1.0.0\nPrivacy-Focused Browser\nPhase 4: Stealth Features\n\n© 2025 StealthKit. All rights reserved.";
    alert.alertStyle = NSAlertStyleInformational;
    [alert runModal];
}

- (void)showPreferences:(NSMenuItem *)sender {
    // TODO: Implement preferences window in future phase
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Preferences";
    alert.informativeText = @"Preferences panel will be implemented in a future update.";
    alert.alertStyle = NSAlertStyleInformational;
    [alert runModal];
    
    NSLog(@"StealthKit: Preferences requested (not yet implemented)");
}

- (void)quit:(NSMenuItem *)sender {
    NSLog(@"StealthKit: Quit requested from status bar");
    [NSApp terminate:nil];
}

@end

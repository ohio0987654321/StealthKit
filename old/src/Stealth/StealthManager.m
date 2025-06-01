//
//  StealthManager.m
//  StealthKit
//
//  Created on Phase 4: Stealth Features Implementation
//

#import "StealthManager.h"
#import "WindowCloaking.h"
#import "StatusBarController.h"
#import "BrowserWindow.h"

@interface StealthManager ()
@property (nonatomic, readwrite) BOOL isStealthModeActive;
@property (nonatomic, readwrite) BOOL isBackgroundOperationEnabled;
@end

@implementation StealthManager

+ (instancetype)shared {
    static StealthManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[StealthManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isStealthModeActive = NO;
        _isBackgroundOperationEnabled = NO;
        
        NSLog(@"StealthKit: StealthManager initialized");
    }
    return self;
}

#pragma mark - Public Methods

- (void)initializeStealthFeatures {
    NSLog(@"StealthKit: Initializing stealth features...");
    
    // Set up notification observers
    [self setupNotificationObservers];
    
    // Initialize default stealth mode
    [self setStealthModeEnabled:YES];
    
    NSLog(@"StealthKit: Stealth features initialization complete");
}

- (void)applyStealthToWindow:(NSWindow *)window {
    if (!window) {
        NSLog(@"StealthKit: Cannot apply stealth to nil window");
        return;
    }
    
    NSLog(@"StealthKit: Applying stealth configuration to window: %@", window);
    
    if (self.isStealthModeActive) {
        [WindowCloaking applyCloakingToWindow:window];
    }
    
    NSLog(@"StealthKit: Stealth applied to window");
}

- (void)configureWebViewForStealth:(WKWebView *)webView {
    if (!webView) {
        NSLog(@"StealthKit: Cannot configure nil web view for stealth");
        return;
    }
    
    NSLog(@"StealthKit: Configuring web view for stealth operation");
    
    if (self.isStealthModeActive) {
        [WindowCloaking configureWebViewForStealth:webView];
    }
    
    NSLog(@"StealthKit: Web view stealth configuration complete");
}

- (void)enableBackgroundOperation {
    if (self.isBackgroundOperationEnabled) {
        NSLog(@"StealthKit: Background operation already enabled");
        return;
    }
    
    NSLog(@"StealthKit: Enabling background operation...");
    
    // Set app activation policy to accessory (no dock icon)
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    
    // Set up status bar
    [[StatusBarController shared] setupStatusBar];
    
    self.isBackgroundOperationEnabled = YES;
    
    NSLog(@"StealthKit: Background operation enabled");
}

- (void)disableBackgroundOperation {
    if (!self.isBackgroundOperationEnabled) {
        NSLog(@"StealthKit: Background operation already disabled");
        return;
    }
    
    NSLog(@"StealthKit: Disabling background operation...");
    
    // Restore normal app activation policy
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    
    // Remove status bar
    [[StatusBarController shared] removeStatusBar];
    
    self.isBackgroundOperationEnabled = NO;
    
    NSLog(@"StealthKit: Background operation disabled");
}

- (void)setStealthModeEnabled:(BOOL)enabled {
    if (self.isStealthModeActive == enabled) {
        NSLog(@"StealthKit: Stealth mode already %@", enabled ? @"enabled" : @"disabled");
        return;
    }
    
    NSLog(@"StealthKit: %@ stealth mode...", enabled ? @"Enabling" : @"Disabling");
    
    self.isStealthModeActive = enabled;
    
    // Apply/remove stealth from all existing browser windows
    [self updateAllBrowserWindows];
    
    NSLog(@"StealthKit: Stealth mode %@", enabled ? @"enabled" : @"disabled");
}

- (NSWindow *)createStealthBrowserWindow {
    NSLog(@"StealthKit: Creating stealth-configured browser window...");
    
    // Create browser window
    BrowserWindow *browserWindow = [BrowserWindow createBrowserWindow];
    
    // Apply stealth configuration
    [self applyStealthToWindow:browserWindow];
    
    // Configure web view for stealth
    // Note: We need to access the web view from BrowserWindow
    // This will be done when the web view is created in BrowserWindow
    
    // Register with status bar controller if background operation is enabled
    if (self.isBackgroundOperationEnabled) {
        [[StatusBarController shared] setMainBrowserWindow:browserWindow];
    }
    
    NSLog(@"StealthKit: Stealth browser window created");
    
    return browserWindow;
}

#pragma mark - Private Methods

- (void)setupNotificationObservers {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    // Listen for new window creation requests from status bar
    [center addObserver:self
               selector:@selector(handleCreateNewWindowNotification:)
                   name:@"StealthKitCreateNewWindow"
                 object:nil];
    
    // Listen for app termination to clean up
    [center addObserver:self
               selector:@selector(handleAppTermination:)
                   name:NSApplicationWillTerminateNotification
                 object:nil];
    
    NSLog(@"StealthKit: Notification observers set up");
}

- (void)updateAllBrowserWindows {
    NSArray<NSWindow *> *windows = [NSApp windows];
    
    for (NSWindow *window in windows) {
        if ([window isKindOfClass:[BrowserWindow class]]) {
            if (self.isStealthModeActive) {
                [WindowCloaking applyCloakingToWindow:window];
            } else {
                [WindowCloaking removeCloakingFromWindow:window];
            }
        }
    }
    
    NSLog(@"StealthKit: Updated stealth configuration for %lu browser windows", 
          (unsigned long)[self countBrowserWindows]);
}

- (NSUInteger)countBrowserWindows {
    NSUInteger count = 0;
    NSArray<NSWindow *> *windows = [NSApp windows];
    
    for (NSWindow *window in windows) {
        if ([window isKindOfClass:[BrowserWindow class]]) {
            count++;
        }
    }
    
    return count;
}

#pragma mark - Notification Handlers

- (void)handleCreateNewWindowNotification:(NSNotification *)notification {
    NSLog(@"StealthKit: Received request to create new window");
    
    // Create new stealth browser window
    NSWindow *newWindow = [self createStealthBrowserWindow];
    [newWindow makeKeyAndOrderFront:nil];
    
    NSLog(@"StealthKit: New browser window created and shown");
}

- (void)handleAppTermination:(NSNotification *)notification {
    NSLog(@"StealthKit: App terminating, cleaning up stealth features...");
    
    // Clean up status bar
    if (self.isBackgroundOperationEnabled) {
        [[StatusBarController shared] removeStatusBar];
    }
    
    // Remove notification observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"StealthKit: Stealth cleanup complete");
}

#pragma mark - Advanced Stealth Features

- (void)enableAdvancedStealthMode {
    NSLog(@"StealthKit: Enabling advanced stealth mode...");
    
    // Enable both stealth mode and background operation
    [self setStealthModeEnabled:YES];
    [self enableBackgroundOperation];
    
    // Apply additional advanced stealth configurations
    NSArray<NSWindow *> *windows = [NSApp windows];
    for (NSWindow *window in windows) {
        if ([window isKindOfClass:[BrowserWindow class]]) {
            // Apply advanced stealth configurations
            [WindowCloaking configureAdvancedStealth:window];
        }
    }
    
    NSLog(@"StealthKit: Advanced stealth mode enabled");
}

- (void)disableAdvancedStealthMode {
    NSLog(@"StealthKit: Disabling advanced stealth mode...");
    
    // Disable stealth mode and background operation
    [self setStealthModeEnabled:NO];
    [self disableBackgroundOperation];
    
    NSLog(@"StealthKit: Advanced stealth mode disabled");
}

- (void)logStealthStatus {
    NSLog(@"StealthKit: === Stealth Status Report ===");
    NSLog(@"  - Stealth Mode Active: %@", self.isStealthModeActive ? @"YES" : @"NO");
    NSLog(@"  - Background Operation Enabled: %@", self.isBackgroundOperationEnabled ? @"YES" : @"NO");
    NSLog(@"  - Status Bar Active: %@", [[StatusBarController shared] isStatusBarActive] ? @"YES" : @"NO");
    NSLog(@"  - Browser Windows: %lu", (unsigned long)[self countBrowserWindows]);
    NSLog(@"  - App Activation Policy: %ld", (long)[NSApp activationPolicy]);
    
    // Log status for each browser window
    NSArray<NSWindow *> *windows = [NSApp windows];
    for (NSWindow *window in windows) {
        if ([window isKindOfClass:[BrowserWindow class]]) {
            [WindowCloaking logStealthStatus:window];
        }
    }
    
    NSLog(@"StealthKit: === End Stealth Status Report ===");
}

#pragma mark - Cleanup

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

//
//  AppDelegate.m
//  StealthKit
//
//  Created by StealthKit Migration on 2025.
//  Copyright © 2025 StealthKit. All rights reserved.
//

#import "AppDelegate.h"
#import <WebKit/WebKit.h>
#import "BrowserWindow.h"
#import "StealthManager.h"
#import "StatusBarController.h"
#import "ShortcutManager.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSLog(@"StealthKit: Application launching...");
    
    // Create application menu programmatically
    [self createApplicationMenu];
    
    // Initialize stealth features
    [self initializeStealthFeatures];
    
    // Create main window
    self.mainWindow = [self createMainWindow];
    [self.mainWindow makeKeyAndOrderFront:nil];
    
    // Set up background operation
    [self setupBackgroundOperation];
    
    NSLog(@"StealthKit: Application launch completed");
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    NSLog(@"StealthKit: Application terminating...");
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    // Don't terminate when window closes in stealth mode
    return NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
    // Show window when app icon is clicked
    if (!flag && self.mainWindow) {
        [self.mainWindow makeKeyAndOrderFront:nil];
    }
    return YES;
}

#pragma mark - Stealth Features Initialization

- (void)initializeStealthFeatures {
    NSLog(@"StealthKit: Initializing stealth features...");
    
    // Phase 4: Initialize StealthManager for Full Stealth Mode
    [[StealthManager shared] initializeStealthFeatures];
    
    // Initialize ShortcutManager for keyboard shortcuts
    [[ShortcutManager shared] registerAllShortcuts];
    
    // Set up notification observers for shortcuts
    [self setupShortcutNotifications];
    
    NSLog(@"StealthKit: Stealth features initialized successfully");
}

#pragma mark - Window Management

- (NSWindow *)createMainWindow {
    NSLog(@"StealthKit: Creating stealth-enabled browser window...");
    
    // Create stealth-enabled browser window through StealthManager
    BrowserWindow *browserWindow = (BrowserWindow *)[[StealthManager shared] createStealthBrowserWindow];
    
    // Load a welcome page
    NSString *welcomeHTML = [self createWelcomePageHTML];
    [browserWindow loadHTMLString:welcomeHTML baseURL:nil];
    
    NSLog(@"StealthKit: Stealth-enabled browser window created successfully");
    return browserWindow;
}

#pragma mark - Background Operation

- (void)setupBackgroundOperation {
    NSLog(@"StealthKit: Setting up background operation...");
    
    // Set app activation policy to accessory (no dock icon)
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    NSLog(@"StealthKit: App activation policy set to accessory - no dock icon");
    
    // Initialize StatusBarController
    self.statusBarController = [StatusBarController shared];
    [self.statusBarController setupStatusBar];
    NSLog(@"StealthKit: Status bar controller initialized");
    
    // Connect main window to status bar controller
    if ([self.statusBarController respondsToSelector:@selector(setMainBrowserWindow:)]) {
        [self.statusBarController setMainBrowserWindow:(BrowserWindow *)self.mainWindow];
        NSLog(@"StealthKit: Main window connected to status bar controller");
    }
    
    NSLog(@"StealthKit: Background operation setup completed (placeholder)");
}

#pragma mark - Welcome Page

- (NSString *)createWelcomePageHTML {
    return @"<!DOCTYPE html>"
           @"<html><head>"
           @"<meta charset='utf-8'>"
           @"<title>Welcome to StealthKit</title>"
           @"<style>"
           @"body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; "
           @"       background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); "
           @"       color: white; margin: 0; padding: 40px; text-align: center; }"
           @"h1 { font-size: 3em; margin-bottom: 20px; }"
           @"p { font-size: 1.2em; line-height: 1.6; max-width: 600px; margin: 0 auto 30px; }"
           @"ul { text-align: left; max-width: 400px; margin: 0 auto; }"
           @"li { margin: 10px 0; }"
           @"</style>"
           @"</head><body>"
           @"<h1>🛡️ StealthKit</h1>"
           @"<p>Welcome to StealthKit - Phase 3: Smart Address Bar</p>"
           @"<p>A privacy-focused browser built with modern Cocoa and CMake.</p>"
           @"<ul>"
           @"<li>✅ CMake build system</li>"
           @"<li>✅ Programmatic UI with Auto Layout</li>"
           @"<li>✅ Safari-like toolbar and navigation</li>"
           @"<li>✅ Smart address bar</li>"
           @"<li>🔄 WebKit integration</li>"
           @"</ul>"
           @"<p>Try navigating to a website or searching for something!</p>"
           @"</body></html>";
}

#pragma mark - Menu Creation

- (void)createApplicationMenu {
    NSLog(@"StealthKit: Creating application menu...");
    
    // Create main menu bar
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Main Menu"];
    
    // Create StealthKit (App) menu
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"StealthKit"];
    
    // About StealthKit
    NSMenuItem *aboutMenuItem = [[NSMenuItem alloc] initWithTitle:@"About StealthKit" 
                                                           action:@selector(showAbout:) 
                                                    keyEquivalent:@""];
    aboutMenuItem.target = self;
    [appMenu addItem:aboutMenuItem];
    
    [appMenu addItem:[NSMenuItem separatorItem]];
    
    // Quit StealthKit
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit StealthKit" 
                                                          action:@selector(terminate:) 
                                                   keyEquivalent:@"q"];
    quitMenuItem.target = NSApp;
    [appMenu addItem:quitMenuItem];
    
    appMenuItem.submenu = appMenu;
    [mainMenu addItem:appMenuItem];
    
    // Create File menu
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    
    // New Window
    NSMenuItem *newWindowMenuItem = [[NSMenuItem alloc] initWithTitle:@"New Window" 
                                                               action:@selector(newDocument:) 
                                                        keyEquivalent:@"n"];
    newWindowMenuItem.target = self;
    [fileMenu addItem:newWindowMenuItem];
    
    fileMenuItem.submenu = fileMenu;
    [mainMenu addItem:fileMenuItem];
    
    // Set the main menu
    [NSApp setMainMenu:mainMenu];
    
    NSLog(@"StealthKit: Application menu created successfully");
}

#pragma mark - Menu Actions

- (IBAction)newDocument:(id)sender {
    NSLog(@"StealthKit: New document requested");
    if (self.mainWindow) {
        [self.mainWindow makeKeyAndOrderFront:nil];
    }
}

- (IBAction)showAbout:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"StealthKit";
    alert.informativeText = @"Version 1.0.0\nPrivacy-Focused Browser\nPhase 2: Core Browser Implementation\n\n© 2025 StealthKit. All rights reserved.";
    alert.alertStyle = NSAlertStyleInformational;
    [alert runModal];
}

#pragma mark - Shortcut Notifications

- (void)setupShortcutNotifications {
    NSLog(@"StealthKit: Setting up shortcut notifications...");
    
    // Register for new window creation notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewWindowRequest:)
                                                 name:@"StealthKitCreateNewWindow"
                                               object:nil];
    
    // Register for new tab creation notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewTabRequest:)
                                                 name:@"StealthKitNewTab"
                                               object:nil];
    
    NSLog(@"StealthKit: Shortcut notifications setup completed");
}

- (void)handleNewWindowRequest:(NSNotification *)notification {
    NSLog(@"StealthKit: Creating new window via shortcut");
    
    // Create a new browser window
    BrowserWindow *newWindow = (BrowserWindow *)[[StealthManager shared] createStealthBrowserWindow];
    
    // Load welcome page
    NSString *welcomeHTML = [self createWelcomePageHTML];
    [newWindow loadHTMLString:welcomeHTML baseURL:nil];
    
    // Show the new window
    [newWindow makeKeyAndOrderFront:nil];
    
    NSLog(@"StealthKit: New window created successfully");
}

- (void)handleNewTabRequest:(NSNotification *)notification {
    NSLog(@"StealthKit: New tab request received (multi-tab not yet implemented)");
    
    // For now, create a new window as fallback
    [self handleNewWindowRequest:notification];
}

@end

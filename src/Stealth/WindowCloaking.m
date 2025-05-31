//
//  WindowCloaking.m
//  StealthKit
//
//  Created on Phase 4: Stealth Features Implementation
//

#import "WindowCloaking.h"

@implementation WindowCloaking

+ (void)applyCloakingToWindow:(NSWindow *)window {
    if (!window) {
        NSLog(@"StealthKit: Cannot apply cloaking to nil window");
        return;
    }
    
    NSLog(@"StealthKit: Applying cloaking to window: %@", window);
    
    // Primary screen capture evasion
    window.sharingType = NSWindowSharingNone;
    
    // Configure window level for stealth operation
    [self applyStealthWindowLevel:window];
    
    // Configure collection behavior
    [self configureStealthCollectionBehavior:window];
    
    // Additional privacy configurations
    window.hidesOnDeactivate = NO;
    window.canHide = YES;
    
    // Prevent window from being included in window lists
    window.excludedFromWindowsMenu = YES;
    
    NSLog(@"StealthKit: Cloaking applied successfully");
}

+ (void)configureWebViewForStealth:(WKWebView *)webView {
    if (!webView) {
        NSLog(@"StealthKit: Cannot configure nil web view for stealth");
        return;
    }
    
    NSLog(@"StealthKit: Configuring web view for stealth operation");
    
    WKWebViewConfiguration *config = webView.configuration;
    
    // Use non-persistent data store for maximum privacy
    config.websiteDataStore = [self createStealthDataStore];
    
    // Disable media capture
    config.allowsAirPlayForMediaPlayback = NO;
    
    // Configure preferences for privacy
    WKPreferences *preferences = config.preferences;
    preferences.javaScriptCanOpenWindowsAutomatically = NO;
    
    // Additional privacy settings
    if (@available(macOS 11.0, *)) {
        config.limitsNavigationsToAppBoundDomains = NO;
    }
    
    NSLog(@"StealthKit: Web view stealth configuration complete");
}

+ (void)removeCloakingFromWindow:(NSWindow *)window {
    if (!window) {
        return;
    }
    
    NSLog(@"StealthKit: Removing cloaking from window: %@", window);
    
    // Restore normal sharing behavior
    window.sharingType = NSWindowSharingReadOnly;
    
    // Restore normal window level
    window.level = NSNormalWindowLevel;
    
    // Restore normal collection behavior
    window.collectionBehavior = NSWindowCollectionBehaviorDefault;
    
    // Restore window menu inclusion
    window.excludedFromWindowsMenu = NO;
    
    NSLog(@"StealthKit: Cloaking removed successfully");
}

+ (BOOL)windowHasCloaking:(NSWindow *)window {
    if (!window) {
        return NO;
    }
    
    return window.sharingType == NSWindowSharingNone;
}

+ (void)applyStealthWindowLevel:(NSWindow *)window {
    if (!window) {
        return;
    }
    
    window.level = NSFloatingWindowLevel;
    
    NSLog(@"StealthKit: Stealth window level applied");
}

+ (void)configureStealthCollectionBehavior:(NSWindow *)window {
    if (!window) {
        return;
    }
    
    // Configure collection behavior for stealth operation
    NSWindowCollectionBehavior behavior = NSWindowCollectionBehaviorDefault;
    
    // Allow window to join all spaces for better stealth operation
    behavior |= NSWindowCollectionBehaviorCanJoinAllSpaces;
    
    // Manage window in Exposé
    behavior |= NSWindowCollectionBehaviorParticipatesInCycle;
    
    // Allow full screen if needed
    if (@available(macOS 10.7, *)) {
        behavior |= NSWindowCollectionBehaviorFullScreenAuxiliary;
    }
    
    window.collectionBehavior = behavior;
    
    NSLog(@"StealthKit: Stealth collection behavior configured");
}

+ (WKWebsiteDataStore *)createStealthDataStore {
    // Create a non-persistent data store for maximum privacy
    WKWebsiteDataStore *dataStore = [WKWebsiteDataStore nonPersistentDataStore];
    
    NSLog(@"StealthKit: Created non-persistent website data store for stealth operation");
    
    return dataStore;
}

#pragma mark - Advanced Stealth Features

+ (void)configureAdvancedStealth:(NSWindow *)window {
    if (!window) {
        return;
    }
    
    // Additional advanced stealth configurations can be added here
    
    // Prevent window from appearing in screenshots (primary method)
    window.sharingType = NSWindowSharingNone;
    
    // Configure window to be less detectable
    window.displaysWhenScreenProfileChanges = NO;
    
    NSLog(@"StealthKit: Advanced stealth features configured");
}

+ (void)logStealthStatus:(NSWindow *)window {
    if (!window) {
        NSLog(@"StealthKit: Cannot log status for nil window");
        return;
    }
    
    NSLog(@"StealthKit: Window Stealth Status:");
    NSLog(@"  - Sharing Type: %ld", (long)window.sharingType);
    NSLog(@"  - Window Level: %ld", (long)window.level);
    NSLog(@"  - Collection Behavior: %lu", (unsigned long)window.collectionBehavior);
    NSLog(@"  - Excluded from Windows Menu: %@", window.excludedFromWindowsMenu ? @"YES" : @"NO");
    NSLog(@"  - Has Cloaking: %@", [self windowHasCloaking:window] ? @"YES" : @"NO");
}

@end

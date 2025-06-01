//
//  StatusBarController.h
//  StealthKit
//
//  Created on Phase 4: Stealth Features Implementation
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class BrowserWindow;

/**
 * Manages the status bar item and menu for background operation.
 * Provides discrete access to browser functionality when the app is hidden from the dock.
 */
@interface StatusBarController : NSObject

/// Shared instance for app-wide status bar management
@property (class, readonly) StatusBarController *shared;

/// The status bar item
@property (nonatomic, strong, readonly, nullable) NSStatusItem *statusItem;

/// Whether the status bar is currently active
@property (nonatomic, readonly) BOOL isStatusBarActive;

/**
 * Set up the status bar item and menu.
 * This should be called when enabling background operation.
 */
- (void)setupStatusBar;

/**
 * Remove the status bar item.
 * This should be called when disabling background operation.
 */
- (void)removeStatusBar;

/**
 * Update the status bar menu with current browser state.
 * Call this when browser windows are created or destroyed.
 */
- (void)updateStatusBarMenu;

/**
 * Set the main browser window for status bar controls.
 * @param window The main browser window to control from status bar
 */
- (void)setMainBrowserWindow:(BrowserWindow * _Nullable)window;

@end

NS_ASSUME_NONNULL_END

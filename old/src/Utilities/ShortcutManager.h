//
//  ShortcutManager.h
//  StealthKit
//
//  Created on Multi-Window & Multi-Tab Implementation
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class BrowserWindow;
@class TabManager;
@class WindowManager;

/**
 * Centralized keyboard shortcut management for StealthKit.
 * Handles all application keyboard shortcuts in a unified system.
 */
@interface ShortcutManager : NSObject

/// Shared instance for app-wide shortcut management
@property (class, readonly) ShortcutManager *shared;

/// Whether shortcuts are currently active
@property (nonatomic, readonly) BOOL shortcutsActive;

/**
 * Initialize and register all keyboard shortcuts.
 * This should be called once during application startup.
 */
- (void)registerAllShortcuts;

/**
 * Disable all keyboard shortcuts.
 * Call this during application shutdown.
 */
- (void)unregisterAllShortcuts;

/**
 * Set the current window manager for window-related shortcuts.
 * @param windowManager The window manager to use for multi-window operations
 */
- (void)setWindowManager:(id)windowManager;

/**
 * Set the current tab manager for tab-related shortcuts.
 * @param tabManager The tab manager to use for multi-tab operations
 */
- (void)setTabManager:(id)tabManager;

/**
 * Handle a specific shortcut key combination.
 * @param shortcutKey The shortcut identifier
 * @param event The key event that triggered the shortcut
 * @return YES if the shortcut was handled, NO otherwise
 */
- (BOOL)handleShortcut:(NSString *)shortcutKey withEvent:(NSEvent *)event;

@end

NS_ASSUME_NONNULL_END

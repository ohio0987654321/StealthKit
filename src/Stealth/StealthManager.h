//
//  StealthManager.h
//  StealthKit
//
//  Created on Phase 4: Stealth Features Implementation
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Central coordinator for all stealth functionality.
 * Manages window cloaking, background operation, and privacy features.
 */
@interface StealthManager : NSObject

/// Shared instance for app-wide stealth coordination
@property (class, readonly) StealthManager *shared;

/// Whether stealth mode is currently active
@property (nonatomic, readonly) BOOL isStealthModeActive;

/// Whether background operation is enabled
@property (nonatomic, readonly) BOOL isBackgroundOperationEnabled;

/**
 * Initialize stealth features for the application.
 * This should be called during application startup.
 */
- (void)initializeStealthFeatures;

/**
 * Apply stealth configuration to a browser window.
 * @param window The window to configure for stealth operation
 */
- (void)applyStealthToWindow:(NSWindow *)window;

/**
 * Configure web view for maximum privacy.
 * @param webView The web view to configure
 */
- (void)configureWebViewForStealth:(WKWebView *)webView;

/**
 * Enable background operation mode with status bar.
 * This hides the app from the dock and shows a status bar item.
 */
- (void)enableBackgroundOperation;

/**
 * Disable background operation and return to normal app behavior.
 */
- (void)disableBackgroundOperation;

/**
 * Toggle stealth mode on/off.
 * @param enabled YES to enable stealth mode, NO to disable
 */
- (void)setStealthModeEnabled:(BOOL)enabled;

/**
 * Create a new stealth-configured browser window.
 * @return A new browser window with stealth features applied
 */
- (NSWindow *)createStealthBrowserWindow;

@end

NS_ASSUME_NONNULL_END

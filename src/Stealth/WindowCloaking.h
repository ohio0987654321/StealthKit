//
//  WindowCloaking.h
//  StealthKit
//
//  Created on Phase 4: Stealth Features Implementation
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Provides screen capture evasion functionality for StealthKit windows.
 * This class implements window cloaking features that make windows invisible
 * to screenshot tools and screen recording software.
 */
@interface WindowCloaking : NSObject

/**
 * Apply comprehensive cloaking configuration to a window.
 * This makes the window invisible to screen capture and recording tools.
 * @param window The window to apply cloaking to
 */
+ (void)applyCloakingToWindow:(NSWindow *)window;

/**
 * Configure a web view for maximum privacy and stealth operation.
 * @param webView The web view to configure
 */
+ (void)configureWebViewForStealth:(WKWebView *)webView;

/**
 * Remove cloaking from a window, making it visible to screen capture again.
 * @param window The window to remove cloaking from
 */
+ (void)removeCloakingFromWindow:(NSWindow *)window;

/**
 * Check if a window has cloaking applied.
 * @param window The window to check
 * @return YES if the window has cloaking applied, NO otherwise
 */
+ (BOOL)windowHasCloaking:(NSWindow *)window;

/**
 * Apply stealth window level configuration.
 * This ensures the window appears at the correct level for stealth operation.
 * @param window The window to configure
 */
+ (void)applyStealthWindowLevel:(NSWindow *)window;

/**
 * Configure window collection behavior for stealth operation.
 * @param window The window to configure
 */
+ (void)configureStealthCollectionBehavior:(NSWindow *)window;

/**
 * Create a non-persistent website data store for maximum privacy.
 * @return A configured website data store that doesn't persist data
 */
+ (WKWebsiteDataStore *)createStealthDataStore;

/**
 * Configure advanced stealth features for a window.
 * @param window The window to configure with advanced stealth
 */
+ (void)configureAdvancedStealth:(NSWindow *)window;

/**
 * Log detailed stealth status for a window.
 * @param window The window to log status for
 */
+ (void)logStealthStatus:(NSWindow *)window;

@end

NS_ASSUME_NONNULL_END

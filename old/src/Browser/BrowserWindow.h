//
//  BrowserWindow.h
//  StealthKit
//
//  Created on Phase 2: Core Browser Implementation
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class ToolbarView;
@class AddressBarView;
@class TabManager;

NS_ASSUME_NONNULL_BEGIN

/**
 * Main browser window with integrated toolbar and web view.
 * Implements Safari-like appearance with programmatic UI construction.
 */
@interface BrowserWindow : NSWindow

/// The toolbar containing navigation controls and address bar
@property (nonatomic, readonly) ToolbarView *toolbarView;

/// The web view for displaying content (current tab's web view)
@property (nonatomic, readonly) WKWebView *webView;

/// Tab manager for this window
@property (nonatomic, readonly) TabManager *tabManager;

/**
 * Creates a new browser window with default configuration.
 * @return Configured browser window ready for display
 */
+ (instancetype)createBrowserWindow;

/**
 * Load a URL in the web view.
 * @param url The URL to load
 */
- (void)loadURL:(NSURL *)url;

/**
 * Load an HTML string in the web view.
 * @param htmlString The HTML content to display
 * @param baseURL Optional base URL for relative links
 */
- (void)loadHTMLString:(NSString *)htmlString baseURL:(nullable NSURL *)baseURL;

/**
 * Navigate back in web view history.
 */
- (void)goBack;

/**
 * Navigate forward in web view history.
 */
- (void)goForward;

/**
 * Reload the current page.
 */
- (void)reload;

/**
 * Show find interface and start find operation.
 */
- (void)showFindInterface;

/**
 * Find next occurrence of current search term.
 */
- (void)findNext;

/**
 * Find previous occurrence of current search term.
 */
- (void)findPrevious;

/**
 * Use current selection for find operation.
 */
- (void)useSelectionForFind;

@end

NS_ASSUME_NONNULL_END

//
//  TabManager.h
//  StealthKit
//
//  Created on Multi-Tab Implementation
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@class BrowserWindow;

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents a single browser tab with its associated data.
 */
@interface Tab : NSObject

/// Unique identifier for the tab
@property (nonatomic, readonly) NSString *tabId;

/// The WebView for this tab
@property (nonatomic, readonly) WKWebView *webView;

/// Current title of the tab
@property (nonatomic, copy) NSString *title;

/// Current URL of the tab
@property (nonatomic, strong, nullable) NSURL *url;

/// Whether this tab is loading
@property (nonatomic) BOOL isLoading;

/// Favicon for the tab (future use)
@property (nonatomic, strong, nullable) NSImage *favicon;

/**
 * Creates a new tab with a WebView.
 * @return Configured tab ready for use
 */
+ (instancetype)createTab;

/**
 * Load a URL in this tab's WebView.
 * @param url The URL to load
 */
- (void)loadURL:(NSURL *)url;

/**
 * Load HTML content in this tab's WebView.
 * @param htmlString The HTML content
 * @param baseURL Optional base URL
 */
- (void)loadHTMLString:(NSString *)htmlString baseURL:(nullable NSURL *)baseURL;

@end

/**
 * Manages multiple tabs within a browser window.
 * Handles tab creation, switching, and lifecycle.
 */
@interface TabManager : NSObject

/// Array of all tabs
@property (nonatomic, readonly) NSArray<Tab *> *tabs;

/// Currently active tab
@property (nonatomic, readonly, nullable) Tab *currentTab;

/// Index of the currently active tab
@property (nonatomic, readonly) NSInteger currentTabIndex;

/// Browser window that owns this tab manager
@property (nonatomic, weak) BrowserWindow *browserWindow;

/**
 * Creates a new tab manager.
 * @param browserWindow The browser window that will own this manager
 * @return Configured tab manager
 */
+ (instancetype)tabManagerForBrowserWindow:(BrowserWindow *)browserWindow;

/**
 * Create a new tab and optionally make it active.
 * @param makeActive Whether to switch to the new tab immediately
 * @return The newly created tab
 */
- (Tab *)createNewTab:(BOOL)makeActive;

/**
 * Create a new tab with initial URL.
 * @param url Initial URL to load
 * @param makeActive Whether to switch to the new tab immediately
 * @return The newly created tab
 */
- (Tab *)createNewTabWithURL:(NSURL *)url makeActive:(BOOL)makeActive;

/**
 * Close a specific tab.
 * @param tab The tab to close
 */
- (void)closeTab:(Tab *)tab;

/**
 * Close the tab at a specific index.
 * @param index The index of the tab to close
 */
- (void)closeTabAtIndex:(NSInteger)index;

/**
 * Close the currently active tab.
 */
- (void)closeCurrentTab;

/**
 * Switch to a specific tab.
 * @param tab The tab to activate
 */
- (void)selectTab:(Tab *)tab;

/**
 * Switch to the tab at a specific index.
 * @param index The index of the tab to activate
 */
- (void)selectTabAtIndex:(NSInteger)index;

/**
 * Switch to the next tab (circular).
 */
- (void)selectNextTab;

/**
 * Switch to the previous tab (circular).
 */
- (void)selectPreviousTab;

/**
 * Reopen the last closed tab.
 */
- (void)reopenLastClosedTab;

/**
 * Get the tab at a specific index.
 * @param index The index of the tab
 * @return The tab at the index, or nil if invalid
 */
- (nullable Tab *)tabAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END

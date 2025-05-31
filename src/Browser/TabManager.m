//
//  TabManager.m
//  StealthKit
//
//  Created on Multi-Tab Implementation
//

#import "TabManager.h"
#import "BrowserWindow.h"
#import "URLHelper.h"
#import "SearchEngineManager.h"

@interface Tab ()
@property (nonatomic, strong) NSString *tabId;
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation Tab

+ (instancetype)createTab {
    Tab *tab = [[Tab alloc] init];
    [tab setupTab];
    return tab;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tabId = [[NSUUID UUID] UUIDString];
        _title = @"New Tab";
        _isLoading = NO;
    }
    return self;
}

- (void)setupTab {
    // Create WebView with configuration
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.websiteDataStore = [WKWebsiteDataStore defaultDataStore];
    
    self.webView = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:config];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Load welcome page by default
    [self loadWelcomePage];
    
    NSLog(@"Tab: Created new tab with ID: %@", self.tabId);
}

- (void)loadURL:(NSURL *)url {
    if (url) {
        self.url = url;
        self.isLoading = YES;
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
        NSLog(@"Tab %@: Loading URL: %@", self.tabId, url.absoluteString);
    }
}

- (void)loadHTMLString:(NSString *)htmlString baseURL:(NSURL *)baseURL {
    self.isLoading = YES;
    [self.webView loadHTMLString:htmlString baseURL:baseURL];
    NSLog(@"Tab %@: Loading HTML content", self.tabId);
}

- (void)loadWelcomePage {
    // Set a special URL for the welcome page (for internal tracking only)
    self.url = [NSURL URLWithString:@"stealthkit://welcome"];
    self.title = @"Welcome";
    
    // Create simple welcome HTML
    NSString *welcomeHTML = [self createWelcomeHTML];
    
    // Load the welcome HTML with nil baseURL to avoid URL scheme issues
    [self.webView loadHTMLString:welcomeHTML baseURL:nil];
    
    NSLog(@"Tab %@: Loaded welcome page", self.tabId);
}

- (NSString *)createWelcomeHTML {
    return @"<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Welcome to StealthKit</title><style>body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;margin:0;padding:60px 40px;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;text-align:center;min-height:100vh}.container{max-width:600px;margin:0 auto}h1{font-size:3rem;margin-bottom:1rem}.subtitle{font-size:1.2rem;margin-bottom:3rem}.feature{background:rgba(255,255,255,.1);padding:2rem;border-radius:12px;margin:1rem}.shortcut{display:flex;justify-content:space-between;padding:.5rem}.key{background:rgba(255,255,255,.2);padding:.25rem .5rem;border-radius:4px;font-family:monospace}</style></head><body><div class='container'><h1>🛡️ StealthKit</h1><p class='subtitle'>Private & Secure Web Browsing</p><div class='feature'><h3>🔒 Privacy First</h3><p>Built with privacy and security at its core</p></div><div class='feature'><h3>⚡ Fast & Light</h3><p>Optimized for speed and minimal resource usage</p></div><div class='feature'><h3>⌨️ Keyboard Shortcuts</h3><div class='shortcut'><span>New Tab</span><span class='key'>⌘ T</span></div><div class='shortcut'><span>Close Tab</span><span class='key'>⌘ W</span></div><div class='shortcut'><span>Focus Address Bar</span><span class='key'>⌘ L</span></div></div></div></body></html>";
}

@end

@interface TabManager ()
@property (nonatomic, strong) NSMutableArray<Tab *> *mutableTabs;
@property (nonatomic) NSInteger currentTabIndex;
@property (nonatomic, strong) NSMutableArray<Tab *> *recentlyClosedTabs;
@end

@implementation TabManager

+ (instancetype)tabManagerForBrowserWindow:(BrowserWindow *)browserWindow {
    TabManager *manager = [[TabManager alloc] init];
    manager.browserWindow = browserWindow;
    [manager setupTabManager];
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableTabs = [[NSMutableArray alloc] init];
        _recentlyClosedTabs = [[NSMutableArray alloc] init];
        _currentTabIndex = -1;
    }
    return self;
}

- (void)setupTabManager {
    NSLog(@"TabManager: Initializing tab manager for browser window");
    
    // Create initial tab
    [self createNewTab:YES];
}

- (NSArray<Tab *> *)tabs {
    return [self.mutableTabs copy];
}

- (Tab *)currentTab {
    if (self.currentTabIndex >= 0 && self.currentTabIndex < (NSInteger)self.mutableTabs.count) {
        return self.mutableTabs[self.currentTabIndex];
    }
    return nil;
}

#pragma mark - Tab Creation

- (Tab *)createNewTab:(BOOL)makeActive {
    Tab *tab = [Tab createTab];
    [self.mutableTabs addObject:tab];
    
    if (makeActive || self.mutableTabs.count == 1) {
        [self selectTab:tab];
    }
    
    NSLog(@"TabManager: Created new tab (Total: %lu)", (unsigned long)self.mutableTabs.count);
    [self notifyTabsChanged];
    
    return tab;
}

- (Tab *)createNewTabWithURL:(NSURL *)url makeActive:(BOOL)makeActive {
    Tab *tab = [self createNewTab:makeActive];
    [tab loadURL:url];
    return tab;
}

#pragma mark - Tab Closing

- (void)closeTab:(Tab *)tab {
    if (!tab) return;
    
    NSInteger index = [self.mutableTabs indexOfObject:tab];
    if (index != NSNotFound) {
        [self closeTabAtIndex:index];
    }
}

- (void)closeTabAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.mutableTabs.count) return;
    
    Tab *tabToClose = self.mutableTabs[index];
    
    // Add to recently closed tabs (keep last 10)
    [self.recentlyClosedTabs addObject:tabToClose];
    if (self.recentlyClosedTabs.count > 10) {
        [self.recentlyClosedTabs removeObjectAtIndex:0];
    }
    
    // Remove from tabs array
    [self.mutableTabs removeObjectAtIndex:index];
    
    NSLog(@"TabManager: Closed tab at index %ld (Remaining: %lu)", (long)index, (unsigned long)self.mutableTabs.count);
    
    // Handle current tab index adjustment
    if (self.mutableTabs.count == 0) {
        // No tabs left - close window or create new tab
        self.currentTabIndex = -1;
        if (self.browserWindow) {
            // Close the window if no tabs remain
            [self.browserWindow performClose:nil];
        }
        return;
    }
    
    // Adjust current tab index
    if (index == self.currentTabIndex) {
        // Closed the current tab - select the next one or previous if at end
        if (index >= (NSInteger)self.mutableTabs.count) {
            self.currentTabIndex = self.mutableTabs.count - 1;
        }
        [self selectTabAtIndex:self.currentTabIndex];
    } else if (index < self.currentTabIndex) {
        // Closed a tab before current - adjust index
        self.currentTabIndex--;
    }
    
    [self notifyTabsChanged];
}

- (void)closeCurrentTab {
    if (self.currentTabIndex >= 0) {
        [self closeTabAtIndex:self.currentTabIndex];
    }
}

#pragma mark - Tab Selection

- (void)selectTab:(Tab *)tab {
    if (!tab) return;
    
    NSInteger index = [self.mutableTabs indexOfObject:tab];
    if (index != NSNotFound) {
        [self selectTabAtIndex:index];
    }
}

- (void)selectTabAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.mutableTabs.count) return;
    
    self.currentTabIndex = index;
    Tab *newCurrentTab = self.mutableTabs[index];
    
    NSLog(@"TabManager: Selected tab %ld: %@", (long)index, newCurrentTab.title);
    
    // Notify browser window about tab change
    [self notifyCurrentTabChanged:newCurrentTab];
}

- (void)selectNextTab {
    if (self.mutableTabs.count <= 1) return;
    
    NSInteger nextIndex = (self.currentTabIndex + 1) % self.mutableTabs.count;
    [self selectTabAtIndex:nextIndex];
}

- (void)selectPreviousTab {
    if (self.mutableTabs.count <= 1) return;
    
    NSInteger prevIndex = self.currentTabIndex - 1;
    if (prevIndex < 0) {
        prevIndex = self.mutableTabs.count - 1;
    }
    [self selectTabAtIndex:prevIndex];
}

#pragma mark - Tab Reopening

- (void)reopenLastClosedTab {
    if (self.recentlyClosedTabs.count == 0) {
        NSLog(@"TabManager: No recently closed tabs to reopen");
        return;
    }
    
    Tab *lastClosedTab = [self.recentlyClosedTabs lastObject];
    [self.recentlyClosedTabs removeLastObject];
    
    // Create new tab with same URL
    Tab *newTab = [self createNewTab:YES];
    if (lastClosedTab.url) {
        [newTab loadURL:lastClosedTab.url];
    }
    
    NSLog(@"TabManager: Reopened last closed tab");
}

#pragma mark - Tab Access

- (Tab *)tabAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.mutableTabs.count) {
        return nil;
    }
    return self.mutableTabs[index];
}

#pragma mark - Notifications

- (void)notifyTabsChanged {
    // Post notification that tabs have changed (for UI updates)
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StealthKitTabsChanged" 
                                                        object:self 
                                                      userInfo:@{@"tabs": self.tabs}];
}

- (void)notifyCurrentTabChanged:(Tab *)tab {
    // Post notification that current tab has changed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StealthKitCurrentTabChanged" 
                                                        object:self 
                                                      userInfo:@{@"currentTab": tab}];
}

@end

//
//  BrowserWindow.m
//  StealthKit
//
//  Created on Phase 2: Core Browser Implementation
//  Updated on Multi-Tab Implementation
//

#import "BrowserWindow.h"
#import "ToolbarView.h"
#import "AddressBarView.h"
#import "TabBarView.h"
#import "TabManager.h"
#import "URLHelper.h"
#import "SearchEngineManager.h"
#import "UIManager.h"

@interface BrowserWindow () <AddressBarViewDelegate, WKNavigationDelegate, TabBarViewDelegate>
@property (nonatomic, strong) ToolbarView *toolbarView;
@property (nonatomic, strong) TabBarView *tabBarView;
@property (nonatomic, strong) TabManager *tabManager;
@property (nonatomic, strong) NSView *webViewContainer;
@property (nonatomic, strong) NSString *currentFindTerm;
@end

@implementation BrowserWindow

+ (instancetype)createBrowserWindow {
    NSRect windowFrame = NSMakeRect(100, 100, 1200, 800);
    
    BrowserWindow *window = [[BrowserWindow alloc] initWithContentRect:windowFrame
                                                             styleMask:NSWindowStyleMaskTitled |
                                                                       NSWindowStyleMaskClosable |
                                                                       NSWindowStyleMaskMiniaturizable |
                                                                       NSWindowStyleMaskResizable
                                                               backing:NSBackingStoreBuffered
                                                                 defer:NO];
    
    [window setupWindow];
    [window setupViews];
    [window setupLayout];
    [window setupTabManager];
    
    return window;
}

- (void)setupWindow {
    self.title = @"StealthKit";
    self.minSize = NSMakeSize(400, 300);
    self.releasedWhenClosed = NO;
    
    // Center the window on screen
    [self center];
}

- (void)setupViews {
    // Create main content view
    NSView *mainContentView = [[NSView alloc] init];
    mainContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self setContentView:mainContentView];
    
    // Create toolbar
    self.toolbarView = [ToolbarView createToolbarView];
    self.toolbarView.addressBar.addressBarDelegate = self;
    
    // Create tab bar
    self.tabBarView = [TabBarView createTabBarView];
    self.tabBarView.delegate = self;
    
    // Create web view container
    self.webViewContainer = [[NSView alloc] init];
    self.webViewContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Add views to hierarchy
    [mainContentView addSubview:self.toolbarView];
    [mainContentView addSubview:self.tabBarView];
    [mainContentView addSubview:self.webViewContainer];
}

- (void)setupLayout {
    UIManager *uiManager = [UIManager sharedManager];
    
    // Ensure all views have proper constraints disabled
    self.toolbarView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabBarView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webViewContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // Toolbar at top - with explicit height
        [self.toolbarView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.toolbarView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.toolbarView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.toolbarView.heightAnchor constraintEqualToConstant:uiManager.toolbarHeight],
        
        // Tab bar below toolbar - using UIManager constant
        [self.tabBarView.topAnchor constraintEqualToAnchor:self.toolbarView.bottomAnchor],
        [self.tabBarView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.tabBarView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.tabBarView.heightAnchor constraintEqualToConstant:uiManager.tabBarHeight],
        
        // Web view container fills remaining space
        [self.webViewContainer.topAnchor constraintEqualToAnchor:self.tabBarView.bottomAnchor],
        [self.webViewContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.webViewContainer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.webViewContainer.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        
        // Ensure web view container has minimum height to prevent collapse
        [self.webViewContainer.heightAnchor constraintGreaterThanOrEqualToConstant:100]
    ]];
    
    NSLog(@"BrowserWindow: Layout constraints applied with UIManager constants");
}

- (void)setupTabManager {
    // Create tab manager
    self.tabManager = [TabManager tabManagerForBrowserWindow:self];
    
    // Connect tab bar to tab manager
    self.tabBarView.tabManager = self.tabManager;
    
    // Listen for tab changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currentTabChanged:)
                                                 name:@"StealthKitCurrentTabChanged"
                                               object:self.tabManager];
    
    NSLog(@"BrowserWindow: Tab manager setup completed");
}

#pragma mark - Current Tab Access

- (WKWebView *)webView {
    return self.tabManager.currentTab.webView;
}

#pragma mark - Public Methods

- (void)loadURL:(NSURL *)url {
    if (url && self.tabManager.currentTab) {
        [self.tabManager.currentTab loadURL:url];
    }
}

- (void)loadHTMLString:(NSString *)htmlString baseURL:(NSURL *)baseURL {
    if (self.tabManager.currentTab) {
        [self.tabManager.currentTab loadHTMLString:htmlString baseURL:baseURL];
    }
}

- (void)goBack {
    if (self.webView && self.webView.canGoBack) {
        [self.webView goBack];
    }
}

- (void)goForward {
    if (self.webView && self.webView.canGoForward) {
        [self.webView goForward];
    }
}

- (void)reload {
    if (self.webView) {
        [self.webView reload];
    }
}

#pragma mark - Find Functionality

- (void)showFindInterface {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Find in Page";
    alert.informativeText = @"Enter text to search for:";
    
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    input.stringValue = self.currentFindTerm ? self.currentFindTerm : @"";
    alert.accessoryView = input;
    
    [alert addButtonWithTitle:@"Find"];
    [alert addButtonWithTitle:@"Cancel"];
    
    [alert beginSheetModalForWindow:self completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            NSString *searchTerm = input.stringValue;
            if (searchTerm.length > 0) {
                self.currentFindTerm = searchTerm;
                [self performFind:searchTerm];
            }
        }
    }];
    
    // Focus the text field
    [input becomeFirstResponder];
    
    NSLog(@"BrowserWindow: Find interface shown");
}

- (void)findNext {
    if (self.currentFindTerm.length > 0) {
        [self performFind:self.currentFindTerm];
    } else {
        [self showFindInterface];
    }
}

- (void)findPrevious {
    if (self.currentFindTerm.length > 0) {
        [self performFindPrevious:self.currentFindTerm];
    } else {
        [self showFindInterface];
    }
}

- (void)useSelectionForFind {
    if (!self.webView) return;
    
    // Get current selection from WebView
    [self.webView evaluateJavaScript:@"window.getSelection().toString()" completionHandler:^(id result, NSError *error) {
        if (!error && [result isKindOfClass:[NSString class]] && [(NSString *)result length] > 0) {
            self.currentFindTerm = (NSString *)result;
            [self performFind:self.currentFindTerm];
            NSLog(@"BrowserWindow: Using selection for find: %@", self.currentFindTerm);
        } else {
            NSLog(@"BrowserWindow: No text selection found");
        }
    }];
}

- (void)performFind:(NSString *)searchTerm {
    if (!self.webView) return;
    
    NSString *script = [NSString stringWithFormat:@"window.find('%@')", searchTerm];
    [self.webView evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        if (error) {
            NSLog(@"Find error: %@", error.localizedDescription);
        } else {
            NSLog(@"Find result for '%@': %@", searchTerm, result);
        }
    }];
}

- (void)performFindPrevious:(NSString *)searchTerm {
    if (!self.webView) return;
    
    NSString *script = [NSString stringWithFormat:@"window.find('%@', false, true)", searchTerm];
    [self.webView evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        if (error) {
            NSLog(@"Find previous error: %@", error.localizedDescription);
        } else {
            NSLog(@"Find previous result for '%@': %@", searchTerm, result);
        }
    }];
}

#pragma mark - Tab Management

- (void)switchToWebView:(WKWebView *)webView {
    // Remove current web view from container
    for (NSView *subview in self.webViewContainer.subviews) {
        [subview removeFromSuperview];
    }
    
    // Add new web view to container
    if (webView) {
        webView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.webViewContainer addSubview:webView];
        
        [NSLayoutConstraint activateConstraints:@[
            [webView.topAnchor constraintEqualToAnchor:self.webViewContainer.topAnchor],
            [webView.leadingAnchor constraintEqualToAnchor:self.webViewContainer.leadingAnchor],
            [webView.trailingAnchor constraintEqualToAnchor:self.webViewContainer.trailingAnchor],
            [webView.bottomAnchor constraintEqualToAnchor:self.webViewContainer.bottomAnchor]
        ]];
        
        // Set navigation delegate
        webView.navigationDelegate = self;
    }
}

#pragma mark - TabBarViewDelegate

- (void)tabBarView:(TabBarView *)tabBarView didSelectTab:(Tab *)tab {
    [self.tabManager selectTab:tab];
}

- (void)tabBarView:(TabBarView *)tabBarView didRequestCloseTab:(Tab *)tab {
    [self.tabManager closeTab:tab];
}

- (void)tabBarViewDidRequestNewTab:(TabBarView *)tabBarView {
    [self.tabManager createNewTab:YES];
}

#pragma mark - AddressBarViewDelegate

- (void)addressBar:(AddressBarView *)addressBar didSubmitInput:(NSString *)input {
    // Phase 3: Use smart URL detection and search engine management
    NSURL *url = [self smartURLFromUserInput:input];
    if (url) {
        [self loadURL:url];
    }
}

- (NSURL *)smartURLFromUserInput:(NSString *)input {
    if (!input || input.length == 0) {
        return nil;
    }
    
    // Use URLHelper for intelligent URL detection
    NSURL *url = [URLHelper URLFromUserInput:input];
    if (url) {
        NSLog(@"StealthKit: Detected URL: %@", url.absoluteString);
        return url;
    }
    
    // Use SearchEngineManager for search queries
    SearchEngineManager *searchManager = [SearchEngineManager shared];
    NSURL *searchURL = [searchManager searchURLForQuery:input];
    
    if (searchURL) {
        NSLog(@"StealthKit: Searching with %@: %@", searchManager.currentSearchEngine.displayName, input);
        return searchURL;
    }
    
    // Fallback to Google if something goes wrong
    NSString *encodedQuery = [input stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *fallbackURL = [NSString stringWithFormat:@"https://www.google.com/search?q=%@", encodedQuery];
    return [NSURL URLWithString:fallbackURL];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    // Update toolbar button states
    [self.toolbarView updateNavigationButtons:webView.canGoBack canGoForward:webView.canGoForward];
    
    // Update current tab loading state
    Tab *currentTab = self.tabManager.currentTab;
    if (currentTab && currentTab.webView == webView) {
        currentTab.isLoading = YES;
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // Update address bar with current URL
    if (webView.URL) {
        [self.toolbarView.addressBar updateWithURL:webView.URL];
    }
    
    // Update toolbar button states
    [self.toolbarView updateNavigationButtons:webView.canGoBack canGoForward:webView.canGoForward];
    
    // Update current tab
    Tab *currentTab = self.tabManager.currentTab;
    if (currentTab && currentTab.webView == webView) {
        currentTab.isLoading = NO;
        currentTab.url = webView.URL;
        
        // Update tab title
        if (webView.title.length > 0) {
            currentTab.title = webView.title;
        }
        
        // Update window title
        self.title = [NSString stringWithFormat:@"%@ - StealthKit", webView.title ? webView.title : @"StealthKit"];
    }
    
    // Refresh tab bar to show updated titles
    [self.tabBarView updateTabs];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"Navigation failed: %@", error.localizedDescription);
    
    // Update toolbar button states even on error
    [self.toolbarView updateNavigationButtons:webView.canGoBack canGoForward:webView.canGoForward];
    
    // Update current tab loading state
    Tab *currentTab = self.tabManager.currentTab;
    if (currentTab && currentTab.webView == webView) {
        currentTab.isLoading = NO;
    }
}

#pragma mark - Notifications

- (void)currentTabChanged:(NSNotification *)notification {
    Tab *currentTab = notification.userInfo[@"currentTab"];
    if (currentTab) {
        // Switch to the new tab's web view
        [self switchToWebView:currentTab.webView];
        
        // Update address bar
        if (currentTab.url) {
            [self.toolbarView.addressBar updateWithURL:currentTab.url];
        }
        
        // Update toolbar buttons
        [self.toolbarView updateNavigationButtons:currentTab.webView.canGoBack 
                                     canGoForward:currentTab.webView.canGoForward];
        
        // Update window title
        if (currentTab.title.length > 0) {
            self.title = [NSString stringWithFormat:@"%@ - StealthKit", currentTab.title];
        } else {
            self.title = @"StealthKit";
        }
        
        NSLog(@"BrowserWindow: Switched to tab: %@", currentTab.title);
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

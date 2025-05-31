//
//  TabBarView.m
//  StealthKit
//
//  Created on Multi-Tab UI Implementation
//

#import "TabBarView.h"
#import "TabManager.h"
#import "UIManager.h"

@interface TabButton : NSButton
@property (nonatomic, weak) Tab *tab;
@property (nonatomic, weak) TabBarView *tabBarView;
@property (nonatomic, strong) NSButton *closeButton;
@property (nonatomic, strong) NSLayoutConstraint *widthConstraint;
@end

@implementation TabButton

- (instancetype)initWithTab:(Tab *)tab tabBarView:(TabBarView *)tabBarView {
    self = [super init];
    if (self) {
        _tab = tab;
        _tabBarView = tabBarView;
        [self setupTabButton];
    }
    return self;
}

- (void)setupTabButton {
    self.title = self.tab.title;
    self.bordered = NO;
    self.buttonType = NSButtonTypeMomentaryChange;
    self.target = self;
    self.action = @selector(tabButtonClicked:);
    
    // Remove all button styling
    self.wantsLayer = YES;
    self.layer.backgroundColor = [NSColor clearColor].CGColor;
    
    // Create close button with clean styling
    self.closeButton = [[NSButton alloc] init];
    self.closeButton.title = @"✕";
    self.closeButton.bordered = NO;
    self.closeButton.buttonType = NSButtonTypeMomentaryChange;
    self.closeButton.target = self;
    self.closeButton.action = @selector(closeButtonClicked:);
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Remove all button styling for clean appearance
    self.closeButton.wantsLayer = YES;
    self.closeButton.layer.backgroundColor = [NSColor clearColor].CGColor;
    
    // Style the close button text
    UIManager *uiManager = [UIManager sharedManager];
    NSMutableAttributedString *closeTitle = [[NSMutableAttributedString alloc] initWithString:@"✕"];
    [closeTitle addAttribute:NSForegroundColorAttributeName value:uiManager.secondaryTextColor range:NSMakeRange(0, 1)];
    [closeTitle addAttribute:NSFontAttributeName value:[uiManager systemFontOfSize:12.0] range:NSMakeRange(0, 1)];
    self.closeButton.attributedTitle = closeTitle;
    
    [self addSubview:self.closeButton];
    
    // Layout close button
    [NSLayoutConstraint activateConstraints:@[
        [self.closeButton.widthAnchor constraintEqualToConstant:16],
        [self.closeButton.heightAnchor constraintEqualToConstant:16],
        [self.closeButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-4],
        [self.closeButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
    ]];
}

- (void)tabButtonClicked:(id)sender {
    if (self.tabBarView.delegate) {
        [self.tabBarView.delegate tabBarView:self.tabBarView didSelectTab:self.tab];
    }
}

- (void)closeButtonClicked:(id)sender {
    if (self.tabBarView.delegate) {
        [self.tabBarView.delegate tabBarView:self.tabBarView didRequestCloseTab:self.tab];
    }
}

- (void)updateAppearanceForSelected:(BOOL)selected {
    UIManager *uiManager = [UIManager sharedManager];
    
    self.wantsLayer = YES;
    
    // Clear any existing sublayers
    for (CALayer *sublayer in [self.layer.sublayers copy]) {
        [sublayer removeFromSuperlayer];
    }
    
    NSColor *textColor;
    NSFont *font;
    
    if (selected) {
        // Active tab styling - clearly visible like Safari
        self.layer.backgroundColor = [NSColor.whiteColor colorWithAlphaComponent:0.9].CGColor;
        self.layer.cornerRadius = 6.0;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [NSColor.separatorColor colorWithAlphaComponent:0.3].CGColor;
        
        // Add subtle shadow for depth
        self.layer.shadowColor = NSColor.blackColor.CGColor;
        self.layer.shadowOffset = CGSizeMake(0, -1);
        self.layer.shadowRadius = 2.0;
        self.layer.shadowOpacity = 0.1;
        
        textColor = uiManager.primaryTextColor;
        font = [uiManager mediumSystemFontOfSize:13.0];
        
        NSLog(@"TabButton: Applied active styling for tab: %@", self.title);
    } else {
        // Inactive tab styling - subtle background
        self.layer.backgroundColor = [NSColor clearColor].CGColor;
        self.layer.cornerRadius = 0;
        self.layer.borderWidth = 0;
        self.layer.shadowOpacity = 0;
        
        textColor = uiManager.secondaryTextColor;
        font = [uiManager systemFontOfSize:13.0];
    }
    
    // Update text appearance
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:self.title];
    [attrTitle addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, attrTitle.length)];
    [attrTitle addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, attrTitle.length)];
    self.attributedTitle = attrTitle;
    
    // Update title with current tab title
    if (self.tab.title.length > 0) {
        self.title = self.tab.title;
        NSMutableAttributedString *updatedTitle = [[NSMutableAttributedString alloc] initWithString:self.tab.title];
        [updatedTitle addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, updatedTitle.length)];
        [updatedTitle addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, updatedTitle.length)];
        self.attributedTitle = updatedTitle;
    }
}

@end

@interface TabBarView ()
@property (nonatomic, strong) NSScrollView *tabScrollView;
@property (nonatomic, strong) NSStackView *tabStackView;
@property (nonatomic, strong) NSMutableArray<TabButton *> *tabButtons;
@end

@implementation TabBarView

+ (instancetype)createTabBarView {
    TabBarView *tabBarView = [[TabBarView alloc] init];
    [tabBarView setupTabBarView];
    return tabBarView;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tabButtons = [[NSMutableArray alloc] init];
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

- (void)setupTabBarView {
    UIManager *uiManager = [UIManager sharedManager];
    
    // Apply Safari-like tab bar styling
    self.wantsLayer = YES;
    self.layer.backgroundColor = uiManager.tabBarBackgroundColor.CGColor;
    
    // Add subtle bottom border
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.backgroundColor = uiManager.subtleBorderColor.CGColor;
    bottomBorder.frame = CGRectMake(0, 0, self.bounds.size.width, 1);
    bottomBorder.autoresizingMask = kCALayerWidthSizable;
    [self.layer addSublayer:bottomBorder];
    
    // Add minimum width constraint to prevent collapse
    [self.widthAnchor constraintGreaterThanOrEqualToConstant:200].active = YES;
    
    // Create scroll view for tabs
    self.tabScrollView = [[NSScrollView alloc] init];
    self.tabScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabScrollView.hasVerticalScroller = NO;
    self.tabScrollView.hasHorizontalScroller = NO;
    self.tabScrollView.scrollerStyle = NSScrollerStyleOverlay;
    
    // Create stack view for tabs
    self.tabStackView = [[NSStackView alloc] init];
    self.tabStackView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    self.tabStackView.alignment = NSLayoutAttributeCenterY;
    self.tabStackView.spacing = 0;
    self.tabStackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Tab bar will only contain tabs, add button moved to toolbar
    
    // Set up view hierarchy - only tabs
    self.tabScrollView.documentView = self.tabStackView;
    [self addSubview:self.tabScrollView];
    
    // Layout constraints - full width for tabs
    [NSLayoutConstraint activateConstraints:@[
        // Tab scroll view fills entire tab bar
        [self.tabScrollView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.tabScrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.tabScrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.tabScrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        
        // Tab stack view
        [self.tabStackView.topAnchor constraintEqualToAnchor:self.tabScrollView.topAnchor constant:4],
        [self.tabStackView.leadingAnchor constraintEqualToAnchor:self.tabScrollView.leadingAnchor constant:4],
        [self.tabStackView.bottomAnchor constraintEqualToAnchor:self.tabScrollView.bottomAnchor constant:-4],
        [self.tabStackView.heightAnchor constraintEqualToConstant:28]
    ]];
    
    NSLog(@"TabBarView: Tab bar view setup completed");
}

- (void)setTabManager:(TabManager *)tabManager {
    // Unregister from previous tab manager
    if (_tabManager) {
        [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                         name:@"StealthKitTabsChanged" 
                                                       object:_tabManager];
        [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                         name:@"StealthKitCurrentTabChanged" 
                                                       object:_tabManager];
    }
    
    _tabManager = tabManager;
    
    // Register for new tab manager notifications
    if (_tabManager) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(tabsChanged:) 
                                                     name:@"StealthKitTabsChanged" 
                                                   object:_tabManager];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(currentTabChanged:) 
                                                     name:@"StealthKitCurrentTabChanged" 
                                                   object:_tabManager];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(tabTitleChanged:) 
                                                     name:@"StealthKitTabTitleChanged" 
                                                   object:nil];
        
        // Initial update
        [self updateTabs];
    }
}

- (void)updateTabs {
    if (!self.tabManager) return;
    
    // Remove existing tab buttons
    for (TabButton *button in self.tabButtons) {
        [self.tabStackView removeArrangedSubview:button];
        [button removeFromSuperview];
    }
    [self.tabButtons removeAllObjects];
    
    // Create new tab buttons
    for (Tab *tab in self.tabManager.tabs) {
        TabButton *tabButton = [[TabButton alloc] initWithTab:tab tabBarView:self];
        tabButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.tabButtons addObject:tabButton];
        [self.tabStackView addArrangedSubview:tabButton];
        
        // Set height constraint only - width will be calculated
        [tabButton.heightAnchor constraintEqualToConstant:28].active = YES;
    }
    
    // Calculate and apply equal width distribution
    [self distributeTabWidthsEvenly];
    
    // Update selected tab appearance
    [self selectTab:self.tabManager.currentTab];
    
    NSLog(@"TabBarView: Updated tabs (%lu tabs)", (unsigned long)self.tabManager.tabs.count);
}

- (void)distributeTabWidthsEvenly {
    NSInteger tabCount = self.tabButtons.count;
    if (tabCount == 0) return;
    
    // Get current bounds width
    CGFloat currentWidth = self.bounds.size.width;
    CGFloat padding = 8.0;
    
    // CRITICAL FIX: Validate bounds and use fallback if invalid
    CGFloat availableWidth;
    if (currentWidth <= 0) {
        // Bounds not available yet - use fallback calculation
        // Estimate based on parent view or use reasonable default
        CGFloat fallbackWidth = 800.0; // Reasonable default window width
        if (self.superview && self.superview.bounds.size.width > 0) {
            fallbackWidth = self.superview.bounds.size.width;
        }
        availableWidth = fallbackWidth - padding;
        NSLog(@"TabBarView: Using fallback width calculation: %.1f (bounds was %.1f)", availableWidth, currentWidth);
    } else {
        availableWidth = currentWidth - padding;
        NSLog(@"TabBarView: Using actual bounds width: %.1f", availableWidth);
    }
    
    // Intelligent tab sizing based on tab count
    CGFloat tabWidth;
    CGFloat minTabWidth = 120.0;
    CGFloat maxTabWidth = 250.0;
    CGFloat naturalTabWidth = 180.0; // Preferred width for few tabs
    CGFloat guaranteedMinWidth = 100.0; // Absolute minimum to ensure visibility
    
    if (tabCount <= 2) {
        // For 1-2 tabs, use natural width (don't spread across full width)
        tabWidth = naturalTabWidth;
    } else {
        // For 3+ tabs, start distributing available space
        CGFloat calculatedWidth = availableWidth / tabCount;
        tabWidth = MAX(minTabWidth, MIN(maxTabWidth, calculatedWidth));
    }
    
    // CRITICAL FIX: Ensure tab width is never too small to be visible
    tabWidth = MAX(tabWidth, guaranteedMinWidth);
    
    NSLog(@"TabBarView: Calculated tab width: %.1f for %ld tabs (available: %.1f)", tabWidth, tabCount, availableWidth);
    
    for (TabButton *tabButton in self.tabButtons) {
        // Remove old width constraint if it exists
        if (tabButton.widthConstraint) {
            tabButton.widthConstraint.active = NO;
        }
        
        // Create and store new width constraint
        tabButton.widthConstraint = [tabButton.widthAnchor constraintEqualToConstant:tabWidth];
        tabButton.widthConstraint.active = YES;
    }
}

- (void)selectTab:(Tab *)tab {
    self.selectedTab = tab;
    
    // Update visual appearance of all tab buttons (PURE VISUAL ONLY)
    for (TabButton *tabButton in self.tabButtons) {
        BOOL isSelected = (tabButton.tab == tab);
        [tabButton updateAppearanceForSelected:isSelected];
    }
    
    NSLog(@"TabBarView: Selected tab: %@ (visual update only)", tab.title);
}

#pragma mark - Layout

- (void)layout {
    [super layout];
    
    // SIMPLIFIED: Only recalculate when window width significantly changes
    if (self.tabButtons.count > 0 && self.bounds.size.width > 0) {
        static CGFloat lastKnownWidth = 0;
        CGFloat currentWidth = self.bounds.size.width;
        
        // Only recalculate if width significantly changed (avoid constant recalculation)
        if (fabs(currentWidth - lastKnownWidth) > 10.0) {
            NSLog(@"TabBarView: Layout detected width change from %.1f to %.1f, recalculating tabs", lastKnownWidth, currentWidth);
            [self distributeTabWidthsEvenly];
            lastKnownWidth = currentWidth;
        }
    }
}

- (void)viewDidMoveToSuperview {
    [super viewDidMoveToSuperview];
    
    // PHASE 2 FIX: Recalculate when added to view hierarchy
    if (self.superview && self.tabButtons.count > 0) {
        NSLog(@"TabBarView: Added to superview, ensuring tab visibility");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self distributeTabWidthsEvenly];
        });
    }
}

#pragma mark - Notifications

- (void)tabsChanged:(NSNotification *)notification {
    NSLog(@"TabBarView: Received tabsChanged notification");
    dispatch_async(dispatch_get_main_queue(), ^{
        // Only rebuild tabs if the count actually changed
        NSInteger newTabCount = self.tabManager.tabs.count;
        NSInteger currentTabCount = self.tabButtons.count;
        
        if (newTabCount != currentTabCount) {
            NSLog(@"TabBarView: Tab count changed from %ld to %ld, rebuilding", currentTabCount, newTabCount);
            [self updateTabs];
        } else {
            NSLog(@"TabBarView: Tab count unchanged, skipping rebuild");
            // Just refresh the selected state
            [self selectTab:self.tabManager.currentTab];
        }
    });
}

- (void)currentTabChanged:(NSNotification *)notification {
    Tab *currentTab = notification.userInfo[@"currentTab"];
    NSLog(@"TabBarView: Received currentTabChanged notification for tab: %@", currentTab.title);
    dispatch_async(dispatch_get_main_queue(), ^{
        // Only update selection, don't rebuild tabs
        [self selectTab:currentTab];
    });
}

- (void)tabTitleChanged:(NSNotification *)notification {
    Tab *changedTab = notification.userInfo[@"tab"];
    NSString *newTitle = notification.userInfo[@"title"];
    NSLog(@"TabBarView: Received tabTitleChanged notification for tab: %@ -> %@", changedTab, newTitle);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Find the tab button for the changed tab and update its title
        for (TabButton *tabButton in self.tabButtons) {
            if (tabButton.tab == changedTab) {
                // Update the button title immediately
                tabButton.title = newTitle;
                
                // Refresh the appearance to apply styling to new title
                BOOL isSelected = (tabButton.tab == self.tabManager.currentTab);
                [tabButton updateAppearanceForSelected:isSelected];
                
                NSLog(@"TabBarView: Updated tab button title to: %@", newTitle);
                break;
            }
        }
    });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

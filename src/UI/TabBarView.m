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

- (void)removeManuallyAddedSublayers {
    // CRITICAL FIX: Only remove sublayers we explicitly added for styling
    // This preserves system-managed layers that handle button visibility and functionality
    
    if (!self.layer.sublayers) return;
    
    NSMutableArray *layersToRemove = [NSMutableArray array];
    
    for (CALayer *sublayer in self.layer.sublayers) {
        // Only remove layers we can identify as manually added for styling
        // System layers typically don't have custom names or specific properties
        
        // Remove shadow layers (we'll recreate them if needed)
        if (sublayer.shadowOpacity > 0) {
            [layersToRemove addObject:sublayer];
        }
        
        // Remove layers with custom background colors that aren't clear
        // (but preserve the main layer background)
        if (sublayer != self.layer && 
            sublayer.backgroundColor && 
            !CGColorEqualToColor(sublayer.backgroundColor, [NSColor clearColor].CGColor)) {
            [layersToRemove addObject:sublayer];
        }
        
        // Remove layers with border styling that we might have added
        if (sublayer.borderWidth > 0 && sublayer != self.layer) {
            [layersToRemove addObject:sublayer];
        }
    }
    
    // Remove identified layers
    for (CALayer *layer in layersToRemove) {
        [layer removeFromSuperlayer];
    }
    
    NSLog(@"TabButton: Removed %lu manually added sublayers", (unsigned long)layersToRemove.count);
}

- (void)updateAppearanceForSelected:(BOOL)selected {
    UIManager *uiManager = [UIManager sharedManager];
    
    self.wantsLayer = YES;
    
    // CRITICAL FIX: Only remove specific layers we manage, not all sublayers
    // This prevents removal of system-managed layers that handle button visibility
    [self removeManuallyAddedSublayers];
    
    NSColor *textColor;
    NSFont *font;
    
    if (selected) {
        // Active tab styling - clearly visible like Safari
        // self.layer.backgroundColor = [NSColor.whiteColor colorWithAlphaComponent:0.9].CGColor;
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
// DEBUGGING: Track selection changes to detect rapid switching
@property (nonatomic, strong) NSTimer *selectionDebounceTimer;
@property (nonatomic, weak) Tab *pendingSelectedTab;
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
    // THREAD SAFETY: Ensure this always runs on main thread
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self distributeTabWidthsEvenly];
        });
        return;
    }
    
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
    
    // CONSTRAINT SAFETY: Validate calculated width is reasonable
    if (tabWidth <= 0 || tabWidth > 1000.0) {
        NSLog(@"TabBarView: WARNING - Invalid tab width calculated: %.1f, using safe fallback", tabWidth);
        tabWidth = guaranteedMinWidth;
    }
    
    NSLog(@"TabBarView: Calculated tab width: %.1f for %ld tabs (available: %.1f)", tabWidth, tabCount, availableWidth);
    
    // CONSTRAINT MANAGEMENT: Batch constraint updates to prevent conflicts
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0]; // No animation for constraint changes
    
    for (TabButton *tabButton in self.tabButtons) {
        // IMPROVED CONSTRAINT HANDLING: Only update if width actually changed
        CGFloat currentConstraintWidth = tabButton.widthConstraint ? tabButton.widthConstraint.constant : 0;
        
        if (fabs(currentConstraintWidth - tabWidth) > 1.0) { // Only update if significantly different
            // Remove old width constraint if it exists
            if (tabButton.widthConstraint) {
                tabButton.widthConstraint.active = NO;
                tabButton.widthConstraint = nil; // Clear reference
            }
            
            // Create and store new width constraint
            tabButton.widthConstraint = [tabButton.widthAnchor constraintEqualToConstant:tabWidth];
            tabButton.widthConstraint.priority = NSLayoutPriorityRequired;
            tabButton.widthConstraint.active = YES;
            
            NSLog(@"TabBarView: Updated constraint for tab '%@' from %.1f to %.1f", tabButton.title, currentConstraintWidth, tabWidth);
        }
    }
    
    [NSAnimationContext endGrouping];
    
    // LAYOUT VALIDATION: Force layout update to ensure constraints are applied
    [self.tabStackView setNeedsLayout:YES];
    [self setNeedsLayout:YES];
}

- (void)selectTab:(Tab *)tab {
    // DEBOUNCING: Handle rapid tab selections gracefully
    self.pendingSelectedTab = tab;
    
    // Cancel any existing timer
    if (self.selectionDebounceTimer && self.selectionDebounceTimer.isValid) {
        [self.selectionDebounceTimer invalidate];
    }
    
    // Set a short debounce timer to batch rapid selections
    self.selectionDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 // 50ms debounce
                                                                   repeats:NO
                                                                     block:^(NSTimer * _Nonnull timer) {
        [self performDebouncedTabSelection];
    }];
    
    NSLog(@"TabBarView: Queued tab selection: %@ (debounced)", tab.title);
}

- (void)performDebouncedTabSelection {
    // THREAD SAFETY: Ensure this runs on main thread
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performDebouncedTabSelection];
        });
        return;
    }
    
    Tab *tabToSelect = self.pendingSelectedTab;
    if (!tabToSelect) return;
    
    self.selectedTab = tabToSelect;
    
    // VISIBILITY CHECK: Validate tabs are still visible before updating
    BOOL tabsAreVisible = [self validateTabVisibility];
    if (!tabsAreVisible) {
        NSLog(@"TabBarView: WARNING - Tabs not visible during selection, attempting recovery");
        [self recoverTabVisibility];
    }
    
    // Update visual appearance of all tab buttons (PURE VISUAL ONLY)
    for (TabButton *tabButton in self.tabButtons) {
        BOOL isSelected = (tabButton.tab == tabToSelect);
        [tabButton updateAppearanceForSelected:isSelected];
    }
    
    NSLog(@"TabBarView: Applied tab selection: %@ (debounced completion)", tabToSelect.title);
    
    // Clear pending selection
    self.pendingSelectedTab = nil;
}

- (BOOL)validateTabVisibility {
    // Check if tab buttons are visible and have reasonable frames
    for (TabButton *tabButton in self.tabButtons) {
        if (tabButton.isHidden || 
            tabButton.alphaValue < 0.1 || 
            tabButton.frame.size.width < 10 || 
            tabButton.frame.size.height < 10) {
            NSLog(@"TabBarView: Tab '%@' visibility issue - hidden:%d alpha:%.2f frame:%@", 
                  tabButton.title, tabButton.isHidden, tabButton.alphaValue, NSStringFromRect(tabButton.frame));
            return NO;
        }
    }
    return YES;
}

- (void)recoverTabVisibility {
    NSLog(@"TabBarView: Attempting to recover tab visibility");
    
    // Force all tabs to be visible
    for (TabButton *tabButton in self.tabButtons) {
        tabButton.hidden = NO;
        tabButton.alphaValue = 1.0;
        
        // Ensure the button has a layer and it's configured properly
        if (!tabButton.wantsLayer) {
            tabButton.wantsLayer = YES;
        }
        
        // Reset any problematic layer properties
        if (tabButton.layer) {
            tabButton.layer.hidden = NO;
            tabButton.layer.opacity = 1.0;
            
            // Ensure the layer has a reasonable frame
            if (CGSizeEqualToSize(tabButton.layer.bounds.size, CGSizeZero)) {
                [tabButton setNeedsLayout:YES];
            }
        }
    }
    
    // Force layout update
    [self.tabStackView setNeedsLayout:YES];
    [self setNeedsLayout:YES];
    
    // Recalculate tab widths in case that's the issue
    dispatch_async(dispatch_get_main_queue(), ^{
        [self distributeTabWidthsEvenly];
    });
    
    NSLog(@"TabBarView: Tab visibility recovery completed");
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
    // Clean up timer to prevent memory leaks
    if (self.selectionDebounceTimer && self.selectionDebounceTimer.isValid) {
        [self.selectionDebounceTimer invalidate];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

//
//  TabBarView.m
//  StealthKit
//
//  Created on Multi-Tab UI Implementation
//

#import "TabBarView.h"
#import "TabManager.h"

@interface TabButton : NSButton
@property (nonatomic, weak) Tab *tab;
@property (nonatomic, weak) TabBarView *tabBarView;
@property (nonatomic, strong) NSButton *closeButton;
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
    self.bezelStyle = NSBezelStyleRounded;
    self.buttonType = NSButtonTypeMomentaryPushIn;
    self.target = self;
    self.action = @selector(tabButtonClicked:);
    
    // Create close button
    self.closeButton = [[NSButton alloc] init];
    self.closeButton.title = @"✕";
    self.closeButton.bezelStyle = NSBezelStyleCircular;
    self.closeButton.buttonType = NSButtonTypeMomentaryPushIn;
    self.closeButton.target = self;
    self.closeButton.action = @selector(closeButtonClicked:);
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    
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
    if (selected) {
        self.layer.backgroundColor = [NSColor selectedControlColor].CGColor;
    } else {
        self.layer.backgroundColor = [NSColor controlColor].CGColor;
    }
}

@end

@interface TabBarView ()
@property (nonatomic, strong) NSScrollView *tabScrollView;
@property (nonatomic, strong) NSStackView *tabStackView;
@property (nonatomic, strong) NSButton *addTabButton;
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
    // Set background color
    self.wantsLayer = YES;
    self.layer.backgroundColor = [NSColor windowBackgroundColor].CGColor;
    
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
    
    // Create add tab button
    self.addTabButton = [[NSButton alloc] init];
    self.addTabButton.title = @"+";
    self.addTabButton.bezelStyle = NSBezelStyleRounded;
    self.addTabButton.buttonType = NSButtonTypeMomentaryPushIn;
    self.addTabButton.target = self;
    self.addTabButton.action = @selector(newTabButtonClicked:);
    self.addTabButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Set up view hierarchy
    self.tabScrollView.documentView = self.tabStackView;
    [self addSubview:self.tabScrollView];
    [self addSubview:self.addTabButton];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Tab scroll view
        [self.tabScrollView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.tabScrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.tabScrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.tabScrollView.trailingAnchor constraintEqualToAnchor:self.addTabButton.leadingAnchor constant:-4],
        
        // Add tab button
        [self.addTabButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:4],
        [self.addTabButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-4],
        [self.addTabButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-4],
        [self.addTabButton.widthAnchor constraintEqualToConstant:30],
        
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
        
        // Set tab button constraints
        [NSLayoutConstraint activateConstraints:@[
            [tabButton.widthAnchor constraintGreaterThanOrEqualToConstant:120],
            [tabButton.widthAnchor constraintLessThanOrEqualToConstant:200],
            [tabButton.heightAnchor constraintEqualToConstant:28]
        ]];
    }
    
    // Update selected tab appearance
    [self selectTab:self.tabManager.currentTab];
    
    NSLog(@"TabBarView: Updated tabs (%lu tabs)", (unsigned long)self.tabManager.tabs.count);
}

- (void)selectTab:(Tab *)tab {
    self.selectedTab = tab;
    
    // Update visual appearance of all tab buttons
    for (TabButton *tabButton in self.tabButtons) {
        BOOL isSelected = (tabButton.tab == tab);
        [tabButton updateAppearanceForSelected:isSelected];
    }
}

- (void)newTabButtonClicked:(id)sender {
    if (self.delegate) {
        [self.delegate tabBarViewDidRequestNewTab:self];
    }
}

#pragma mark - Notifications

- (void)tabsChanged:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateTabs];
    });
}

- (void)currentTabChanged:(NSNotification *)notification {
    Tab *currentTab = notification.userInfo[@"currentTab"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self selectTab:currentTab];
    });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

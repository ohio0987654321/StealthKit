//
//  TabBarView.h
//  StealthKit
//
//  Created on Multi-Tab UI Implementation
//

#import <Cocoa/Cocoa.h>

@class Tab;
@class TabManager;
@class TabBarView;

NS_ASSUME_NONNULL_BEGIN

/**
 * Delegate protocol for tab bar interactions.
 */
@protocol TabBarViewDelegate <NSObject>

/**
 * Called when user selects a tab.
 * @param tabBarView The tab bar view
 * @param tab The selected tab
 */
- (void)tabBarView:(TabBarView *)tabBarView didSelectTab:(Tab *)tab;

/**
 * Called when user requests to close a tab.
 * @param tabBarView The tab bar view
 * @param tab The tab to close
 */
- (void)tabBarView:(TabBarView *)tabBarView didRequestCloseTab:(Tab *)tab;

/**
 * Called when user requests a new tab.
 * @param tabBarView The tab bar view
 */
- (void)tabBarViewDidRequestNewTab:(TabBarView *)tabBarView;

@end

/**
 * Visual tab bar that displays tabs and handles user interactions.
 * Provides Safari-like tab appearance with close buttons and new tab button.
 */
@interface TabBarView : NSView

/// Delegate for handling tab interactions
@property (nonatomic, weak, nullable) id<TabBarViewDelegate> delegate;

/// Associated tab manager
@property (nonatomic, weak, nullable) TabManager *tabManager;

/// Currently selected tab
@property (nonatomic, weak, nullable) Tab *selectedTab;

/**
 * Creates a new tab bar view.
 * @return Configured tab bar view
 */
+ (instancetype)createTabBarView;

/**
 * Update the tab bar with current tabs from tab manager.
 */
- (void)updateTabs;

/**
 * Select a specific tab visually.
 * @param tab The tab to select
 */
- (void)selectTab:(Tab *)tab;

/**
 * Set the tab manager and register for notifications.
 * @param tabManager The tab manager to observe
 */
- (void)setTabManager:(TabManager *)tabManager;

@end

NS_ASSUME_NONNULL_END

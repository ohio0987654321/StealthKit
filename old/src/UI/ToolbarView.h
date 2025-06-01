//
//  ToolbarView.h
//  StealthKit
//
//  Created on Phase 2: Core Browser Implementation
//

#import <Cocoa/Cocoa.h>

@class AddressBarView;

NS_ASSUME_NONNULL_BEGIN

/**
 * Navigation toolbar with Safari-like appearance.
 * Contains back/forward/reload buttons and address bar.
 */
@interface ToolbarView : NSView

/// Back navigation button
@property (nonatomic, readonly) NSButton *backButton;

/// Forward navigation button
@property (nonatomic, readonly) NSButton *forwardButton;

/// Reload button
@property (nonatomic, readonly) NSButton *reloadButton;

/// Smart address bar
@property (nonatomic, readonly) AddressBarView *addressBar;

/**
 * Creates a new toolbar view with all controls configured.
 * @return Configured toolbar view ready for layout
 */
+ (instancetype)createToolbarView;

/**
 * Update navigation button states based on web view state.
 * @param canGoBack Whether back navigation is available
 * @param canGoForward Whether forward navigation is available
 */
- (void)updateNavigationButtons:(BOOL)canGoBack canGoForward:(BOOL)canGoForward;

@end

NS_ASSUME_NONNULL_END

//
//  AddressBarView.h
//  StealthKit
//
//  Created on Phase 2: Core Browser Implementation
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class AddressBarView;

/**
 * Delegate protocol for address bar interactions.
 */
@protocol AddressBarViewDelegate <NSObject>

/**
 * Called when user submits input (presses Enter).
 * @param addressBar The address bar view
 * @param input The user input string
 */
- (void)addressBar:(AddressBarView *)addressBar didSubmitInput:(NSString *)input;

@end

/**
 * Smart address bar that handles both URLs and search queries.
 * Provides Safari-like appearance and behavior.
 */
@interface AddressBarView : NSView

/// Delegate for handling user input
@property (nonatomic, weak, nullable) id<AddressBarViewDelegate> addressBarDelegate;

/**
 * Creates a new address bar with proper styling.
 * @return Configured address bar ready for use
 */
+ (instancetype)createAddressBar;

/**
 * Update the address bar with the current URL.
 * @param url The current URL to display
 */
- (void)updateWithURL:(NSURL *)url;

/**
 * Clear the address bar content.
 */
- (void)clear;

/**
 * Focus the address bar for user input.
 */
- (void)focusAddressField;

@end

NS_ASSUME_NONNULL_END

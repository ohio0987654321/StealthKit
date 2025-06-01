//
//  UIManager.h
//  StealthKit
//
//  Created on UI Management System Implementation
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Theme definitions for consistent UI styling throughout the application.
 */
typedef NS_ENUM(NSInteger, UITheme) {
    UIThemeLight,
    UIThemeDark,
    UIThemeAuto  // Follows system appearance
};

/**
 * Button styles for different UI contexts.
 */
typedef NS_ENUM(NSInteger, UIButtonStyle) {
    UIButtonStyleNavigation,    // Back, forward, reload buttons
    UIButtonStyleTab,          // Tab buttons
    UIButtonStyleAction,       // Primary action buttons
    UIButtonStyleSecondary,    // Secondary action buttons
    UIButtonStyleClose         // Close/dismiss buttons
};

/**
 * Text field styles for different input contexts.
 */
typedef NS_ENUM(NSInteger, UITextFieldStyle) {
    UITextFieldStyleAddressBar,   // URL/search input
    UITextFieldStyleSearch,       // General search fields
    UITextFieldStyleForm          // Form input fields
};

/**
 * Centralized UI management system for consistent styling and component creation.
 * Provides theme management, component factories, and styling utilities.
 */
@interface UIManager : NSObject

#pragma mark - Singleton Access
/**
 * Shared UIManager instance.
 * @return The singleton UIManager instance
 */
+ (instancetype)sharedManager;

#pragma mark - Theme Management
/**
 * Current active theme.
 */
@property (nonatomic, assign) UITheme currentTheme;

/**
 * Switch to a specific theme.
 * @param theme The theme to activate
 */
- (void)setTheme:(UITheme)theme;

/**
 * Check if the current theme is in dark mode.
 * @return YES if dark mode is active, NO otherwise
 */
- (BOOL)isDarkMode;

#pragma mark - Safari-Like Color System
/**
 * Primary background color for main content areas.
 */
@property (nonatomic, readonly) NSColor *primaryBackgroundColor;

/**
 * Secondary background color for toolbars and secondary areas.
 */
@property (nonatomic, readonly) NSColor *secondaryBackgroundColor;

/**
 * Toolbar background with subtle gradient effect.
 */
@property (nonatomic, readonly) NSColor *toolbarBackgroundColor;

/**
 * Tab bar background color.
 */
@property (nonatomic, readonly) NSColor *tabBarBackgroundColor;

/**
 * Primary text color for main content.
 */
@property (nonatomic, readonly) NSColor *primaryTextColor;

/**
 * Secondary text color for labels and secondary content.
 */
@property (nonatomic, readonly) NSColor *secondaryTextColor;

/**
 * Tertiary text color for subtle labels.
 */
@property (nonatomic, readonly) NSColor *tertiaryTextColor;

/**
 * Safari blue accent color for interactive elements.
 */
@property (nonatomic, readonly) NSColor *accentColor;

/**
 * Border color for dividers and separators.
 */
@property (nonatomic, readonly) NSColor *borderColor;

/**
 * Subtle border color for internal dividers.
 */
@property (nonatomic, readonly) NSColor *subtleBorderColor;

/**
 * Selected state color for buttons and tabs.
 */
@property (nonatomic, readonly) NSColor *selectedColor;

/**
 * Hover state color for interactive elements.
 */
@property (nonatomic, readonly) NSColor *hoverColor;

/**
 * Active/pressed state color.
 */
@property (nonatomic, readonly) NSColor *activeColor;

/**
 * Disabled state color for inactive elements.
 */
@property (nonatomic, readonly) NSColor *disabledColor;

/**
 * Shadow color for depth effects.
 */
@property (nonatomic, readonly) NSColor *shadowColor;

/**
 * Address bar background color.
 */
@property (nonatomic, readonly) NSColor *addressBarBackgroundColor;

/**
 * Tab background color for inactive tabs.
 */
@property (nonatomic, readonly) NSColor *inactiveTabColor;

/**
 * Tab background color for active tabs.
 */
@property (nonatomic, readonly) NSColor *activeTabColor;

#pragma mark - Typography System
/**
 * Standard system font for UI elements.
 * @param size Font size
 * @return Configured NSFont
 */
- (NSFont *)systemFontOfSize:(CGFloat)size;

/**
 * Bold system font for emphasis.
 * @param size Font size
 * @return Configured NSFont
 */
- (NSFont *)boldSystemFontOfSize:(CGFloat)size;

/**
 * Medium weight system font for semi-bold text.
 * @param size Font size
 * @return Configured NSFont
 */
- (NSFont *)mediumSystemFontOfSize:(CGFloat)size;

#pragma mark - Dimension Constants
/**
 * Standard toolbar height.
 */
@property (nonatomic, readonly) CGFloat toolbarHeight;

/**
 * Standard tab bar height.
 */
@property (nonatomic, readonly) CGFloat tabBarHeight;

/**
 * Standard button height for navigation elements.
 */
@property (nonatomic, readonly) CGFloat navigationButtonHeight;

/**
 * Standard button width for navigation elements.
 */
@property (nonatomic, readonly) CGFloat navigationButtonWidth;

/**
 * Standard spacing between UI elements.
 */
@property (nonatomic, readonly) CGFloat standardSpacing;

/**
 * Small spacing for tight layouts.
 */
@property (nonatomic, readonly) CGFloat smallSpacing;

/**
 * Large spacing for section separation.
 */
@property (nonatomic, readonly) CGFloat largeSpacing;

/**
 * Standard corner radius for rounded elements.
 */
@property (nonatomic, readonly) CGFloat cornerRadius;

#pragma mark - Component Factory
/**
 * Create a styled button with the specified style.
 * @param title Button title
 * @param style Button style
 * @param target Target for button action
 * @param action Selector for button action
 * @return Configured NSButton
 */
- (NSButton *)createButtonWithTitle:(NSString *)title
                              style:(UIButtonStyle)style
                             target:(nullable id)target
                             action:(nullable SEL)action;

/**
 * Create a styled text field with the specified style.
 * @param placeholder Placeholder text
 * @param style Text field style
 * @return Configured NSTextField
 */
- (NSTextField *)createTextFieldWithPlaceholder:(NSString *)placeholder
                                          style:(UITextFieldStyle)style;

/**
 * Create a styled container view with standard background.
 * @return Configured NSView
 */
- (NSView *)createContainerView;

/**
 * Create a separator view for dividing content areas.
 * @return Configured separator view
 */
- (NSView *)createSeparatorView;

#pragma mark - Style Application
/**
 * Apply consistent styling to an existing button.
 * @param button Button to style
 * @param style Style to apply
 */
- (void)styleButton:(NSButton *)button withStyle:(UIButtonStyle)style;

/**
 * Apply consistent styling to an existing text field.
 * @param textField Text field to style
 * @param style Style to apply
 */
- (void)styleTextField:(NSTextField *)textField withStyle:(UITextFieldStyle)style;

/**
 * Apply container styling to an existing view.
 * @param view View to style as container
 */
- (void)styleAsContainer:(NSView *)view;

/**
 * Apply toolbar styling to an existing view.
 * @param view View to style as toolbar
 */
- (void)styleAsToolbar:(NSView *)view;

#pragma mark - Layout Utilities
/**
 * Create standard spacing constraint.
 * @param firstItem First layout item
 * @param firstAttribute First attribute
 * @param secondItem Second layout item
 * @param secondAttribute Second attribute
 * @return Configured constraint with standard spacing
 */
- (NSLayoutConstraint *)standardSpacingConstraintFrom:(id)firstItem
                                            attribute:(NSLayoutAttribute)firstAttribute
                                                   to:(id)secondItem
                                            attribute:(NSLayoutAttribute)secondAttribute;

/**
 * Create small spacing constraint.
 * @param firstItem First layout item
 * @param firstAttribute First attribute
 * @param secondItem Second layout item
 * @param secondAttribute Second attribute
 * @return Configured constraint with small spacing
 */
- (NSLayoutConstraint *)smallSpacingConstraintFrom:(id)firstItem
                                         attribute:(NSLayoutAttribute)firstAttribute
                                                to:(id)secondItem
                                         attribute:(NSLayoutAttribute)secondAttribute;

/**
 * Apply standard button size constraints to a button.
 * @param button Button to constrain
 */
- (void)applyStandardButtonConstraints:(NSButton *)button;

/**
 * Apply navigation button size constraints to a button.
 * @param button Button to constrain
 */
- (void)applyNavigationButtonConstraints:(NSButton *)button;

@end

NS_ASSUME_NONNULL_END

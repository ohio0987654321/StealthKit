//
//  UIManager.m
//  StealthKit
//
//  Created on UI Management System Implementation
//

#import "UIManager.h"

@interface UIManager ()
@end

@implementation UIManager

#pragma mark - Singleton Access

+ (instancetype)sharedManager {
    static UIManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[UIManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentTheme = UIThemeAuto;
        [self setupThemeObserver];
    }
    return self;
}

- (void)setupThemeObserver {
    // Observe system appearance changes for auto theme
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(systemAppearanceChanged:)
                                                            name:@"AppleInterfaceThemeChangedNotification"
                                                          object:nil];
}

- (void)systemAppearanceChanged:(NSNotification *)notification {
    if (self.currentTheme == UIThemeAuto) {
        // Force update colors when system appearance changes
        [self postThemeChangeNotification];
    }
}

- (void)postThemeChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StealthKitThemeChanged" object:self];
}

#pragma mark - Theme Management

- (void)setTheme:(UITheme)theme {
    if (_currentTheme != theme) {
        _currentTheme = theme;
        [self postThemeChangeNotification];
        NSLog(@"UIManager: Theme changed to %ld", (long)theme);
    }
}

- (BOOL)isDarkMode {
    switch (self.currentTheme) {
        case UIThemeDark:
            return YES;
        case UIThemeLight:
            return NO;
        case UIThemeAuto:
            if (@available(macOS 10.14, *)) {
                NSAppearance *appearance = [NSApp effectiveAppearance];
                NSAppearanceName appearanceName = [appearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
                return [appearanceName isEqualToString:NSAppearanceNameDarkAqua];
            }
            return NO;
    }
}

#pragma mark - Safari-Like Color System

- (NSColor *)primaryBackgroundColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.11 green:0.11 blue:0.11 alpha:1.0]; // #1C1C1C
    } else {
        return [NSColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]; // #FFFFFF
    }
}

- (NSColor *)secondaryBackgroundColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]; // #262626
    } else {
        return [NSColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0]; // #F5F5F5
    }
}

- (NSColor *)toolbarBackgroundColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.18 green:0.18 blue:0.18 alpha:0.95]; // #2D2D2D with slight transparency
    } else {
        return [NSColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:0.95]; // #FAFAFA with slight transparency
    }
}

- (NSColor *)tabBarBackgroundColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.14 green:0.14 blue:0.14 alpha:1.0]; // #242424
    } else {
        return [NSColor colorWithRed:0.94 green:0.94 blue:0.94 alpha:1.0]; // #F0F0F0
    }
}

- (NSColor *)primaryTextColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0]; // #F2F2F2
    } else {
        return [NSColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:1.0]; // #212121
    }
}

- (NSColor *)secondaryTextColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0]; // #B3B3B3
    } else {
        return [NSColor colorWithRed:0.45 green:0.45 blue:0.45 alpha:1.0]; // #737373
    }
}

- (NSColor *)tertiaryTextColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.55 green:0.55 blue:0.55 alpha:1.0]; // #8C8C8C
    } else {
        return [NSColor colorWithRed:0.65 green:0.65 blue:0.65 alpha:1.0]; // #A6A6A6
    }
}

- (NSColor *)accentColor {
    // Safari-like blue accent
    return [NSColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0]; // #007AFF
}

- (NSColor *)borderColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0]; // #404040
    } else {
        return [NSColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0]; // #D9D9D9
    }
}

- (NSColor *)subtleBorderColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1.0]; // #383838
    } else {
        return [NSColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]; // #E6E6E6
    }
}

- (NSColor *)selectedColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0]; // #333333
    } else {
        return [NSColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]; // #E6E6E6
    }
}

- (NSColor *)hoverColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0]; // #404040
    } else {
        return [NSColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0]; // #D9D9D9
    }
}

- (NSColor *)activeColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0]; // #4D4D4D
    } else {
        return [NSColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0]; // #CCCCCC
    }
}

- (NSColor *)disabledColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0]; // #4D4D4D
    } else {
        return [NSColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1.0]; // #BFBFBF
    }
}

- (NSColor *)shadowColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3];
    } else {
        return [NSColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.1];
    }
}

- (NSColor *)addressBarBackgroundColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.19 green:0.19 blue:0.19 alpha:1.0]; // #303030
    } else {
        return [NSColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0]; // #FCFCFC
    }
}

- (NSColor *)inactiveTabColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.16 green:0.16 blue:0.16 alpha:1.0]; // #292929
    } else {
        return [NSColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1.0]; // #EBEBEB
    }
}

- (NSColor *)activeTabColor {
    if ([self isDarkMode]) {
        return [NSColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0]; // #333333
    } else {
        return [NSColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]; // #FFFFFF
    }
}

#pragma mark - Typography System

- (NSFont *)systemFontOfSize:(CGFloat)size {
    return [NSFont systemFontOfSize:size];
}

- (NSFont *)boldSystemFontOfSize:(CGFloat)size {
    return [NSFont boldSystemFontOfSize:size];
}

- (NSFont *)mediumSystemFontOfSize:(CGFloat)size {
    return [NSFont systemFontOfSize:size weight:NSFontWeightMedium];
}

#pragma mark - Dimension Constants

- (CGFloat)toolbarHeight {
    return 44.0;
}

- (CGFloat)tabBarHeight {
    return 36.0;
}

- (CGFloat)navigationButtonHeight {
    return 28.0;
}

- (CGFloat)navigationButtonWidth {
    return 32.0;
}

- (CGFloat)standardSpacing {
    return 8.0;
}

- (CGFloat)smallSpacing {
    return 4.0;
}

- (CGFloat)largeSpacing {
    return 16.0;
}

- (CGFloat)cornerRadius {
    return 6.0;
}

#pragma mark - Component Factory

- (NSButton *)createButtonWithTitle:(NSString *)title
                              style:(UIButtonStyle)style
                             target:(nullable id)target
                             action:(nullable SEL)action {
    NSButton *button = [[NSButton alloc] init];
    button.title = title;
    button.target = target;
    button.action = action;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self styleButton:button withStyle:style];
    
    return button;
}

- (NSTextField *)createTextFieldWithPlaceholder:(NSString *)placeholder
                                          style:(UITextFieldStyle)style {
    NSTextField *textField = [[NSTextField alloc] init];
    textField.placeholderString = placeholder;
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self styleTextField:textField withStyle:style];
    
    return textField;
}

- (NSView *)createContainerView {
    NSView *view = [[NSView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self styleAsContainer:view];
    return view;
}

- (NSView *)createSeparatorView {
    NSView *separator = [[NSView alloc] init];
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    separator.wantsLayer = YES;
    separator.layer.backgroundColor = self.borderColor.CGColor;
    
    // Add height constraint for horizontal separator
    [separator.heightAnchor constraintEqualToConstant:1.0].active = YES;
    
    return separator;
}

#pragma mark - Style Application

- (void)styleButton:(NSButton *)button withStyle:(UIButtonStyle)style {
    button.wantsLayer = YES;
    button.bordered = NO;
    button.buttonType = NSButtonTypeMomentaryChange;
    
    switch (style) {
        case UIButtonStyleNavigation:
            [self applySafariNavigationButtonStyle:button];
            break;
            
        case UIButtonStyleTab:
            [self applySafariTabButtonStyle:button];
            break;
            
        case UIButtonStyleAction:
            [self applySafariActionButtonStyle:button];
            break;
            
        case UIButtonStyleSecondary:
            [self applySafariSecondaryButtonStyle:button];
            break;
            
        case UIButtonStyleClose:
            [self applySafariCloseButtonStyle:button];
            break;
    }
}

- (void)applySafariNavigationButtonStyle:(NSButton *)button {
    button.font = [self mediumSystemFontOfSize:16.0];
    button.layer.cornerRadius = 6.0;
    button.layer.backgroundColor = [NSColor clearColor].CGColor;
    button.layer.borderWidth = 0;
    
    // Add subtle shadow
    button.layer.shadowColor = self.shadowColor.CGColor;
    button.layer.shadowOffset = CGSizeMake(0, -0.5);
    button.layer.shadowRadius = 1.0;
    button.layer.shadowOpacity = 0.2;
    
    // Set text color
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:button.title];
    [attrTitle addAttribute:NSForegroundColorAttributeName value:self.primaryTextColor range:NSMakeRange(0, attrTitle.length)];
    button.attributedTitle = attrTitle;
}

- (void)applySafariTabButtonStyle:(NSButton *)button {
    button.font = [self systemFontOfSize:13.0];
    button.layer.cornerRadius = 8.0;
    button.layer.backgroundColor = self.inactiveTabColor.CGColor;
    button.layer.borderWidth = 0.5;
    button.layer.borderColor = self.subtleBorderColor.CGColor;
    
    // Add subtle inner shadow
    button.layer.shadowColor = self.shadowColor.CGColor;
    button.layer.shadowOffset = CGSizeMake(0, 1);
    button.layer.shadowRadius = 2.0;
    button.layer.shadowOpacity = 0.1;
    
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:button.title];
    [attrTitle addAttribute:NSForegroundColorAttributeName value:self.primaryTextColor range:NSMakeRange(0, attrTitle.length)];
    button.attributedTitle = attrTitle;
}

- (void)applySafariActionButtonStyle:(NSButton *)button {
    button.font = [self mediumSystemFontOfSize:14.0];
    button.layer.cornerRadius = 6.0;
    button.layer.backgroundColor = self.accentColor.CGColor;
    button.layer.borderWidth = 0;
    
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:button.title];
    [attrTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, attrTitle.length)];
    button.attributedTitle = attrTitle;
}

- (void)applySafariSecondaryButtonStyle:(NSButton *)button {
    button.font = [self systemFontOfSize:14.0];
    button.layer.cornerRadius = 6.0;
    button.layer.backgroundColor = [NSColor clearColor].CGColor;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = self.borderColor.CGColor;
    
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:button.title];
    [attrTitle addAttribute:NSForegroundColorAttributeName value:self.secondaryTextColor range:NSMakeRange(0, attrTitle.length)];
    button.attributedTitle = attrTitle;
}

- (void)applySafariCloseButtonStyle:(NSButton *)button {
    button.font = [self systemFontOfSize:12.0];
    button.layer.cornerRadius = 8.0;
    button.layer.backgroundColor = [NSColor clearColor].CGColor;
    button.layer.borderWidth = 0;
    
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:button.title];
    [attrTitle addAttribute:NSForegroundColorAttributeName value:self.tertiaryTextColor range:NSMakeRange(0, attrTitle.length)];
    button.attributedTitle = attrTitle;
}

- (void)styleTextField:(NSTextField *)textField withStyle:(UITextFieldStyle)style {
    textField.wantsLayer = YES;
    textField.bordered = NO;
    textField.bezeled = NO;
    
    switch (style) {
        case UITextFieldStyleAddressBar:
            [self applySafariAddressBarStyle:textField];
            break;
            
        case UITextFieldStyleSearch:
            [self applySafariSearchFieldStyle:textField];
            break;
            
        case UITextFieldStyleForm:
            [self applySafariFormFieldStyle:textField];
            break;
    }
    
    // Configure cell for better behavior
    NSTextFieldCell *cell = textField.cell;
    cell.scrollable = YES;
    cell.wraps = NO;
}

- (void)applySafariAddressBarStyle:(NSTextField *)textField {
    // Completely disable NSTextField's visual styling to avoid double borders
    textField.bordered = NO;
    textField.bezeled = NO;
    textField.drawsBackground = NO;
    textField.focusRingType = NSFocusRingTypeNone;
    
    // Configure font and text properties
    textField.font = [self systemFontOfSize:14.0];
    textField.textColor = self.primaryTextColor;
    
    // Configure cell for proper behavior
    NSTextFieldCell *cell = textField.cell;
    cell.usesSingleLineMode = YES;
    cell.scrollable = YES;
    cell.wraps = NO;
    cell.bezeled = NO;
    cell.bordered = NO;
    cell.drawsBackground = NO;
    
    // Remove any layer styling from the text field itself
    textField.wantsLayer = NO;
}

- (void)applySafariSearchFieldStyle:(NSTextField *)textField {
    textField.font = [self systemFontOfSize:13.0];
    textField.textColor = self.primaryTextColor;
    textField.layer.backgroundColor = self.secondaryBackgroundColor.CGColor;
    textField.layer.cornerRadius = 6.0;
    textField.layer.borderWidth = 1.0;
    textField.layer.borderColor = self.borderColor.CGColor;
}

- (void)applySafariFormFieldStyle:(NSTextField *)textField {
    textField.font = [self systemFontOfSize:13.0];
    textField.textColor = self.primaryTextColor;
    textField.layer.backgroundColor = self.primaryBackgroundColor.CGColor;
    textField.layer.cornerRadius = 4.0;
    textField.layer.borderWidth = 1.0;
    textField.layer.borderColor = self.borderColor.CGColor;
}

- (void)styleAsContainer:(NSView *)view {
    view.wantsLayer = YES;
    view.layer.backgroundColor = self.primaryBackgroundColor.CGColor;
}

- (void)styleAsToolbar:(NSView *)view {
    view.wantsLayer = YES;
    view.layer.backgroundColor = self.toolbarBackgroundColor.CGColor;
    
    // Add bottom border
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.backgroundColor = self.subtleBorderColor.CGColor;
    bottomBorder.frame = CGRectMake(0, 0, view.bounds.size.width, 1);
    bottomBorder.autoresizingMask = kCALayerWidthSizable;
    [view.layer addSublayer:bottomBorder];
    
    // Add subtle shadow
    view.layer.shadowColor = self.shadowColor.CGColor;
    view.layer.shadowOffset = CGSizeMake(0, -1);
    view.layer.shadowRadius = 2.0;
    view.layer.shadowOpacity = 0.1;
}

#pragma mark - Layout Utilities

- (NSLayoutConstraint *)standardSpacingConstraintFrom:(id)firstItem
                                            attribute:(NSLayoutAttribute)firstAttribute
                                                   to:(id)secondItem
                                            attribute:(NSLayoutAttribute)secondAttribute {
    return [NSLayoutConstraint constraintWithItem:firstItem
                                         attribute:firstAttribute
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:secondItem
                                         attribute:secondAttribute
                                        multiplier:1.0
                                          constant:self.standardSpacing];
}

- (NSLayoutConstraint *)smallSpacingConstraintFrom:(id)firstItem
                                         attribute:(NSLayoutAttribute)firstAttribute
                                                to:(id)secondItem
                                         attribute:(NSLayoutAttribute)secondAttribute {
    return [NSLayoutConstraint constraintWithItem:firstItem
                                         attribute:firstAttribute
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:secondItem
                                         attribute:secondAttribute
                                        multiplier:1.0
                                          constant:self.smallSpacing];
}

- (void)applyStandardButtonConstraints:(NSButton *)button {
    [NSLayoutConstraint activateConstraints:@[
        [button.heightAnchor constraintEqualToConstant:self.navigationButtonHeight]
    ]];
}

- (void)applyNavigationButtonConstraints:(NSButton *)button {
    [NSLayoutConstraint activateConstraints:@[
        [button.widthAnchor constraintEqualToConstant:self.navigationButtonWidth],
        [button.heightAnchor constraintEqualToConstant:self.navigationButtonHeight]
    ]];
}

- (void)dealloc {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

@end

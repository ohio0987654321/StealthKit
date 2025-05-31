//
//  ToolbarView.m
//  StealthKit
//
//  Created on Phase 2: Core Browser Implementation
//

#import "ToolbarView.h"
#import "AddressBarView.h"
#import "UIManager.h"

@interface ToolbarView ()
@property (nonatomic, strong) NSButton *backButton;
@property (nonatomic, strong) NSButton *forwardButton;
@property (nonatomic, strong) NSButton *reloadButton;
@property (nonatomic, strong) AddressBarView *addressBar;
@end

@implementation ToolbarView

+ (instancetype)createToolbarView {
    ToolbarView *toolbar = [[ToolbarView alloc] init];
    [toolbar setupViews];
    [toolbar setupLayout];
    [toolbar setupStyling];
    return toolbar;
}

- (void)setupViews {
    UIManager *uiManager = [UIManager sharedManager];
    
    // Create navigation buttons using UIManager
    self.backButton = [uiManager createButtonWithTitle:@"←" style:UIButtonStyleNavigation target:self action:@selector(backButtonPressed:)];
    self.forwardButton = [uiManager createButtonWithTitle:@"→" style:UIButtonStyleNavigation target:self action:@selector(forwardButtonPressed:)];
    self.reloadButton = [uiManager createButtonWithTitle:@"↻" style:UIButtonStyleNavigation target:self action:@selector(reloadButtonPressed:)];
    
    // Create address bar
    self.addressBar = [AddressBarView createAddressBar];
    
    // Add to view hierarchy
    [self addSubview:self.backButton];
    [self addSubview:self.forwardButton];
    [self addSubview:self.reloadButton];
    [self addSubview:self.addressBar];
}

- (void)setupLayout {
    UIManager *uiManager = [UIManager sharedManager];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Apply navigation button constraints using UIManager
    [uiManager applyNavigationButtonConstraints:self.backButton];
    [uiManager applyNavigationButtonConstraints:self.forwardButton];
    [uiManager applyNavigationButtonConstraints:self.reloadButton];
    
    // Add minimum width constraint to prevent collapse
    [self.widthAnchor constraintGreaterThanOrEqualToConstant:400].active = YES;
    
    // Layout constraints using UIManager constants
    [NSLayoutConstraint activateConstraints:@[
        // Toolbar height
        [self.heightAnchor constraintEqualToConstant:uiManager.toolbarHeight],
        
        // Address bar height
        [self.addressBar.heightAnchor constraintEqualToConstant:uiManager.navigationButtonHeight],
        
        // Back button
        [self.backButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:uiManager.standardSpacing],
        [self.backButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        
        // Forward button
        [self.forwardButton.leadingAnchor constraintEqualToAnchor:self.backButton.trailingAnchor constant:uiManager.smallSpacing],
        [self.forwardButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        
        // Reload button
        [self.reloadButton.leadingAnchor constraintEqualToAnchor:self.forwardButton.trailingAnchor constant:uiManager.standardSpacing],
        [self.reloadButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        
        // Address bar - takes remaining space
        [self.addressBar.leadingAnchor constraintEqualToAnchor:self.reloadButton.trailingAnchor constant:uiManager.standardSpacing],
        [self.addressBar.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-uiManager.standardSpacing],
        [self.addressBar.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
    ]];
}

- (void)setupStyling {
    // Apply styling through UIManager for consistency
    UIManager *uiManager = [UIManager sharedManager];
    [uiManager styleAsToolbar:self];
    
    // Register for theme change notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:@"StealthKitThemeChanged"
                                               object:nil];
}

- (void)updateNavigationButtons:(BOOL)canGoBack canGoForward:(BOOL)canGoForward {
    self.backButton.enabled = canGoBack;
    self.forwardButton.enabled = canGoForward;
}

#pragma mark - Button Actions

- (void)backButtonPressed:(id)sender {
    // Will be handled by parent window
    [NSApp sendAction:@selector(goBack) to:nil from:self];
}

- (void)forwardButtonPressed:(id)sender {
    // Will be handled by parent window
    [NSApp sendAction:@selector(goForward) to:nil from:self];
}

- (void)reloadButtonPressed:(id)sender {
    // Will be handled by parent window
    [NSApp sendAction:@selector(reload) to:nil from:self];
}

#pragma mark - Theme Support

- (void)themeChanged:(NSNotification *)notification {
    // Reapply styling when theme changes
    UIManager *uiManager = [UIManager sharedManager];
    [uiManager styleAsToolbar:self];
    [uiManager styleButton:self.backButton withStyle:UIButtonStyleNavigation];
    [uiManager styleButton:self.forwardButton withStyle:UIButtonStyleNavigation];
    [uiManager styleButton:self.reloadButton withStyle:UIButtonStyleNavigation];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

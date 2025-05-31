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
@property (nonatomic, strong) NSButton *addTabButton;
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
    
    // Create add tab button with clean styling
    self.addTabButton = [[NSButton alloc] init];
    self.addTabButton.title = @"+";
    self.addTabButton.bordered = NO;
    self.addTabButton.buttonType = NSButtonTypeMomentaryChange;
    self.addTabButton.target = self;
    self.addTabButton.action = @selector(addTabButtonPressed:);
    self.addTabButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Style the add tab button
    self.addTabButton.wantsLayer = YES;
    self.addTabButton.layer.backgroundColor = [NSColor clearColor].CGColor;
    NSMutableAttributedString *addTabTitle = [[NSMutableAttributedString alloc] initWithString:@"+"];
    [addTabTitle addAttribute:NSForegroundColorAttributeName value:uiManager.secondaryTextColor range:NSMakeRange(0, 1)];
    [addTabTitle addAttribute:NSFontAttributeName value:[uiManager systemFontOfSize:16.0] range:NSMakeRange(0, 1)];
    self.addTabButton.attributedTitle = addTabTitle;
    
    // Add to view hierarchy
    [self addSubview:self.backButton];
    [self addSubview:self.forwardButton];
    [self addSubview:self.reloadButton];
    [self addSubview:self.addressBar];
    [self addSubview:self.addTabButton];
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
        
        // Address bar - takes remaining space between reload and add tab button
        [self.addressBar.leadingAnchor constraintEqualToAnchor:self.reloadButton.trailingAnchor constant:uiManager.standardSpacing],
        [self.addressBar.trailingAnchor constraintEqualToAnchor:self.addTabButton.leadingAnchor constant:-uiManager.standardSpacing],
        [self.addressBar.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        
        // Add tab button
        [self.addTabButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-uiManager.standardSpacing],
        [self.addTabButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.addTabButton.widthAnchor constraintEqualToConstant:30],
        [self.addTabButton.heightAnchor constraintEqualToConstant:uiManager.navigationButtonHeight]
    ]];
}

- (void)setupStyling {
    // Apply Safari-like styling through UIManager
    UIManager *uiManager = [UIManager sharedManager];
    [uiManager styleAsToolbar:self];
    
    // Add visual effects for Safari-like appearance
    self.wantsLayer = YES;
    self.layer.masksToBounds = NO;
    
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

- (void)addTabButtonPressed:(id)sender {
    // Send add tab action to the responder chain
    [[NSApplication sharedApplication] sendAction:@selector(createNewTab:) to:nil from:self];
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

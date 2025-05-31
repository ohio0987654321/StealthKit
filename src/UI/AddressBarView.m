//
//  AddressBarView.m
//  StealthKit
//
//  Created on Phase 2: Core Browser Implementation
//

#import "AddressBarView.h"
#import "UIManager.h"

@interface AddressBarView ()
@property (nonatomic, strong) NSTextField *textField;
@end

@implementation AddressBarView

+ (instancetype)createAddressBar {
    AddressBarView *addressBar = [[AddressBarView alloc] init];
    [addressBar setupViews];
    [addressBar setupLayout];
    [addressBar setupStyling];
    [addressBar setupBehavior];
    return addressBar;
}

- (void)setupViews {
    // Create the text field directly - no container needed
    self.textField = [[NSTextField alloc] init];
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Add directly to this view
    [self addSubview:self.textField];
}

- (void)setupLayout {
    [NSLayoutConstraint activateConstraints:@[
        // Text field fills the entire AddressBarView with padding
        [self.textField.topAnchor constraintEqualToAnchor:self.topAnchor constant:2],
        [self.textField.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:2],
        [self.textField.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-2],
        [self.textField.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-2]
    ]];
    
    // Add minimum width constraint to prevent collapse
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.widthAnchor constraintGreaterThanOrEqualToConstant:200].active = YES;
}

- (void)setupStyling {
    UIManager *uiManager = [UIManager sharedManager];
    
    // Apply all styling directly to the main view (this provides the visual appearance)
    self.wantsLayer = YES;
    self.layer.backgroundColor = uiManager.addressBarBackgroundColor.CGColor;
    self.layer.cornerRadius = 8.0;
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = uiManager.subtleBorderColor.CGColor;
    
    // Add subtle inner shadow
    self.layer.shadowColor = uiManager.shadowColor.CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowRadius = 1.0;
    self.layer.shadowOpacity = 0.05;
    
    // Make text field completely transparent - no visual elements
    self.textField.bordered = NO;
    self.textField.bezeled = NO;
    self.textField.drawsBackground = NO;
    self.textField.focusRingType = NSFocusRingTypeNone;
    
    // Apply only text styling through UIManager
    [uiManager styleTextField:self.textField withStyle:UITextFieldStyleAddressBar];
    
    // Set placeholder
    self.textField.placeholderString = @"Search or enter website name";
    
    // Register for theme change notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:@"StealthKitThemeChanged"
                                               object:nil];
}

- (void)setupBehavior {
    self.textField.target = self;
    self.textField.action = @selector(textFieldAction:);
}

- (void)textFieldAction:(id)sender {
    NSString *input = self.textField.stringValue;
    if (input.length > 0 && self.addressBarDelegate) {
        [self.addressBarDelegate addressBar:self didSubmitInput:input];
    }
}

- (void)updateWithURL:(NSURL *)url {
    if (url) {
        self.textField.stringValue = url.absoluteString;
    } else {
        // Clear the address bar if no URL
        self.textField.stringValue = @"";
    }
}

- (void)clear {
    self.textField.stringValue = @"";
}

- (void)focusAddressField {
    // Make the text field first responder to focus it
    [[self.textField window] makeFirstResponder:self.textField];
    
    // Select all text for easy overwriting
    [self.textField selectText:nil];
    
    NSLog(@"AddressBarView: Address field focused");
}

// Accessor methods for compatibility
- (NSString *)stringValue {
    return self.textField.stringValue;
}

- (void)setStringValue:(NSString *)stringValue {
    self.textField.stringValue = stringValue;
}

#pragma mark - Theme Support

- (void)themeChanged:(NSNotification *)notification {
    UIManager *uiManager = [UIManager sharedManager];
    
    // Update main view styling
    self.layer.backgroundColor = uiManager.addressBarBackgroundColor.CGColor;
    self.layer.borderColor = uiManager.subtleBorderColor.CGColor;
    self.layer.shadowColor = uiManager.shadowColor.CGColor;
    
    // Reapply text field styling
    [uiManager styleTextField:self.textField withStyle:UITextFieldStyleAddressBar];
    
    // Preserve placeholder text
    self.textField.placeholderString = @"Search or enter website name";
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

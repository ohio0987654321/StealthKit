//
//  AddressBarView.m
//  StealthKit
//
//  Created on Phase 2: Core Browser Implementation
//

#import "AddressBarView.h"
#import "UIManager.h"

@interface AddressBarView ()
@end

@implementation AddressBarView

+ (instancetype)createAddressBar {
    AddressBarView *addressBar = [[AddressBarView alloc] init];
    [addressBar setupStyling];
    [addressBar setupBehavior];
    return addressBar;
}

- (void)setupStyling {
    // Apply styling through UIManager for consistency
    UIManager *uiManager = [UIManager sharedManager];
    [uiManager styleTextField:self withStyle:UITextFieldStyleAddressBar];
    
    // Set placeholder after styling
    self.placeholderString = @"Search or enter website name";
    
    // Add minimum width constraint to prevent collapse
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.widthAnchor constraintGreaterThanOrEqualToConstant:200].active = YES;
    
    // Register for theme change notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged:)
                                                 name:@"StealthKitThemeChanged"
                                               object:nil];
    
    // Height will be set by parent ToolbarView constraints
}

- (void)setupBehavior {
    self.target = self;
    self.action = @selector(textFieldAction:);
}

- (void)textFieldAction:(id)sender {
    NSString *input = self.stringValue;
    if (input.length > 0 && self.addressBarDelegate) {
        [self.addressBarDelegate addressBar:self didSubmitInput:input];
    }
}

- (void)updateWithURL:(NSURL *)url {
    if (url) {
        self.stringValue = url.absoluteString;
    }
}

- (void)clear {
    self.stringValue = @"";
}

- (void)focusAddressField {
    // Make the text field first responder to focus it
    [[self window] makeFirstResponder:self];
    
    // Select all text for easy overwriting
    [self selectText:nil];
    
    NSLog(@"AddressBarView: Address field focused");
}

// Handle Enter key properly
- (void)keyDown:(NSEvent *)event {
    if (event.keyCode == 36) { // Enter key
        [self textFieldAction:self];
    } else {
        [super keyDown:event];
    }
}

// Select all text when focused (Safari behavior)
- (BOOL)becomeFirstResponder {
    BOOL result = [super becomeFirstResponder];
    if (result) {
        // Delay text selection to ensure it works properly
        dispatch_async(dispatch_get_main_queue(), ^{
            [self selectText:nil];
        });
    }
    return result;
}

#pragma mark - Theme Support

- (void)themeChanged:(NSNotification *)notification {
    // Reapply styling when theme changes
    UIManager *uiManager = [UIManager sharedManager];
    [uiManager styleTextField:self withStyle:UITextFieldStyleAddressBar];
    
    // Preserve placeholder text
    self.placeholderString = @"Search or enter website name";
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

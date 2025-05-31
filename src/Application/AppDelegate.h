//
//  AppDelegate.h
//  StealthKit
//
//  Created by StealthKit Migration on 2025.
//  Copyright © 2025 StealthKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Main application delegate for StealthKit.
 * Coordinates app lifecycle and stealth feature initialization.
 */
@interface AppDelegate : NSObject <NSApplicationDelegate>

/// Main application window
@property (strong, nonatomic, nullable) NSWindow *mainWindow;

/// Status bar controller for background operation
@property (strong, nonatomic, nullable) id statusBarController;

/// Stealth manager for privacy features
@property (strong, nonatomic, nullable) id stealthManager;

/**
 * Initialize stealth features.
 * Called during applicationDidFinishLaunching.
 */
- (void)initializeStealthFeatures;

/**
 * Create and configure the main browser window.
 * @return Configured browser window ready for display
 */
- (NSWindow *)createMainWindow;

/**
 * Set up background operation mode with status bar.
 */
- (void)setupBackgroundOperation;

@end

NS_ASSUME_NONNULL_END

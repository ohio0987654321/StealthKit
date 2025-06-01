//
//  main.m
//  StealthKit
//
//  Created by StealthKit Migration on 2025.
//  Copyright © 2025 StealthKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Set process name for better identification
        [[NSProcessInfo processInfo] setProcessName:@"StealthKit"];
        
        // Create application instance
        NSApplication *app = [NSApplication sharedApplication];
        
        // Create and set app delegate
        AppDelegate *delegate = [[AppDelegate alloc] init];
        [app setDelegate:delegate];
        
        // Run the application
        [app run];
        
        return 0;
    }
}

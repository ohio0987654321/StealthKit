//
//  URLHelper.h
//  StealthKit
//
//  Created on Phase 3: Smart Address Bar
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility class for intelligent URL detection and processing.
 * Replaces private WebKit APIs with public Foundation/NSDataDetector methods.
 */
@interface URLHelper : NSObject

/**
 * Determines if a string looks like a URL rather than a search query.
 * Uses NSDataDetector and pattern matching for accurate detection.
 * 
 * @param string The input string to analyze
 * @return YES if the string appears to be a URL, NO if it's likely a search query
 */
+ (BOOL)stringLooksLikeURL:(NSString *)string;

/**
 * Converts user input into a properly formatted URL.
 * Handles various URL formats and adds protocols as needed.
 * 
 * @param input The user input string
 * @return A valid NSURL or nil if the input doesn't represent a URL
 */
+ (nullable NSURL *)URLFromUserInput:(NSString *)input;

/**
 * Validates if a string is a properly formatted domain name.
 * Checks for valid TLD and domain structure.
 * 
 * @param string The string to validate
 * @return YES if it's a valid domain name
 */
+ (BOOL)isValidDomainName:(NSString *)string;

/**
 * Extracts the domain from a URL string for display purposes.
 * 
 * @param urlString The URL string
 * @return The domain portion or the original string if extraction fails
 */
+ (NSString *)displayDomainFromURLString:(NSString *)urlString;

/**
 * Determines if input should be treated as a localhost/local network address.
 * 
 * @param string The input string
 * @return YES if it's a local address (localhost, IP, .local, etc.)
 */
+ (BOOL)isLocalAddress:(NSString *)string;

@end

NS_ASSUME_NONNULL_END

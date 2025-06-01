//
//  URLHelper.m
//  StealthKit
//
//  Created on Phase 3: Smart Address Bar
//

#import "URLHelper.h"

@implementation URLHelper

+ (BOOL)stringLooksLikeURL:(NSString *)string {
    if (!string || string.length == 0) {
        return NO;
    }
    
    NSString *trimmed = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Already has a protocol scheme
    if ([self hasValidScheme:trimmed]) {
        return YES;
    }
    
    // Check for local addresses
    if ([self isLocalAddress:trimmed]) {
        return YES;
    }
    
    // Use NSDataDetector to check for URL patterns
    NSError *error = nil;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
    if (error) {
        // Fallback to manual detection
        return [self manualURLDetection:trimmed];
    }
    
    NSRange range = NSMakeRange(0, trimmed.length);
    NSTextCheckingResult *result = [detector firstMatchInString:trimmed options:0 range:range];
    
    if (result && result.range.length == trimmed.length) {
        // NSDataDetector found a complete URL match
        return YES;
    }
    
    // Manual domain validation for cases NSDataDetector might miss
    return [self manualURLDetection:trimmed];
}

+ (BOOL)hasValidScheme:(NSString *)string {
    NSArray *validSchemes = @[@"http://", @"https://", @"ftp://", @"file://", @"about:", @"data:"];
    
    for (NSString *scheme in validSchemes) {
        if ([string.lowercaseString hasPrefix:scheme]) {
            return YES;
        }
    }
    
    return NO;
}

+ (BOOL)manualURLDetection:(NSString *)string {
    // Contains spaces - likely a search query
    if ([string containsString:@" "]) {
        return NO;
    }
    
    // Check for valid domain structure
    if ([self isValidDomainName:string]) {
        return YES;
    }
    
    // Check for IP addresses
    if ([self isIPAddress:string]) {
        return YES;
    }
    
    // Contains common URL patterns
    if ([string containsString:@"."] && ![string hasPrefix:@"."] && ![string hasSuffix:@"."]) {
        // Could be a domain - check for valid TLD
        NSArray *components = [string componentsSeparatedByString:@"."];
        if (components.count >= 2) {
            NSString *tld = [components lastObject];
            return [self isValidTLD:tld];
        }
    }
    
    return NO;
}

+ (nullable NSURL *)URLFromUserInput:(NSString *)input {
    if (!input || input.length == 0) {
        return nil;
    }
    
    NSString *trimmed = [input stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Already has a scheme
    if ([self hasValidScheme:trimmed]) {
        return [NSURL URLWithString:trimmed];
    }
    
    // Local addresses
    if ([self isLocalAddress:trimmed]) {
        NSString *urlString = [@"http://" stringByAppendingString:trimmed];
        return [NSURL URLWithString:urlString];
    }
    
    // Check if it looks like a URL
    if ([self stringLooksLikeURL:trimmed]) {
        // Add https:// by default for security
        NSString *urlString = [@"https://" stringByAppendingString:trimmed];
        NSURL *url = [NSURL URLWithString:urlString];
        
        // Validate the URL is properly formed
        if (url && url.host) {
            return url;
        }
    }
    
    return nil;
}

+ (BOOL)isValidDomainName:(NSString *)string {
    if (!string || string.length == 0) {
        return NO;
    }
    
    // Basic domain validation
    NSString *domainPattern = @"^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\\.[a-zA-Z]{2,}$";
    NSPredicate *domainPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", domainPattern];
    
    if ([domainPredicate evaluateWithObject:string]) {
        return YES;
    }
    
    // Check for subdomain patterns
    NSString *subdomainPattern = @"^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\\.[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\\.[a-zA-Z]{2,}$";
    NSPredicate *subdomainPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", subdomainPattern];
    
    return [subdomainPredicate evaluateWithObject:string];
}

+ (BOOL)isValidTLD:(NSString *)tld {
    if (!tld || tld.length < 2) {
        return NO;
    }
    
    // Common TLDs - this is a subset, but covers most cases
    NSArray *commonTLDs = @[
        @"com", @"org", @"net", @"edu", @"gov", @"mil", @"int", @"info", @"biz", @"name",
        @"uk", @"de", @"fr", @"it", @"es", @"ca", @"au", @"jp", @"cn", @"in", @"br", @"ru",
        @"io", @"co", @"me", @"tv", @"cc", @"ly", @"app", @"dev", @"tech", @"design",
        @"html", @"css", @"js", @"php", @"py", @"rb", @"go", @"rs", @"swift"
    ];
    
    return [commonTLDs containsObject:tld.lowercaseString];
}

+ (BOOL)isIPAddress:(NSString *)string {
    // IPv4 pattern
    NSString *ipv4Pattern = @"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$";
    NSPredicate *ipv4Predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", ipv4Pattern];
    
    if ([ipv4Predicate evaluateWithObject:string]) {
        return YES;
    }
    
    // Basic IPv6 detection (simplified)
    if ([string containsString:@":"]) {
        NSArray *components = [string componentsSeparatedByString:@":"];
        if (components.count >= 3 && components.count <= 8) {
            return YES;
        }
    }
    
    return NO;
}

+ (NSString *)displayDomainFromURLString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (url && url.host) {
        return url.host;
    }
    
    // Fallback: try to extract domain manually
    NSString *cleaned = urlString;
    if ([cleaned hasPrefix:@"http://"]) {
        cleaned = [cleaned substringFromIndex:7];
    } else if ([cleaned hasPrefix:@"https://"]) {
        cleaned = [cleaned substringFromIndex:8];
    }
    
    NSRange slashRange = [cleaned rangeOfString:@"/"];
    if (slashRange.location != NSNotFound) {
        cleaned = [cleaned substringToIndex:slashRange.location];
    }
    
    return cleaned.length > 0 ? cleaned : urlString;
}

+ (BOOL)isLocalAddress:(NSString *)string {
    if (!string || string.length == 0) {
        return NO;
    }
    
    NSString *lower = string.lowercaseString;
    
    // Localhost variations
    if ([lower isEqualToString:@"localhost"] || 
        [lower hasPrefix:@"localhost:"] ||
        [lower isEqualToString:@"127.0.0.1"] ||
        [lower hasPrefix:@"127.0.0.1:"]) {
        return YES;
    }
    
    // Local network addresses
    if ([lower hasPrefix:@"192.168."] || 
        [lower hasPrefix:@"10."] || 
        [lower hasPrefix:@"172.16."] ||
        [lower hasPrefix:@"172.17."] ||
        [lower hasPrefix:@"172.18."] ||
        [lower hasPrefix:@"172.19."] ||
        [lower hasPrefix:@"172.2"] ||
        [lower hasPrefix:@"172.30."] ||
        [lower hasPrefix:@"172.31."]) {
        return YES;
    }
    
    // .local domains
    if ([lower hasSuffix:@".local"] || [lower containsString:@".local:"]) {
        return YES;
    }
    
    return NO;
}

@end

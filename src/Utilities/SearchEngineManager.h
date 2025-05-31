//
//  SearchEngineManager.h
//  StealthKit
//
//  Created on Phase 3: Smart Address Bar
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Search engine configuration object.
 */
@interface SearchEngine : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *searchURLTemplate;
@property (nonatomic, readonly) NSString *suggestionURLTemplate;

+ (instancetype)searchEngineWithName:(NSString *)name
                         displayName:(NSString *)displayName
                    searchURLTemplate:(NSString *)searchURLTemplate
                suggestionURLTemplate:(nullable NSString *)suggestionURLTemplate;

- (NSURL *)searchURLForQuery:(NSString *)query;
- (nullable NSURL *)suggestionURLForQuery:(NSString *)query;

@end

/**
 * Manages search engines and provides search functionality.
 * Replaces hard-coded search with configurable engines.
 */
@interface SearchEngineManager : NSObject

/// Shared singleton instance
@property (class, readonly) SearchEngineManager *shared;

/// Currently selected search engine
@property (nonatomic, strong) SearchEngine *currentSearchEngine;

/// All available search engines
@property (nonatomic, readonly) NSArray<SearchEngine *> *availableSearchEngines;

/**
 * Initialize with default search engines.
 */
- (instancetype)init;

/**
 * Add a custom search engine.
 * @param searchEngine The search engine to add
 */
- (void)addSearchEngine:(SearchEngine *)searchEngine;

/**
 * Remove a search engine by name.
 * @param name The name of the search engine to remove
 */
- (void)removeSearchEngineWithName:(NSString *)name;

/**
 * Set the current search engine by name.
 * @param name The name of the search engine to use
 * @return YES if the search engine was found and set, NO otherwise
 */
- (BOOL)setCurrentSearchEngineByName:(NSString *)name;

/**
 * Get a search URL for the given query using the current search engine.
 * @param query The search query
 * @return URL for searching the query
 */
- (NSURL *)searchURLForQuery:(NSString *)query;

/**
 * Get a suggestion URL for the given query using the current search engine.
 * @param query The partial query for suggestions
 * @return URL for getting search suggestions, or nil if not supported
 */
- (nullable NSURL *)suggestionURLForQuery:(NSString *)query;

/**
 * Find search engine by name.
 * @param name The search engine name
 * @return The search engine or nil if not found
 */
- (nullable SearchEngine *)searchEngineWithName:(NSString *)name;

#pragma mark - Convenience Methods

/**
 * Get display names of all available search engines.
 * @return Array of display names
 */
- (NSArray<NSString *> *)availableSearchEngineDisplayNames;

/**
 * Get internal names of all available search engines.
 * @return Array of internal names
 */
- (NSArray<NSString *> *)availableSearchEngineNames;

/**
 * Set the current search engine by display name.
 * @param displayName The display name of the search engine to use
 */
- (void)setCurrentSearchEngineByDisplayName:(NSString *)displayName;

@end

NS_ASSUME_NONNULL_END

//
//  SearchEngineManager.m
//  StealthKit
//
//  Created on Phase 3: Smart Address Bar
//

#import "SearchEngineManager.h"

#pragma mark - SearchEngine Implementation

@interface SearchEngine ()
@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSString *displayName;
@property (nonatomic, readwrite) NSString *searchURLTemplate;
@property (nonatomic, readwrite) NSString *suggestionURLTemplate;
@end

@implementation SearchEngine

+ (instancetype)searchEngineWithName:(NSString *)name
                         displayName:(NSString *)displayName
                    searchURLTemplate:(NSString *)searchURLTemplate
                suggestionURLTemplate:(NSString *)suggestionURLTemplate {
    SearchEngine *engine = [[SearchEngine alloc] init];
    engine.name = name;
    engine.displayName = displayName;
    engine.searchURLTemplate = searchURLTemplate;
    engine.suggestionURLTemplate = suggestionURLTemplate;
    return engine;
}

- (NSURL *)searchURLForQuery:(NSString *)query {
    NSString *encodedQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [self.searchURLTemplate stringByReplacingOccurrencesOfString:@"{searchTerms}" withString:encodedQuery];
    return [NSURL URLWithString:urlString];
}

- (NSURL *)suggestionURLForQuery:(NSString *)query {
    if (!self.suggestionURLTemplate) {
        return nil;
    }
    
    NSString *encodedQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [self.suggestionURLTemplate stringByReplacingOccurrencesOfString:@"{searchTerms}" withString:encodedQuery];
    return [NSURL URLWithString:urlString];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"SearchEngine: %@ (%@)", self.displayName, self.name];
}

@end

#pragma mark - SearchEngineManager Implementation

@interface SearchEngineManager ()
@property (nonatomic, strong) NSMutableArray<SearchEngine *> *mutableSearchEngines;
@end

@implementation SearchEngineManager

+ (instancetype)shared {
    static SearchEngineManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SearchEngineManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupDefaultSearchEngines];
    }
    return self;
}

- (void)setupDefaultSearchEngines {
    self.mutableSearchEngines = [[NSMutableArray alloc] init];
    
    // Google (default)
    SearchEngine *google = [SearchEngine searchEngineWithName:@"google"
                                                  displayName:@"Google"
                                             searchURLTemplate:@"https://www.google.com/search?q={searchTerms}"
                                         suggestionURLTemplate:@"https://suggestqueries.google.com/complete/search?client=chrome&q={searchTerms}"];
    [self.mutableSearchEngines addObject:google];
    
    // DuckDuckGo (privacy-focused)
    SearchEngine *duckduckgo = [SearchEngine searchEngineWithName:@"duckduckgo"
                                                      displayName:@"DuckDuckGo"
                                                 searchURLTemplate:@"https://duckduckgo.com/?q={searchTerms}"
                                             suggestionURLTemplate:@"https://duckduckgo.com/ac/?q={searchTerms}&type=list"];
    [self.mutableSearchEngines addObject:duckduckgo];
    
    // Bing
    SearchEngine *bing = [SearchEngine searchEngineWithName:@"bing"
                                                displayName:@"Bing"
                                           searchURLTemplate:@"https://www.bing.com/search?q={searchTerms}"
                                       suggestionURLTemplate:@"https://www.bing.com/osjson.aspx?query={searchTerms}"];
    [self.mutableSearchEngines addObject:bing];
    
    // Yahoo
    SearchEngine *yahoo = [SearchEngine searchEngineWithName:@"yahoo"
                                                 displayName:@"Yahoo"
                                            searchURLTemplate:@"https://search.yahoo.com/search?p={searchTerms}"
                                        suggestionURLTemplate:nil];
    [self.mutableSearchEngines addObject:yahoo];
    
    // Startpage (privacy-focused)
    SearchEngine *startpage = [SearchEngine searchEngineWithName:@"startpage"
                                                     displayName:@"Startpage"
                                                searchURLTemplate:@"https://www.startpage.com/sp/search?query={searchTerms}"
                                            suggestionURLTemplate:nil];
    [self.mutableSearchEngines addObject:startpage];
    
    // Searx (open source)
    SearchEngine *searx = [SearchEngine searchEngineWithName:@"searx"
                                                 displayName:@"Searx"
                                            searchURLTemplate:@"https://searx.org/search?q={searchTerms}"
                                        suggestionURLTemplate:nil];
    [self.mutableSearchEngines addObject:searx];
    
    // Developer-focused search engines
    
    // Stack Overflow
    SearchEngine *stackoverflow = [SearchEngine searchEngineWithName:@"stackoverflow"
                                                          displayName:@"Stack Overflow"
                                                     searchURLTemplate:@"https://stackoverflow.com/search?q={searchTerms}"
                                                 suggestionURLTemplate:nil];
    [self.mutableSearchEngines addObject:stackoverflow];
    
    // GitHub
    SearchEngine *github = [SearchEngine searchEngineWithName:@"github"
                                                   displayName:@"GitHub"
                                              searchURLTemplate:@"https://github.com/search?q={searchTerms}"
                                          suggestionURLTemplate:nil];
    [self.mutableSearchEngines addObject:github];
    
    // Set Google as default
    self.currentSearchEngine = google;
}

- (NSArray<SearchEngine *> *)availableSearchEngines {
    return [self.mutableSearchEngines copy];
}

- (void)addSearchEngine:(SearchEngine *)searchEngine {
    if (!searchEngine || !searchEngine.name) {
        return;
    }
    
    // Remove existing engine with same name
    [self removeSearchEngineWithName:searchEngine.name];
    
    // Add new engine
    [self.mutableSearchEngines addObject:searchEngine];
}

- (void)removeSearchEngineWithName:(NSString *)name {
    if (!name) {
        return;
    }
    
    NSMutableArray *toRemove = [[NSMutableArray alloc] init];
    for (SearchEngine *engine in self.mutableSearchEngines) {
        if ([engine.name isEqualToString:name]) {
            [toRemove addObject:engine];
        }
    }
    
    [self.mutableSearchEngines removeObjectsInArray:toRemove];
    
    // If we removed the current search engine, switch to Google
    if ([self.currentSearchEngine.name isEqualToString:name]) {
        [self setCurrentSearchEngineByName:@"google"];
    }
}

- (BOOL)setCurrentSearchEngineByName:(NSString *)name {
    SearchEngine *engine = [self searchEngineWithName:name];
    if (engine) {
        self.currentSearchEngine = engine;
        return YES;
    }
    return NO;
}

- (NSURL *)searchURLForQuery:(NSString *)query {
    if (!query || !self.currentSearchEngine) {
        return nil;
    }
    
    return [self.currentSearchEngine searchURLForQuery:query];
}

- (NSURL *)suggestionURLForQuery:(NSString *)query {
    if (!query || !self.currentSearchEngine) {
        return nil;
    }
    
    return [self.currentSearchEngine suggestionURLForQuery:query];
}

- (SearchEngine *)searchEngineWithName:(NSString *)name {
    if (!name) {
        return nil;
    }
    
    for (SearchEngine *engine in self.mutableSearchEngines) {
        if ([engine.name isEqualToString:name]) {
            return engine;
        }
    }
    
    return nil;
}

#pragma mark - Convenience Methods

- (NSArray<NSString *> *)availableSearchEngineNames {
    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (SearchEngine *engine in self.mutableSearchEngines) {
        [names addObject:engine.name];
    }
    return [names copy];
}

- (NSArray<NSString *> *)availableSearchEngineDisplayNames {
    NSMutableArray *displayNames = [[NSMutableArray alloc] init];
    for (SearchEngine *engine in self.mutableSearchEngines) {
        [displayNames addObject:engine.displayName];
    }
    return [displayNames copy];
}

- (void)setCurrentSearchEngineByDisplayName:(NSString *)displayName {
    if (!displayName) {
        return;
    }
    
    for (SearchEngine *engine in self.mutableSearchEngines) {
        if ([engine.displayName isEqualToString:displayName]) {
            self.currentSearchEngine = engine;
            break;
        }
    }
}

@end

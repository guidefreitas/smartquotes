//
//  QuotesRemoteLoader.h
//  smartquote
//
//  Created by Guilherme on 1/27/14.
//  Copyright (c) 2014 guidefreitas. All rights reserved.
//

#import <Foundation/Foundation.h> 
#import "Quote.h"
#import "CoreDataHelper.h"

typedef void (^LoadQuoteRemoteResultBlock)(NSArray *objects, NSError *error);
typedef void (^LoadQuoteImageRemoteResultBlock)(UIImage *coverImage, NSError *error);

@interface QuotesRemoteLoader : NSObject

@property (strong, nonatomic) CoreDataHelper *coreDataHelper;

- (void) loadQuotesFromServer:(LoadQuoteRemoteResultBlock)block;
- (void) loadOldQuotesFromServer:(LoadQuoteRemoteResultBlock)block;
- (void) saveQuotesInDatabase:(NSArray *) quotes Error:(NSError **)error;
- (void) createQuote:(Quote **) quote fromParseObject:(PFObject *) parseObject;
- (BOOL) databaseIsEmpty;
- (void) updateQuotes:(LoadQuoteRemoteResultBlock)block;
- (void) deleteQuotes:(LoadQuoteRemoteResultBlock)block;
- (void) loadQuoteImageWithUUID:(NSString *) quoteUUID completition:(LoadQuoteImageRemoteResultBlock)block;
- (void) preloadWithLocalData;

@end

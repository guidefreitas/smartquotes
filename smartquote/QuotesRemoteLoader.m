//
//  QuotesRemoteLoader.m
//  smartquote
//
//  Created by Guilherme on 1/27/14.
//  Copyright (c) 2014 guidefreitas. All rights reserved.
//

#import "QuotesRemoteLoader.h"
#import "AppDelegate.h"

#define debug 0



@implementation QuotesRemoteLoader

- (id) init{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    
    self = [super init];
    if(!self) return nil;
    
    
    _coreDataHelper = [(AppDelegate *) [[UIApplication sharedApplication] delegate] cdh];
    return self;
}

- (void) loadQuotesFromServer:(LoadQuoteRemoteResultBlock)block{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }

    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Quote"];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObjects:sort, nil]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchedItems = [_coreDataHelper.context executeFetchRequest:request error:&error];
    if(error){
        dispatch_async(dispatch_get_main_queue(), ^{
            block(nil, error);
        });
        return;
    }

    PFQuery *query = [PFQuery queryWithClassName:@"quote"];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    query.limit = 3;
    [query orderByAscending:@"createdAt"];
    [query whereKey:@"deleted" equalTo:[NSNumber numberWithBool:NO]];
    if([fetchedItems count] > 0){
        Quote *quoteQuery = (Quote *) [fetchedItems objectAtIndex:0];
        [query whereKey:@"createdAt" greaterThan:quoteQuery.createdAt];
    }
    
    error = nil;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSLog(@"Successfully retrieved %d scores.", objects.count);
            
            NSMutableArray *quotes = [[NSMutableArray alloc] initWithCapacity:objects.count];
            
            for (PFObject *object in objects) {
                Quote *quote = [NSEntityDescription insertNewObjectForEntityForName:@"Quote" inManagedObjectContext:_coreDataHelper.context];
                [self createQuote:&quote fromParseObject:object];
                [quotes addObject:quote];
            }
            
            [_coreDataHelper backgroundSaveContext];
            NSArray *results = [[NSArray alloc] initWithArray:quotes];
            block(results, nil);
            //dispatch_async(dispatch_get_main_queue(), ^{
            
            return;
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            block(nil, error);
            return;
        }
    }];
}

- (void) loadOldQuotesFromServer:(LoadQuoteRemoteResultBlock)block{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Quote"];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObjects:sort, nil]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchedItems = [_coreDataHelper.context executeFetchRequest:request error:&error];
    if(error){
        dispatch_async(dispatch_get_main_queue(), ^{
            block(nil, error);
        });
        return;
    }

    PFQuery *query = [PFQuery queryWithClassName:@"quote"];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    query.limit = 3;
    [query orderByDescending:@"createdAt"];
    [query whereKey:@"deleted" equalTo:[NSNumber numberWithBool:NO]];
    if([fetchedItems count] > 0){
        Quote *quoteQuery = (Quote *) [fetchedItems objectAtIndex:0];
        [query whereKey:@"createdAt" lessThan:quoteQuery.createdAt];
    }
    
    error = nil;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {

            NSMutableArray *quotes = [[NSMutableArray alloc] initWithCapacity:objects.count];
            
            for (PFObject *object in objects) {
                Quote *quote = [NSEntityDescription insertNewObjectForEntityForName:@"Quote" inManagedObjectContext:_coreDataHelper.context];
                [self createQuote:&quote fromParseObject:object];
                [quotes addObject:quote];
            }
            
            [_coreDataHelper backgroundSaveContext];
            NSArray *results = [[NSArray alloc] initWithArray:quotes];
            block(results, nil);
            return;
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            block(nil, error);
            return;
        }
    }];
}

- (void) deleteQuotes:(LoadQuoteRemoteResultBlock)block{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"quote"];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    [query whereKey:@"deleted" equalTo:[NSNumber numberWithBool:YES]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error){
            NSLog(@"Error while trying to find deleted quotes: %@", error);
            block(nil, error);
            return;
        }
        
        if(objects.count == 0 ){
            NSLog(@"Nothing to delete.");
            block(objects, nil);
        }
        
        for (PFObject *parseObject in objects) {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Quote"];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"quoteUUID == %@", parseObject.objectId ];
            [request setPredicate:predicate];
            error = nil;
            NSArray *fetchedQuotesToDelete = [_coreDataHelper.context executeFetchRequest:request error:&error];
            
            if(fetchedQuotesToDelete.count == 0){
                NSLog(@"No local quotes to delete.");
                block(fetchedQuotesToDelete, nil);
                return;
            }
            NSMutableArray *deletedQuotes = [[NSMutableArray alloc] initWithCapacity:fetchedQuotesToDelete.count];
            for(Quote *quote in fetchedQuotesToDelete){
                [_coreDataHelper.context deleteObject:quote];
                [deletedQuotes addObject:quote];
            }
            
            block(deletedQuotes, nil);
            
            NSLog(@"%lu local quotes deleted", (unsigned long)fetchedQuotesToDelete.count);
        }
    }];
}

- (void) loadQuoteImageWithUUID:(NSString *) quoteUUID completition:(LoadQuoteImageRemoteResultBlock)block{
    Quote *quoteDB = [self getDBQuoteByUUID:quoteUUID];
    PFQuery *query = [PFQuery queryWithClassName:@"quote"];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    [query whereKey:@"objectId" equalTo:quoteDB.quoteUUID];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        PFObject *quotePS = [objects objectAtIndex:0];
        PFFile *coverImagePFFile = quotePS[@"coverImage"];
        [coverImagePFFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if(error){
                block(nil, error);
            }
            
            UIImage *image = [UIImage imageWithData:data];
            NSData *imageData = UIImagePNGRepresentation(image);
            [quoteDB setCoverImage:imageData];
            [_coreDataHelper backgroundSaveContext];
            block(image, nil);
        }];
    }];
}

- (void) updateQuotes:(LoadQuoteRemoteResultBlock)block{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Quote"];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"updatedAt" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObjects:sort, nil]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchedItems = [_coreDataHelper.context executeFetchRequest:request error:&error];
    if(error){
        NSLog(@"ERROR: %@", error);
        block(nil, error);
        return;
    }
    
    if(fetchedItems.count == 0){
        block(fetchedItems, nil);
        return;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"quote"];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    Quote *quoteQuery = (Quote *) [fetchedItems objectAtIndex:0];
    [query whereKey:@"updatedAt" greaterThan:quoteQuery.updatedAt];
    [query whereKey:@"deleted" equalTo:[NSNumber numberWithBool:NO]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error){
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            block(nil, error);
            return;
        }
        
        if(objects.count == 0){
            NSLog(@"No updated quotes in the remote server");
            block(objects, nil);
            return;
        }
        
        for (PFObject *parseObject in objects) {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Quote"];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"quoteUUID == %@", parseObject.objectId ];
            [request setPredicate:predicate];
            NSArray *fetchedQuotesToUpdate = [_coreDataHelper.context executeFetchRequest:request error:&error];
            if(fetchedQuotesToUpdate.count == 0){
                //Nothing to update
                return;
            }
            NSMutableArray *updatedQuotes = [[NSMutableArray alloc] initWithCapacity:fetchedQuotesToUpdate.count];
            
            
            for(Quote *quote in fetchedQuotesToUpdate){
                [quote setQuoteUUID:parseObject.objectId];
                [quote setCreatedAt:parseObject.createdAt];
                [quote setUpdatedAt:parseObject.updatedAt];
                [quote setQuote:parseObject[@"quote"]];
                [quote setAuthor:parseObject[@"author"]];
                NSNumber *quoteNumber = [NSNumber numberWithInt:[parseObject[@"quoteNumber"] intValue]];
                [quote setQuoteNumber:quoteNumber];
                [quote setCompany:parseObject[@"company"]];
                [quote setBackgroundColor:parseObject[@"backgroundColor"]];
                PFFile *coverImagePFFile = parseObject[@"coverImage"];
                NSString *quoteUUID = parseObject.objectId;
                
                [coverImagePFFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                    UIImage *image = [UIImage imageWithData:data];
                    NSData *imageData = UIImagePNGRepresentation(image);
                    Quote *quote = [self getDBQuoteByUUID:quoteUUID];
                    [quote setCoverImage:imageData];
                    [_coreDataHelper backgroundSaveContext];
                    
                }];
                
                [updatedQuotes addObject:quote];
            }
            
            block(updatedQuotes, nil);
        }
        
    }];
    
}

- (void) saveQuotesInDatabase:(NSArray *) quotes Error:(NSError **)error{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
}

- (void) createQuote:(Quote **) quote fromParseObject:(PFObject *) parseObject{

    //Quote *quote = [NSEntityDescription insertNewObjectForEntityForName:@"Quote" inManagedObjectContext:_coreDataHelper.context];
    [*quote setQuoteUUID:parseObject.objectId];
    [*quote setCreatedAt:parseObject.createdAt];
    [*quote setUpdatedAt:parseObject.updatedAt];
    [*quote setQuote:parseObject[@"quote"]];
    [*quote setAuthor:parseObject[@"author"]];
    NSNumber *quoteNumber = [NSNumber numberWithInt:[parseObject[@"quoteNumber"] intValue]];
    [*quote setQuoteNumber:quoteNumber];
    [*quote setCompany:parseObject[@"company"]];
    [*quote setBackgroundColor:parseObject[@"backgroundColor"]];
    PFFile *coverImagePFFile = parseObject[@"coverImage"];
    NSString *quoteUUID = parseObject.objectId;
    
    [coverImagePFFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        NSLog(@"Quote UUID: %@",quoteUUID);
        UIImage *image = [UIImage imageWithData:data];
        NSData *imageData = UIImagePNGRepresentation(image);
        
        Quote *quote = [self getDBQuoteByUUID:quoteUUID];
        [quote setCoverImage:imageData];
        [_coreDataHelper backgroundSaveContext];
    }];
   
    
}

- (Quote *) getDBQuoteByUUID:(NSString *)uuid{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Quote"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"quoteUUID == %@", uuid ];
    [request setPredicate:predicate];
    NSError *error;
    NSArray *fetchedQuotes = [_coreDataHelper.context executeFetchRequest:request error:&error];
    if(error){
        NSLog(@"Error white trying to retrieve quote record");
        return nil;
    }
    if(fetchedQuotes.count == 1){
        return [fetchedQuotes objectAtIndex:0];
    }
    
    return nil;
}

- (BOOL) databaseIsEmpty{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Quote"];
    NSError *error = nil;
    NSUInteger count = [_coreDataHelper.context countForFetchRequest:request error:&error];
    NSLog(@"Count: %i", count);
    if(count == NSNotFound || count == 0) {
        return YES;
    }
    
    return NO;
}

- (void) preloadWithLocalData{
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pre_data" ofType:@"plist"]];
    NSArray *quotes = [dictionary objectForKey:@"quotes"];
    for(NSDictionary *quoteDic in quotes){
        Quote *quote = [NSEntityDescription insertNewObjectForEntityForName:@"Quote" inManagedObjectContext:_coreDataHelper.context];
        quote.quoteUUID = [quoteDic objectForKey:@"quoteUUID"];
        quote.quoteNumber = [quoteDic objectForKey:@"quoteNumber"];
        quote.backgroundColor = [quoteDic objectForKey:@"backgroundColor"];
        quote.author = [quoteDic objectForKey:@"author"];
        quote.company = [quoteDic objectForKey:@"company"];
        quote.createdAt = [quoteDic objectForKey:@"createdAt"];
        quote.updatedAt = [quoteDic objectForKey:@"updatedAt"];
        quote.quote = [quoteDic objectForKey:@"quote"];
        UIImage *coverImage = [UIImage imageNamed:[quoteDic objectForKey:@"coverImageName"]];
        quote.coverImage =  UIImageJPEGRepresentation(coverImage, 1.0);
    }
    
    [_coreDataHelper backgroundSaveContext];
}

@end

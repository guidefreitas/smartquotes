//
//  AppDelegate.m
//  smartquote
//
//  Created by Guilherme on 1/21/14.
//  Copyright (c) 2014 guidefreitas. All rights reserved.
//

#import "AppDelegate.h"
#import "Quote.h"

#define debug 0

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [Parse setApplicationId:@"YOUR_PARSE_APPLICATION_ID"
                  clientKey:@"YOUR_PARSE_CLIENT_KEY"];
    
    //[PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [self cdh];
    //[self demo];
    return YES;
}

- (void)demo {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Quote"];
    NSError *error = nil;
    NSUInteger count = [_coreDataHelper.context countForFetchRequest:request error:&error];
    NSLog(@"Count: %i", count);
    if(count == NSNotFound || count == 0) {
        Quote *quote = [NSEntityDescription insertNewObjectForEntityForName:@"Quote" inManagedObjectContext:_coreDataHelper.context];
        quote.quote = @"Always choose your investors based on who you want to work with, be friends with, and get advice from. Never, ever, choose your investors based on valuation.";
        quote.author = @"Jason Goldberg";
        quote.quoteNumber = [[NSNumber alloc]initWithInt:1];
        quote.company = @"FAB";
        quote.backgroundColor = @"D71417";
        UIImage *image = [UIImage imageNamed:@"ive"];
        NSData *imageData = UIImagePNGRepresentation(image);
        quote.coverImage = imageData;
        
        
        Quote *quote2 = [NSEntityDescription insertNewObjectForEntityForName:@"Quote" inManagedObjectContext:_coreDataHelper.context];
        quote2.quote = @"I knew that if I failed I wouldn’t regret that, but I knew the one thing I might regret is not trying.";
        quote2.author = @"Jeff Bezos";
        quote2.quoteNumber = [[NSNumber alloc]initWithInt:2];
        quote2.company = @"Amazon";
        quote2.backgroundColor = @"FF9A01";
        UIImage *image2 = [UIImage imageNamed:@"ive"];
        NSData *imageData2 = UIImagePNGRepresentation(image2);
        quote2.coverImage = imageData2;
        
        Quote *quote3 = [NSEntityDescription insertNewObjectForEntityForName:@"Quote" inManagedObjectContext:_coreDataHelper.context];
        quote3.quote = @"It’s very easy to be different, but very difficult to be better.";
        quote3.author = @"Jonathan Ive";
        quote3.quoteNumber = [[NSNumber alloc]initWithInt:3];
        quote3.company = @"Apple";
        quote3.backgroundColor = @"9D9D9D";
        UIImage *image3 = [UIImage imageNamed:@"ive"];
        NSData *imageData3 = UIImagePNGRepresentation(image3);
        quote3.coverImage = imageData3;
        
        Quote *quote4 = [NSEntityDescription insertNewObjectForEntityForName:@"Quote" inManagedObjectContext:_coreDataHelper.context];
        quote4.quote = @"As a startup CEO, I slept like a baby. I woke up every 2 hours and cried.";
        quote4.author = @"Ben Horowitz";
        quote4.quoteNumber = [[NSNumber alloc]initWithInt:4];
        quote4.company = @"Horowitz";
        quote4.backgroundColor = @"406171";
        UIImage *image4 = [UIImage imageNamed:@"ive"];
        NSData *imageData4 = UIImagePNGRepresentation(image4);
        quote4.coverImage = imageData4;
        
        Quote *quote5 = [NSEntityDescription insertNewObjectForEntityForName:@"Quote" inManagedObjectContext:_coreDataHelper.context];
        quote5.quote = @"Don’t worry about failure, you only have to be right once.";
        quote5.author = @"Drew Houston";
        quote5.quoteNumber = [[NSNumber alloc]initWithInt:5];
        quote5.company = @"Dropbox";
        quote5.backgroundColor = @"1F76CD";
        UIImage *image5 = [UIImage imageNamed:@"ive"];
        NSData *imageData5 = UIImagePNGRepresentation(image5);
        quote5.coverImage = imageData5;
        
        [[self cdh] saveContext];
    }
}

- (CoreDataHelper*)cdh {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd)); }
    if (!_coreDataHelper) {
        static dispatch_once_t predicate;
        dispatch_once(&predicate, ^{
            _coreDataHelper = [CoreDataHelper new];
        });
        [_coreDataHelper setupCoreData];
    }
    return _coreDataHelper;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[self cdh] saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self cdh];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[self cdh] saveContext];
}

@end

//
//  CoreDataHelper.h
//  smartquote
//
//  Created by Guilherme on 1/22/14.
//  Copyright (c) 2014 guidefreitas. All rights reserved.
//

#import <Foundation/Foundation.h> 
#import <CoreData/CoreData.h>

@interface CoreDataHelper : NSObject <NSXMLParserDelegate>

@property (nonatomic, readonly) NSManagedObjectContext          *context;
@property (nonatomic, readonly) NSManagedObjectContext          *parentContext;
@property (nonatomic, readonly) NSManagedObjectContext          *importContext;
@property (nonatomic, readonly) NSManagedObjectModel            *model;
@property (nonatomic, readonly) NSPersistentStoreCoordinator    *coordinator;
@property (nonatomic, readonly) NSPersistentStore               *store;
@property (nonatomic) NSXMLParser                               *parser;
- (void) setupCoreData;
- (void) saveContext;
- (void) backgroundSaveContext;

@end

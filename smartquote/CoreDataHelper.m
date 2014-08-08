//
//  CoreDataHelper.m
//  smartquote
//
//  Created by Guilherme on 1/22/14.
//  Copyright (c) 2014 guidefreitas. All rights reserved.
//

#import "CoreDataHelper.h"

@implementation CoreDataHelper

#define debug 0

#pragma mark - FILES
NSString *storeFileName = @"smartquotes.sqlite";

#pragma mark - PATHS
- (NSString *) applicationDocumentsDirectory{
    if(debug == 1){
        NSLog(@"Running %@ '%@'", self.class,NSStringFromSelector(_cmd));
    }
    
    return [NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) lastObject];
    
}

- (NSURL *) applicationStoresDirectory{
    
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    NSURL *storesDirectory = [[NSURL fileURLWithPath:[self applicationDocumentsDirectory]]
                              URLByAppendingPathComponent:@"Stores"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if(![fileManager fileExistsAtPath:[storesDirectory path]]){
        NSError *error = nil;
        if([fileManager createDirectoryAtURL:storesDirectory
                        withIntermediateDirectories:YES
                        attributes:nil
                        error:&error]){
            if(debug==1){
                NSLog(@"Successfully created Stores directory");
            }else{
                NSLog(@"FAILED to create Stores directory: %@", error);
            }
        }
    }
    return storesDirectory;
}

- (NSURL *) storeURL{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    return [[self applicationStoresDirectory] URLByAppendingPathComponent:storeFileName];
}

#pragma mark - SETUP
- (id) init{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    self = [super init];
    if(!self){ return nil; }
    _model = [NSManagedObjectModel mergedModelFromBundles:nil];
    _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
    
    _parentContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_parentContext performBlockAndWait:^{
        [_parentContext setPersistentStoreCoordinator:_coordinator];
        [_parentContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    }];
    
    _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_context setParentContext:_parentContext];
    
    _importContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_importContext setParentContext:_context];
    [_importContext performBlockAndWait:^{
        [_importContext setUndoManager:nil];
    }];
    return self;
}


- (void) backgroundSaveContext {
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    [self saveContext];
    
    [_parentContext performBlock:^{
        if([_parentContext hasChanges]){
            NSError *error = nil;
            if([_parentContext save:&error]){
                NSLog(@"_parentContext SAVED changes to persistent store");
            }else{
                NSLog(@"_parentContext FAILED to save: %@", error);
            }
        } else {
            NSLog(@"_parentContext SKIPPED saving as there are no changes");
        }
    }];
    
}

- (void) loadStore{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    if(_store){ return; }
    
    BOOL useMigrationManager = YES;
    if(useMigrationManager && [self isMigrationNecessaryForStore:[self storeURL]]){
        [self performBackgroundManagedMigrationForStore:[self storeURL]];
    }else{
    
        NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption:@YES
                               ,NSInferMappingModelAutomaticallyOption:@YES
                               ,NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"}
                                   };
    
        NSError *error = nil;
        _store = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                           URL:[self storeURL]
                           options:options
                           error:&error];
    
        if(!_store){
            NSLog(@"Failed to add store. Error: %@", error);abort();
        } else {
            if(debug==1){
                NSLog(@"Successfully added store: %@", _store);
            }
        }
    }
}

- (void) setupCoreData{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    [self loadStore];
}

#pragma mark - SAVING
- (void) saveContext{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    if([_context hasChanges]){
        NSError *error = nil;
        if([_context save:&error]){
            NSLog(@"_context SAVED changes to persistent store");
        } else {
            NSLog(@"Failed to save _context: %@", error);
        }
    } else {
        NSLog(@"SKIPPED _context save, there are no changes!");
    }
}

#pragma mark - MIGRATION MANAGER
- (BOOL)isMigrationNecessaryForStore:(NSURL*)storeUrl {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self storeURL].path]) {
        if (debug==1) {
            NSLog(@"SKIPPED MIGRATION: Source database missing.");
        }
        
        return NO;
    }
    
    NSError *error = nil;
    NSDictionary *sourceMetadata =
    [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                               URL:storeUrl error:&error];
    
    NSManagedObjectModel *destinationModel = _coordinator.managedObjectModel;
    if ([destinationModel isConfiguration:nil                                                                                        compatibleWithStoreMetadata:sourceMetadata]) {
        if (debug==1) {
            NSLog(@"SKIPPED MIGRATION: Source is already compatible");
        }
        return NO;
    }
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"migrationProgress"]){
        dispatch_async(dispatch_get_main_queue(), ^{
            float progress = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
            //Update screen
        });
    }
    
}

- (BOOL) replaceStore:(NSURL *) old withStore: (NSURL *) new{
    BOOL success = NO;
    NSError *error = nil;
    if([[NSFileManager defaultManager] removeItemAtURL:old error:&error]){
        error = nil;
        if([[NSFileManager defaultManager] moveItemAtURL:new toURL:old error:&error]){
            success = YES;
        } else {
            if (debug==1){
                NSLog(@"FAILED to re-home new store %@", error);
            }
        }
    } else {
        if (debug==1){
            NSLog(@"FAILED to remove old store %@: Error:%@", old, error);
        }
    }
    
    return success;
}

- (BOOL)migrateStore:(NSURL*)sourceStore {
    if (debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    BOOL success = NO;
    NSError *error = nil;
    
    // STEP 1 - Gather the Source, Destination and Mapping Model
    
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:sourceStore error:&error];
  
    NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:nil forStoreMetadata:sourceMetadata];
    
    NSManagedObjectModel *destinModel = _model;
    
    NSMappingModel *mappingModel = [NSMappingModel mappingModelFromBundles:nil forSourceModel:sourceModel destinationModel:destinModel];
    // STEP 2 - Perform migration, assuming the mapping model isn't null
    if (mappingModel) {
        NSError *error = nil;
        
        NSMigrationManager *migrationManager  = [[NSMigrationManager alloc] initWithSourceModel:sourceModel destinationModel:destinModel];
        
        [migrationManager addObserver:self forKeyPath:@"migrationProgress" options:NSKeyValueObservingOptionNew context:NULL];
        
        NSURL *destinStore = [[self applicationStoresDirectory] URLByAppendingPathComponent:@"Temp.sqlite"];
        
        success = [migrationManager migrateStoreFromURL:sourceStore
                                                   type:NSSQLiteStoreType
                                                options:nil
                                       withMappingModel:mappingModel
                                       toDestinationURL:destinStore
                                        destinationType:NSSQLiteStoreType
                                     destinationOptions:nil
                                                  error:&error];
        
        if(success){
            // STEP 3 - Replace the old store with the new migrated store
            if([self replaceStore:sourceStore withStore:destinStore]){
                if(debug==1){
                    NSLog(@"SUCCESSFULLY MIGRATED %@ to the Current Model", sourceStore.path);
                }
                
                [migrationManager removeObserver:self forKeyPath:@"migrationProgress"];
            }
        } else {
            if(debug==1){
                NSLog(@"FAILED MIGRATION: %@",error);
            }
        }
        
    } else {
        if (debug==1) {
            NSLog(@"FAILED MIGRATION: Mapping Model is null");
        }
    }
    
    return YES;
}

- (void)performBackgroundManagedMigrationForStore:(NSURL*)storeURL {
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    //UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    //UIViewController *migrateVC = [sb instantiateViewControllerWithIdentifier:@"migration"];
    //UIApplication *sa = [UIApplication sharedApplication];
    //UINavigationController *nc = (UINavigationController *) sa.keyWindow.rootViewController;
    //[nc  presentViewController:migrateVC animated:NO completition:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        BOOL done = [self migrateStore:storeURL];
        if(done){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = nil;
                _store = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                    configuration:nil
                                                              URL:[self storeURL]
                                                          options:nil
                                                            error:&error];
                if(!_store){
                    NSLog(@"Failed to add a migrated store. Error: %@", error);
                    abort();
                } else {
                    NSLog(@"Successfully added a migrated store: %@", _store);
                }
                
                //[migrateVC dismissViewControllerAnimated:NO, completition:nil];
                //migrateVC = nil;
            });
        }
    });
}


#pragma mark - DATA IMPORT

- (void) importFromXML: (NSURL *)url{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    self.parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    self.parser.delegate = self;
    NSLog(@"**** START PARSE OF %@", url.path);
    [self.parser parse];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:nil];
    NSLog(@"***** END PARSE OF %@", url.path);
    
}

- (void) importDefaultData{
    [_importContext performBlock:^{
        [self importFromXML:[[NSBundle mainBundle] URLForResource:@"DefaultData" withExtension:@"xml"]];
    }];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }

}

- (void)parserDidEndDocument:(NSXMLParser *)parser{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    
}

@end

//
//  CoreDataTVC.m
//  smartquote
//
//  Created by Guilherme on 1/22/14.
//  Copyright (c) 2014 guidefreitas. All rights reserved.
//

#import "CoreDataTVC.h"

@implementation CoreDataTVC

#define debug 0

#pragma mark - FETCHING
- (void) performFetch{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    if(self.frc){
        [self.frc.managedObjectContext performBlockAndWait:^{
            NSError *error = nil;
            if(![self.frc performFetch:&error]){
                NSLog(@"Failed to perform fetch: %@", error);
            }else{
                [self.tableView reloadData];
            }
        }];
    } else {
        NSLog(@"Failed to fetch, the fetched results controller is nil.");
    }
}

#pragma mark - DATASOURCE: UITableView
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    return [[[self.frc sections] objectAtIndex:section] numberOfObjects];
}

- (NSInteger) tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    return [self.frc sectionForSectionIndexTitle:title atIndex:index];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    return [[[self.frc sections] objectAtIndex:section] name];
}

-(NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    return [self.frc sectionIndexTitles];
}

#pragma mark - NSFetchedResultsController

- (void) controllerWillChangeContent:(NSFetchedResultsController *)controller{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    [self.tableView beginUpdates];
}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    [self.tableView endUpdates];
}

- (void) controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        
        case NSFetchedResultsChangeDelete:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void) controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath{
    if(debug==1){
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    UITableView *tableView = self.tableView;
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
            if(!newIndexPath){
                [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            } else {
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}


@end

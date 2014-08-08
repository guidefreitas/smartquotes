//
//  CoreDataTVC.h
//  smartquote
//
//  Created by Guilherme on 1/22/14.
//  Copyright (c) 2014 guidefreitas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataHelper.h"

@interface CoreDataTVC : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *frc;

- (void) performFetch;

@end

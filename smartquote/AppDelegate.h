//
//  AppDelegate.h
//  smartquote
//
//  Created by Guilherme on 1/21/14.
//  Copyright (c) 2014 guidefreitas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataHelper.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong, readonly) CoreDataHelper *coreDataHelper;

- (CoreDataHelper*)cdh;

@end

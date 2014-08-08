//
//  QuotesTableViewController.h
//  smartquote
//
//  Created by Guilherme on 1/21/14.
//  Copyright (c) 2014 guidefreitas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTVC.h"
#import "QuotesRemoteLoader.h"
#import <SpinKit/RTSpinKitView.h>

@interface QuotesTableViewController : CoreDataTVC{
    UIView *loadingView;
    UIView *fullscreenMessageView;
    UIView *messageView;
    BOOL loadingRemoteData;
    BOOL tableViewFinishLoading;
}

@property (nonatomic, readonly) QuotesRemoteLoader *quotesRemoteLoader;
@property (nonatomic, readonly) CoreDataHelper *cdh;

@end

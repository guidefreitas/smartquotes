//
//  QuotesTableViewController.m
//  smartquote
//
//  Created by Guilherme on 1/21/14.
//  Copyright (c) 2014 guidefreitas. All rights reserved.
//

#import "QuotesTableViewController.h"
#import <MPColorTools.h>
#import "AppDelegate.h"
#import "Quote.h"
#import "Reachability.h"

#define debug 0

#define AUTHOR_IMAGE_TAG 6
#define QUOTE_BACKGROUND_TAG 1
#define QUOTE_FIELD_TAG 2
#define AUTHOR_NAME_TAG 3
#define QUOTE_NUMBER_TAG 8

@interface QuotesTableViewController (){
    CGFloat screen_height;
}
- (void) setUITextViewFieldsShadow:(UITextView *)field;
- (void) setUILabelFieldsShadow:(UILabel *)field;
@end


@implementation QuotesTableViewController

- (void) viewDidLoad{
    if(debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    screen_height = screenRect.size.height + 2.0f;
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
    _cdh = [(AppDelegate *) [[UIApplication sharedApplication] delegate] cdh];
    [self configureFetch];
    [self performFetch];
   
    
    _quotesRemoteLoader = [[QuotesRemoteLoader alloc] init];
    loadingRemoteData = NO;
    
    
    if([_quotesRemoteLoader databaseIsEmpty] && !loadingRemoteData){
        if([self isConnection]){
            [self updateWithRemoteData];
        }else{
            [_quotesRemoteLoader preloadWithLocalData];
        }
    }else{
        if([self isConnection]){
            [_quotesRemoteLoader updateQuotes:^(NSArray *objects, NSError *error) {
                if(error){
                    [self showNotification:@"Ops. Error while updating quotes."];
                }
            }];
            
            [_quotesRemoteLoader deleteQuotes:^(NSArray *objects, NSError *error) {
                if(error){
                    [self showNotification:@"Ops. Error while deleting old quotes."];
                }
                
            }];
        }
    }
    tableViewFinishLoading = YES;
    [super viewDidLoad];
}

- (void) viewDidAppear:(BOOL)animated{
    if([_quotesRemoteLoader databaseIsEmpty] && loadingRemoteData){
        [self showLoadindViewFullScreen];
    }
}

#pragma mark - DATA

- (void) configureFetch{
    if(debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Quote"];
    request.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"quoteNumber" ascending:NO], nil];
    [request setFetchBatchSize:20];
    self.frc = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:_cdh.context sectionNameKeyPath:nil cacheName:nil];
    [request setFetchBatchSize:1];
    self.frc.delegate = self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"quoteIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];
    
    //NSUInteger sectionIndex = [indexPath section];
    //NSUInteger rowIndex = [indexPath row];
    
    UIImageView *authorImageView = (UIImageView *)[cell viewWithTag:AUTHOR_IMAGE_TAG];
    UIView *backgroundView = (UIView *) [cell viewWithTag:QUOTE_BACKGROUND_TAG];
    UITextView *quoteTextView = (UITextView *) [cell viewWithTag:QUOTE_FIELD_TAG];
    UILabel *authorNameLabel = (UILabel *) [cell viewWithTag:AUTHOR_NAME_TAG];
    UILabel *quoteNumberLabel = (UILabel *) [cell viewWithTag:QUOTE_NUMBER_TAG];
    
    authorImageView.image = nil;
    [authorImageView setAlpha:0.0f];
    quoteTextView.text = nil;
    authorNameLabel.text = nil;
    quoteNumberLabel.text = nil;
    [backgroundView setBackgroundColor:[UIColor grayColor]];
    
    [self setUITextViewFieldsShadow:quoteTextView];
    [self setUILabelFieldsShadow:authorNameLabel];

    Quote *quote = [self.frc objectAtIndexPath:indexPath];
    
    if(!quote){
        NSLog(@"No quote for index");
        return cell;
    }
    
    UIColor *backgroundColor = MP_HEX_RGB(quote.backgroundColor);
    [UIView animateWithDuration:0.3 animations:^{
        [backgroundView setBackgroundColor:backgroundColor];
    }];
    

    if(quote.coverImage){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            UIImage *authorImage = [UIImage imageWithData:quote.coverImage];
            if(authorImage){
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    authorImageView.image = authorImage;
                    [UIView animateWithDuration:0.2 animations:^{
                        [authorImageView setAlpha:1.0f];
                    }];
                    
                });
            }
        });
    }else{
        if([self isConnection]){
            NSLog(@"Loading missing image");
            [_quotesRemoteLoader loadQuoteImageWithUUID:quote.quoteUUID completition:^(UIImage *coverImage, NSError *error) {
                NSLog(@"Missing image loaded");
                authorImageView.image = coverImage;
                [UIView animateWithDuration:0.2 animations:^{
                    [authorImageView setAlpha:1.0f];
                }];
            }];
        }
    }
    
    if(quote.quote.length >= 100 && quote.quote.length < 150){
        UIFont *font = [UIFont fontWithName:quoteTextView.font.fontName size:22];
        [quoteTextView setFont:font];
    } else if (quote.quote.length >= 150 && quote.quote.length < 200){
        UIFont *font = [UIFont fontWithName:quoteTextView.font.fontName size:18];
        [quoteTextView setFont:font];
    } else if (quote.quote.length >= 200){
        UIFont *font = [UIFont fontWithName:quoteTextView.font.fontName size:16];
        [quoteTextView setFont:font];
    }
    quoteTextView.text = [NSString stringWithFormat:@"\"%@\"",  quote.quote];
    if(!quote.author && quote.company){
        authorNameLabel.text = [NSString stringWithFormat:@"%@", quote.company];
    } else if(!quote.company && quote.author){
        authorNameLabel.text = [NSString stringWithFormat:@"%@", quote.author];
    }else if(quote.author && quote.company){
        authorNameLabel.text = [NSString stringWithFormat:@"%@, %@", quote.author, quote.company];
    } else {
        authorNameLabel.text = @"";
    }
    
    quoteNumberLabel.text = [NSString stringWithFormat:@"#%@", quote.quoteNumber];
    
    
    return cell;
}

- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView{
    if(debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    return nil;
}

- (void) setUITextViewFieldsShadow:(UITextView *)field{
    if(debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    field.textColor = [UIColor whiteColor];
    field.backgroundColor = [UIColor clearColor];
    field.layer.shadowColor = [[UIColor blackColor] CGColor];
    field.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    field.layer.masksToBounds = NO;
    field.layer.shadowRadius = 0.0;
    field.layer.shadowOpacity = 0.6;
}

- (void) setUILabelFieldsShadow:(UILabel *)field{
    if(debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    field.textColor = [UIColor whiteColor];
    field.backgroundColor = [UIColor clearColor];
    field.layer.shadowColor = [[UIColor blackColor] CGColor];
    field.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    field.layer.masksToBounds = NO;
    field.layer.shadowRadius = 0.0;
    field.layer.shadowOpacity = 0.6;
}

- (void) moveToTopCell{
    
    CGFloat cellIndex = self.tableView.contentOffset.y / screen_height;
    NSNumber *cellIndexInt = [NSNumber numberWithFloat:cellIndex];
    NSNumber *cellOffset = [NSNumber numberWithFloat:([cellIndexInt intValue] - [cellIndexInt floatValue])];
    NSArray *indexPathsForVisibleRows = [self.tableView indexPathsForVisibleRows];
    
    NSIndexPath *selectedIndexPath = nil;
    
    NSNumber *offsetThreshold = [NSNumber numberWithFloat:-0.55f];
    if([cellOffset floatValue] >= [offsetThreshold floatValue]){
        int objIndex = (indexPathsForVisibleRows.count / 2) - 1;
        if(indexPathsForVisibleRows.count > objIndex){
            selectedIndexPath = [indexPathsForVisibleRows objectAtIndex:objIndex];
        }
    }else{
        int objIndex = indexPathsForVisibleRows.count / 2;
        if(indexPathsForVisibleRows.count > objIndex){
            selectedIndexPath = [indexPathsForVisibleRows objectAtIndex:objIndex];
        }
    }
    
    [self.tableView scrollToRowAtIndexPath:selectedIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];

    
}

- (void) scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    
    if(debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    NSInteger currentOffset = scrollView.contentOffset.y;
    NSInteger maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
    if (currentOffset > 0 && currentOffset < maximumOffset){
        [self moveToTopCell];
    }
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    if(debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    NSInteger currentOffset = scrollView.contentOffset.y;
    NSInteger maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
    if (currentOffset > 0 && currentOffset < maximumOffset){
        [self moveToTopCell];
    }
    
}

- (void) showLoadindView{
    if(debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    loadingView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    [loadingView setBackgroundColor:[UIColor whiteColor]];
    [loadingView setAlpha:0.0];
    UIView *spinnerHolder = [[UIView alloc] initWithFrame:CGRectMake(144, 14, 100, 50)];
    RTSpinKitView *spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleWave color:[UIColor colorWithRed:0.12 green:0.46 blue:0.8 alpha:1]];
    [spinnerHolder addSubview:spinner];
    [loadingView addSubview:spinnerHolder];
    [[[self view] window] addSubview:loadingView];
    [UIView animateWithDuration:1.0 animations:^{
        [loadingView setAlpha:1.0];
    }];
}

- (BOOL) isConnection{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus != NotReachable) {
        return YES;
    }
    return NO;
}

- (void) showFullscreenMessage:(NSString *)msg{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    fullscreenMessageView = [[UIView alloc]initWithFrame:screenRect];
    [fullscreenMessageView setBackgroundColor:[UIColor colorWithRed:0.12 green:0.46 blue:0.8 alpha:1]];
    [fullscreenMessageView setAlpha:1.0];
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 10, screenWidth, screenHeight)];
    messageLabel.text = msg;
    messageLabel.textColor = [UIColor whiteColor];
    [fullscreenMessageView addSubview:messageLabel];
    [[[self view] window] addSubview:fullscreenMessageView];
}

- (void) showLoadindViewFullScreen{
    if(debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    if(loadingView){
        return;
    }
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    loadingView = [[UIView alloc]initWithFrame:screenRect];
    [loadingView setBackgroundColor:[UIColor colorWithRed:0.12 green:0.46 blue:0.8 alpha:1]];
    [loadingView setAlpha:1.0];
    UIView *spinnerHolder = [[UIView alloc] initWithFrame:CGRectMake(144, 200, screenWidth, screenHeight)];
    RTSpinKitView *spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleWave color:[UIColor whiteColor]];
    [spinnerHolder addSubview:spinner];
    [loadingView addSubview:spinnerHolder];
    [[[self view] window] addSubview:loadingView];
}

- (void) hideLoadingView{
    if(debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    [UIView animateWithDuration:1.0 animations:^{
        [loadingView setAlpha:0.0];
    }completion:^(BOOL finished){
        [loadingView removeFromSuperview];
        loadingView = nil;
    }];
    
}

- (void) showNotification:(NSString *) message{
    
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    hud.mode = MBProgressHUDModeText;
//    hud.labelText = message;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
//    [hud show:YES];
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        [MBProgressHUD hideHUDForView:self.view animated:YES];
//    });
    
    if(debug==1) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    
    if(messageView){
        return;
    }
    
    messageView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    [messageView setBackgroundColor:[UIColor whiteColor]];
    [messageView setAlpha:0.0];
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 320, 50)];
    messageLabel.text = message;
    [messageLabel setTextColor:[UIColor colorWithRed:0.12 green:0.46 blue:0.8 alpha:1]];
    [messageView addSubview:messageLabel];
    [[[self view] window] addSubview:messageView];
    [UIView animateWithDuration:1.0 animations:^{
        [messageView setAlpha:1.0];
    }];
    
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(hideNotification) userInfo:nil repeats:NO];
}

- (void) hideNotification{
    [UIView animateWithDuration:1.0 animations:^{
        [messageView setAlpha:0.0];
    }completion:^(BOOL finished){
        [messageView removeFromSuperview];
        messageView = nil;
    }];
}

- (void) updateWithRemoteData{
    
    if(![self isConnection]){
        return;
    }
    
    if(!loadingRemoteData){
        loadingRemoteData = YES;
        if(![_quotesRemoteLoader databaseIsEmpty]){
            [self showLoadindView];
        }
        
        [_quotesRemoteLoader loadQuotesFromServer:^(NSArray *objects, NSError *error){
            [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(setLoadingOff) userInfo:nil repeats:NO];
            if(!error){
                NSLog(@"Nenhum problema");
                if([objects count] == 0){
                    [self showNotification:@"No new quotes."];
                }
            }else{
                NSLog(@"Error: %@", error);
                [self showNotification:@"Ops. An error ocurred. Please try again later."];
            }
            
            [self hideLoadingView];
        }];
    }
}

- (void) setLoadingOff{
    loadingRemoteData = NO;
}

- (void)scrollViewDidScroll: (UIScrollView *)scroll {
    
    NSInteger currentOffset = scroll.contentOffset.y;
    NSInteger maximumOffset = scroll.contentSize.height - scroll.frame.size.height;
    
    if (currentOffset <= -100.0f){
        if([self isConnection]){
            [self updateWithRemoteData];
        }else{
            [self showNotification:@"No internet connection."];
        }
        
    }
    
    if(maximumOffset > 0 && currentOffset >= maximumOffset + 30.0f){
        
        //because scrollViewDidScroll is called before viewDidLoad
        //maximumOffset
        if(!tableViewFinishLoading){
            NSLog(@"Called before viewDidLoad");
            return;
        }
        
        if(![self isConnection]){
            [self showNotification:@"No internet connection."];
            return;
        }
        
        
        if(!loadingRemoteData){
            NSLog(@"Loading old entries");
            loadingRemoteData = YES;
            [self showLoadindView];
            [_quotesRemoteLoader loadOldQuotesFromServer:^(NSArray *objects, NSError *error) {
                [self hideLoadingView];
                [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(setLoadingOff) userInfo:nil repeats:NO];
                
                if(error){
                    NSLog(@"Error while loading old entries: %@", error);
                    [self showNotification:@"Ops. Error while loading old entries."];
                    return;
                }
            
                if(objects.count == 0){
                    NSLog(@"No more itens to load");
                    [self showNotification:@"No more quotes to load"];
                    return;
                }
                
                NSString *numQuotesLoaded = [NSString stringWithFormat:@"%lu new itens loaded", (unsigned long)objects.count];
                [self showNotification:numQuotesLoaded];
            }];
        }
        
    }

}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 0.0f;
    return 32.0f;
}

- (NSString*) tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    }
    
    return [super tableView:tableView titleForHeaderInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return screen_height;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


@end

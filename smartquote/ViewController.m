//
//  ViewController.m
//  smartquote
//
//  Created by Guilherme on 1/21/14.
//  Copyright (c) 2014 guidefreitas. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
- (void) setFieldsShadow;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setFieldsShadow];
}

- (void) setFieldsShadow{
    _quote.textColor = [UIColor whiteColor];
    _quote.backgroundColor = [UIColor clearColor];
    _quote.layer.shadowColor = [[UIColor blackColor] CGColor];
    _quote.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    _quote.layer.masksToBounds = NO;
    _quote.layer.shadowRadius = 0.0;
    _quote.layer.shadowOpacity = 0.6;
    
    _author.textColor = [UIColor whiteColor];
    _author.backgroundColor = [UIColor clearColor];
    _author.layer.shadowColor = [[UIColor blackColor] CGColor];
    _author.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    _author.layer.masksToBounds = NO;
    _author.layer.shadowRadius = 0.0;
    _author.layer.shadowOpacity = 0.6;
    
    _company.textColor = [UIColor whiteColor];
    _company.backgroundColor = [UIColor clearColor];
    _company.layer.shadowColor = [[UIColor blackColor] CGColor];
    _company.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    _company.layer.masksToBounds = NO;
    _company.layer.shadowRadius = 0.0;
    _company.layer.shadowOpacity = 0.6;
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

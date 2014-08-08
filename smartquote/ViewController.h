//
//  ViewController.h
//  smartquote
//
//  Created by Guilherme on 1/21/14.
//  Copyright (c) 2014 guidefreitas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *quote;
@property (weak, nonatomic) IBOutlet UILabel *author;
@property (weak, nonatomic) IBOutlet UILabel *company;
@property (weak, nonatomic) IBOutlet UIImageView *authorImage;

@end

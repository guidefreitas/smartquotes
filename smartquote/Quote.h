//
//  Quote.h
//  smartquote
//
//  Created by Guilherme on 1/29/14.
//  Copyright (c) 2014 guidefreitas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Quote : NSManagedObject

@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSString * backgroundColor;
@property (nonatomic, retain) NSString * company;
@property (nonatomic, retain) NSData * coverImage;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * quote;
@property (nonatomic, retain) NSNumber * quoteNumber;
@property (nonatomic, retain) NSString * quoteUUID;
@property (nonatomic, retain) NSDate * updatedAt;

@end

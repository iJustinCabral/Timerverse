//
//  Color.h
//  Timerverse
//
//  Created by Larry Ryan on 1/25/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Item;

@interface Color : NSManagedObject

@property (nonatomic, retain) NSNumber * alpha;
@property (nonatomic, retain) NSNumber * brightness;
@property (nonatomic, retain) NSNumber * hue;
@property (nonatomic, retain) NSNumber * saturation;
@property (nonatomic, retain) Item *item;

- (UIColor *)UIColor;

@end

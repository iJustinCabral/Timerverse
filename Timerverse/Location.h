//
//  Location.h
//  Timerverse
//
//  Created by Larry Ryan on 1/25/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Item;

@interface Location : NSManagedObject

@property (nonatomic, retain) NSNumber * x;
@property (nonatomic, retain) NSNumber * y;
@property (nonatomic, retain) Item *item;

@end

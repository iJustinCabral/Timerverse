//
//  Sound.h
//  Timerverse
//
//  Created by Larry Ryan on 1/25/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Item;

@interface Sound : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * sourceExt;
@property (nonatomic, retain) NSString * sourceURL;
@property (nonatomic, retain) NSNumber * vibration;
@property (nonatomic, retain) NSNumber * vibrationDuration;
@property (nonatomic, retain) NSNumber * volume;
@property (nonatomic, retain) NSSet *items;
@end

@interface Sound (CoreDataGeneratedAccessors)

- (void)addItemsObject:(Item *)value;
- (void)removeItemsObject:(Item *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

@end

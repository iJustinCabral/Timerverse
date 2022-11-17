//
//  Item.h
//  Timerverse
//
//  Created by Larry Ryan on 7/21/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Color, Location, Sound;

@interface Item : NSManagedObject

@property (nonatomic, retain) NSString * glyphURL;
@property (nonatomic, retain) NSNumber * gridLockIndex;
@property (nonatomic, retain) NSNumber * iterationStartTime;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * note;
@property (nonatomic, retain) NSNumber * repeat;
@property (nonatomic, retain) NSNumber * running;
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSString * uniqueID;
@property (nonatomic, retain) NSNumber * enabled;
@property (nonatomic, retain) NSNumber * drawIndex;
@property (nonatomic, retain) Color *color;
@property (nonatomic, retain) Location *location;
@property (nonatomic, retain) Sound *sound;

@end

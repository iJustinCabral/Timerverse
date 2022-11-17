//
//  Days.h
//  Timerverse
//
//  Created by Larry Ryan on 7/22/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AlarmItem;

@interface Days : NSManagedObject

@property (nonatomic, retain) NSNumber * sunday;
@property (nonatomic, retain) NSNumber * monday;
@property (nonatomic, retain) NSNumber * tuesday;
@property (nonatomic, retain) NSNumber * wednesday;
@property (nonatomic, retain) NSNumber * thrusday;
@property (nonatomic, retain) NSNumber * friday;
@property (nonatomic, retain) NSNumber * saturday;
@property (nonatomic, retain) AlarmItem *alarmItem;

@end

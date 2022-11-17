//
//  AlarmItem.h
//  Timerverse
//
//  Created by Larry Ryan on 7/22/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Item.h"

@class Days;

@interface AlarmItem : Item

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) Days *days;

@end

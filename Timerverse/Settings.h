//
//  Settings.h
//  Timerverse
//
//  Created by Larry Ryan on 7/13/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Settings : NSManagedObject

@property (nonatomic, retain) NSNumber * alertVibrationEnabled;
@property (nonatomic, retain) NSNumber * clockCorner;
@property (nonatomic, retain) NSNumber * clockSecondsEnabled;
@property (nonatomic, retain) NSNumber * effectGridLockEnabled;
@property (nonatomic, retain) NSNumber * totalCountedSeconds;

@end

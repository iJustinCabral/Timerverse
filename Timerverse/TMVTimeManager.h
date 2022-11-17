//
//  TMVTimeManager.h
//  Timerverse
//
//  Created by Larry Ryan on 2/16/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TimeManager \
((TMVTimeManager *)[TMVTimeManager sharedTimeManager])

@interface TMVTimeManager : NSObject

+ (instancetype)sharedTimeManager;

- (void)addInterval:(NSNumber *)interval forObject:(id)object;
- (void)removeIntervalForObject:(id)object;

- (BOOL)nightTimeAtLocale;

- (void)start;
- (void)stop;

@end

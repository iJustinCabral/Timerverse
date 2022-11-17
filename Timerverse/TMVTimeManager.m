//
//  TMVTimeManager.m
//  Timerverse
//
//  Created by Larry Ryan on 2/16/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVTimeManager.h"

static BOOL const kAlwaysShowStars = YES;

@interface TMVTimeManager ()

@property (nonatomic) NSTimer *mainTimer;
@property (nonatomic) NSMutableDictionary *intervalTracker;

@end

@implementation TMVTimeManager

+ (instancetype)sharedTimeManager
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - Management

- (void)addInterval:(NSNumber *)interval
          forObject:(id)object
{
    
}

- (void)removeIntervalForObject:(id)object
{
    
}

#pragma mark - Timer

- (void)configureMainTimer
{
    if (!self.mainTimer)
    {
        self.mainTimer = [NSTimer timerWithTimeInterval:0.02
                                                 target:self
                                               selector:@selector(notifyMainTimerUpdated:)
                                               userInfo:nil
                                                repeats:YES];
        
        
        [[NSRunLoop mainRunLoop] addTimer:self.mainTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)notifyMainTimerUpdated:(NSTimer *)timer
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"mainTimerUpdated"
                                                        object:timer
                                                      userInfo:nil];
}

- (void)start
{
    [self configureMainTimer];
}

- (void)stop
{
    [self.mainTimer invalidate];
    self.mainTimer = nil;
}

#pragma mark - Helpers

- (BOOL)nightTimeAtLocale
{
    if (kAlwaysShowStars) return YES;
    
    NSDateFormatter *timeFormatter = [NSDateFormatter new];
    [timeFormatter setLocale:[NSLocale currentLocale]];
    [timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
    [timeFormatter setDateFormat:@"HH"];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour + NSCalendarUnitMinute
                                                                   fromDate:[NSDate date]];
    NSInteger hour = [components hour];
    NSInteger minutes = [components minute];
    
    NSString *fixedMinutes = @"";
    
    if (minutes < 10)
    {
        fixedMinutes = [NSString stringWithFormat:@"0%li", (long)minutes];
    }
    else
    {
        fixedMinutes = [NSString stringWithFormat:@"%li", (long)minutes];
    }
    
    NSInteger currentTime = [[NSString stringWithFormat:@"%li%@", (long)hour, fixedMinutes] integerValue];
    
    NSInteger sunrise = 640;
    NSInteger sunset = 1720;
    
    return (currentTime <= sunrise || currentTime >= sunset) ? YES : NO;
}

@end

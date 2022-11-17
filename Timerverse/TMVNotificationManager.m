
//  TMVNotificationManager.m
//  Timerverse
//
//  Created by Justin Cabral on 2/13/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVNotificationManager.h"

#define kTimerNameKey @"kTimerNameKey"
#define kAlarmNameKey @"kAlarmNameKey"

@implementation TMVNotificationManager

+ (instancetype)sharedNotificationManager
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (void)scheduleTimerForDate:(NSDate *)date withTimerItemView:(TMVTimerItemView *)itemView
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    NSString *string  = @".mp3";
    
    notification.fireDate = date;
    notification.timeZone = [NSTimeZone systemTimeZone];
    notification.alertBody = NSLocalizedString(@"Your timer has finished it's countdown!", FinishedCountDown);
    notification.soundName = [itemView.item.sound.name stringByAppendingString:string];
    notification.userInfo = [NSDictionary dictionaryWithObject:itemView.item.uniqueID forKey:kTimerNameKey];
    notification.applicationIconBadgeNumber++;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)scheduleAlarmForDate:(NSDate *)date withAlarmItemView:(TMVAlarmItemView *)itemView
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    notification.fireDate = date;
    notification.timeZone = [NSTimeZone systemTimeZone];
    notification.alertBody = NSLocalizedString(@"Wake up!", WakeUp);
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.userInfo = [NSDictionary dictionaryWithObject:itemView.item.name forKey:kAlarmNameKey];
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)cancelTimerNotificationForItemView:(TMVTimerItemView *)itemView
{
    for (UILocalNotification *notification in [[[UIApplication sharedApplication] scheduledLocalNotifications] copy])
    {
        NSDictionary *userInfo = notification.userInfo;
        
        if ([itemView.item.uniqueID isEqualToString:[userInfo objectForKey:kTimerNameKey]])
        {
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }
        
    }
}

- (void)cancelAlarmNotificationForItemView:(TMVAlarmItemView *)itemView
{
    for (UILocalNotification *notification in [[[UIApplication sharedApplication] scheduledLocalNotifications] copy])
    {
        NSDictionary *userInfo = notification.userInfo;
        
        if ([itemView.item.uniqueID isEqualToString:[userInfo objectForKey:kAlarmNameKey]])
        {
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }
        
    }
}

- (void)clearAllScheduledNotifications
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}


@end

//
//  TMVNotificationManager.h
//  Timerverse
//
//  Created by Justin Cabral on 2/13/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

@import UIKit;

#define NotificationManager \
((TMVNotificationManager *)[TMVNotificationManager sharedNotificationManager])

@interface TMVNotificationManager : NSObject

+ (instancetype)sharedNotificationManager;

- (void)scheduleTimerForDate:(NSDate *)date withTimerItemView:(TMVTimerItemView *)itemView;
- (void)scheduleAlarmForDate:(NSDate *)date withAlarmItemView:(TMVAlarmItemView *)itemView;

- (void)cancelTimerNotificationForItemView:(TMVTimerItemView *)itemView;
- (void)cancelAlarmNotificationForItemView:(TMVAlarmItemView *)itemView;

- (void)clearAllScheduledNotifications;



@end

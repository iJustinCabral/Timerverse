//
//  TMVAppDelegate.m
//  Timerverse
//
//  Created by Larry Ryan on 1/11/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVAppDelegate.h"

@interface TMVAppDelegate ()

@end

@implementation TMVAppDelegate

#pragma mark - Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Load the data
    IAPManager;
    DataManager;
    TimeManager;
    NotificationManager;
    SoundManager;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"])
    {
        self.firstLaunch = NO;
    }
    else
    {
        float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
        
        if (sysVer >= 8.0)
        {
            [self askAlertPermissions];
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [defaults setBool:YES forKey:@"HasLaunchedOnce"];
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"alerts_allowed"];
        [defaults synchronize];
        
        self.firstLaunch = YES;
    }
    
    // Handle launching from a notification
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey])
    {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:application.scheduledLocalNotifications.count];
    }
    
    return YES;
}

- (void)askAlertPermissions
{
    UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
}

// This will be called only after confirming your settings
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // There is also a built in method to find out if the user has appropriate settings, you might want to use that instead if you just want to know what the setting is
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"alerts_allowed"];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:application.scheduledLocalNotifications.count];

    [DataManager saveContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:application.scheduledLocalNotifications.count];

    [DataManager saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:application.scheduledLocalNotifications.count];
    
    [DataManager saveContext];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    UIApplicationState state = [application applicationState];
    
    if (state == UIApplicationStateActive)
    {
        
    }
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:application.scheduledLocalNotifications.count];
}

@end

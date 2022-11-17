//
//  TMVAppDelegate.h
//  Timerverse
//
//  Created by Larry Ryan on 1/11/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

#define AppDelegate \
((TMVAppDelegate *)[UIApplication sharedApplication].delegate)

@protocol TMVFirstLaunchDelegate;

@interface TMVAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, getter = isFirstLaunch) BOOL firstLaunch;

@end

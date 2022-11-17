//
//  TMVSettingsContainerController.h
//  Timerverse
//
//  Created by Larry Ryan on 3/23/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TMVSettingsViewController.h"

#define SettingsController \
((TMVSettingsViewController *)[SettingsContainerController settingsViewController])

#define SettingsContainerController \
((TMVSettingsContainerController *)[TMVSettingsContainerController sharedSettingsContainer])

@protocol TMVSettingsContainerControllerDelegate;

@interface TMVSettingsContainerController : UIViewController

#pragma mark - Singleton
+ (instancetype)sharedSettingsContainer;

@property (nonatomic, weak) id <TMVSettingsContainerControllerDelegate> delegate;

@property (nonatomic, readonly) TMVSettingsViewController *settingsViewController;

- (void)hideSettingsAnimated;

@end

@protocol TMVSettingsContainerControllerDelegate <NSObject>

- (void)didDismissViewController:(UIViewController *)viewController;

@end
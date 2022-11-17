//
//  TMVSettingsViewController.h
//  Timerverse
//
//  Created by Larry Ryan on 2/1/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMVSettingsViewController : UIViewController

#pragma mark - Settings Accessors

// Alert
- (BOOL)alertVibrationEnabled;

// Effects
- (BOOL)effectGridLockEnabled;

- (void)showPurchaseCells:(BOOL)show
                 animated:(BOOL)animated;

@end

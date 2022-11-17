//
//  TMVAlarmViewController.h
//  Timerverse
//
//  Created by Justin Cabral on 2/7/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SAAlarmControl.h"

@interface TMVAlarmViewController : UIViewController

@property (strong, nonatomic) IBOutlet SAAlarmControl *alarmSelector;

@property (nonatomic, readwrite) CGPoint itemCenter;

- (instancetype)initWithItemView:(TMVItemView *)itemView;


@end

//
//  TMVSwitchCell.h
//  Timerverse
//
//  Created by Larry Ryan on 2/1/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMVSwitchCell : UITableViewCell


@property (nonatomic) UISwitch *cellSwitch;
- (void)switchAction:(UISwitch *)sender;

@end

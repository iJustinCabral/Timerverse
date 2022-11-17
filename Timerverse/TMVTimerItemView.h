//
//  TMVTimerItem.h
//  Timerverse
//
//  Created by Larry Ryan on 1/11/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVItemView.h"

@protocol TMVTimerItemViewDelegate;

@interface TMVTimerItemView : TMVItemView

@end

#pragma mark - Delegate

@protocol TMVTimerItemViewDelegate <NSObject>
@optional

- (void)didStartCountItem:(TMVTimerItemView *)item;
- (void)didStopCountItem:(TMVTimerItemView *)item;

@end
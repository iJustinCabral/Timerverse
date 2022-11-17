//
//  TMVStatusBarLockView.h
//  Timerverse
//
//  Created by Larry Ryan on 10/23/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMVStatusBarLockView : UIView

- (void)showActivityIndicator;
- (void)showLock;

- (void)updateColor:(UIColor *)color
      withAnimation:(BOOL)animation;

@end

//
//  TMVDashView.h
//  Timerverse
//
//  Created by Larry Ryan on 5/2/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMVDashView : UIView

@property (nonatomic, readonly, getter = isSpinning) BOOL spinning;
@property (nonatomic, readonly) CAShapeLayer *ringLayer;

- (instancetype)initWithFrame:(CGRect)frame
           attachedToItemView:(TMVItemView *)itemView;

- (void)startSpinning;
- (void)stopSpinning;

@end

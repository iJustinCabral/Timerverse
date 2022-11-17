//
//  TMVAlarmItemView.m
//  Timerverse
//
//  Created by Larry Ryan on 2/3/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVAlarmItemView.h"

@interface TMVAlarmItemView ()

@property (nonatomic) UIImageView *alarmBellsImageView;

@end

@implementation TMVAlarmItemView

#pragma mark - Hooks

- (instancetype)initWithState:(TMVItemViewState)state
{
    self = [super initWithState:state];
    if (self)
    {
        [self configureAlarmBells];
    }
    return self;
}

- (void)setApparentColor:(UIColor *)apparentColor
{
    [super setApparentColor:apparentColor];
    
    self.alarmBellsImageView.tintColor = apparentColor;
}

- (void)interactiveTransitionToAbyssWithPercentage:(CGFloat)percentage
{
    [super interactiveTransitionToAbyssWithPercentage:percentage];
    
    // Adjust the percentage so we accomplish the transitions at the half point
//    percentage = percentage / 0.5f;
//    
//    if (percentage < 0.0f) percentage = 0.0f;
//    if (percentage > 1.0f) percentage = 1.0f;
    
//    CGFloat reversedPercentage = 1.0f - percentage;
    
//    switch (self.state)
//    {
//        case TMVItemViewStateDefault:
//        {
//            self.alarmBellsImageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, reversedPercentage, reversedPercentage);
//        }
//            break;
//            
//        case TMVItemViewStatePoint:
//        {
//            
//        }
//            break;
//    }
}

#pragma mark - Methods

- (void)configureAlarmBells
{
    if (!self.alarmBellsImageView)
    {
        self.alarmBellsImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"alarmBells"]
                                                                 imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.alarmBellsImageView.frame = CGRectMake(-3.0f, -12, 105, 41);
        self.alarmBellsImageView.tintColor = self.apparentColor;
        [self.containerView addSubview:self.alarmBellsImageView];
        [self.containerView sendSubviewToBack:self.alarmBellsImageView];
    }
}

@end

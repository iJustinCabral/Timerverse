//
//  TMVAtmosphere.h
//  Timerverse
//
//  Created by Larry Ryan on 1/29/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "EGOGradientView.h"
#import "TMVGalaxy.h"

typedef NS_ENUM (NSUInteger, TMVAtmosphereState)
{
    TMVAtmosphereStateNight = 0,
    TMVAtmosphereStateDay
};

NSString * NSStringFromAtmosphereState(TMVAtmosphereState state);

@protocol TMVAtmosphereDelegate;

@interface TMVAtmosphere : EGOGradientView

- (instancetype)initWithFrame:(CGRect)frame
                  andDelegate:(id <TMVAtmosphereDelegate>)delegate;

@property (nonatomic, weak) id <TMVAtmosphereDelegate> delegate;

@property (nonatomic, readonly) TMVAtmosphereState state;
@property (nonatomic, readonly) TMVGalaxy *galaxy;
@property (nonatomic, readonly) CGFloat transitionDuration;
@property (nonatomic, readonly) UIColor *currentColor;
@property (nonatomic, readonly) UIColor *derivedColor;

// Element colors return the appropriate color for views over the atmosphere. NightState will return white for top and bottom. DayState will return the opposite gradient color;
@property (nonatomic, readonly) UIColor *elementColorTop;
@property (nonatomic, readonly) UIColor *elementColorBottom;

- (void)changeToColor:(UIColor *)color;
- (void)transitionToColor:(UIColor *)color;
- (void)flashColor:(UIColor *)color;

- (void)changeToNight;
- (void)transitionToNight;

- (UIColor *)derivedColorFromColor:(UIColor *)color;

- (void)updateColorAnimated:(BOOL)animated;

@end


@protocol TMVAtmosphereDelegate <NSObject>

- (void)didChangeAtmosphereToState:(TMVAtmosphereState)state;

// Can be consistenly called
- (void)didChangeAtmosphereToTopColor:(UIColor *)topColor
                       andBottomColor:(UIColor *)bottomColor
                            withState:(TMVAtmosphereState)state;

@end
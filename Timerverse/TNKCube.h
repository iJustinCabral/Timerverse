//
//  TNKCube.h
//  Thinkr
//
//  Created by Larry Ryan on 1/2/14.
//  Copyright (c) 2014 Thinkr LLC. All rights reserved.
//

@import UIKit;

typedef NS_ENUM (NSUInteger, TNKCubeType)
{
    TNKCubeTypeLayers,
    TNKCubeTypeImages,
    TNKCubeTypeFlat
};

typedef NS_ENUM (NSUInteger, TNKCubeState)
{
    TNKCubeStateDefault,
    TNKCubeStateSpiral,
    TNKCubeStateExpansion,
    TNKCubeStateSun,
    TNKCubeStateX,
    TNKCubeStateArrow,
    TNKCubeStateShare
};

typedef NS_ENUM (NSUInteger, TNKCubeExpansionState)
{
    TNKCubeExpansionStateContracted,
    TNKCubeExpansionStateExpanded
};

typedef NS_ENUM (NSUInteger, TNKCubeArrowOrientation)
{
    TNKCubeArrowOrientationUp,
    TNKCubeArrowOrientationDown
};


@interface TNKCube : UIView

@property (nonatomic, readonly) TNKCubeType type;
@property (nonatomic, readonly) TNKCubeState state;
@property (nonatomic, readonly) TNKCubeState stateByPercentage; // The state may be other than default and have a value of 0.0 percent which is actually the default state.
@property (nonatomic, readonly) TNKCubeExpansionState expansionState;
@property (nonatomic, readonly) TNKCubeArrowOrientation arrowOrientation;

@property (nonatomic, readonly, getter = isFlickering) BOOL flickering;
@property (nonatomic, readonly) UIColor *color;

- (instancetype)initWithType:(TNKCubeType)type
                    andState:(TNKCubeState)state;

- (void)changeToExpansionState:(TNKCubeExpansionState)expansionState
                      animated:(BOOL)animated;

- (void)transitionToState:(TNKCubeState)state
           withPercentage:(CGFloat)percentage
                 animated:(BOOL)animated;

// Color
- (void)changeToDefaultColorsAnimated:(BOOL)animated;
- (void)changeToColor:(UIColor *)color
             animated:(BOOL)animated;
- (void)transitionToColor:(UIColor *)color
           withPercentage:(CGFloat)percentage;

// Flickering
- (void)startFlickering;
- (void)stopFlickering;

@end

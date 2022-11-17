//
//  TMVSettingsButtonView.h
//  Timerverse
//
//  Created by Larry Ryan on 2/2/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

@import UIKit;

#import "TNKCube.h"

typedef NS_ENUM (NSUInteger, TMVSettingsButtonViewState)
{
    TMVSettingsButtonViewStateCube = 0,
    TMVSettingsButtonViewStateTrash
};

@protocol TMVSettingsButtonViewDelegate;

@interface TMVSettingsButtonView : UIButton

@property (nonatomic) id <TMVSettingsButtonViewDelegate> delegate;

@property (nonatomic, readonly) TNKCube *cube;

@property (nonatomic) TMVSettingsButtonViewState viewState;
@property (nonatomic, readonly, getter = isDraggingOutsideBounds) BOOL draggingOutsideBounds;
@property (nonatomic, readonly) BOOL canBeTouched;

- (instancetype)initWithState:(TMVSettingsButtonViewState)viewState;

- (void)setViewState:(TMVSettingsButtonViewState)viewState
            animated:(BOOL)animated;

- (void)interactiveTransitionToState:(TMVSettingsButtonViewState)viewState
                      withPercentage:(CGFloat)percentage;

- (void)showAnimated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated;

- (void)updateColor:(UIColor *)color
      withAnimation:(BOOL)animation;

- (void)changeCubeToSun:(BOOL)changeToSun
               animated:(BOOL)animated;
- (void)sunsetPercentage:(CGFloat)percentage;

// Pass through to the cube. quoteContainer > App Container > SELF > cube
- (void)updateCubeSharePercentage:(CGFloat)percentage;

- (void)updateCubeArrowWithOrientation:(TNKCubeArrowOrientation)orientation
                          andPercenage:(CGFloat)percentage;

- (void)changeCubeToX:(BOOL)changeToX
             animated:(BOOL)animated;

- (void)cancelTouch;

@end

@protocol TMVSettingsButtonViewDelegate <NSObject>

- (void)didBeginTouchingSettingsButtonView:(TMVSettingsButtonView *)settingsButtonView;
- (void)didEndTouchingSettingsButtonView:(TMVSettingsButtonView *)settingsButtonView;
- (void)didLongPressSettingsButtonView:(TMVSettingsButtonView *)settingsButtonView;

@end

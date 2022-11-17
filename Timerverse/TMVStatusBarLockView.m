//
//  TMVStatusBarLockView.m
//  Timerverse
//
//  Created by Larry Ryan on 10/23/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVStatusBarLockView.h"

@interface TMVStatusBarLockView ()

@property (nonatomic) UIButton *unlockButton;
@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic) UIColor *color;

@end

@implementation TMVStatusBarLockView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self configureUnlockButton];
    }
    
    return self;
}

#pragma mark - Unlock Button

- (void)configureUnlockButton
{
    if (!self.unlockButton)
    {
        // Add the arrow button
        self.unlockButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.unlockButton.frame = CGRectMake(0, 0, 16, 16);
        self.unlockButton.layer.opacity = 1.0f;
        self.unlockButton.tintColor = self.color;
        [self.unlockButton setImage:[[UIImage imageNamed:@"lock"]
                                     imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                           forState:UIControlStateNormal];
        [self.unlockButton addTarget:self action:@selector(unlockAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.unlockButton];
    }
}

- (void)unlockAction:(UIButton *)button
{
    [IAPManager buyProduct:IAPManager.productArray.firstObject];
}

#pragma mark - Avtivity Indicator

- (void)configureActivityIndicator
{
    if (!self.activityIndicatorView)
    {
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.activityIndicatorView.center = CGPointMake(8, 8);
        self.activityIndicatorView.transform = CGAffineTransformMakeScale(0.76, 0.76); // Roughly 16pt
        [self.activityIndicatorView setColor:self.color];
        [self.activityIndicatorView startAnimating];
    }
}

#pragma mark - Public Methods

- (void)showActivityIndicator
{
    [self configureActivityIndicator];
    
    [UIView transitionFromView:self.unlockButton
                        toView:self.activityIndicatorView
                      duration:1.0
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    completion:^(BOOL finished) {
                        
    }];
}

- (void)showLock
{
    [UIView transitionFromView:self.activityIndicatorView
                        toView:self.unlockButton
                      duration:1.0
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    completion:^(BOOL finished) {
                        
                        [self.activityIndicatorView stopAnimating];
                        self.activityIndicatorView = nil;
                        
                    }];
}

#pragma mark - Color

- (void)updateColor:(UIColor *)color
      withAnimation:(BOOL)animation
{
    self.color = color;
    
    if (animation)
    {
        [UIView animateWithDuration:AppContainer.atmosphere.transitionDuration
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.activityIndicatorView setColor:color];
                             self.unlockButton.tintColor = color;
                             
                         }
                         completion:^(BOOL finished) {}];
    }
    else
    {
        [self.activityIndicatorView setColor:color];
        self.unlockButton.tintColor = color;
    }
}

@end

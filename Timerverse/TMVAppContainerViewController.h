//
//  TMVViewController.h
//  Timerverse
//
//  Created by Larry Ryan on 1/11/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

@import UIKit;

#import "AbyssView.h"
#import "TMVSettingsButtonView.h"
#import "TMVAtmosphere.h"
#import "TMVItemManager.h"
#import "TMVStatusBarView.h"

@import iAd;
@class TMVItemView;

#define AppContainer \
((TMVAppContainerViewController *)[UIApplication sharedApplication].delegate.window.rootViewController)

static NSUInteger const kMotionEffectFactor = 10.0f;

@interface TMVAppContainerViewController : UIViewController <UIGestureRecognizerDelegate, TMVAtmosphereDelegate>

@property (nonatomic, readonly) TMVAtmosphere *atmosphere;

// Holds the ContentContainerView with the Abyss underneath it. Also holds any VC's
@property (nonatomic) UIScrollView *view;

// Holds the HUD aswell as the itemContinerView.
@property (nonatomic, readonly) UIView *contentContainerView;

@property (nonatomic, readonly) AbyssView *theAbyss;

// HUD
@property (nonatomic, readonly, getter = isShowingHUD) BOOL showingHUD;
@property (nonatomic, readonly) TMVStatusBarView *statusBarView;
@property (nonatomic, readonly) TMVSettingsButtonView *settingsButton;

@property (nonatomic, readonly) ADBannerView *adBanner;
@property (nonatomic, readonly, getter = isAdLoaded) BOOL adLoaded;

// Holds the TMVItemViews, which is assigned to the ItemManager
@property (nonatomic) TMVNonInteractiveView *itemContainerView;
@property (nonatomic) TMVItemManager *itemManager;

// Track if an alert view is showing so we can adjust the apps motion effects accordingly
@property (nonatomic, readonly, getter = isShowingAlertView) BOOL showingAlertView;

@property (nonatomic, readonly, getter = isSidePanning) BOOL sidePanning;

- (void)refreshStats;

- (void)loadMainApplicationUI;

- (void)setHUDUserInteraction:(BOOL)userInteraction;
- (void)showHUDAnimated:(BOOL)animated;

- (void)didDismissViewController:(UIViewController *)viewController;

- (CGFloat)percentageToAbyssForPoint:(CGPoint)point;
- (void)interactiveTransitionToAbyssWithItemView:(TMVItemView *)itemView
                                  withPanGesture:(UIPanGestureRecognizer *)panGesture
                                  andUpdateBlock:(void (^)(BOOL finished, BOOL inAbyss))updateBlock;

- (void)loadTutorialUIWithOrigin:(CGPoint)origin;

@end

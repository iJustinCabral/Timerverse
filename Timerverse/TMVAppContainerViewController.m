//
//  TMVViewController.m
//  Timerverse
//
//  Created by Larry Ryan on 1/11/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVAppContainerViewController.h"
#import "TDMScreenEdgePanGestureRecognizer.h"
#import "TMVSettingsContainerController.h"
#import "TMVTimerViewController.h"
#import "TMVQuoteView.h"
#import "TMVAlarmViewController.h"
#import "TMVQuoteViewContainerView.h"
#import "TMVTutorialViewController.h"

@import AVFoundation;

static CGFloat const kAbyssHeight = 120.0f;
static BOOL const kAlarmsEnabled = NO;
static BOOL const kBrightnessGestureEnabled = YES;
static BOOL const kQuoteViewScrollingEnabled = NO;
static BOOL const kSnapHintAnytime = NO;

@interface TMVAppContainerViewController ()

<UIScrollViewDelegate, UIAlertViewDelegate, ADBannerViewDelegate, TMVItemManagerDataSource, TMVItemManagerDelegate, TMVSettingsContainerControllerDelegate, TMVStatusBarViewDelegate, TMVQuoteViewContainerDelegate, TMVQuoteViewDelegate, TMVSettingsButtonViewDelegate>

// Holds the HUD aswell as the itemContinerView.
@property (nonatomic, readwrite) UIView *contentContainerView;

@property (nonatomic) TMVTimerViewController *timerViewController;
@property (nonatomic) TMVAlarmViewController *alarmViewController;
@property (nonatomic, readwrite) TMVQuoteView *quoteView;
@property (nonatomic, readwrite) TMVQuoteViewContainerView *quoteViewContainer;
@property (nonatomic, readwrite) TMVSettingsButtonView *settingsButton;
@property (nonatomic, readwrite) AbyssView *theAbyss;
@property (nonatomic, readwrite) TMVStatusBarView *statusBarView;

@property (nonatomic) UIView *statsView;
@property (nonatomic) UILabel *totalTimeLabel;

@property (nonatomic, readwrite) ADBannerView *adBanner;
@property (nonatomic) UIView *adBannerDynamicView;
@property (nonatomic) UIDynamicItemBehavior *adBannerDynamicOptions;
@property (nonatomic) UISnapBehavior *adBannerSnapBehavior;
@property (nonatomic, readwrite, getter = isAdLoaded) BOOL adLoaded;

@property (nonatomic, readwrite) TMVAtmosphere *atmosphere;

@property (nonatomic, readwrite, getter = isShowingAlertView) BOOL showingAlertView;
@property (nonatomic, readwrite, getter = isShowingHUD) BOOL showingHUD;
@property (nonatomic, readwrite, getter = isSidePanning) BOOL sidePanning;

// Stop app resume from gettings called multiple times
@property (nonatomic) BOOL hasResumed;

@property (nonatomic) UITapGestureRecognizer *itemHintTapGesture;
@property (nonatomic) UITapGestureRecognizer *startAllTapGesture;
@property (nonatomic) UIPanGestureRecognizer *brightnessGesture;
@property (nonatomic) TDMScreenEdgePanGestureRecognizer *edgeGestureLeft;
@property (nonatomic) TDMScreenEdgePanGestureRecognizer *edgeGestureRight;

@property (nonatomic) CGFloat brightnessLastPosition;

@property (nonatomic) NSMutableArray *edgeGestureArray;

@end

@implementation TMVAppContainerViewController

@dynamic view;

#pragma mark - _______________________Lifecycle_______________________
#pragma mark -

- (void)loadView
{
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    
    // RootView
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:frame];
    scrollView.delegate = self;
    scrollView.scrollEnabled = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.contentSize = CGSizeMake(frame.size.width, frame.size.height + kAbyssHeight);
    scrollView.multipleTouchEnabled = YES;
    
    // ContentContainer
    self.contentContainerView = [[UIView alloc] initWithFrame:scrollView.frame];
    [scrollView addSubview:self.contentContainerView];
    
    // ItemContainer
    self.itemContainerView = [[TMVNonInteractiveView alloc] initWithFrame:scrollView.frame];
    self.itemContainerView.interaction = NO;
    
    [self.contentContainerView addSubview:self.itemContainerView];
    [self.contentContainerView bringSubviewToFront:self.itemContainerView];
    
    self.view = scrollView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Dont clip to bounds for the motion effects of the app
    self.view.clipsToBounds = NO;
    
    // Atmosphere
    [self configureAtmosphere];
    
    // Setup the ItemManager
    self.itemManager = [[TMVItemManager alloc] initWithAnimatorView:self.itemContainerView
                                                         dataSource:self
                                                        andDelegate:self];
    
    // HUD Elements
    [self configureStatusBarView];
    [self configureSettingsButton];
    
    // Hide the HUD so we can animate it in
    [self hideHUDAnimated:NO];
    
    if (AppDelegate.firstLaunch)
    {
        [self loadTutorialUI];
    }
    else
    {
        [self loadMainApplicationUI];
    }
}

- (void)loadTutorialUI
{
    [self loadTutorialUIWithOrigin:CGPointZero];
}

// TODO: Make work with settings
- (void)loadTutorialUIWithOrigin:(CGPoint)origin
{
    TMVTutorialViewController *tutorialVC = [[TMVTutorialViewController alloc] init];
    
    tutorialVC.view.origin = origin;
    
    [self addChildViewController:tutorialVC];
    [self.view addSubview:tutorialVC.view];
    [self.view bringSubviewToFront:tutorialVC.view];
    
    [tutorialVC didMoveToParentViewController:self];
}

- (void)loadMainApplicationUI
{
    [self listenToApplicationBackground];
    
    [self listenToPurchases];
    
    // Gestures
    [self configureGestures];
    
    [self showHUDDelayed:YES];
    
    [self configureTheAbyss];
    
    if (!IAPManager.isPurchased)
    {
        if (IAPManager.purchaseType == IAPHelperPurchaseTypeAd)
        {
            self.adBanner = [[ADBannerView alloc] initWithFrame:CGRectMake(0, -50, self.view.width, 50)];
            self.adBanner.delegate = self;
        }
    }
    else
    {
        [SettingsController showPurchaseCells:NO
                                     animated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)didDismissViewController:(UIViewController *)viewController
{
    [self setHUDUserInteraction:YES];
    
    [self.atmosphere updateColorAnimated:YES];
    [self.itemManager snapItemViewsToGridLock];
    
    viewController = nil;
}


#pragma mark - _______________________Notifications_______________________
#pragma mark -

- (void)listenToApplicationActivity
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)didBecomeActive:(NSNotification *)notification
{
    if (self.hasResumed) return;
    
    self.hasResumed = YES;
    
    [self.atmosphere.galaxy resumeAnimating];
}

- (void)showHUDDelayed:(BOOL)delay
{
    if (delay)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            //            [self.atmosphere.galaxy startAnimating];
            
            //            if (self.itemManager.hasActiveItems || self.childViewControllers.count > 0) return;
            
            [self showHUDAnimated:YES];
            
            if (!self.quoteView.isShowing)
            {
                [self showQuoteViewAnimated:YES];
            }
        });
    }
    else
    {
        //        [self.atmosphere.galaxy startAnimating];
        
        //        if (self.itemManager.hasActiveItems || self.childViewControllers.count > 0) return;
        
        [self showHUDAnimated:YES];
        
        if (!self.quoteView.isShowing)
        {
            [self showQuoteViewAnimated:YES];
        }
    }
}

- (void)listenToApplicationBackground
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)didEnterBackground:(NSNotification *)notification
{
    self.hasResumed = NO;
    
    // Start observing the activy once the app went to the background. Using willEnterForeground would get called to early.
    [self listenToApplicationActivity];
    
    [self.atmosphere.galaxy stopAnimating];
    
    //    if (self.itemManager.hasActiveItems || self.childViewControllers.count > 0) return;
    
    //    [self hideHUDAnimated:NO];
    //    [self hideQuoteViewAnimated:NO];
}


- (void)listenToPurchases
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(productPurchased:)
                                                 name:@"IAPHelperProductPurchasedNotification"
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - IAPManager Notification

- (void)productPurchased:(NSNotification *)notification
{
    IAPHelperTransactionState state = [notification.object integerValue];
    
    switch (state)
    {
        case IAPHelperTransactionStateStarted:
        {
            [self.statusBarView.lockView showActivityIndicator];
            
            for (TMVItemView *itemView in self.itemManager.itemViewArray)
            {
                if (itemView.state == TMVItemViewStateLocked)
                {
                    [itemView showActivityIndicatorAnimated:YES];
                }
            }
        }
            break;
        case IAPHelperTransactionStateCompleted:
        case IAPHelperTransactionStateRestored:
        {
            [self hideAdWithCompletion:^{
                
                self.adLoaded = NO;
                
                [self.adBanner removeFromSuperview];
                self.adBanner = nil;
                
            }];
            
            [self.statusBarView.groupView hideItemAtIndex:2
                                                 animated:YES];
            
            for (TMVItemView *itemView in self.itemManager.itemViewArray)
            {
                [itemView setState:TMVItemViewStateDefault
                          animated:YES];
            }
            
            [SettingsController showPurchaseCells:NO
                                         animated:YES];
        }
            break;
        case IAPHelperTransactionStateFailed:
        {
            [self.statusBarView.lockView showLock];
            
            for (TMVItemView *itemView in self.itemManager.itemViewArray)
            {
                [itemView hideActivityIndicatorAnimated:YES];
            }
        }
            break;
    }
}

#pragma mark - _______________________HUD Methods_______________________
#pragma mark -

- (void)showHUDAnimated:(BOOL)animated
{
    self.showingHUD = YES;
    
    if (self.isAdLoaded)
    {
        [UIView animateWithDuration:0.6
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.adBanner.y = 0.0f;
                         }
                         completion:^(BOOL finished) {}];
    }
    
    [self.statusBarView showAnimated:animated];
    [self.settingsButton showAnimated:animated];
    [self.itemManager showItemsAnimated:animated];
    [self.atmosphere.galaxy zoomInStarsAnimated:animated];
}

- (void)hideHUDAnimated:(BOOL)animated
{
    self.showingHUD = NO;
    
    if (self.isAdLoaded)
    {
        [UIView animateWithDuration:0.6
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.adBanner.y = -self.adBanner.height - self.statusBarView.height;
                         }
                         completion:^(BOOL finished) {}];
    }
    
    [self.statusBarView hideAnimated:animated];
    [self.settingsButton hideAnimated:animated];
    [self.itemManager hideItemsAnimated:animated];
    [self.atmosphere.galaxy zoomOutStarsAnimated:animated];
}

- (void)setHUDUserInteraction:(BOOL)userInteraction
{
    self.quoteView.userInteractionEnabled = userInteraction;
    
    self.edgeGestureLeft.enabled = userInteraction;
    self.edgeGestureRight.enabled = userInteraction;
    self.itemHintTapGesture.enabled = userInteraction;
    //    self.brightnessGesture.enabled = userInteraction;
    
    self.statusBarView.userInteractionEnabled = userInteraction;
    self.settingsButton.userInteractionEnabled = userInteraction;
    
    self.itemContainerView.userInteractionEnabled = userInteraction;
}

- (void)cancelGestures
{
    [self.itemManager cancelGesturesForAllItems];
}

#pragma mark - Quote View

- (void)configureQuoteView
{
    if (kQuoteViewScrollingEnabled)
    {
        if (!self.quoteViewContainer)
        {
            self.quoteViewContainer = [[TMVQuoteViewContainerView alloc] initWithFrame:self.view.frame];
            self.quoteViewContainer.quoteContainerDelegate = self;
            
            [self.contentContainerView insertSubview:self.quoteViewContainer
                                        belowSubview:self.itemContainerView];
        }
    }
    else
    {
        if (!self.quoteView)
        {
            self.quoteView = [[TMVQuoteView alloc] initWithFrame:CGRectMake(10, 0, self.view.width - 20, 200)];
            
            if (self.isAdLoaded)
            {
                self.quoteView.center = CGPointMake(self.view.center.x, self.adBanner.height + ((self.view.height - self.adBanner.height) / 2));
            }
            else
            {
                self.quoteView.center = self.view.center;
            }
            
            self.quoteView.quoteViewDelegate = self;
            
            [self.contentContainerView addSubview:self.quoteView];
        }
    }
}

- (void)didUpdateState:(TMVQuoteState)state
{
    switch (state)
    {
        case TMVQuoteStateSingle:
        {
            [self showHUDAnimated:YES];
        }
            break;
        case TMVQuoteStateList:
        {
            [self hideHUDAnimated:YES];
        }
            break;
    }
}

- (void)showQuoteViewAnimated:(BOOL)animated
{
    if (![self.itemManager hasItems] && !self.itemManager.isShowingHint && ![self.itemManager hasInteractiveItems])
    {
        if (!self.quoteView)
        {
            [self configureQuoteView];
        }
        else
        {
            [self changeQuoteAnimated:NO];
        }
        
        if (kQuoteViewScrollingEnabled)
        {
            if (animated)
            {
                [UIView animateWithDuration:0.4
                                      delay:0.2
                                    options:UIViewAnimationOptionBeginFromCurrentState
                                 animations:^{
                                     self.quoteViewContainer.layer.opacity = 1.0;
                                 }
                                 completion:NULL];
            }
            else
            {
                self.quoteViewContainer.layer.opacity = 1.0;
            }
        }
        else
        {
            [self.quoteView showAnimated:animated
                          withCompletion:^{}];
        }
    }
}

- (void)hideQuoteViewAnimated:(BOOL)animated
{
    if (kQuoteViewScrollingEnabled)
    {
        if (!self.quoteViewContainer) return;
        
        if (animated)
        {
            [UIView animateWithDuration:0.4
                                  delay:0.2
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 self.quoteViewContainer.layer.opacity = 0.0;
                             }
                             completion:NULL];
        }
        else
        {
            self.quoteViewContainer.layer.opacity = 0.0;
        }
    }
    else
    {
        if (!self.quoteView) return;
        
        [self.quoteView dismissAnimated:animated
                         withCompletion:^{}];
    }
}

- (void)changeQuoteAnimated:(BOOL)animated
{
    TMVQuoteView *quoteView = [[TMVQuoteView alloc] initWithFrame:CGRectMake(10, 0, self.view.width - 20, 200)];
    quoteView.center = self.view.center;
    quoteView.quoteViewDelegate = self;
    
    [self.contentContainerView addSubview:quoteView];
    
    if (animated)
    {
        [UIView transitionFromView:self.quoteView
                            toView:quoteView
                          duration:0.4f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        completion:^(BOOL finished) {
                            [self.quoteView removeFromSuperview];
                            self.quoteView = quoteView;
                        }];
    }
    else
    {
        [self.quoteView removeFromSuperview];
        self.quoteView = quoteView;
    }
}

#pragma mark Delegate

- (void)didBeginPanning
{
    [self setHUDUserInteraction:NO];
    self.statusBarView.userInteractionEnabled = YES;
}

- (void)didUpdatePercentageForShareAction:(CGFloat)percentage
{
    [self.settingsButton updateCubeSharePercentage:percentage];
}

- (void)didEndPanningWithPercentage:(CGFloat)percentage
{
    if (percentage >= 1.0f)
    {
        [self.statusBarView cancelPanningAndSnapToEdge];
    }
    else if (percentage == 0.0f)
    {
        [self setHUDUserInteraction:YES];
    }
}

- (void)didDecelerateShareAction
{
    [self setHUDUserInteraction:YES];
}

#pragma mark - StatusBarView

- (void)configureStatusBarView
{
    if (!self.statusBarView)
    {
        self.statusBarView = [TMVStatusBarView new];
        self.statusBarView.tintColor = self.atmosphere.elementColorTop;
        self.statusBarView.delegate = self;
        
        [self.contentContainerView addSubview:self.statusBarView];
        [self.contentContainerView sendSubviewToBack:self.statusBarView];
    }
}

#pragma mark Delegate

- (BOOL)shouldUpdateExclusionPaths
{
    return self.quoteView.shouldUseExclusionPaths;
}

- (void)didUpdateExclusionPaths:(NSArray *)exclusionPaths
{
    if (self.quoteView.isShowing)
    {
        [self.quoteView updateExclusionPaths:exclusionPaths];
    }
}


#pragma mark - Settings Button

- (void)configureSettingsButton
{
    if (!self.settingsButton)
    {
        self.settingsButton = [[TMVSettingsButtonView alloc] initWithState:TMVSettingsButtonViewStateCube];
        self.settingsButton.bottom = self.view.bottom;
        self.settingsButton.centerX = self.view.centerX;
        self.settingsButton.delegate = self;
        
        [self.settingsButton addTarget:self
                                action:@selector(didPressSettingsButton:forEvent:)
                      forControlEvents:UIControlEventTouchUpInside];
        
        [self.contentContainerView addSubview:self.settingsButton];
        [self.contentContainerView sendSubviewToBack:self.settingsButton];
    }
}

- (void)didPressSettingsButton:(TMVSettingsButtonView *)settingsButton forEvent:(UIEvent *)event
{
    if (settingsButton.isDraggingOutsideBounds || self.quoteView.isDragging || (!settingsButton.canBeTouched && settingsButton.cube.stateByPercentage != TNKCubeStateExpansion)) return;
    
    // If the touch is outside of the button we need to stop settings from showing. This is because Apple adds a touch range to the UIControl which does not sync nicely with the cube expansion.
    UITouch *touch = [[event touchesForView:settingsButton] anyObject];
    CGPoint location = [touch locationInView:self.view];
    
    if (!CGRectContainsPoint(settingsButton.frame, location)) return;
    
    [self.statusBarView cancelPanningAndSnapToEdge];
    [self cancelGestures];
    
    [self setHUDUserInteraction:NO];
    
    TMVSettingsContainerController *settingsContainer = SettingsContainerController;
    [self addChildViewController:settingsContainer];
    [self.view addSubview:settingsContainer.view];
    [self.view bringSubviewToFront:settingsContainer.view];
    [settingsContainer didMoveToParentViewController:self];
    
    settingsContainer.delegate = self;
}

#pragma mark Delegate

- (void)didBeginTouchingSettingsButtonView:(TMVSettingsButtonView *)settingsButtonView
{
    self.quoteView.userInteractionEnabled = NO;
    
    //    [self showStatsViewAnimated:YES];
}

- (void)didEndTouchingSettingsButtonView:(TMVSettingsButtonView *)settingsButtonView
{
    //    [self hideStatsViewAnimated:YES];
}

- (void)didLongPressSettingsButtonView:(TMVSettingsButtonView *)settingsButtonView
{
    
}

- (void)configureStatsView
{
    if (!self.statsView)
    {
        self.totalTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
        self.totalTimeLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Total Time", TotalTime), [self timeFormatted:DataManager.settings.totalCountedSeconds.integerValue]];
        [self.totalTimeLabel sizeToFit];
        self.totalTimeLabel.textColor = [UIColor whiteColor];
        self.totalTimeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        
        self.statsView = [[UIView alloc] initWithFrame:self.totalTimeLabel.frame];
        
        [self.statsView addSubview:self.totalTimeLabel];
        [self.view addSubview:self.statsView];
        
        
        [self hideStatsViewAnimated:NO];
    }
}

- (void)refreshStats
{
    self.totalTimeLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Total Time", TotalTime), [self timeFormatted:DataManager.settings.totalCountedSeconds.integerValue]];
}

- (void)showStatsViewAnimated:(BOOL)animated
{
    [self configureStatsView];
    
    //    if (self.statsView.layer.opacity == 1.0f) return;
    
    if (animated)
    {
        [UIView animateWithDuration:1.0
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self showStatsViewAnimated:NO];
                         }
                         completion:^(BOOL finished) {}];
    }
    else
    {
        self.statsView.layer.opacity = 1.0f;
        self.statsView.center = CGPointMake(self.settingsButton.centerX, self.settingsButton.centerY - 50);
        self.statsView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    }
}

- (void)hideStatsViewAnimated:(BOOL)animated
{
    //    if (self.statsView.layer.opacity == 0.0f) return;
    
    if (animated)
    {
        [UIView animateWithDuration:1.0
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self hideStatsViewAnimated:NO];
                         }
                         completion:^(BOOL finished) {}];
    }
    else
    {
        self.statsView.layer.opacity = 0.0f;
        self.statsView.center = self.settingsButton.center;
        self.statsView.transform = CGAffineTransformMakeScale(0.0f, 0.0f);
    }
}

- (NSString *)timeFormatted:(NSInteger)totalSeconds
{
    NSInteger seconds = totalSeconds % 60;
    NSInteger minutes = (totalSeconds / 60) % 60;
    NSInteger hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

#pragma mark - _______________________The Abyss_______________________
#pragma mark -

- (void)configureTheAbyss
{
    if (!self.theAbyss)
    {
        self.theAbyss = [[AbyssView alloc] initWithFrame:CGRectMake(0, self.view.height, self.view.width, kAbyssHeight)
                                                    type:AbyssParticleTypeTimer
                                        andParticleColor:[UIColor colorAbyssInterpolatingBetweenColor:self.atmosphere.derivedColor
                                                                                             andColor:self.atmosphere.currentColor
                                                                                       withPercentage:self.theAbyss.origin.y / self.view.height]];
        
        
    }
    
    [self.view addSubview:self.theAbyss];
    [self.view sendSubviewToBack:self.theAbyss];
}

- (void)deleteTheAbyss
{
    return;
    
    if (self.theAbyss)
    {
        [self.theAbyss removeFromSuperview];
    }
}

- (CGFloat)percentageToAbyssForPoint:(CGPoint)point
{
    CGFloat crossingPoint = self.view.height - kAbyssHeight;
    
    CGFloat pointsPastCrossingPoint = point.y - crossingPoint;
    
    CGFloat percentage = pointsPastCrossingPoint / kAbyssHeight;
    
    if (percentage < 0.0) percentage = 0.0;
    if (percentage > 1.0) percentage = 1.0;
    
    return percentage;
}


- (void)interactiveTransitionToAbyssWithItemView:(TMVItemView *)itemView
                                  withPanGesture:(UIPanGestureRecognizer *)panGesture
                                  andUpdateBlock:(void (^)(BOOL finished, BOOL inAbyss))updateBlock
{
    // Get the location of the item compared to the appdelegate window since the scrollview, which is the animatorView moves while panning.
    CGPoint center = [panGesture locationInView:AppDelegate.window];
    
    //        CGPoint center = itemView.center;
    //    CGPoint center = centerOfTouch.y > centerOfItemView.y ? centerOfTouch : centerOfItemView;
    
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            if (panGesture.state == UIGestureRecognizerStateBegan)
            {
                //                [self.settingsButton setViewState:TMVSettingsButtonViewStateTrash
                //                                         animated:YES];
                
                if (self.settingsButton.cube.state != TNKCubeStateDefault)
                {
                    [self.settingsButton cancelTouch];
                }
                
                [self.settingsButton changeCubeToX:YES
                                          animated:YES];
                
                self.theAbyss.type = AbyssParticleTypeTimer; // Change back to all when alarms implemented
            }
            
            
            CGFloat crossingPoint = self.view.height - kAbyssHeight;
            CGFloat percentage = [self percentageToAbyssForPoint:itemView.center];
            
            // Update the items view scale, shadow opacity... going towards the abyss
            [itemView interactiveTransitionToAbyssWithPercentage:percentage];
            
            // If the pan is in the abyss zone
            if ([itemView isEqual:[self.itemManager interactiveItemViewNotActiveNearestToBottomOfScreen]])
            {
                //                CGFloat nearestToBottomPercentage = [self percentageToAbyssForPoint:center];
                //                nearestToBottomPercentage /= 0.2f;
                //                [self.settingsButton updateCubeArrowWithOrientation:TNKCubeArrowOrientationUp andPercenage:nearestToBottomPercentage];
                
                NSArray *activeItemViews = [self.itemManager allActiveItemViews];
                
                if (activeItemViews.count > 0)
                {
                    for (TMVItemView *itemViewObject in activeItemViews)
                    {
                        //                        if (!CGRectContainsRect(AppContainer.itemContainerView.frame, itemViewObject.frame))
                        {
                            
                            [itemViewObject fixOriginForBounds];
                        }
                    }
                }
                
                [self.statusBarView fixOriginForBounds];
                
                BOOL otherItemTypeInAbyss = NO;
                
                for (TMVItemView *itemViewObject in self.itemManager.interactingItemsArray)
                {
                    [itemViewObject updateDashViewOpacityForItemViewPosition];
                    
                    if (![itemView isEqual:itemViewObject]
                        && ![itemViewObject isKindOfClass:[itemView class]]
                        && itemViewObject.center.y >= crossingPoint)
                    {
                        otherItemTypeInAbyss = YES;
                    }
                }
                
                if (otherItemTypeInAbyss)
                {
                    self.theAbyss.type = AbyssParticleTypeAll;
                }
                else if ([itemView isKindOfClass:[TMVAlarmItemView class]])
                {
                    self.theAbyss.type = AbyssParticleTypeAlarm;
                }
                else
                {
                    self.theAbyss.type = AbyssParticleTypeTimer;
                }
                
                if (itemView.center.y >= crossingPoint)
                {
                    // If the abyss is active and one item gets deleted and another item is in the abyss range, then the abyss animates to its new location. If that other item starts panning we need to cancel the animation
                    [self.view.layer removeAllAnimations];
                    
                    CGPoint convertedPoint = [self.theAbyss.superview convertPoint:self.theAbyss.origin toView:nil];
                    
                    self.theAbyss.particleColor = [UIColor colorAbyssInterpolatingBetweenColor:self.atmosphere.derivedColor
                                                                                      andColor:self.atmosphere.currentColor
                                                                                withPercentage:convertedPoint.y / AppDelegate.window.height];
                    
                    //                    CGFloat difference = self.view.contentSize.height - self.view.height;
                    
                    CGFloat pointsToTravel = self.theAbyss.height * percentage;
                    
                    // If they just began panning the item which happens to be in the abyss frame we need to animate it to look good
                    if (panGesture.state == UIGestureRecognizerStateBegan)
                    {
                        [UIView animateWithDuration:0.3
                                              delay:0.0
                                            options:UIViewAnimationOptionBeginFromCurrentState
                                         animations:^{
                                             self.view.contentOffsetY = pointsToTravel;
                                         }
                                         completion:^(BOOL finished) {
                                             
                                         }];
                        
                    }
                    else
                    {
                        self.view.contentOffsetY = pointsToTravel;
                    }
                    
                    updateBlock(NO, YES);
                }
                else // Above of the abyss crossing point
                {
                    if (!CGPointEqualToPoint(self.view.contentOffset, CGPointZero))
                    {
                        self.view.contentOffset = CGPointZero;
                        [self deleteTheAbyss];
                    }
                    
                    updateBlock(NO, NO);
                }
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            [itemView hideDashViewAnimated:YES];
            
            // Here we can't check the abyss frame since his frame doesn't update since he's on the scrollView. So instead we make a rect to represent it.
            CGRect inteRection;
            inteRection.size = self.theAbyss.size;
            inteRection.origin = CGPointMake(0, self.view.height - self.view.contentOffsetY);
            
            NSArray *itemViews = [self.itemManager interactiveItemViewsNotActive];
            
            // If the itemView is the only item being interacted with we can just reset everything back to normal
            // Somehow if touching things just right the count will be 0 and the X will be stuck so we have to check if the count is 0
            if ((itemViews.count == 1
                 && [itemViews containsObject:itemView]) || itemViews.count == 0)
            {
                [self.settingsButton changeCubeToX:NO
                                          animated:YES];
                
                [UIView animateWithDuration:0.3
                                      delay:0.0
                                    options:UIViewAnimationOptionBeginFromCurrentState
                                 animations:^{
                                     self.view.contentOffsetY = 0.0f;
                                 }
                                 completion:^(BOOL finished) {
                                     
                                     [self deleteTheAbyss];
                                 }];
                
                if (CGRectContainsPoint(inteRection, center))
                {
                    updateBlock(YES, YES);
                }
                else
                {
                    updateBlock(YES, NO);
                }
            }
            // Since we have mulitple interactive items, when one itemView is let go in the abyss and another is still in the abyss we need to keep the abyss around.
            else if (itemViews.count > 1)
            {
                BOOL itemViewsInAbyssRange = NO;
                
                for (TMVItemView *itemViewObject in self.itemManager.interactingItemsArray)
                {
                    if (CGRectContainsPoint(inteRection, itemViewObject.center) && ![itemViewObject isEqual:itemView])
                    {
                        itemViewsInAbyssRange = YES;
                    }
                }
                
                if (CGRectContainsPoint(inteRection, center))
                {
                    updateBlock(YES, YES);
                }
                else
                {
                    updateBlock(YES, NO);
                }
                
                if (itemViewsInAbyssRange)
                {
                    TMVItemView *itemViewObject = [self.itemManager interactiveItemViewNotActiveNearestToBottomOfScreen];
                    
                    CGFloat difference = self.view.contentSize.height - self.view.height;
                    
                    CGFloat pointsToTravel = difference * [self percentageToAbyssForPoint:itemViewObject.center];
                    
                    [UIView animateWithDuration:0.3
                                          delay:0.0
                                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                                     animations:^{
                                         self.view.contentOffsetY = pointsToTravel;
                                     }
                                     completion:^(BOOL finished) {
                                         
                                     }];
                    
                }
                else
                {
                    // Animate the animatorView back to its normal offset then delete the abyss
                    [UIView animateWithDuration:0.3
                                          delay:0.0
                                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                                     animations:^{
                                         self.view.contentOffsetY = 0.0f;
                                     }
                                     completion:^(BOOL finished) {
                                         [self deleteTheAbyss];
                                     }];
                }
            }
            else
            {
                // You can get here by quickly stopping the time and swiping it into the abyss. At this point the item kind of escaped the apps frame so we just set the settingsbutton back to the default state and tell the block we are finished and the item should be deleted as if it was in the abyss
                [self.settingsButton setViewState:TMVSettingsButtonViewStateCube
                                         animated:YES];
                
                if (CGRectContainsPoint(inteRection, center))
                {
                    updateBlock(YES, YES);
                }
                else
                {
                    updateBlock(YES, NO);
                }
            }
        }
            break;
        default:
            break;
    }
}


#pragma mark - _______________________ItemManager Delegate_______________________
#pragma mark -

- (void)didAddItemView:(TMVItemView *)itemView
{
}

- (void)didRemoveAllItemViews
{
    [self showQuoteViewAnimated:YES];
}

- (void)didAddInteractiveItemView:(TMVItemView *)itemView
{
    
}

- (void)didRemoveAllInteractiveItemViews
{
    
}

- (void)didAddActiveItemView:(TMVItemView *)itemView
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)didRemoveAllActiveItemViews
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)didTapItem:(TMVTimerItemView *)itemView
       withGesture:(UITapGestureRecognizer *)gesture
{
    switch (itemView.state)
    {
        case TMVItemViewStateDefault:
            break;
        case TMVItemViewStatePoint:
            break;
        case TMVItemViewStateLocked:
        {
            [IAPManager buyProduct:IAPManager.productArray.firstObject];
        }
            break;
    }
}

- (void)didLongPressItem:(TMVTimerItemView *)itemView
             withGesture:(UILongPressGestureRecognizer *)gesture
{
    [self.statusBarView cancelPanningAndSnapToEdge];
    [self.settingsButton cancelTouch];
    
    itemView.editing = YES;
    
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        if ([itemView isKindOfClass:[TMVAlarmItemView class]])
        {
            self.alarmViewController = [[UIStoryboard storyboardWithName:@"iPhone_Storyboard"
                                                                  bundle:nil] instantiateViewControllerWithIdentifier:@"AlarmVC"];
            
            [self addChildViewController:self.alarmViewController];
            [self.view addSubview:self.alarmViewController.view];
            
            // Transformation start scale
            self.alarmViewController.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
            
            // Store original center point of the destination view
            CGPoint originalCenter = self.alarmViewController.view.center;
            
            // Set center to start point of the timer item
            self.alarmViewController.view.center = itemView.center;
            self.alarmViewController.itemCenter = itemView.center;
            
            [UIView animateWithDuration:0.5
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 self.alarmViewController.view.transform = CGAffineTransformMakeScale(1.0, 1.0);
                                 self.alarmViewController.view.center = originalCenter;
                                 
                                 itemView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                             }
                             completion:^(BOOL finished) {}];
        }
        else if ([itemView isKindOfClass:[TMVTimerItemView class]])
        {
            self.timerViewController = [[UIStoryboard storyboardWithName:@"iPhone_Storyboard"
                                                                  bundle:nil] instantiateViewControllerWithIdentifier:@"TimerVC"];
            self.timerViewController.itemView = itemView;
            
            [self addChildViewController:self.timerViewController];
            [self.view addSubview:self.timerViewController.view];
            
            // Transformation start scale
            self.timerViewController.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
            
            // Set center to start point of the timer item
            self.timerViewController.view.center = self.view.center;
            self.timerViewController.itemView.center = itemView.center;
            
            [self hideHUDAnimated:YES];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self viewTransiationAnimationWithItem:itemView];
            });
        }
    }
    
    [self setHUDUserInteraction:NO];
}

- (void)viewTransiationAnimationWithItem:(TMVItemView *)itemView
{
    CGPoint originalCenter = self.view.center;
    
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{
                         // Grow!
                         self.timerViewController.view.transform = CGAffineTransformMakeScale(1.0, 1.0);
                         self.timerViewController.view.center = originalCenter;
                         //
                         itemView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                         
                     }
                     completion:^(BOOL finished){
                     }];
}

#pragma mark - _______________________Atmosphere_______________________
#pragma mark -

- (void)configureAtmosphere
{
    if (!self.atmosphere)
    {
        self.atmosphere = [[TMVAtmosphere alloc] initWithFrame:AppDelegate.window.frame
                                                   andDelegate:self];
        
        [AppDelegate.window addSubview:self.atmosphere];
        [AppDelegate.window sendSubviewToBack:self.atmosphere];
    }
}

- (void)showHUDForAtmosphereDay
{
    [self hideQuoteViewAnimated:YES];
}

#pragma mark Delegate

- (void)didChangeAtmosphereToState:(TMVAtmosphereState)state
{
    switch (state)
    {
        case TMVAtmosphereStateDay:
        {
            [self showHUDForAtmosphereDay];
        }
            break;
        case TMVAtmosphereStateNight:
        {
        }
            break;
    }
}

- (void)didChangeAtmosphereToTopColor:(UIColor *)topColor
                       andBottomColor:(UIColor *)bottomColor
                            withState:(TMVAtmosphereState)state
{
    // Abyss
    // If the itemViewArray is at the max items then the abyss will take the night color. If not then it will be clear.
    NSInteger maxItemCount = AppContainer.itemManager.maxItemCount;
    self.theAbyss.particleColor = [UIColor colorAbyssInterpolatingBetweenColor:self.itemManager.itemViewArray.count == maxItemCount ? topColor : [UIColor clearColor]
                                                                      andColor:self.itemManager.itemViewArray.count == maxItemCount ? bottomColor : [UIColor clearColor]
                                                                withPercentage:self.theAbyss.origin.y / self.view.height];
    
    // If it is night, the HUD doesn't take the atmosphere color. Instead the HUD goes white
    if (state == TMVAtmosphereStateNight)
    {
        topColor = [UIColor whiteColor];
        bottomColor = [UIColor whiteColor];
    }
    
    // StatusBarView
    BOOL locationTop = self.statusBarView.center.y < self.view.halfHeight;
    [self.statusBarView updateColor:locationTop ? bottomColor : topColor
                      withAnimation:NO];
    
    // SettingsButton
    [self.settingsButton updateColor:topColor
                       withAnimation:NO];
}

#pragma mark - _______________________Gestures_______________________
#pragma mark -

- (void)configureGestures
{
    [self configureStartAllTapGesture];
    [self configureItemHintTapGesture];
    [self configureEdgePanGestures];
    [self configureBrightnessGesture];
}

#pragma mark Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer isKindOfClass:[TDMScreenEdgePanGestureRecognizer class]] || [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]])
    {
        CGPoint location = [touch locationInView:self.contentContainerView];
        
        if (CGRectContainsPoint(self.settingsButton.frame, location))
        {
            return NO;
        }
    }
    
    if (self.isSidePanning) //[gestureRecognizer isKindOfClass:[TDMScreenEdgePanGestureRecognizer class]] &&
    {
        return NO;
    }
    
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[TDMScreenEdgePanGestureRecognizer class]])
    {
        if (self.statusBarView.isDragging || self.settingsButton.isHighlighted || self.itemManager.interactingItemsArray.count > 0 || self.isSidePanning)
        {
            return NO;
        }
    }
    else if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]])
    {
        CGPoint tapPoint = [gestureRecognizer locationInView:gestureRecognizer.view];
        
        for (TMVItemView *itemView in self.itemManager.itemViewArray)
        {
            if (CGRectContainsPoint(itemView.frame, tapPoint))
            {
                return NO;
            }
        }
    }
    else if ([gestureRecognizer isEqual:self.brightnessGesture])
    {
        if (self.settingsButton.isHighlighted || !self.itemContainerView.userInteractionEnabled || self.itemManager.hasInteractiveItems)
        {
            return NO;
        }
    }
    
    if (([gestureRecognizer.view isEqual:self.statusBarView.clockLabelView] && [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
        || ([gestureRecognizer.view isEqual:self.statusBarView.groupView] && [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]))
    {
        if (self.isSidePanning)
        {
            return NO;
        }
        
        if ([gestureRecognizer.view isEqual:self.statusBarView.groupView] && self.statusBarView.volumeDownImageView.layer.opacity == 0.0f)
        {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[TDMScreenEdgePanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[TDMScreenEdgePanGestureRecognizer class]])
    {
        return YES;
    }
    
    return NO;
}

#pragma mark Brightness

- (void)configureBrightnessGesture
{
    if (kBrightnessGestureEnabled)
    {
        if (!self.brightnessGesture)
        {
            self.brightnessGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanForBrightness:)];
            self.brightnessGesture.delegate = self;
            self.brightnessGesture.minimumNumberOfTouches = 2;
            self.brightnessGesture.maximumNumberOfTouches = 2;
            
            [self.contentContainerView addGestureRecognizer:self.brightnessGesture];
        }
    }
}

- (void)didPanForBrightness:(UIPanGestureRecognizer *)panGesture
{
    CGFloat inset = 22.0f;
    CGFloat percentValuePerPoint = ((self.view.height - (inset * 2)) / 100);
    CGPoint locationInView = [panGesture locationInView:panGesture.view];
    
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            self.brightnessLastPosition = locationInView.y;
            
            [self setHUDUserInteraction:NO];
            [self.settingsButton changeCubeToSun:YES animated:YES];
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            [self setHUDUserInteraction:YES];
            [self.settingsButton changeCubeToSun:NO animated:YES];
        }
            break;
        default:
            break;
    }
    
    CGFloat percentage = ((locationInView.y - self.brightnessLastPosition) / percentValuePerPoint) / 100;
    
    [UIScreen mainScreen].brightness -= percentage;
    
    if (panGesture.state != UIGestureRecognizerStateEnded)
    {
        [self.settingsButton sunsetPercentage:1.0f - [UIScreen mainScreen].brightness];
    }
    
    self.brightnessLastPosition = locationInView.y;
}

#pragma mark Screen Edge Pan

- (TDMScreenEdgePanGestureRecognizer *)edgeGestureForEdges:(UIRectEdge)edges
{
    TDMScreenEdgePanGestureRecognizer *edgeGesture = [[TDMScreenEdgePanGestureRecognizer alloc] initWithTarget:self
                                                                                                        action:@selector(pannedFromEdge:)];
    edgeGesture.delegate = self;
    edgeGesture.edges = edges;
    
    return edgeGesture;
}

- (void)configureEdgePanGestures
{
    if (!self.edgeGestureLeft)
    {
        self.edgeGestureLeft = [self edgeGestureForEdges:UIRectEdgeLeft];
        [self.contentContainerView addGestureRecognizer:self.edgeGestureLeft];
    }
    
    if (!self.edgeGestureRight)
    {
        self.edgeGestureRight = [self edgeGestureForEdges:UIRectEdgeRight];
        [self.contentContainerView addGestureRecognizer:self.edgeGestureRight];
    }
}

- (void)pannedFromEdge:(TDMScreenEdgePanGestureRecognizer *)panGesture
{
    
    // Stop double edge pan
    if (panGesture.state == UIGestureRecognizerStateBegan)
    {
        self.sidePanning = YES;
        
        [self.itemManager snapHintOutForAllHintingItemViews]; // Hide any hinting items
        //        TDMScreenEdgePanGestureRecognizer *edgeGesture = [self edgeGestureForEdges:panGesture.edges];
        //        [self.edgeGestureArray addObject:edgeGesture];
        //
        //        [self.contentContainerView addGestureRecognizer:edgeGesture];
        
        CGPoint center = [(TDMScreenEdgePanGestureRecognizer *)panGesture locationInView:self.view];
        
        if (center.x > self.view.halfWidth && kAlarmsEnabled)
        {
            // If the pan is starting on the right side make an ALARM Item
            TMVAlarmItemView *itemView = [[TMVAlarmItemView alloc] initWithState:TMVItemViewStatePoint
                                                                   andPanGesture:panGesture];
            [self.itemManager setupItemView:itemView
                                    atPoint:center];
            
            panGesture.itemView = itemView;
        }
        else
        {
            // If the pan is starting on the left side make a TIMER Item
            TMVTimerItemView *itemView = [[TMVTimerItemView alloc] initWithState:TMVItemViewStatePoint
                                                                   andPanGesture:panGesture];
            
            [self.itemManager setupItemView:itemView
                                    atPoint:center];
            
            panGesture.itemView = itemView;
        }
    }
    
    if (panGesture.itemView)
    {
        [panGesture.itemView panFromEdgePanGesture:panGesture];
    }
    
    if (panGesture.state == UIGestureRecognizerStateEnded || panGesture.state == UIGestureRecognizerStateCancelled)
    {
        self.sidePanning = NO;
        //        if ([self.edgeGestureArray containsObject:panGesture])
        //        {
        //            [self.contentContainerView removeGestureRecognizer:panGesture];
        //            [self.edgeGestureArray removeObject:panGesture];
        //        }
    }
}

#pragma mark Tap Gestures

- (void)configureItemHintTapGesture
{
    if (!self.itemHintTapGesture)
    {
        self.itemHintTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(didTapAtmosphere:)];
        self.itemHintTapGesture.delegate = self;
        self.itemHintTapGesture.numberOfTapsRequired = 1;
        [self.itemHintTapGesture requireGestureRecognizerToFail:self.startAllTapGesture];
        
        [self.contentContainerView addGestureRecognizer:self.itemHintTapGesture];
    }
}

- (void)configureStartAllTapGesture
{
    if (!self.startAllTapGesture)
    {
        self.startAllTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(didTapAtmosphere:)];
        self.startAllTapGesture.delegate = self;
        self.startAllTapGesture.numberOfTapsRequired = 2;
        
        [self.contentContainerView addGestureRecognizer:self.startAllTapGesture];
    }
}

- (void)didTapAtmosphere:(UITapGestureRecognizer *)gesture
{
    if ([gesture isEqual:self.itemHintTapGesture])
    {
        if ([self.itemManager hasItems])
        {
            if (kSnapHintAnytime)
            {
                
            }
        }
        else
        {
            [self hideQuoteViewAnimated:YES];
            
            [self.itemManager showSnapHintForPoint:[gesture locationInView:gesture.view]
                             andShouldSnapForXAxis:NO
                                        completion:^{
                                            [self showQuoteViewAnimated:YES];
                                        }];
        }
    }
    else if ([gesture isEqual:self.startAllTapGesture])
    {
        if ([self.itemManager hasItems])
        {
            if ([self.itemManager allItemViewsAreActive])
            {
                [self.itemManager stopAllItems];
            }
            else
            {
                [self.itemManager startAllItems];
            }
        }
    }
}



#pragma mark Shake

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (self.childViewControllers.count > 0) return;
    
    if ([self.itemManager hasItems])
    {
        if (self.showingAlertView) return;
        
        self.showingAlertView = YES;
        
        if (motion == UIEventSubtypeMotionShake)
        {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            
            NSString *title = @"";
            
            NSMutableArray *buttonTitles = [@[] mutableCopy];
            
            if ([self.itemManager hasActiveItems])
            {
                if ([self.itemManager allActiveItemViews].count < self.itemManager.itemViewArray.count)
                {
                    title = NSLocalizedString(@"Remove Timers?", RemoveTimers);
                    [buttonTitles addObjectsFromArray:@[NSLocalizedString(@"All", All),
                                                        NSLocalizedString(@"Active", Active),
                                                        NSLocalizedString(@"Non-Active", NonActive)]];
                }
                else
                {
                    if ([self.itemManager allActiveItemViews].count > 1)
                    {
                        title = NSLocalizedString(@"Remove Active Timers?", RemoveActiveTimers);
                        [buttonTitles addObject:NSLocalizedString(@"Remove", Remove)];
                    }
                    else
                    {
                        title = NSLocalizedString(@"Remove Active Timer", RemoveActiveTimer);
                        [buttonTitles addObject:NSLocalizedString(@"Remove", Remove)];
                    }
                    
                }
            }
            else
            {
                if (self.itemManager.itemViewArray.count > 1)
                {
                    title = NSLocalizedString(@"Remove Timers?", RemoveTimers);
                    [buttonTitles addObject:NSLocalizedString(@"Remove", Remove)];
                }
                else
                {
                    title = NSLocalizedString(@"Remove Timers?", RemoveTimers);
                    [buttonTitles addObject:NSLocalizedString(@"Remove", Remove)];
                }
            }
            
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                            message:@""
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:nil];
            
            for (NSString *string in buttonTitles)
            {
                [alert addButtonWithTitle:string];
            }
            
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", Cancel)];
            [alert setCancelButtonIndex:buttonTitles.count];
            
            [alert show];
        }
    }
    else
    {
        [self changeQuoteAnimated:YES];
    }
    
    [self updateAllAppMotionEffects];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.numberOfButtons == 2)
    {
        if (buttonIndex == 0)
        {
            [self.itemManager kickoutAllItems];
            [NotificationManager clearAllScheduledNotifications];
        }
    }
    else if (alertView.numberOfButtons == 4)
    {
        if (buttonIndex == 0)
        {
            [self.itemManager kickoutAllItems];
            [NotificationManager clearAllScheduledNotifications];
        }
        else if (buttonIndex == 1)
        {
            [self.itemManager kickoutAllActiveItems];
        }
        else if (buttonIndex == 2)
        {
            [self.itemManager kickoutAllNonActiveItems];
        }
    }
    
    self.showingAlertView = NO;
    
    [self updateAllAppMotionEffects];
}

#pragma mark - _______________________Motion Effects_______________________
#pragma mark -

- (void)updateAllAppMotionEffects
{
    [self.atmosphere.galaxy updateMotionEffects];
    [self.quoteView updateMotionEffects];
    [self.itemManager updateMotionEffectsForAllItems];
}


#pragma mark - iAD -

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [self showAdWithCompletion:^{ }];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [self hideAdWithCompletion:^{ }];
}

- (void)showAdWithCompletion:(void (^)(void))completion
{
    if (self.isAdLoaded || IAPManager.isPurchased) return;
    
    self.adLoaded = YES;
    
    // Make sure ad doesn't get added above the settings or timer VC
    if (!self.adBanner.superview)
    {
        if (self.childViewControllers.count > 0)
        {
            [self.view insertSubview:self.adBanner
                        belowSubview:[self.childViewControllers.firstObject view]];
        }
        else
        {
            [self.view addSubview:self.adBanner];
        }
    }
    
    [self enableAdDynamics];
    
    // When the timerVC loads we hide the hud off screen, so we need to prevent the ad loading from snapping back our HUD.
    if (![self.childViewControllers containsObject:self.timerViewController])
    {
        [self.itemManager snapItemViewsToGridLock];
        
        [self.statusBarView snapContentsToCorners];
        
        [UIView animateWithDuration:0.5f
                              delay:0.0
             usingSpringWithDamping:0.9
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.adBanner.y = 0.0f;
                             
                             self.quoteView.centerY = self.adBanner.height + ((self.view.height - self.adBanner.height) / 2);
                         }
                         completion:^(BOOL finished) {
                             completion();
                         }];
    }
}

- (void)hideAdWithCompletion:(void (^)(void))completion
{
    if (!self.isAdLoaded) return;
    
    self.adLoaded = NO;
    
    [self.statusBarView snapContentsToCorners];
    
    [self.itemManager snapItemViewsToGridLock];
    
    [self disableAdDynamics];
    
    [UIView animateWithDuration:0.5f
                          delay:0.0
         usingSpringWithDamping:0.9
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.adBanner.y = !self.isShowingHUD ? -self.adBanner.height - self.statusBarView.height : -self.adBanner.frame.size.height;
                         
                         self.quoteView.centerY = self.view.centerY;
                     }
                     completion:^(BOOL finished) {
                         completion();
                     }];
}

- (void)enableAdDynamics
{
    if (!self.adBannerDynamicView)
    {
        self.adBannerDynamicView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.adBanner.width - 20, 1.0)];
        
        [self.itemManager.animatorView addSubview:self.adBannerDynamicView];
    }
    
    if (!self.adBannerDynamicOptions)
    {
        self.adBannerDynamicOptions = [[UIDynamicItemBehavior alloc] initWithItems:@[self.adBannerDynamicView]];
        self.adBannerDynamicOptions.allowsRotation = NO;
        self.adBannerDynamicOptions.resistance = 20.0f;
        self.adBannerDynamicOptions.density = 100;
        self.adBannerDynamicOptions.elasticity = 0.45f;
    }
    
    [self.itemManager.universalCollisionBehavior addItem:self.adBannerDynamicView];
    
    [self.itemManager.animator addBehavior:self.adBannerDynamicOptions];
    
    [self snapAdBannerDynamicViewToPoint:CGPointMake(self.adBanner.centerX, self.adBanner.height)];
}

- (void)disableAdDynamics
{
    if (self.adBannerDynamicView)
    {
        //        [self.itemManager.universalCollisionBehavior removeItem:self.adBannerDynamicView];
        //
        //        [self.itemManager.animator removeBehavior:self.adBannerDynamicOptions];
        
        [self snapAdBannerDynamicViewToPoint:CGPointMake(self.adBanner.centerX, 0)];
    }
}

- (void)snapAdBannerDynamicViewToPoint:(CGPoint)point
{
    [self.itemManager.animator removeBehavior:self.adBannerSnapBehavior];
    
    UISnapBehavior *snapBehavior = [[UISnapBehavior alloc] initWithItem:self.adBannerDynamicView snapToPoint:point];
    
    snapBehavior.damping = 0.7f;
    [self.itemManager.animator addBehavior:snapBehavior];
    
    self.adBannerSnapBehavior = snapBehavior;
}

@end

//
//  TMVSettingsContainerController.m
//  Timerverse
//
//  Created by Larry Ryan on 3/23/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVSettingsContainerController.h"
#import "TMVPaperView.h"
#import "LRScrollViewController.h"
#import "TMVAboutViewController.h"
#import "TMVNonInteractiveView.h"

#define IS_IPHONE_5 ([[UIScreen mainScreen] bounds].size.height >= 568)

static CGFloat const kDefaultViewOffset = -1.0f;
static CGFloat const kDismissThreshold = 110.0f;
static CGFloat const kDismissHandleHeight = 110.0f;
static BOOL const kDynamicsEnabled = NO;

@interface TMVSettingsContainerController () <LRScrollViewControllerDataSource, LRScrollViewControllerDelegate>

@property (nonatomic) LRScrollViewController *scrollViewController;

@property (nonatomic, readwrite) TMVSettingsViewController *settingsViewController;
@property (nonatomic) TMVAboutViewController *aboutViewController;

@property (nonatomic) TMVNonInteractiveView *quickDismissView;
@property (nonatomic) UIButton *arrowButton;

@property (nonatomic) BOOL allowScrolling;

@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) UICollisionBehavior *collision;
@property (nonatomic) UIGravityBehavior *gravity;
@property (nonatomic) UIDynamicItemBehavior *options;
@property (nonatomic) UIDynamicItemBehavior *flick;

@property (nonatomic) CGPoint lastVelocity;

@end

@implementation TMVSettingsContainerController

#pragma mark - Lifecycle

+ (instancetype)sharedSettingsContainer
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)loadView
{
    TMVPaperView *view = [[TMVPaperView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    view.translucentStyle = UIBarStyleBlack;
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    // The view is going to sit at -1 for its origin to hide the lightEffectLine. So we need to add that 1point to the views height.
    self.view.height += fabsf(kDefaultViewOffset) + 100.0f;
    
    // Have the settings spawn out of frame. We animate it in from the viewDidAppear.
    self.view.y = [UIScreen mainScreen].applicationFrame.size.height + 100.0f;
    
    // Line on top of view
    UIView *lightEffectLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 0.5)];
    lightEffectLine.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    [self.view addSubview:lightEffectLine];
    
    // Setup the pageViewController
	[self configureScrollViewController];
    [self configureQuickDismissView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self showSettingsAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Properties

- (TMVSettingsViewController *)settingsViewController
{
    if (!_settingsViewController)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"iPhone_Storyboard" bundle:nil];
        _settingsViewController = [storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
    }
    
    return _settingsViewController;
}

- (TMVAboutViewController *)aboutViewController
{
    if (!_aboutViewController)
    {
        _aboutViewController = [[TMVAboutViewController alloc] init];
    }
    
    return _aboutViewController;
}


#pragma mark - ScrollViewController

- (void)configureScrollViewController
{
    if (!self.scrollViewController)
    {
        self.scrollViewController = [[LRScrollViewController alloc] initWithPagingStyle:PagingStyleNone
                                                                      pagingOrientation:PagingOrientationVertical
                                                                         andInitialPage:0];
        self.scrollViewController.datasource = self;
        self.scrollViewController.delegate = self;
        
        [self addChildViewController:self.scrollViewController];
        [self.view addSubview:self.scrollViewController.view];
        [self.scrollViewController didMoveToParentViewController:self];
    }
}

#pragma mark DataSource

- (NSUInteger)numberOfViewControllersForScrollViewController:(LRScrollViewController *)scrollViewController
{
    return 2;
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index
                    forScrollViewController:(LRScrollViewController *)scrollViewController
{
    if (index == 0)
    {
        return self.settingsViewController;
    }
    else
    {
        return self.aboutViewController;
    }
}

#pragma mark Delegate

- (BOOL)scrollViewControllerAllowsScrolling:(LRScrollViewController *)scrollViewController
{
    return self.allowScrolling;
}

- (void)scrollViewController:(LRScrollViewController *)scrollViewController
          didStretchPageSide:(PageSide)stretchedSide
                    forIndex:(NSUInteger)index
{
    [self removeAllBehaviors];
    
    switch (stretchedSide)
    {
        case PageSideTop:
        {
            self.allowScrolling = NO;
            [self showQuickDismissView];
        }
            break;
        case PageSideBottom:
        {
            [self hideQuickDismissView];
        }
            break;
        default:
            break;
    }
}

- (void)scrollViewController:(LRScrollViewController *)scrollViewController
didBeginScrollingWithPercentage:(CGFloat)percentage
                 inDirection:(PanDirection)direction
       towardsViewController:(UIViewController *)destinationViewController
          fromViewController:(UIViewController *)sourceViewController
{
    if (direction == PanDirectionUp)
    {
        [self hideQuickDismissView];
    }
    
    [self removeAllBehaviors];
}

- (void)contentOffsetTransitionWhileDisabledScrolling:(CGFloat)contentOffset
{
    [self.view setYWithAdditive:-contentOffset];
    
    if (self.view.y < kDefaultViewOffset)
    {
        self.view.y = kDefaultViewOffset;
    }
    
    if (kDynamicsEnabled) [self.animator updateItemUsingCurrentState:self.view];
    
    self.lastVelocity = [self.scrollViewController.view.panGestureRecognizer velocityInView:self.view.superview];
}

- (void)scrollViewController:(LRScrollViewController *)scrollViewController
     didScrollWithPercentage:(CGFloat)percentage
                 inDirection:(PanDirection)direction
            toViewController:(UIViewController *)viewController
{
    self.allowScrolling = scrollViewController.view.contentOffsetY >= 0.0f && self.view.y <= kDefaultViewOffset;
    
    [self hideQuickDismissView];
}

- (void)scrollViewController:(LRScrollViewController *)scrollViewController
didEndScrollingToViewController:(UIViewController *)destinationViewController
{
    [self determineDismissal];
}

- (void)scrollViewController:(LRScrollViewController *)scrollViewController
didEndDeceleratingToViewController:(UIViewController *)viewController
{
    if ([viewController isEqual:scrollViewController.currentViewController] || [viewController isEqual:self.settingsViewController])
    {
        [self showQuickDismissView];
    }
}

#pragma mark - QuickDismissView

- (void)configureQuickDismissView
{
    if (!self.quickDismissView)
    {
        self.quickDismissView = [[TMVNonInteractiveView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.width, kDismissHandleHeight)];
        
        [self.view addSubview:self.quickDismissView];
        [self.view bringSubviewToFront:self.quickDismissView];
        
        // Add the pan gesture
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pannedQuickDismissView:)];
        [self.quickDismissView addGestureRecognizer:panGesture];
        
        // Add the arrow button
        self.arrowButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.arrowButton.frame = CGRectMake(0, 0, 44, 44);
        self.arrowButton.contentEdgeInsets = UIEdgeInsetsMake(12, 5, 12, 5);
        self.arrowButton.layer.opacity = 0.0f;
        self.arrowButton.center = CGPointMake(self.view.centerX, IS_IPHONE_5 ? 100.0f : 80.0f);
        self.arrowButton.tintColor = [UIColor whiteColor];
        [self.arrowButton setImage:[[UIImage imageNamed:@"thinkrArrow"]
                                    imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                          forState:UIControlStateNormal];
        self.arrowButton.transform = CGAffineTransformMakeRotation(M_PI_2 * 90);
        [self.arrowButton addTarget:self action:@selector(hideSettingsAnimated) forControlEvents:UIControlEventTouchUpInside];
        
        [self.quickDismissView addSubview:self.arrowButton];
    }
}

- (void)pannedQuickDismissView:(UIPanGestureRecognizer *)panGesture
{
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            self.scrollViewController.view.userInteractionEnabled = NO;
            
            [self removeAllBehaviors];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [panGesture translationInView:panGesture.view];
            
            self.view.y += translation.y;
            
            if (self.view.y < kDefaultViewOffset) self.view.y = kDefaultViewOffset;
            
            [panGesture setTranslation:CGPointZero
                                inView:self.view];
            
            if (kDynamicsEnabled) [self.animator updateItemUsingCurrentState:self.view];
            
            self.lastVelocity = [panGesture velocityInView:self.view.superview];
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            self.scrollViewController.view.userInteractionEnabled = YES;
            
            [self hideQuickDismissView];
            [self determineDismissal];
        }
            break;
        default:
            break;
    }
    
}

- (void)determineDismissal
{
    if (self.view.y < kDismissThreshold)
    {
        [self showSettingsAnimated:YES];
    }
    else
    {
        [self hideSettingsAnimated:YES];
    }
}

- (void)showQuickDismissView
{
    [self configureQuickDismissView];
    
    [UIView animateWithDuration:0.3f
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.arrowButton.layer.opacity = 1.0f;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

- (void)hideQuickDismissView
{
    [UIView animateWithDuration:0.3f
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.arrowButton.layer.opacity = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

#pragma mark - Show/Hide Animations

- (void)showSettingsAnimated:(BOOL)animated
{
    if (animated)
    {
        if (kDynamicsEnabled)
        {
            [self configureAllBehaviors];
        }
        else
        {
            [UIView animateWithDuration:0.8f
                                  delay:0.0f
                 usingSpringWithDamping:0.8f
                  initialSpringVelocity:1.0f
                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 self.view.y = kDefaultViewOffset;
                             }
                             completion:^(BOOL finished) {
                             }];
        }
    }
    else
    {
        self.view.y = kDefaultViewOffset;
    }
}

- (void)hideSettingsAnimated
{
    [self hideSettingsAnimated:YES];
}

- (void)hideSettingsAnimated:(BOOL)animated
{
    if (kDynamicsEnabled)
    {
        [self removeAllBehaviors];
    }
    
    if (animated)
    {
        [UIView animateWithDuration:0.8f
                              delay:0.0f
             usingSpringWithDamping:0.7f
              initialSpringVelocity:1.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.view.y = [UIScreen mainScreen].applicationFrame.size.height + 10.0f;
                         }
                         completion:^(BOOL finished) {
                             
                             self.allowScrolling = YES;
                             [self.scrollViewController moveToIndex:0 animated:NO];
                             [self hideQuickDismissView];
                             
                             [self willMoveToParentViewController:nil];
                             [self.view removeFromSuperview];
                             [self removeFromParentViewController];
                             
                             [self.delegate didDismissViewController:self];
                         }];
    }
    else
    {
        self.view.y = [UIScreen mainScreen].applicationFrame.size.height + 10.0f;
        
        [self.delegate didDismissViewController:self];
    }
}

#pragma mark - _______________________Dynamics_______________________
#pragma mark -

- (UIDynamicAnimator *)animator
{
    if (!_animator)
    {
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view.superview];
    }
    
    return _animator;
}

- (void)configureAllBehaviors
{
    if (!kDynamicsEnabled) return;
    
    [self.animator addBehavior:self.collision];
    [self.animator addBehavior:self.gravity];
    [self.animator addBehavior:self.options];
    [self.animator addBehavior:self.flick];
}

- (void)removeAllBehaviors
{
    if (!kDynamicsEnabled) return;
    
//    [self.animator removeAllBehaviors];
    
    [self.animator removeBehavior:self.gravity];
    [self.animator removeBehavior:self.options];
    [self.animator removeBehavior:self.gravity];
}

#pragma mark -

- (UICollisionBehavior *)collision
{
    if (!_collision)
    {
        _collision = [[UICollisionBehavior alloc] initWithItems:@[self.view]];
        [_collision addBoundaryWithIdentifier:@"topBoundary"
                                    fromPoint:CGPointMake(self.view.left, kDefaultViewOffset)
                                      toPoint:CGPointMake(self.view.right, kDefaultViewOffset)];
    }
    
    return _collision;
}

- (void)removeCollision
{
    if ([self.animator.behaviors containsObject:self.collision])
    {
        [self.animator removeBehavior:self.collision];
        self.collision = nil;
    }
}

#pragma mark -

- (UIGravityBehavior *)gravity
{
    if (!_gravity)
    {
        _gravity = [[UIGravityBehavior alloc] initWithItems:@[self.view]];
        _gravity.magnitude = 6.0f;
        _gravity.angle = 270 * M_PI / 180;
    }
    
    return _gravity;
}

- (void)removeGravity
{
    if ([self.animator.behaviors containsObject:self.gravity])
    {
        [self.animator removeBehavior:self.gravity];
        self.gravity = nil;
    }
}

#pragma mark -

- (UIDynamicItemBehavior *)options
{
    if (!_options)
    {
        _options = [[UIDynamicItemBehavior alloc] initWithItems:@[self.view]];
        _options.elasticity = 0.3f;
    }
    
    return _options;
}

- (void)removeOptions
{
    if ([self.animator.behaviors containsObject:self.options])
    {
        [self.animator removeBehavior:self.options];
        self.options = nil;
    }
}

#pragma mark -

- (UIDynamicItemBehavior *)flick
{
    if (![self.animator.behaviors containsObject:_flick])
    {
        if (!_flick)
        {
            _flick = [[UIDynamicItemBehavior alloc] initWithItems:@[self.view]];
            _flick.allowsRotation = NO;
            _flick.resistance = 0.7;
            _flick.friction = 0.7;
        }
        
        [self.animator addBehavior:_flick];
    }
    
    [_flick addLinearVelocity:CGPointMake(0.0f, self.lastVelocity.y)
                      forItem:self.view];
    
    return _flick;
}

- (void)removeFlick
{
    if ([AppContainer.itemManager.animator.behaviors containsObject:self.flick])
    {
        [AppContainer.itemManager.animator removeBehavior:self.flick];
    }
    
    self.flick = nil;
}


@end

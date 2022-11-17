//
//  LRScrollViewController.h
//  Timerverse
//
//  Created by Larry Ryan on 3/23/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

@import UIKit;

typedef NS_ENUM (NSUInteger, PagingStyle)
{
    PagingStyleNone = 0,
    PagingStyleSwoopDown,
    PagingStyleHoverOverRight,
    PagingStyleDynamicSprings
};

typedef NS_ENUM (NSUInteger, PagingOrientation)
{
    PagingOrientationHorizontal = 0,
    PagingOrientationVertical
};

typedef NS_ENUM (NSUInteger, PageSide)
{
    PageSideTop = 0,
    PageSideRight,
    PageSideBottom,
    PageSideLeft,
    PageSideMiddle
};

typedef NS_ENUM (NSUInteger, TransitionAnimation)
{
    TransitionAnimationNone = 0,
    TransitionAnimationScale,
    TransitionAnimationFade,
    TransitionAnimationScaleFade
};

typedef NS_ENUM (NSUInteger, PanDirection)
{
    PanDirectionUp = 0,
    PanDirectionRight,
    PanDirectionDown,
    PanDirectionLeft
};


NSString * NSStringFromPagingStyle(PagingStyle Style);
NSString * NSStringFromPagingOrientation(PagingOrientation orientation);
NSString * NSStringFromPageSide(PageSide side);
NSString * NSStringFromTransitionAnimation(TransitionAnimation animation);
NSString * NSStringFromPanDirection(PanDirection direction);

@protocol LRScrollViewControllerDataSource, LRScrollViewControllerDelegate;

@interface LRScrollViewController : UIViewController

- (instancetype)initWithPagingStyle:(PagingStyle)pagingStyle
                  pagingOrientation:(PagingOrientation)orientation
                     andInitialPage:(NSUInteger)page;

// Delegates
@property (nonatomic, weak) id <LRScrollViewControllerDataSource> datasource;
@property (nonatomic, weak) id <LRScrollViewControllerDelegate> delegate;

// Transition Properties
@property (nonatomic) PagingStyle pagingStyle;
@property (nonatomic) PagingOrientation pagingOrientation;
@property (nonatomic) TransitionAnimation transitionAnimation;

// ScrollView Properties
@property (nonatomic) UIScrollView *view;
@property (nonatomic, readonly, getter = isDragging) BOOL dragging;
@property (nonatomic, readonly, getter = isHidden) BOOL hidden;
@property (nonatomic) NSUInteger initialIndex;
@property (nonatomic, readonly) NSUInteger currentIndex;
@property (nonatomic, readonly, weak) UIViewController *currentViewController;

// If the margin is 0 then the scrollView's PagingEnabled is set to YES. If the margin is > 0 then we have to resort to the targetedContentOffset method
@property (nonatomic) CGFloat margin;

//
- (NSUInteger)numberOfViewControllers;

- (void)moveToIndex:(NSUInteger)index
           animated:(BOOL)animated;

// Transition methods
- (void)showWithAnimation:(TransitionAnimation)transitionAnimation;
- (void)hideWithAnimation:(TransitionAnimation)transitionAnimation;

// Memory Management
- (void)removeViewControllersAtRange:(NSRange)range;
- (void)removeViewControllersAtRanges:(NSArray *)ranges; // Store each range in a NSValue to give to array
- (void)restoreViewControllersAtRange:(NSRange)range;
- (void)restoreViewControllersAtRanges:(NSArray *)ranges; // Store each range in a NSValue to give to array

@end

#pragma mark Delegate
@protocol LRScrollViewControllerDelegate <NSObject>

@optional;

// Forwarded Protocols
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset NS_AVAILABLE_IOS(5_0);

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate;

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView;

// Custom Protocols

- (void)contentOffsetTransitionWhileDisabledScrolling:(CGFloat)contentOffset;

- (BOOL)scrollViewControllerAllowsScrolling:(LRScrollViewController *)scrollViewController;

- (void)scrollViewController:(LRScrollViewController*)scrollViewController
              didMoveToIndex:(NSUInteger)index;

- (void)scrollViewController:(LRScrollViewController *)scrollViewController
          didStretchPageSide:(PageSide)stretchedSide
                    forIndex:(NSUInteger)index;

// User Scrolling
- (void)scrollViewController:(LRScrollViewController *)scrollViewController
didBeginScrollingWithPercentage:(CGFloat)percentage
                 inDirection:(PanDirection)direction
       towardsViewController:(UIViewController *)destinationViewController
          fromViewController:(UIViewController *)sourceViewController;


- (void)scrollViewController:(LRScrollViewController *)scrollViewController
     didScrollWithPercentage:(CGFloat)percentage
                 inDirection:(PanDirection)direction
            toViewController:(UIViewController *)viewController;

- (void)scrollViewController:(LRScrollViewController *)scrollViewController
didEndScrollingToViewController:(UIViewController *)destinationViewController;

// Decelerating
- (void)scrollViewController:(LRScrollViewController *)scrollViewController
willBeginDeceleratingToViewController:(UIViewController *)destinationViewController;

- (void)scrollViewController:(LRScrollViewController *)scrollViewController
 didDecelerateWithPercentage:(CGFloat)percentage
                 inDirection:(PanDirection)direction
            toViewController:(UIViewController *)viewController;

- (void)scrollViewController:(LRScrollViewController *)scrollViewController
didEndDeceleratingToViewController:(UIViewController *)viewController;


@end

#pragma mark DataSource
@protocol LRScrollViewControllerDataSource <NSObject>

- (NSUInteger)numberOfViewControllersForScrollViewController:(LRScrollViewController *)scrollViewController;

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index
                    forScrollViewController:(LRScrollViewController *)scrollViewController;

@end

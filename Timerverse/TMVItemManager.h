//
//  TMVItemManager.h
//  Timerverse
//
//  Created by Larry Ryan on 1/11/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TMVItemView.h"
#import "TMVTimerItemView.h"
#import "TMVAlarmItemView.h"

#import "TMVKickOutBehavior.h"

typedef NS_ENUM (NSUInteger, TMVItemManagerLayout)
{
    TMVItemManagerLayoutGridLock = 0,
    TMVItemManagerLayoutDynamics
};

typedef NS_ENUM (NSUInteger, TMVItemManagerSortingMode)
{
    TMVItemManagerSortingModeAuto,
    TMVItemManagerSortingModeManual,
    TMVItemManagerSortingModeManualOnDrop
};

@protocol TMVItemManagerDataSource, TMVItemManagerDelegate;

@interface TMVItemManager : NSObject <UIGestureRecognizerDelegate, TMVItemViewDelegate>

@property (nonatomic, weak) id <TMVItemManagerDataSource> dataSource;
@property (nonatomic, weak) id <TMVItemManagerDelegate> delegate;

@property (nonatomic, readonly) NSInteger maxItemCount;
@property (nonatomic, readonly) NSInteger maxDemoItemCount;
@property (nonatomic, readonly) CGFloat minimumVelocityForFlickBeahavior;
@property (nonatomic, readonly) BOOL itemMotionEffectEnabled;
@property (nonatomic, readonly) BOOL itemViewCanCopyColor;
@property (nonatomic, readonly) BOOL dynamicSnappingEnabled;
@property (nonatomic, readonly) BOOL snapWithInteractionEnabled;
@property (nonatomic, readonly) BOOL useEvenMarginForGridLock;

@property (nonatomic) TMVItemManagerLayout layout;
@property (nonatomic) TMVItemManagerSortingMode sortingMode;

@property (nonatomic, readonly) NSArray *itemViewArray;
@property (nonatomic, readonly) NSMutableArray *activeTimerItemsArray;
@property (nonatomic, readonly) NSMutableArray *activeStopWatchItemsArray;
@property (nonatomic, readonly) NSMutableArray *interactingItemsArray;

@property (nonatomic, readonly) UIDynamicAnimator *animator;
@property (nonatomic, weak) UIView *animatorView; // AppContainer itemContainerView
@property (nonatomic, readonly) UICollisionBehavior *universalCollisionBehavior; // Public to support Ad dyanmics

@property (nonatomic, readonly, getter = isShowingHint) BOOL showingHint;
@property (nonatomic, getter = isLongPressingItem) BOOL longPressingItem;

@property (nonatomic, readonly, weak) TMVItemView *itemViewBeingEdited;

#pragma mark - Lifecylce

- (instancetype)initWithAnimatorView:(UIView *)animatorView
                          dataSource:(id <TMVItemManagerDataSource>)dataSource
                         andDelegate:(id <TMVItemManagerDelegate>)delegate;

- (void)snapItemViewsToGridLock;

#pragma mark - ItemView Methods
- (void)startAllItems;
- (void)stopAllItems;
- (void)updateMotionEffectsForAllItems;
- (void)kickoutAllItems;
- (void)kickoutAllActiveItems;
- (void)kickoutAllNonActiveItems;
- (void)kickoutItemView:(TMVItemView *)itemView
        withKickOutType:(TMVKickOutType)type;

- (void)cancelGesturesForAllItems;

- (void)showItemsAnimated:(BOOL)animated;
- (void)hideItemsAnimated:(BOOL)animated;

#pragma mark - ItemView Management
- (void)setupItemView:(TMVItemView *)itemView
              atPoint:(CGPoint)point;
- (void)addItemView:(TMVItemView *)itemView;
- (void)removeItemView:(TMVItemView *)itemView;
// Used by kickoutbehavior
- (void)removeItemViewFromItemViewArray:(TMVItemView *)itemView;
- (void)removeItemViewFromInteractiveTimerItemsArray:(TMVItemView *)itemView;

#pragma mark - Dynamic Behaviors

#pragma mark Flick Behavior
- (void)addItemViewToUniversalFlickBehavior:(TMVItemView *)itemView
                               withVelocity:(CGPoint)velocity;
- (void)removeItemViewFromUniversalFlickBehavior:(TMVItemView *)itemView;

#pragma mark Options Behavior
- (void)addItemViewToUniversalOptionsBehavior:(TMVItemView *)itemView;
- (void)removeItemViewFromUniversalOptionsBehavior:(TMVItemView *)itemView;

#pragma mark Collision Behavior
- (void)addItemViewToUniversalCollisionBehavior:(TMVItemView *)itemView;
- (void)addBoundaryToUniversalCollisionBehaviorWithIdentifier:(NSString *)identifier
                                                      forPath:(UIBezierPath *)path;
- (void)removeItemViewFromUniversalCollisionBehavior:(TMVItemView *)itemView;

#pragma mark Gravity Behavior
// Used by the kickout behavior
- (void)addItemViewToUniversalGravityBehavior:(TMVItemView *)itemView;
- (void)removeItemViewFromUniversalGravityBehavior:(TMVItemView *)itemView;

- (void)beginObservingColorForItemView:(TMVItemView *)itemView;
- (void)stopObservingColorForItemView:(TMVItemView *)itemView;


#pragma mark - Hint
- (void)showSnapHintForRandomPoint;
- (void)showSnapHintForPoint:(CGPoint)point
       andShouldSnapForXAxis:(BOOL)xAxisSnapping
                  completion:(void (^)(void))hintCompletion;
- (void)snapHintOutForAllHintingItemViews;


#pragma mark - Item Helpers
- (BOOL)hasInteractiveItems;
- (BOOL)hasItems;
- (BOOL)hasActiveItems;
- (BOOL)hasActiveTimerItems;
- (BOOL)hasActiveStopWatchItems;
- (BOOL)allItemViewsAreActive;
- (BOOL)hasHintingItems;

// Data
- (NSArray *)allItems;
- (NSArray *)allCounterItems;
- (NSArray *)allTimerItems;
- (NSArray *)allAlarmItems;

- (NSArray *)allActiveItemViews;
- (NSArray *)interactiveItemViewsNotActive;
- (TMVItemView *)interactiveItemViewNearestToBottomOfScreen;
- (TMVItemView *)interactiveItemViewNotActiveNearestToBottomOfScreen;

- (UIColor *)colorFromActiveItemWithLeastTime;
- (UIColor *)colorForItemViewPointWithAbyssInset:(TMVItemView *)itemView;
- (UIColor *)colorFromItemWithLeastTime;
- (NSArray *)colorsFromItemViews:(NSArray *)itemViews;

@end


@protocol TMVItemManagerDataSource <NSObject>

@end


@protocol TMVItemManagerDelegate <NSObject>

@optional

#pragma mark - ItemViewArray
- (void)didAddItemView:(TMVItemView *)itemView;
- (void)willRemoveItemView:(TMVItemView *)itemView;
- (void)didRemoveAllItemViews;


#pragma mark - Active ItemView Arrays

#pragma mark Timer & StopWatch
- (void)didAddActiveItemView:(TMVItemView *)itemView;
- (void)didRemoveActiveItemView:(TMVItemView *)itemView;
- (void)didRemoveAllActiveItemViews;

#pragma mark Timer
- (void)didAddActiveTimerItemView:(TMVItemView *)itemView;
- (void)didRemoveActiveTimerItemView:(TMVItemView *)itemView;
- (void)didRemoveAllActiveTimerItemViews;

#pragma mark StopWatch
- (void)didAddActiveStopWatchItemView:(TMVItemView *)itemView;
- (void)didRemoveActiveStopWatchItemView:(TMVItemView *)itemView;
- (void)didRemoveAllActiveStopWatchItemViews;


#pragma mark - Interactive ItemViews
- (void)didAddInteractiveItemView:(TMVItemView *)itemView;
- (void)didRemoveInteractiveItemView:(TMVItemView *)itemView;
- (void)didRemoveAllInteractiveItemViews;


#pragma mark - Gestures
- (void)didTapItem:(TMVTimerItemView *)itemView
       withGesture:(UITapGestureRecognizer *)gesture;

- (void)didLongPressItem:(TMVTimerItemView *)item
             withGesture:(UILongPressGestureRecognizer *)gesture;

- (void)didPanItem:(TMVTimerItemView *)item
       withGesture:(UIPanGestureRecognizer *)panGesture;

@end

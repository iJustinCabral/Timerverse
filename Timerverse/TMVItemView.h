//
//  TMVItem.h
//  Timerverse
//
//  Created by Larry Ryan on 1/11/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TMVTimerItem.h"
#import "TMVAlarmItem.h"

#import "FBShimmeringLayer.h"
#import "TMVSoundWave.h"
#import "TMVCounterLabel.h"
#import "TMVDashView.h"


typedef NS_ENUM (NSUInteger, TMVItemViewState)
{
    TMVItemViewStateDefault, // The itemView is normal, showing time, glyph, name, ect
    TMVItemViewStatePoint, // The itemView is a small dot, seen when dragged out from the screen edge or dragged to the abyss
    TMVItemViewStateLocked // When all items are not unlocked by IAP, the extra itemViews will be locked
};

static CGFloat const kStrokeWidth = 2.0f; // Stroke width of the soundWave
static CGFloat const kItemViewSize = 100.0f + kStrokeWidth;

NSString * NSStringFromItemViewState(TMVItemViewState layout);

@protocol TMVItemViewDelegate;

@interface TMVItemView : UIView

@property (nonatomic, weak) id <TMVItemViewDelegate> delegate;

@property (nonatomic) Item *item; // The managed object for the item
@property (nonatomic) TMVItemViewState state; // The current state the item is in, see enum
@property (nonatomic) NSUInteger gridLockIndex;
@property (nonatomic) UIView *containerView; // Hold the contentView, backgroundView
@property (nonatomic) UIColor *apparentColor; // The current color. When updated it will change the backgroundView's color and the soundWave color
@property (nonatomic, getter = isEditing) BOOL editing; // When editing the itemView and the TimerViewController

@property (nonatomic, readonly) TMVDashView *dashView; // Shows a dashed patterned stroke on the ItemManager.animatorView when the items gridLockIndex is.
@property (nonatomic, readonly) UIImageView *repeatImageView;
@property (nonatomic, readonly) TMVCounterLabel *counterLabel;
@property (nonatomic, readonly) UILabel *nameLabel;
@property (nonatomic, readonly) UILabel *detailLabel;
@property (nonatomic, readonly) UIImageView *glyphImageView;

@property (nonatomic, readonly) TMVSoundWave *soundWave;

@property (nonatomic, readonly, getter = isDragging) BOOL dragging;
@property (nonatomic, readonly, getter = isPulsing) BOOL pulsing;
@property (nonatomic, getter = isKickingOut) BOOL kickingOut;

+ (instancetype)testItem;

//- (instancetype)initWithColor:(UIColor *)color;
- (instancetype)initWithState:(TMVItemViewState)state;
- (instancetype)initWithState:(TMVItemViewState)state
                      andItem:(Item *)item;
- (instancetype)initWithState:(TMVItemViewState)state
                andPanGesture:(UIPanGestureRecognizer *)panGesture;

- (void)panFromEdgePanGesture:(UIPanGestureRecognizer *)panGesture;
- (void)cancelGestures;

- (void)showDashViewAtPoint:(CGPoint)point;
- (void)hideDashViewAnimated:(BOOL)animated;
- (void)hideDashViewAnimated:(BOOL)animated
              withCompletion:(void (^)(void))completion;
- (void)snapDashToPoint:(CGPoint)point;
- (void)updateDashViewOpacityForItemViewPosition;
- (void)removeDashViewAnimated:(BOOL)animated;

- (void)showRepeatImageViewAnimated:(BOOL)animated;
- (void)hideRepeatImageViewAnimated:(BOOL)animated;

- (CGSize)currentScale;
- (CGSize)sizeForCurrentScale;

- (void)showActivityIndicatorAnimated:(BOOL)animated;
- (void)hideActivityIndicatorAnimated:(BOOL)animated;

- (void)setState:(TMVItemViewState)state
        animated:(BOOL)animated;

- (void)interactiveTransitionToAbyssWithPercentage:(CGFloat)percentage;

- (void)fixOriginForBounds;

- (void)addFloatingBehavior;

- (void)observeColor;

- (void)removeAllBehaviorsExceptFlick;
- (void)removeAllBehaviors;

- (void)startPulsing;
- (void)stopPulsing;

- (void)updateTimeFromStartDate;

- (void)sendToWindow;

#pragma mark - Label

- (void)startCounting;
- (void)stopCounting;

- (void)setTimeHours:(NSUInteger)hours
             minutes:(NSUInteger)minutes
             seconds:(NSUInteger)seconds;

#pragma mark - Dynamic Behaviors Methods
- (void)beginObservingAbyss;
- (void)stopObservingAbyss;

- (void)snapToPoint:(CGPoint)point;
- (void)snapToPoint:(CGPoint)point
     withCompletion:(void (^)(void))completion;

#pragma mark - Motion Effect
- (void)updateMotionEffectWithOffset:(NSUInteger)offset;

@end

#pragma mark - Delegate

@protocol TMVItemViewDelegate <NSObject>
@optional

// States
- (void)willChangeFromState:(TMVItemViewState)sourceState
                   toState:(TMVItemViewState)destinationState;
- (void)didChangeFromState:(TMVItemViewState)sourceState
                   toState:(TMVItemViewState)destinationState;

// Timer
- (void)didStartCountItem:(TMVItemView *)itemView;
- (void)didPauseCountItem:(TMVItemView *)itemView;
- (void)didResumeCountItem:(TMVItemView *)itemView;
- (void)didResetCountItem:(TMVItemView *)itemView;
- (void)didStopCountItem:(TMVItemView *)itemView;
- (void)didCountItem:(TMVItemView *)itemView;

// Grid Lock
- (void)didUpdateGridLockIndexForItemView:(TMVItemView *)itemView;

// Gestures
- (void)didTapItem:(TMVItemView *)itemView
       withGesture:(UITapGestureRecognizer *)tapGesture;
- (void)didLongPressItem:(TMVItemView *)itemView
             withGesture:(UILongPressGestureRecognizer *)longPressGesture;

- (void)willPanItem:(TMVItemView *)itemView
        withGesture:(UIPanGestureRecognizer *)panGesture;
- (void)didPanItem:(TMVItemView *)itemView
       withGesture:(UIPanGestureRecognizer *)panGesture;

// Events
- (void)didTouchItem:(TMVItemView *)itemView;
- (void)didEndTouchingItem:(TMVItemView *)itemView;

// Dynamics
- (void)itemDidLeaveBounds:(TMVItemView *)itemView;

// Editing
- (void)didBeginEditingItemView:(TMVItemView *)itemView;
- (void)didEndEditingItemView:(TMVItemView *)itemView;

@end
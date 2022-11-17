//
//  TMVStatusBarView.h
//  Timerverse
//
//  Created by Larry Ryan on 2/9/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVNonInteractiveView.h"

#import "TMVClockLabel.h"
#import "TMVStatusBarGroupView.h"
#import "TMVStatusBarLockView.h"

@protocol TMVStatusBarViewDelegate;

@interface TMVStatusBarView : TMVNonInteractiveView

@property (nonatomic, weak) id <TMVStatusBarViewDelegate> delegate;

@property (nonatomic, readonly, getter = isDragging) BOOL dragging;

@property (nonatomic, readonly) TMVStatusBarGroupView *groupView;
@property (nonatomic, readonly) UIImageView *silentImageView;
@property (nonatomic, readonly) UIImageView *volumeDownImageView;
@property (nonatomic, readonly) TMVStatusBarLockView *lockView;
@property (nonatomic, readonly) TMVClockLabel *clockLabelView;

- (void)fixOriginForBounds;
- (void)cancelPanningAndSnapToEdge;

- (UIRectEdge)currentEdge;

- (void)snapContentsToCorners;

- (void)updateColor:(UIColor *)color
      withAnimation:(BOOL)animation;

- (void)showAnimated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated;

- (void)checkVolumeAndMuteStateAnimated:(BOOL)animated;

@end

@protocol TMVStatusBarViewDelegate <NSObject>

- (BOOL)shouldUpdateExclusionPaths;
- (void)didUpdateExclusionPaths:(NSArray *)exclusionPaths;

@end

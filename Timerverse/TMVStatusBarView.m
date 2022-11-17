//
//  TMVStatusBarView.m
//  Timerverse
//
//  Created by Larry Ryan on 2/9/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVStatusBarView.h"
#import "TMVVolumeDetector.h"

@interface TMVStatusBarView () <UIGestureRecognizerDelegate, TMVStatusBarGroupViewDatasource, TMVStatusBarGroupViewDelegate, TMVVolumeDetecorDelegate>

@property (nonatomic, readwrite) UIImageView *silentImageView;
@property (nonatomic, readwrite) UIImageView *volumeDownImageView;
@property (nonatomic, readwrite) TMVStatusBarLockView *lockView;
@property (nonatomic, readwrite) TMVClockLabel *clockLabelView;
@property (nonatomic, readwrite) TMVStatusBarGroupView *groupView;

@property (nonatomic, weak) UIView *lastPannedView;

@property (nonatomic, readwrite, getter = isDragging) BOOL dragging;

@end

@implementation TMVStatusBarView


#pragma mark - Lifecycle -

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        CGRect bounds = [UIScreen mainScreen].bounds;
        bounds.size.height = 39;
        self.frame = bounds;
        
        switch (DataManager.settings.clockCorner.integerValue)
        {
            case UIRectCornerTopLeft:
            case UIRectCornerTopRight:
            {
                self.centerY = self.halfHeight;
            }
                break;
            case UIRectCornerBottomLeft:
            case UIRectCornerBottomRight:
            {
                self.centerY = [UIScreen mainScreen].bounds.size.height - self.halfHeight;
            }
                break;
            default:
            {
                self.centerY = self.halfHeight;
            }
                break;
        }
        
        [self configureClock];
        
        VolumeDetector.delegate = self;
        
        [self configureGroupView];
    }
    
    return self;
}


#pragma mark - VolumeDetector Delegate -

- (void)didChangeVolumeToValue:(CGFloat)value
{
    if (value == 0)
    {
        [self.groupView showItemAtIndex:1 animated:YES];
    }
    else
    {
        [self.groupView hideItemAtIndex:1 animated:YES];
    }
}


#pragma mark - Properties -

#pragma mark Setters

- (void)updateColor:(UIColor *)color
{
    [self updateColor:color
        withAnimation:NO];
}

- (void)updateColor:(UIColor *)color
      withAnimation:(BOOL)animation
{
    CGFloat yPercentage = [self percentageTravelledInSuperviewForView:self
                                                               filter:NO].y;
    
    switch (AppContainer.atmosphere.state)
    {
        case TMVAtmosphereStateDay:
        {
            color = [UIColor colorAbyssInterpolatingBetweenColor:AppContainer.atmosphere.currentColor
                                                                  andColor:AppContainer.atmosphere.derivedColor
                                                            withPercentage:1.0f - yPercentage];
        }
            break;
        case TMVAtmosphereStateNight:
        {
            color = [UIColor whiteColor];
        }
            break;
    }
    
    [self.clockLabelView updateColor:color
                       withAnimation:animation];
    
    [self.lockView updateColor:color
                 withAnimation:animation];
    
    if (animation)
    {
        [UIView animateWithDuration:AppContainer.atmosphere.transitionDuration
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.silentImageView.tintColor = color;
                             self.volumeDownImageView.tintColor = color;
                             
                         }
                         completion:^(BOOL finished) {}];
    }
    else
    {
        self.silentImageView.tintColor = color;
        self.volumeDownImageView.tintColor = color;
    }
}

#pragma mark  Getters

- (UIImageView *)silentImageView
{
    if (!_silentImageView)
    {
        _silentImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        _silentImageView.image = [[UIImage imageNamed:@"muteSwitch"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _silentImageView.tintColor = AppContainer.atmosphere.elementColorTop;
        _silentImageView.layer.opacity = 1.0f;
    }
    
    return _silentImageView;
}

- (UIImageView *)volumeDownImageView
{
    if (!_volumeDownImageView)
    {
        _volumeDownImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        _volumeDownImageView.image = [[UIImage imageNamed:@"volumeDown"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _volumeDownImageView.tintColor = AppContainer.atmosphere.elementColorTop;
        _volumeDownImageView.layer.opacity = 1.0f;
    }
    
    return _volumeDownImageView;
}

- (TMVStatusBarLockView *)lockView
{
    if (!_lockView)
    {
        // Add the arrow button
        _lockView = [[TMVStatusBarLockView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        _lockView.layer.opacity = 1.0f;
        _lockView.tintColor = AppContainer.atmosphere.elementColorTop;
    }
    
    return _lockView;
}


#pragma mark - Clock Label -

- (void)configureClock
{
    if (!self.clockLabelView)
    {
        self.clockLabelView = [TMVClockLabel new];
        [self addSubview:self.clockLabelView];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(didPanStatusItem:)];
        panGesture.delegate = AppContainer;
        [self.clockLabelView addGestureRecognizer:panGesture];
    }
}


#pragma mark - GroupView -

- (void)configureGroupView
{
    if (!self.groupView)
    {
        self.groupView = [[TMVStatusBarGroupView alloc] initWithFrame:CGRectMake(0, 0, 50, self.height)];
        self.groupView.dataSource = self;
        self.groupView.delegate = self;
        self.groupView.centerX = self.clockLabelView.centerX < self.halfWidth ? self.width - self.groupView.halfWidth : self.groupView.halfWidth;
        
        [self addSubview:self.groupView];
        
        // Gesture Recognizer
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(didPanStatusItem:)];
        panGesture.delegate = AppContainer;
        [self.groupView addGestureRecognizer:panGesture];
        
        [self checkVolumeAndMuteStateAnimated:NO];
        
        if (!IAPManager.isPurchased) [self.groupView showItemAtIndex:2
                                                            animated:NO];
    }
}

- (NSUInteger)numberOfItemsForGroupView:(TMVStatusBarGroupView *)groupView
{
    return IAPManager.isPurchased ? 2 : 3;
}

- (UIView *)groupView:(TMVStatusBarGroupView *)groupView itemForIndex:(NSUInteger)index
{
    switch (index)
    {
        case 0:
        {
            return self.silentImageView;
        }
            break;
        case 1:
        {
            return self.volumeDownImageView;
        }
            break;
        case 2:
        {
            return self.lockView;
        }
            break;
    }
    
    return nil;
}


#pragma mark - Methods -

- (void)checkVolumeAndMuteStateAnimated:(BOOL)animated
{
    [SoundManager isSystemMuted:^(BOOL muted) {
        
        if (muted)
        {
            [self.groupView showItemAtIndex:0 animated:animated];
        }
        else
        {
            [self.groupView hideItemAtIndex:0 animated:animated];
        }
        
    }];
    
    [SoundManager isSystemVolumeDown:^(BOOL volumeDown) {
        
        if (volumeDown)
        {
            [self.groupView showItemAtIndex:1 animated:animated];
        }
        else
        {
            [self.groupView hideItemAtIndex:1 animated:animated];
        }
        
    }];
}

#pragma mark Show/Hide

- (void)showAnimated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.6
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self showAnimated:NO];
                         }
                         completion:^(BOOL finished) {}];
        
    }
    else
    {
        if (self.center.y < self.superview.halfHeight)
        {
            self.centerY = AppContainer.isAdLoaded ? self.halfHeight + AppContainer.adBanner.height : self.halfHeight;
        }
        else
        {
            self.centerY = self.superview.height - self.halfHeight;
        }
    }
}

- (void)hideAnimated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.6
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self hideAnimated:NO];
                         }
                         completion:^(BOOL finished) {}];
        
    }
    else
    {
        self.centerY = self.center.y < self.superview.halfHeight ? -self.halfHeight : self.superview.height + self.halfHeight;
    }
}

#pragma mark Snapping

- (void)snapToCornerForView:(UIView *)view
{
    CGFloat xOffset = view.halfWidth;
    CGFloat yOffset = view.halfHeight;
    
    CGPoint snappingPoint = CGPointZero;
    
    snappingPoint.x = view.center.x < view.superview.halfWidth ? xOffset : view.superview.width - xOffset;
    snappingPoint.y = view.center.y < view.superview.halfHeight ? yOffset : view.superview.height - yOffset;
    
    if ([view isEqual:self])
    {
        if (AppContainer.isAdLoaded && view.center.y < view.superview.halfHeight)
        {
            snappingPoint.y += AppContainer.adBanner.height;
        }
    }
    
    [UIView animateWithDuration:0.5f
                          delay:0.0
         usingSpringWithDamping:0.9
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         view.center = snappingPoint;
                     }
                     completion:^(BOOL finished) {}];
}

- (UIRectEdge)currentEdge
{
    return self.centerY < self.superview.centerY ? UIRectEdgeTop : UIRectEdgeBottom;
}

- (void)snapContentsToCorners
{
    [self snapToCornerForView:self]; // Snaps the Y axis of the status bar
    [self.clockLabelView snapToNearestCornerAnimated:YES];
    [self snapToCornerForView:self.groupView];
    
    if (self.clockLabelView.layer.opacity != 1.0f)
    {
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.clockLabelView.layer.opacity = 1.0f;
                         } completion:^(BOOL finished) {
                             
                         }];
    }
    
    if (self.groupView.layer.opacity != 1.0f)
    {
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.groupView.layer.opacity = 1.0f;
                         } completion:^(BOOL finished) {
                             
                         }];
    }
}

- (void)cancelPanningAndSnapToEdge
{
    for (UIGestureRecognizer *gesture in self.lastPannedView.gestureRecognizers)
    {
        gesture.enabled = NO;
        gesture.enabled = YES;
        
        [self snapContentsToCorners];
    }
}


#pragma mark Helpers

- (CGPoint)percentageTravelledInSuperview:(UIView *)superview
                                  forRect:(CGRect)rect
                                   filter:(BOOL)filter
{
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    CGFloat widthRadius = width / 2;
    CGFloat heightRadius = height / 2;
    
    CGRect percentageBounds = CGRectMake(widthRadius,
                                         0,
                                         (superview.width - width),
                                         superview.height);
    
    CGFloat crossingPointMinX = CGRectGetMinX(percentageBounds);
    CGFloat crossingPointMinY = CGRectGetMinY(percentageBounds);
    
    CGFloat pointsPastXCrossingPoint = (rect.origin.x + widthRadius) - crossingPointMinX;
    CGFloat pointsPastYCrossingPoint = (rect.origin.y + heightRadius) - crossingPointMinY;
    
    CGFloat xPercentage = pointsPastXCrossingPoint / percentageBounds.size.width;
    CGFloat yPercentage = pointsPastYCrossingPoint / percentageBounds.size.height;
    
    if (filter)
    {
        if (xPercentage < 0.0) xPercentage = 0.0;
        if (xPercentage > 1.0) xPercentage = 1.0;
        
        if (yPercentage < 0.0) yPercentage = 0.0;
        if (yPercentage > 1.0) yPercentage = 1.0;
    }
    
    return CGPointMake(xPercentage, yPercentage);
}

// Returns the percentage of X and Y axis of a views coordinates, in its superview
- (CGPoint)percentageTravelledInSuperviewForView:(UIView *)view
                                          filter:(BOOL)filter
{
    // Create a bounds within the superview that the view can't pass
    CGRect percentageBounds = CGRectMake(view.halfWidth,
                                         0,
                                         (view.superview.width - view.width),
                                         view.superview.height);
    
    CGFloat crossingPointMinX = CGRectGetMinX(percentageBounds);
    CGFloat crossingPointMinY = CGRectGetMinY(percentageBounds);
    
    CGFloat pointsPastXCrossingPoint = view.center.x - crossingPointMinX;
    CGFloat pointsPastYCrossingPoint = view.center.y - crossingPointMinY;
    
    CGFloat xPercentage = pointsPastXCrossingPoint / percentageBounds.size.width;
    CGFloat yPercentage = pointsPastYCrossingPoint / percentageBounds.size.height;
    
    if (filter)
    {
        if (xPercentage < 0.0) xPercentage = 0.0;
        if (xPercentage > 1.0) xPercentage = 1.0;
        
        if (yPercentage < 0.0) yPercentage = 0.0;
        if (yPercentage > 1.0) yPercentage = 1.0;
    }
    
    return CGPointMake(xPercentage, yPercentage);
}


- (CGFloat)opacityForOpposingRect:(CGRect)opposingRect
               againstPanningRect:(CGRect)panningRect
{
    if (CGRectGetCenter(panningRect).x < self.centerX)
    {
        CGFloat panningRightPoint = CGRectGetMaxX(panningRect);
        CGFloat opposingLeftPoint = CGRectGetMinX(opposingRect);
        
        CGFloat seperation = opposingLeftPoint - panningRightPoint;
        
        CGFloat percentage = seperation / 120.0f;
        
        if (percentage < 0.0) percentage = 0.0;
        if (percentage > 1.0) percentage = 1.0;
        
        return percentage;
    }
    else
    {
        CGFloat panningLeftPoint = CGRectGetMinX(panningRect);
        CGFloat opposingRightPoint = CGRectGetMaxX(opposingRect);
        
        CGFloat seperation = panningLeftPoint - opposingRightPoint;
        
        CGFloat percentage = seperation / 120.0f;
        
        if (percentage < 0.0) percentage = 0.0;
        if (percentage > 1.0) percentage = 1.0;
        
        return percentage;
    }
    
    return 1.0f;
}


- (CGFloat)opacityForOpposingView:(UIView *)opposingView
               agianstPanningView:(UIView *)panningView
{
    CGFloat rangeMargin = 100;
    CGRect opposingFrameWithMargin = CGRectMake(opposingView.center.x - (opposingView.halfWidth + rangeMargin), opposingView.center.y - (opposingView.halfHeight + rangeMargin), opposingView.width + (rangeMargin * 2), opposingView.height + (rangeMargin * 2));
    
    NSInteger side = panningView.center.x < opposingView.center.x ? 0 : 1;
    
    if (CGRectContainsRect(opposingFrameWithMargin, panningView.frame))
    {
        if (side == 0) // Left side
        {
            CGFloat crossingPointMinX = CGRectGetMinX(opposingFrameWithMargin);
            CGFloat pointsPastXCrossingPoint = panningView.center.x - crossingPointMinX;
            CGFloat xPercentage = pointsPastXCrossingPoint / rangeMargin;
            
            return xPercentage;
        }
        else // Right Side
        {
            CGFloat crossingPointMaxX = CGRectGetMaxX(opposingFrameWithMargin);
            CGFloat pointsPastXCrossingPoint = crossingPointMaxX - panningView.center.x;
            CGFloat xPercentage = pointsPastXCrossingPoint / rangeMargin;
            
            return xPercentage;
        }
    }
    else
    {
        return 0.0f;
    }
}

#pragma mark - Gestures -

- (void)sendToWindow
{
    if (![self.superview isEqual:AppDelegate.window])
    {
        CGPoint convertedPoint = [self.superview convertPoint:self.center toView:nil];
        
        self.center = convertedPoint;
        [AppDelegate.window addSubview:self];
        [AppDelegate.window bringSubviewToFront:self];
    }
}

- (void)sendToContentContainerView
{
    if (![self.superview isEqual:AppContainer.contentContainerView])
    {
        CGPoint convertedPoint = [AppContainer.contentContainerView convertPoint:self.center fromView:nil];
        
        self.center = convertedPoint;
        [AppContainer.contentContainerView addSubview:self];
        [AppContainer.contentContainerView sendSubviewToBack:self];
    }
}

- (void)fixOriginForBounds
{
    if ([self.superview isEqual:AppContainer.contentContainerView]) return;
    
    CGFloat insetRadiusY = self.height + AppContainer.view.contentOffsetY;
    
    if (self.y > self.superview.height - insetRadiusY)
    {
        self.y = self.superview.height - insetRadiusY;
    }
}

- (void)didPanStatusItem:(UIPanGestureRecognizer *)panGesture
{
    // Prevent the opposite view from being dragged at the same time as the panning view
    if (self.dragging && ![panGesture.view isEqual:self.lastPannedView]) return;
    
    self.lastPannedView = panGesture.view;
    
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            self.dragging = YES;
            
            [self sendToWindow];
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            self.dragging = NO;
            
            [self sendToContentContainerView];
            
        }
            break;
        default:
            break;
    }
    
    [self movementForGesture:panGesture];
    [self stylingForGesture:panGesture];
    
    
    [self fixOriginForBounds];
}

- (void)movementForGesture:(UIPanGestureRecognizer *)panGesture
{
    CGPoint translation = [panGesture translationInView:panGesture.view];
    
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            if (panGesture.state == UIGestureRecognizerStateBegan) self.clockLabelView.dragging = YES;
            
            // Move the whole status bar along the Y-Axis. The subviews only move their X-Axis
            [self setYWithAdditive:translation.y];
            
            // Fix the status bar Y position so it can't be panned out of bounds
            if (AppContainer.isAdLoaded && self.y < AppContainer.adBanner.height)
            {
                self.y = AppContainer.adBanner.height;
            }
            else if (self.y < 0)
            {
                if (self.y < 0) self.y = 0;
            }
            
            if (self.y > self.superview.height - self.height) self.y = self.superview.height - self.height;
            
            // Update the panning view
            panGesture.view.origin = CGPointMake(translation.x + panGesture.view.x, panGesture.view.y);
            
            // When the view is on the left side of the screen we just need to make sure the originX doesn't go under 0.0f
            if (panGesture.view.x < 0.0f) panGesture.view.x = 0.0f;
            
            
            // If we are on the right side off the screen
            if ([panGesture.view isEqual:self.clockLabelView])
            {
                if (self.clockLabelView.x > self.width - self.clockLabelView.apparentWidth)
                {
                    self.clockLabelView.x = self.width - self.clockLabelView.apparentWidth;
                }
            }
            else if ([panGesture.view isEqual:self.groupView])
            {
                if (self.groupView.x > self.width - self.groupView.apparentWidth)
                {
                    self.groupView.x = self.width - self.groupView.apparentWidth;
                }
            }
            
            // Make a new rect for the clock since his width is dynamic
            CGRect apparentClockRect = self.clockLabelView.frame;
            apparentClockRect.size.width = self.clockLabelView.apparentWidth;
            
            CGRect apparentGroupRect = self.groupView.frame;
            apparentGroupRect.size.width = self.groupView.apparentWidth;
            
            // Observe the panning view and mirror the other view
            if ([panGesture.view isEqual:self.clockLabelView])
            {
                CGFloat xPercentage = [self percentageTravelledInSuperview:self.clockLabelView.superview
                                                                   forRect:apparentClockRect
                                                                    filter:YES].x;
                
                // Use the percentage and mirror the OTHER view
                self.groupView.origin = CGPointMake((self.width - self.groupView.apparentWidth) * (1.0f - xPercentage),
                                                              self.groupView.origin.y);
                
                // Change the opacity of the OTHER view
                CGFloat opacityPercentage = [self opacityForOpposingRect:apparentGroupRect
                                                      againstPanningRect:apparentClockRect];
                
                //                opacityPercentage = 1.0f - opacityPercentage;
                
                self.groupView.layer.opacity = opacityPercentage;
                
            }
            else if ([panGesture.view isEqual:self.groupView])
            {
                CGFloat xPercentage = [self percentageTravelledInSuperview:self.groupView.superview
                                                                   forRect:apparentGroupRect
                                                                    filter:YES].x;
                
                self.clockLabelView.origin = CGPointMake((self.width - self.clockLabelView.apparentWidth) * (1.0f - xPercentage), self.clockLabelView.origin.y);
                
                CGFloat opacityPercentage = [self opacityForOpposingRect:apparentClockRect
                                                      againstPanningRect:apparentGroupRect];
                
                //                opacityPercentage = 1.0f - opacityPercentage;
                
                self.clockLabelView.layer.opacity = opacityPercentage;
                //                self.clockLabelView.transform = CGAffineTransformMakeScale(opacityPercentage, opacityPercentage);
            }
            
            [panGesture setTranslation:CGPointZero inView:self];
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            self.clockLabelView.dragging = NO;
            
            [self snapContentsToCorners];
        }
            break;
        default:
            break;
    }
    
    if ([self.delegate respondsToSelector:@selector(shouldUpdateExclusionPaths)] && [self.delegate shouldUpdateExclusionPaths])
    {
        if (![self.delegate respondsToSelector:@selector(didUpdateExclusionPaths:)]) return;
        
        CGRect alertsFrame = self.groupView.frame;
        alertsFrame.origin.y = self.y;
        
        CGRect clockFrame = self.clockLabelView.frame;
        clockFrame.origin.y = self.y;
        
        [self.delegate didUpdateExclusionPaths:@[[UIBezierPath bezierPathWithRect:alertsFrame], [UIBezierPath bezierPathWithRect:clockFrame]]];
    }
}

/*
 - (CGPoint)percentageForPoint:(CGPoint)point
 inView:(UIView *)view
 withEdgeInsets:(UIEdgeInsets)edgeInsets
 {
 CGFloat widthInsetTotal = edgeInsets.left + edgeInsets.right;
 CGFloat heightInsetTotal = edgeInsets.top + edgeInsets.bottom;
 
 CGFloat xContentStart = edgeInsets.left;
 CGFloat yContentStart = edgeInsets.top;
 
 CGFloat xContentWidth = view.width - widthInsetTotal;
 CGFloat yContentHeight = view.height - heightInsetTotal;
 
 CGFloat xPercentage = 0.0;
 CGFloat yPercentage = 0.0;
 
 CGPoint convertedPoint = [self.superview convertPoint:self.center
 toView:nil];
 
 if ([view isKindOfClass:[UIWindow class]])
 {
 
 }
 else
 {
 
 }
 
 
 return CGPointMake(xPercentage, yPercentage);
 }
 */

- (void)stylingForGesture:(UIPanGestureRecognizer *)panGesture
{
    CGFloat yPercentage = [self percentageTravelledInSuperviewForView:panGesture.view.superview
                                                               filter:NO].y;
    
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            switch (AppContainer.atmosphere.state)
            {
                case TMVAtmosphereStateDay:
                {
                    [self updateColor:[UIColor colorAbyssInterpolatingBetweenColor:AppContainer.atmosphere.currentColor
                                                                          andColor:AppContainer.atmosphere.derivedColor
                                                                    withPercentage:1.0f - yPercentage]];
                }
                    break;
                case TMVAtmosphereStateNight:
                {
                    [self updateColor:[UIColor whiteColor]];
                }
                    break;
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            if (yPercentage <= 0.5)
            {
                [self updateColor:AppContainer.atmosphere.elementColorTop
                    withAnimation:YES];
            }
            else
            {
                [self updateColor:AppContainer.atmosphere.elementColorBottom
                    withAnimation:YES];
            }
        }
            break;
        default:
            break;
    }
}


@end

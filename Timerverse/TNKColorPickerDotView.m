//
//  TNKColorPickerDotView.m
//  TNKCube
//
//  Created by Larry Ryan on 5/17/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TNKColorPickerDotView.h"

@interface TNKColorPickerDotView ()

@property (nonatomic, readwrite) CGPoint landingPoint;

@end

@implementation TNKColorPickerDotView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.layer.cornerRadius = frame.size.width / 2;
        self.backgroundColor = [UIColor colorForPoint:self.center];
        self.landingPoint = self.center;
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pannedView:)];
        [self addGestureRecognizer:panGesture];
    }
    
    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    
    if ([self.delegate respondsToSelector:@selector(didChangeDotView:toColor:)])
    {
        [self.delegate didChangeDotView:self
                                toColor:backgroundColor];
    }
}

- (void)pannedView:(UIPanGestureRecognizer *)panGesture
{
    [self setOriginWithAdditive:[panGesture translationInView:panGesture.view]];
    
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            self.backgroundColor = [UIColor colorForPoint:self.center];
            
            [panGesture setTranslation:CGPointZero
                                inView:self];
            
            [self fixOriginForBounds];
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            [self snapBackToLandingPoint];
        }
            break;
        default:
            break;
    }
}

- (void)fixOriginForBounds
{
    CGFloat radius = self.halfWidth;
    
    CGFloat top = self.centerY - radius;
    CGFloat bottom = self.centerY + radius;
    CGFloat left = self.centerX - radius;
    CGFloat right = self.centerX + radius;
    
    if (left < 0)
    {
        self.centerX = radius;
    }
    if (right > self.superview.width)
    {
        self.centerX = self.superview.width - radius;
    }

    if (top < 0)
    {
        self.centerY = radius;
    }
    
    if (bottom > self.superview.height)
    {
        self.centerY = self.superview.height - radius;
    }
}

- (void)snapBackToLandingPoint
{
    [UIView animateWithDuration:1.0f
                          delay:0.0f
         usingSpringWithDamping:0.6f
          initialSpringVelocity:0.8f
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.center = self.landingPoint;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

- (void)cancelGestures
{
    for (UIGestureRecognizer *gesture in self.gestureRecognizers)
    {
        gesture.enabled = NO;
        gesture.enabled = YES;
    }
}

@end

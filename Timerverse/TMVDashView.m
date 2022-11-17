//
//  TMVDashView.m
//  Timerverse
//
//  Created by Larry Ryan on 5/2/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVDashView.h"

static NSUInteger const kLineDashCount = 44.0f;

@interface TMVDashView ()

@property (nonatomic, weak) TMVItemView *itemView;
@property (nonatomic, readwrite) CAShapeLayer *ringLayer;

@property (nonatomic, readwrite, getter = isSpinning) BOOL spinning;

@end

@implementation TMVDashView

- (instancetype)initWithFrame:(CGRect)frame
           attachedToItemView:(TMVItemView *)itemView
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _itemView = itemView;
        
        self.userInteractionEnabled = NO;
        
        self.layer.opacity = 0.0f;
        
        [self.layer addSublayer:self.ringLayer];
    }
    
    return self;
}

- (CAShapeLayer *)ringLayer
{
    if (!_ringLayer)
    {
        _ringLayer = [CAShapeLayer layer];
    
        CGFloat lineWidth = self.itemView.soundWave.strokeWidth;
        
        CGFloat pathOffset = -(lineWidth / 2) / 2;
        CGRect pathRect = CGRectMake(pathOffset, pathOffset, self.width, self.height);
        
        CGFloat parimeter = M_PI * self.width;
        CGFloat patternLength = parimeter / (kLineDashCount & ~1); // Rounds the constant down to an even number to keep the line and spacing even
        
        _ringLayer.frame = pathRect;
        _ringLayer.path = [UIBezierPath bezierPathWithOvalInRect:pathRect].CGPath;
        _ringLayer.fillColor = [UIColor clearColor].CGColor;
        _ringLayer.strokeColor = self.itemView.apparentColor.CGColor;
        _ringLayer.lineWidth = lineWidth;
        _ringLayer.lineJoin = kCALineCapRound;
        _ringLayer.lineDashPattern = @[@(patternLength), @(patternLength)];
    }
    
    return _ringLayer;
}

- (void)startSpinning
{
//    if (self.isSpinning) return;
    
//    self.spinning = YES;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    animation.duration = 8.0f;
    animation.repeatCount = NSIntegerMax;
    animation.byValue = @(M_PI * 2.0f);
    
    [self applyBasicAnimation:animation
                      toLayer:self.ringLayer
          withCompletionBlock:^{
        self.spinning = YES;
    }];
}

- (void)stopSpinning
{
    self.spinning = NO;
    
    [self.ringLayer removeAllAnimations];
}

- (void)applyBasicAnimation:(CABasicAnimation *)animation
                    toLayer:(CALayer *)layer
        withCompletionBlock:(void (^)(void))completion
{
    animation.fromValue = [layer.presentationLayer ?: layer valueForKeyPath:animation.keyPath];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [CATransaction setCompletionBlock:^{ completion(); }];
    
    [layer setValue:animation.toValue forKeyPath:animation.keyPath];
    
    [layer addAnimation:animation forKey:animation.keyPath];
    
    [CATransaction commit];
}

@end

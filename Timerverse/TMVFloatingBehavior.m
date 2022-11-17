//
//  TMVFloatingBehavior.m
//  Timerverse
//
//  Created by Larry Ryan on 2/2/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVFloatingBehavior.h"
//#import "TMVItemView.h"

@interface TMVFloatingBehavior ()

@property (nonatomic) NSArray *bezierPaths;
@property (nonatomic) NSMutableArray *items;

@end

@implementation TMVFloatingBehavior

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.bezierPaths = @[[self pathOne]];
    }
    return self;
}

- (instancetype)initWithItem:(UIView *)item
{
    self = [super init];
    if (self)
    {
        self.bezierPaths = @[[self pathOne]];
        [self addFloatingBehaviorToItem:item];
    }
    return self;
}

- (void)addFloatingBehaviorToItem:(UIView *)item
{
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    UIBezierPath *randomPath = (UIBezierPath *)self.bezierPaths[arc4random_uniform((u_int32_t)self.bezierPaths.count)];
    anim.path = randomPath.CGPath;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    anim.repeatCount = HUGE_VALF;
    anim.duration = 60.0;
    anim.speed = 0.4;
    anim.beginTime = 0.10 * arc4random_uniform(60.0 / 0.1);
    [[(TMVItemView *)item containerView].layer addAnimation:anim forKey:@"floating"];
}

- (void)removeFloatingBehaviorToItem:(UIView *)item
{
    [[(TMVItemView *)item containerView].layer removeAnimationForKey:@"floating"];
}

#pragma mark - Paths

- (UIBezierPath *)pathOne
{
    //// Color Declarations
    UIColor* color = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1];
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(35.5, 32.81)];
    [bezierPath addCurveToPoint: CGPointMake(66.41, 32.81) controlPoint1: CGPointMake(40.4, 28.81) controlPoint2: CGPointMake(55.32, 20.92)];
    [bezierPath addCurveToPoint: CGPointMake(62.48, 54.19) controlPoint1: CGPointMake(77.49, 44.7) controlPoint2: CGPointMake(62.48, 54.19)];
    [bezierPath addCurveToPoint: CGPointMake(43.84, 55.16) controlPoint1: CGPointMake(62.48, 54.19) controlPoint2: CGPointMake(50, 57.59)];
    [bezierPath addCurveToPoint: CGPointMake(40.89, 43.01) controlPoint1: CGPointMake(37.67, 52.73) controlPoint2: CGPointMake(36.46, 46.76)];
    [bezierPath addCurveToPoint: CGPointMake(62.48, 59.53) controlPoint1: CGPointMake(45.33, 39.27) controlPoint2: CGPointMake(69.31, 41.62)];
    [bezierPath addCurveToPoint: CGPointMake(38.44, 54.19) controlPoint1: CGPointMake(55.65, 77.44) controlPoint2: CGPointMake(44.99, 58.6)];
    [bezierPath addCurveToPoint: CGPointMake(38.44, 64.87) controlPoint1: CGPointMake(31.9, 49.77) controlPoint2: CGPointMake(18.16, 61.68)];
    [bezierPath addCurveToPoint: CGPointMake(69.84, 61.47) controlPoint1: CGPointMake(58.72, 68.07) controlPoint2: CGPointMake(69.69, 61.94)];
    [bezierPath addCurveToPoint: CGPointMake(61.99, 49.33) controlPoint1: CGPointMake(69.99, 61.01) controlPoint2: CGPointMake(78.31, 55.99)];
    [bezierPath addCurveToPoint: CGPointMake(40.89, 49.33) controlPoint1: CGPointMake(45.67, 42.67) controlPoint2: CGPointMake(42.15, 47.3)];
    [bezierPath addCurveToPoint: CGPointMake(55.61, 59.53) controlPoint1: CGPointMake(39.64, 51.36) controlPoint2: CGPointMake(41.93, 58.92)];
    [bezierPath addCurveToPoint: CGPointMake(67.88, 51.76) controlPoint1: CGPointMake(69.3, 60.14) controlPoint2: CGPointMake(67.88, 51.76)];
    [bezierPath addCurveToPoint: CGPointMake(49.23, 35.73) controlPoint1: CGPointMake(67.88, 51.76) controlPoint2: CGPointMake(68.34, 40.18)];
    [bezierPath addCurveToPoint: CGPointMake(32.06, 39.61) controlPoint1: CGPointMake(30.13, 31.27) controlPoint2: CGPointMake(32.06, 39.61)];
    [bezierPath addCurveToPoint: CGPointMake(48.74, 60.99) controlPoint1: CGPointMake(32.06, 39.61) controlPoint2: CGPointMake(28.47, 50.08)];
    [bezierPath addCurveToPoint: CGPointMake(68.86, 58.07) controlPoint1: CGPointMake(69.02, 71.9) controlPoint2: CGPointMake(68.86, 58.07)];
    [bezierPath addCurveToPoint: CGPointMake(50, 50) controlPoint1: CGPointMake(68.86, 58.07) controlPoint2: CGPointMake(72.23, 50.85)];
    [bezierPath addCurveToPoint: CGPointMake(35.5, 32.81) controlPoint1: CGPointMake(27.77, 49.15) controlPoint2: CGPointMake(30.59, 36.82)];
    [bezierPath closePath];
    [color setStroke];
    bezierPath.lineWidth = 0.5;
    [bezierPath stroke];
    
    return bezierPath;
}

@end

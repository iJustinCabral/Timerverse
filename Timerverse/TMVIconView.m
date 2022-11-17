//
//  TMVIconView.m
//  Timerverse
//
//  Created by Larry Ryan on 3/28/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVIconView.h"

@implementation TMVIconView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* ellipseRedColor = [UIColor colorWithRed: 0.949 green: 0.373 blue: 0.459 alpha: 1];
    UIColor* dropShadowColor = [UIColor colorWithRed: 0.001 green: 0.002 blue: 0.002 alpha: 1];
    UIColor* ellipseBlueColor = [UIColor colorWithRed: 0.176 green: 0.663 blue: 0.765 alpha: 1];
    UIColor* ellipsePurpleColor = [UIColor colorWithRed: 0.569 green: 0.235 blue: 0.808 alpha: 1];
    UIColor* ellipseYellowColor = [UIColor colorWithRed: 0.973 green: 0.851 blue: 0.259 alpha: 1];
    UIColor* handsWhiteColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    
    //// Shadow Declarations
    UIColor* ellipse1Copy3DropShadow = [dropShadowColor colorWithAlphaComponent: 0.5];
    CGSize ellipse1Copy3DropShadowOffset = CGSizeMake(0.1, -0.1);
    CGFloat ellipse1Copy3DropShadowBlurRadius = 1;
    UIColor* handsInnerShadow = dropShadowColor;
    CGSize handsInnerShadowOffset = CGSizeMake(0.1, -0.1);
    CGFloat handsInnerShadowBlurRadius = 1;
    
    //// ellipseGroup
    {
        //// ellipseRedGroup
        {
            CGContextSaveGState(context);
            CGContextSetBlendMode(context, kCGBlendModeSoftLight);
            CGContextBeginTransparencyLayer(context, NULL);
            
            
            //// ellipseRedShape Drawing
            UIBezierPath* ellipseRedShapePath = [UIBezierPath bezierPath];
            [ellipseRedShapePath moveToPoint: CGPointMake(67.44, 37.62)];
            [ellipseRedShapePath addCurveToPoint: CGPointMake(94.81, 65.01) controlPoint1: CGPointMake(82.55, 37.62) controlPoint2: CGPointMake(94.81, 49.88)];
            [ellipseRedShapePath addCurveToPoint: CGPointMake(67.44, 92.4) controlPoint1: CGPointMake(94.81, 80.14) controlPoint2: CGPointMake(82.55, 92.4)];
            [ellipseRedShapePath addCurveToPoint: CGPointMake(40.06, 65.01) controlPoint1: CGPointMake(52.32, 92.4) controlPoint2: CGPointMake(40.06, 80.14)];
            [ellipseRedShapePath addCurveToPoint: CGPointMake(67.44, 37.62) controlPoint1: CGPointMake(40.06, 49.88) controlPoint2: CGPointMake(52.32, 37.62)];
            [ellipseRedShapePath closePath];
            CGContextSaveGState(context);
            CGContextSetShadowWithColor(context, ellipse1Copy3DropShadowOffset, ellipse1Copy3DropShadowBlurRadius, ellipse1Copy3DropShadow.CGColor);
            [ellipseRedColor setFill];
            [ellipseRedShapePath fill];
            CGContextRestoreGState(context);
            
            
            
            CGContextEndTransparencyLayer(context);
            CGContextRestoreGState(context);
        }
        
        
        //// ellipseBlueGroup
        {
            CGContextSaveGState(context);
            CGContextSetBlendMode(context, kCGBlendModeSoftLight);
            CGContextBeginTransparencyLayer(context, NULL);
            
            
            //// ellipseBlueShape Drawing
            UIBezierPath* ellipseBlueShapePath = [UIBezierPath bezierPath];
            [ellipseBlueShapePath moveToPoint: CGPointMake(38.99, 0.95)];
            [ellipseBlueShapePath addCurveToPoint: CGPointMake(72.78, 34.77) controlPoint1: CGPointMake(57.65, 0.95) controlPoint2: CGPointMake(72.78, 16.09)];
            [ellipseBlueShapePath addCurveToPoint: CGPointMake(38.99, 68.59) controlPoint1: CGPointMake(72.78, 53.45) controlPoint2: CGPointMake(57.65, 68.59)];
            [ellipseBlueShapePath addCurveToPoint: CGPointMake(5.19, 34.77) controlPoint1: CGPointMake(20.32, 68.59) controlPoint2: CGPointMake(5.19, 53.45)];
            [ellipseBlueShapePath addCurveToPoint: CGPointMake(38.99, 0.95) controlPoint1: CGPointMake(5.19, 16.09) controlPoint2: CGPointMake(20.32, 0.95)];
            [ellipseBlueShapePath closePath];
            CGContextSaveGState(context);
            CGContextSetShadowWithColor(context, ellipse1Copy3DropShadowOffset, ellipse1Copy3DropShadowBlurRadius, ellipse1Copy3DropShadow.CGColor);
            [ellipseBlueColor setFill];
            [ellipseBlueShapePath fill];
            CGContextRestoreGState(context);
            
            
            
            CGContextEndTransparencyLayer(context);
            CGContextRestoreGState(context);
        }
        
        
        //// elliipsePurpleGroup
        {
            CGContextSaveGState(context);
            CGContextSetBlendMode(context, kCGBlendModeSoftLight);
            CGContextBeginTransparencyLayer(context, NULL);
            
            
            //// ellipsePurpleShape Drawing
            UIBezierPath* ellipsePurpleShapePath = [UIBezierPath bezierPath];
            [ellipsePurpleShapePath moveToPoint: CGPointMake(37.09, 50.03)];
            [ellipsePurpleShapePath addCurveToPoint: CGPointMake(59.11, 72.07) controlPoint1: CGPointMake(49.25, 50.03) controlPoint2: CGPointMake(59.11, 59.9)];
            [ellipsePurpleShapePath addCurveToPoint: CGPointMake(37.09, 94.11) controlPoint1: CGPointMake(59.11, 84.25) controlPoint2: CGPointMake(49.25, 94.11)];
            [ellipsePurpleShapePath addCurveToPoint: CGPointMake(15.06, 72.07) controlPoint1: CGPointMake(24.92, 94.11) controlPoint2: CGPointMake(15.06, 84.25)];
            [ellipsePurpleShapePath addCurveToPoint: CGPointMake(37.09, 50.03) controlPoint1: CGPointMake(15.06, 59.9) controlPoint2: CGPointMake(24.92, 50.03)];
            [ellipsePurpleShapePath closePath];
            CGContextSaveGState(context);
            CGContextSetShadowWithColor(context, ellipse1Copy3DropShadowOffset, ellipse1Copy3DropShadowBlurRadius, ellipse1Copy3DropShadow.CGColor);
            [ellipsePurpleColor setFill];
            [ellipsePurpleShapePath fill];
            CGContextRestoreGState(context);
            
            
            
            CGContextEndTransparencyLayer(context);
            CGContextRestoreGState(context);
        }
        
        
        //// ellipseYellowGroup
        {
            CGContextSaveGState(context);
            CGContextSetBlendMode(context, kCGBlendModeSoftLight);
            CGContextBeginTransparencyLayer(context, NULL);
            
            
            //// ellipseYellowShape Drawing
            UIBezierPath* ellipseYellowShapePath = [UIBezierPath bezierPath];
            [ellipseYellowShapePath moveToPoint: CGPointMake(69.94, 6.46)];
            [ellipseYellowShapePath addCurveToPoint: CGPointMake(91.96, 28.5) controlPoint1: CGPointMake(82.1, 6.46) controlPoint2: CGPointMake(91.96, 16.33)];
            [ellipseYellowShapePath addCurveToPoint: CGPointMake(69.94, 50.54) controlPoint1: CGPointMake(91.96, 40.67) controlPoint2: CGPointMake(82.1, 50.54)];
            [ellipseYellowShapePath addCurveToPoint: CGPointMake(47.91, 28.5) controlPoint1: CGPointMake(57.77, 50.54) controlPoint2: CGPointMake(47.91, 40.67)];
            [ellipseYellowShapePath addCurveToPoint: CGPointMake(69.94, 6.46) controlPoint1: CGPointMake(47.91, 16.33) controlPoint2: CGPointMake(57.77, 6.46)];
            [ellipseYellowShapePath closePath];
            CGContextSaveGState(context);
            CGContextSetShadowWithColor(context, ellipse1Copy3DropShadowOffset, ellipse1Copy3DropShadowBlurRadius, ellipse1Copy3DropShadow.CGColor);
            [ellipseYellowColor setFill];
            [ellipseYellowShapePath fill];
            CGContextRestoreGState(context);
            
            
            
            CGContextEndTransparencyLayer(context);
            CGContextRestoreGState(context);
        }
    }
    
    
    //// starGroup
    {
        //// Rounded Rectangle 1 copy Drawing
        UIBezierPath* roundedRectangle1CopyPath = [UIBezierPath bezierPath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(29.62, 23.12)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(30.32, 23.81) controlPoint1: CGPointMake(30, 23.12) controlPoint2: CGPointMake(30.32, 23.43)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(29.62, 24.51) controlPoint1: CGPointMake(30.32, 24.2) controlPoint2: CGPointMake(30, 24.51)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(28.92, 23.81) controlPoint1: CGPointMake(29.24, 24.51) controlPoint2: CGPointMake(28.92, 24.2)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(29.62, 23.12) controlPoint1: CGPointMake(28.92, 23.43) controlPoint2: CGPointMake(29.24, 23.12)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(37.15, 26.92)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(37.85, 27.61) controlPoint1: CGPointMake(37.54, 26.92) controlPoint2: CGPointMake(37.85, 27.23)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(37.15, 28.31) controlPoint1: CGPointMake(37.85, 28) controlPoint2: CGPointMake(37.54, 28.31)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(36.46, 27.61) controlPoint1: CGPointMake(36.77, 28.31) controlPoint2: CGPointMake(36.46, 28)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(37.15, 26.92) controlPoint1: CGPointMake(36.46, 27.23) controlPoint2: CGPointMake(36.77, 26.92)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(29.43, 70.55)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(30.13, 71.25) controlPoint1: CGPointMake(29.81, 70.55) controlPoint2: CGPointMake(30.13, 70.87)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(29.43, 71.95) controlPoint1: CGPointMake(30.13, 71.63) controlPoint2: CGPointMake(29.81, 71.95)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(28.73, 71.25) controlPoint1: CGPointMake(29.05, 71.95) controlPoint2: CGPointMake(28.73, 71.63)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(29.43, 70.55) controlPoint1: CGPointMake(28.73, 70.87) controlPoint2: CGPointMake(29.05, 70.55)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(74.94, 57.51)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(75.63, 58.2) controlPoint1: CGPointMake(75.32, 57.51) controlPoint2: CGPointMake(75.63, 57.82)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(74.94, 58.9) controlPoint1: CGPointMake(75.63, 58.59) controlPoint2: CGPointMake(75.32, 58.9)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(74.24, 58.2) controlPoint1: CGPointMake(74.55, 58.9) controlPoint2: CGPointMake(74.24, 58.59)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(74.94, 57.51) controlPoint1: CGPointMake(74.24, 57.82) controlPoint2: CGPointMake(74.55, 57.51)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(64.37, 32.36)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(65.06, 33.06) controlPoint1: CGPointMake(64.75, 32.36) controlPoint2: CGPointMake(65.06, 32.68)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(64.37, 33.76) controlPoint1: CGPointMake(65.06, 33.44) controlPoint2: CGPointMake(64.75, 33.76)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(63.67, 33.06) controlPoint1: CGPointMake(63.98, 33.76) controlPoint2: CGPointMake(63.67, 33.44)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(64.37, 32.36) controlPoint1: CGPointMake(63.67, 32.68) controlPoint2: CGPointMake(63.98, 32.36)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(53.52, 38.19)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(53.06, 37.98) controlPoint1: CGPointMake(53.33, 38.26) controlPoint2: CGPointMake(53.13, 38.16)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(53.27, 37.52) controlPoint1: CGPointMake(52.99, 37.79) controlPoint2: CGPointMake(53.09, 37.59)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(53.73, 37.73) controlPoint1: CGPointMake(53.46, 37.45) controlPoint2: CGPointMake(53.66, 37.55)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(53.52, 38.19) controlPoint1: CGPointMake(53.8, 37.92) controlPoint2: CGPointMake(53.7, 38.12)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(44.49, 40.72)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(44.03, 40.5) controlPoint1: CGPointMake(44.3, 40.78) controlPoint2: CGPointMake(44.1, 40.69)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(44.24, 40.05) controlPoint1: CGPointMake(43.96, 40.32) controlPoint2: CGPointMake(44.06, 40.11)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(44.7, 40.26) controlPoint1: CGPointMake(44.43, 39.98) controlPoint2: CGPointMake(44.63, 40.07)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(44.49, 40.72) controlPoint1: CGPointMake(44.77, 40.45) controlPoint2: CGPointMake(44.67, 40.65)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(43.7, 23)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(43.25, 22.79) controlPoint1: CGPointMake(43.52, 23.07) controlPoint2: CGPointMake(43.31, 22.97)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(43.46, 22.33) controlPoint1: CGPointMake(43.18, 22.6) controlPoint2: CGPointMake(43.28, 22.4)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(43.92, 22.54) controlPoint1: CGPointMake(43.65, 22.26) controlPoint2: CGPointMake(43.85, 22.36)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(43.7, 23) controlPoint1: CGPointMake(43.98, 22.73) controlPoint2: CGPointMake(43.89, 22.93)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(24.27, 33.6)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(23.82, 33.39) controlPoint1: CGPointMake(24.09, 33.67) controlPoint2: CGPointMake(23.88, 33.57)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(24.03, 32.93) controlPoint1: CGPointMake(23.75, 33.2) controlPoint2: CGPointMake(23.84, 33)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(24.49, 33.14) controlPoint1: CGPointMake(24.21, 32.86) controlPoint2: CGPointMake(24.42, 32.96)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(24.27, 33.6) controlPoint1: CGPointMake(24.55, 33.33) controlPoint2: CGPointMake(24.46, 33.53)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(33.73, 43.85)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(33.28, 43.64) controlPoint1: CGPointMake(33.55, 43.92) controlPoint2: CGPointMake(33.35, 43.83)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(33.49, 43.18) controlPoint1: CGPointMake(33.21, 43.46) controlPoint2: CGPointMake(33.31, 43.25)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(33.95, 43.4) controlPoint1: CGPointMake(33.68, 43.12) controlPoint2: CGPointMake(33.88, 43.21)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(33.73, 43.85) controlPoint1: CGPointMake(34.02, 43.58) controlPoint2: CGPointMake(33.92, 43.79)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(70.54, 75.94)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(70.09, 75.72) controlPoint1: CGPointMake(70.36, 76.01) controlPoint2: CGPointMake(70.15, 75.91)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(70.3, 75.27) controlPoint1: CGPointMake(70.02, 75.54) controlPoint2: CGPointMake(70.11, 75.33)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(70.76, 75.48) controlPoint1: CGPointMake(70.48, 75.2) controlPoint2: CGPointMake(70.69, 75.3)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(70.54, 75.94) controlPoint1: CGPointMake(70.82, 75.67) controlPoint2: CGPointMake(70.73, 75.87)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(66.26, 75.42)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(65.8, 75.21) controlPoint1: CGPointMake(66.07, 75.49) controlPoint2: CGPointMake(65.87, 75.39)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(66.01, 74.75) controlPoint1: CGPointMake(65.73, 75.02) controlPoint2: CGPointMake(65.83, 74.82)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(66.47, 74.97) controlPoint1: CGPointMake(66.2, 74.69) controlPoint2: CGPointMake(66.4, 74.78)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(66.26, 75.42) controlPoint1: CGPointMake(66.54, 75.15) controlPoint2: CGPointMake(66.44, 75.36)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(64.53, 63.79)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(64.07, 63.57) controlPoint1: CGPointMake(64.34, 63.85) controlPoint2: CGPointMake(64.14, 63.76)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(64.28, 63.12) controlPoint1: CGPointMake(64, 63.39) controlPoint2: CGPointMake(64.1, 63.18)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(64.74, 63.33) controlPoint1: CGPointMake(64.47, 63.05) controlPoint2: CGPointMake(64.67, 63.15)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(64.53, 63.79) controlPoint1: CGPointMake(64.81, 63.52) controlPoint2: CGPointMake(64.71, 63.72)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(42.75, 67.29)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(42.3, 67.08) controlPoint1: CGPointMake(42.57, 67.36) controlPoint2: CGPointMake(42.36, 67.27)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(42.51, 66.62) controlPoint1: CGPointMake(42.23, 66.9) controlPoint2: CGPointMake(42.33, 66.69)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(42.97, 66.84) controlPoint1: CGPointMake(42.7, 66.56) controlPoint2: CGPointMake(42.9, 66.65)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(42.75, 67.29) controlPoint1: CGPointMake(43.03, 67.02) controlPoint2: CGPointMake(42.94, 67.23)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(52.22, 77.55)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(51.76, 77.33) controlPoint1: CGPointMake(52.03, 77.61) controlPoint2: CGPointMake(51.83, 77.52)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(51.97, 76.88) controlPoint1: CGPointMake(51.69, 77.15) controlPoint2: CGPointMake(51.79, 76.94)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(52.43, 77.09) controlPoint1: CGPointMake(52.16, 76.81) controlPoint2: CGPointMake(52.36, 76.91)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(52.22, 77.55) controlPoint1: CGPointMake(52.5, 77.28) controlPoint2: CGPointMake(52.4, 77.48)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(74.52, 47.61)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(75, 47.45) controlPoint1: CGPointMake(74.6, 47.44) controlPoint2: CGPointMake(74.82, 47.36)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(75.16, 47.93) controlPoint1: CGPointMake(75.17, 47.54) controlPoint2: CGPointMake(75.25, 47.75)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(74.68, 48.09) controlPoint1: CGPointMake(75.07, 48.1) controlPoint2: CGPointMake(74.86, 48.18)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(74.52, 47.61) controlPoint1: CGPointMake(74.51, 48.01) controlPoint2: CGPointMake(74.43, 47.79)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(30.73, 78.74)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(31.21, 78.57) controlPoint1: CGPointMake(30.82, 78.56) controlPoint2: CGPointMake(31.03, 78.49)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(31.37, 79.05) controlPoint1: CGPointMake(31.39, 78.66) controlPoint2: CGPointMake(31.46, 78.87)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(30.9, 79.21) controlPoint1: CGPointMake(31.29, 79.23) controlPoint2: CGPointMake(31.07, 79.3)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(30.73, 78.74) controlPoint1: CGPointMake(30.72, 79.13) controlPoint2: CGPointMake(30.65, 78.91)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(34.9, 54.86)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(35.38, 54.7) controlPoint1: CGPointMake(34.99, 54.69) controlPoint2: CGPointMake(35.2, 54.61)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(35.54, 55.18) controlPoint1: CGPointMake(35.55, 54.79) controlPoint2: CGPointMake(35.63, 55)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(35.06, 55.34) controlPoint1: CGPointMake(35.45, 55.35) controlPoint2: CGPointMake(35.24, 55.43)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(34.9, 54.86) controlPoint1: CGPointMake(34.89, 55.25) controlPoint2: CGPointMake(34.81, 55.04)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(20.97, 54.09)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(21.44, 53.92) controlPoint1: CGPointMake(21.05, 53.91) controlPoint2: CGPointMake(21.27, 53.84)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(21.61, 54.4) controlPoint1: CGPointMake(21.62, 54.01) controlPoint2: CGPointMake(21.7, 54.22)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(21.13, 54.56) controlPoint1: CGPointMake(21.52, 54.58) controlPoint2: CGPointMake(21.31, 54.65)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(20.97, 54.09) controlPoint1: CGPointMake(20.96, 54.48) controlPoint2: CGPointMake(20.88, 54.26)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(77.8, 28.09)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(77.63, 28.71) controlPoint1: CGPointMake(77.92, 28.3) controlPoint2: CGPointMake(77.85, 28.58)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(77.01, 28.54) controlPoint1: CGPointMake(77.41, 28.83) controlPoint2: CGPointMake(77.14, 28.76)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(77.18, 27.92) controlPoint1: CGPointMake(76.88, 28.32) controlPoint2: CGPointMake(76.96, 28.05)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(77.8, 28.09) controlPoint1: CGPointMake(77.39, 27.79) controlPoint2: CGPointMake(77.67, 27.87)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(78.11, 33.59)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(77.94, 34.21) controlPoint1: CGPointMake(78.23, 33.8) controlPoint2: CGPointMake(78.16, 34.08)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(77.32, 34.04) controlPoint1: CGPointMake(77.72, 34.33) controlPoint2: CGPointMake(77.45, 34.26)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(77.49, 33.42) controlPoint1: CGPointMake(77.2, 33.82) controlPoint2: CGPointMake(77.27, 33.55)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(78.11, 33.59) controlPoint1: CGPointMake(77.7, 33.29) controlPoint2: CGPointMake(77.98, 33.37)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(49.58, 49.54)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(49.48, 49.93) controlPoint1: CGPointMake(49.66, 49.68) controlPoint2: CGPointMake(49.61, 49.85)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(49.09, 49.83) controlPoint1: CGPointMake(49.34, 50.01) controlPoint2: CGPointMake(49.17, 49.96)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(49.19, 49.44) controlPoint1: CGPointMake(49.01, 49.69) controlPoint2: CGPointMake(49.06, 49.52)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(49.58, 49.54) controlPoint1: CGPointMake(49.33, 49.36) controlPoint2: CGPointMake(49.5, 49.41)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(73.16, 64.94)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(72.99, 65.56) controlPoint1: CGPointMake(73.29, 65.16) controlPoint2: CGPointMake(73.21, 65.44)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(72.37, 65.39) controlPoint1: CGPointMake(72.78, 65.69) controlPoint2: CGPointMake(72.5, 65.61)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(72.54, 64.77) controlPoint1: CGPointMake(72.25, 65.18) controlPoint2: CGPointMake(72.32, 64.9)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(73.16, 64.94) controlPoint1: CGPointMake(72.76, 64.65) controlPoint2: CGPointMake(73.03, 64.72)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(83.91, 50.76)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(83.75, 51.38) controlPoint1: CGPointMake(84.04, 50.97) controlPoint2: CGPointMake(83.96, 51.25)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(83.13, 51.21) controlPoint1: CGPointMake(83.53, 51.5) controlPoint2: CGPointMake(83.25, 51.43)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(83.29, 50.59) controlPoint1: CGPointMake(83, 50.99) controlPoint2: CGPointMake(83.07, 50.72)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(83.91, 50.76) controlPoint1: CGPointMake(83.51, 50.46) controlPoint2: CGPointMake(83.79, 50.54)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(62.37, 53.08)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(61.92, 52.87) controlPoint1: CGPointMake(62.19, 53.15) controlPoint2: CGPointMake(61.98, 53.05)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(62.13, 52.41) controlPoint1: CGPointMake(61.85, 52.68) controlPoint2: CGPointMake(61.95, 52.48)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(62.59, 52.63) controlPoint1: CGPointMake(62.32, 52.35) controlPoint2: CGPointMake(62.52, 52.44)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(62.37, 53.08) controlPoint1: CGPointMake(62.65, 52.81) controlPoint2: CGPointMake(62.56, 53.02)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(75.35, 77.27)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(75.76, 77.68) controlPoint1: CGPointMake(75.58, 77.27) controlPoint2: CGPointMake(75.76, 77.45)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(75.35, 78.09) controlPoint1: CGPointMake(75.76, 77.91) controlPoint2: CGPointMake(75.58, 78.09)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(74.94, 77.68) controlPoint1: CGPointMake(75.12, 78.09) controlPoint2: CGPointMake(74.94, 77.91)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(75.35, 77.27) controlPoint1: CGPointMake(74.94, 77.45) controlPoint2: CGPointMake(75.12, 77.27)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(57.5, 25.15)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(57.04, 24.94) controlPoint1: CGPointMake(57.32, 25.22) controlPoint2: CGPointMake(57.11, 25.12)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(57.26, 24.48) controlPoint1: CGPointMake(56.98, 24.75) controlPoint2: CGPointMake(57.07, 24.55)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(57.71, 24.7) controlPoint1: CGPointMake(57.44, 24.42) controlPoint2: CGPointMake(57.65, 24.51)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(57.5, 25.15) controlPoint1: CGPointMake(57.78, 24.88) controlPoint2: CGPointMake(57.69, 25.09)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(36.49, 75.38)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(36.97, 75.22) controlPoint1: CGPointMake(36.58, 75.2) controlPoint2: CGPointMake(36.79, 75.13)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(37.13, 75.69) controlPoint1: CGPointMake(37.15, 75.3) controlPoint2: CGPointMake(37.22, 75.52)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(36.66, 75.86) controlPoint1: CGPointMake(37.05, 75.87) controlPoint2: CGPointMake(36.83, 75.94)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(36.49, 75.38) controlPoint1: CGPointMake(36.48, 75.77) controlPoint2: CGPointMake(36.41, 75.56)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(68.44, 43.34)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(68.34, 43.73) controlPoint1: CGPointMake(68.52, 43.47) controlPoint2: CGPointMake(68.47, 43.65)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(67.95, 43.62) controlPoint1: CGPointMake(68.2, 43.8) controlPoint2: CGPointMake(68.03, 43.76)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(68.05, 43.23) controlPoint1: CGPointMake(67.87, 43.48) controlPoint2: CGPointMake(67.92, 43.31)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(68.44, 43.34) controlPoint1: CGPointMake(68.19, 43.15) controlPoint2: CGPointMake(68.36, 43.2)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(44.96, 58.22)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(44.86, 58.61) controlPoint1: CGPointMake(45.04, 58.36) controlPoint2: CGPointMake(44.99, 58.53)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(44.47, 58.5) controlPoint1: CGPointMake(44.72, 58.69) controlPoint2: CGPointMake(44.55, 58.64)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(44.57, 58.12) controlPoint1: CGPointMake(44.39, 58.37) controlPoint2: CGPointMake(44.44, 58.19)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(44.96, 58.22) controlPoint1: CGPointMake(44.71, 58.04) controlPoint2: CGPointMake(44.88, 58.08)];
        [roundedRectangle1CopyPath closePath];
        [roundedRectangle1CopyPath moveToPoint: CGPointMake(75.34, 21.87)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(75.24, 22.26) controlPoint1: CGPointMake(75.42, 22) controlPoint2: CGPointMake(75.37, 22.18)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(74.85, 22.15) controlPoint1: CGPointMake(75.1, 22.33) controlPoint2: CGPointMake(74.93, 22.29)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(74.95, 21.76) controlPoint1: CGPointMake(74.77, 22.01) controlPoint2: CGPointMake(74.82, 21.84)];
        [roundedRectangle1CopyPath addCurveToPoint: CGPointMake(75.34, 21.87) controlPoint1: CGPointMake(75.09, 21.68) controlPoint2: CGPointMake(75.26, 21.73)];
        [roundedRectangle1CopyPath closePath];
        [handsWhiteColor setFill];
        [roundedRectangle1CopyPath fill];
    }
    
    
    //// handsGroup
    {
        CGContextSaveGState(context);
        CGContextSetAlpha(context, 0.85);
        CGContextBeginTransparencyLayer(context, NULL);
        
        
        //// handsShape Drawing
        UIBezierPath* handsShapePath = [UIBezierPath bezierPath];
        [handsShapePath moveToPoint: CGPointMake(70.12, 68.7)];
        [handsShapePath addCurveToPoint: CGPointMake(62.34, 70.78) controlPoint1: CGPointMake(68.55, 71.42) controlPoint2: CGPointMake(65.07, 72.36)];
        [handsShapePath addLineToPoint: CGPointMake(49.75, 63.52)];
        [handsShapePath addCurveToPoint: CGPointMake(46.9, 58.58) controlPoint1: CGPointMake(47.92, 62.47) controlPoint2: CGPointMake(46.9, 60.55)];
        [handsShapePath addCurveToPoint: CGPointMake(46.9, 37.05) controlPoint1: CGPointMake(46.9, 55.17) controlPoint2: CGPointMake(46.9, 37.05)];
        [handsShapePath addCurveToPoint: CGPointMake(52.59, 31.35) controlPoint1: CGPointMake(46.9, 33.9) controlPoint2: CGPointMake(49.45, 31.35)];
        [handsShapePath addCurveToPoint: CGPointMake(58.29, 37.05) controlPoint1: CGPointMake(55.74, 31.35) controlPoint2: CGPointMake(58.29, 33.9)];
        [handsShapePath addCurveToPoint: CGPointMake(58.29, 52.88) controlPoint1: CGPointMake(58.29, 37.05) controlPoint2: CGPointMake(58.29, 47.9)];
        [handsShapePath addCurveToPoint: CGPointMake(62.46, 57.7) controlPoint1: CGPointMake(58.29, 55.3) controlPoint2: CGPointMake(58.29, 55.29)];
        [handsShapePath addCurveToPoint: CGPointMake(68.04, 60.91) controlPoint1: CGPointMake(65.11, 59.23) controlPoint2: CGPointMake(68.04, 60.91)];
        [handsShapePath addCurveToPoint: CGPointMake(70.12, 68.7) controlPoint1: CGPointMake(70.76, 62.48) controlPoint2: CGPointMake(71.7, 65.97)];
        [handsShapePath closePath];
        [handsWhiteColor setFill];
        [handsShapePath fill];
        
        ////// handsShape Inner Shadow
        CGRect handsShapeBorderRect = CGRectInset([handsShapePath bounds], -handsInnerShadowBlurRadius, -handsInnerShadowBlurRadius);
        handsShapeBorderRect = CGRectOffset(handsShapeBorderRect, -handsInnerShadowOffset.width, -handsInnerShadowOffset.height);
        handsShapeBorderRect = CGRectInset(CGRectUnion(handsShapeBorderRect, [handsShapePath bounds]), -1, -1);
        
        UIBezierPath* handsShapeNegativePath = [UIBezierPath bezierPathWithRect: handsShapeBorderRect];
        [handsShapeNegativePath appendPath: handsShapePath];
        handsShapeNegativePath.usesEvenOddFillRule = YES;
        
        CGContextSaveGState(context);
        {
            CGFloat xOffset = handsInnerShadowOffset.width + round(handsShapeBorderRect.size.width);
            CGFloat yOffset = handsInnerShadowOffset.height;
            CGContextSetShadowWithColor(context,
                                        CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                        handsInnerShadowBlurRadius,
                                        handsInnerShadow.CGColor);
            
            [handsShapePath addClip];
            CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(handsShapeBorderRect.size.width), 0);
            [handsShapeNegativePath applyTransform: transform];
            [[UIColor grayColor] setFill];
            [handsShapeNegativePath fill];
        }
        CGContextRestoreGState(context);
        
        
        
        CGContextEndTransparencyLayer(context);
        CGContextRestoreGState(context);
    }
    
    
    //// Layer 1 Drawing
    
    

}

@end

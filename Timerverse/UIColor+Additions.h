//
//  UIColor+Additions.h
//  Timerverse
//
//  Created by Larry Ryan on 2/26/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Additions)

// Helper logs
- (void)logHSBA;
- (void)logRGBA;
- (NSString *)stringForHSBA;
- (NSString *)stringForRGBA;

// Getters
- (CGFloat)hueValue;
- (CGFloat)saturationValue;
- (CGFloat)brightnessValue;

- (CGFloat)redValue;
- (CGFloat)greenValue;
- (CGFloat)blueValue;

- (CGFloat)alphaValue;

// Returns a color in the same color space as the receiver with the specified component.
- (UIColor *)colorWithHueComponent:(CGFloat)hue;
- (UIColor *)colorWithSaturationComponent:(CGFloat)saturation;
- (UIColor *)colorWithBrightnessComponent:(CGFloat)brightness;

- (UIColor *)colorWithRedComponent:(CGFloat)red;
- (UIColor *)colorWithGreenComponent:(CGFloat)green;
- (UIColor *)colorWithBlueComponent:(CGFloat)blue;

// Returns pre-defined colors
+ (UIColor *)turquoiseColor;
+ (UIColor *)greenSeaColor;
+ (UIColor *)emerlandColor;
+ (UIColor *)nephritisColor;
+ (UIColor *)peterRiverColor;
+ (UIColor *)belizeHoleColor;
+ (UIColor *)amethystColor;
+ (UIColor *)wisteriaColor;
+ (UIColor *)wetAsphaltColor;
+ (UIColor *)midnightBlueColor;
+ (UIColor *)sunflowerColor;
+ (UIColor *)tangerineColor;
+ (UIColor *)carrotColor;
+ (UIColor *)pumpkinColor;
+ (UIColor *)alizarinColor;
+ (UIColor *)pomegranateColor;
+ (UIColor *)cloudsColor;
+ (UIColor *)silverColor;
+ (UIColor *)concreteColor;
+ (UIColor *)asbestosColor;

// Color From Hex
+ (UIColor *)colorFromHexCode:(NSString *)hexString;

// ChatFeed Colors
+ (UIColor *)chatFeedGreen;

// Timerverse Colors
+ (UIColor *)randomTimerverseColor;
+ (UIColor *)timerverseLightBlue;
+ (UIColor *)timerverseGreen;
+ (UIColor *)timerverseYellow;
+ (UIColor *)timerverseOrange;
+ (UIColor *)timerverseSalmon;
+ (UIColor *)timerversePink;
+ (UIColor *)timerversePurple;
+ (UIColor *)timerverseBlue;

// Random Colors
+ (UIColor *)randomColor;
+ (UIColor *)randomColorWithAlpha:(CGFloat)alpha;

// Returns white or black color for visibilty of content which is over a color
+ (UIColor *)colorForContentsContrastOverColor:(UIColor *)color;

// Returns a color for a point in the screen coordinate space. Hue value is the y-axis, brightness is the x-axis
+ (UIColor *)colorForPoint:(CGPoint)point;

+ (UIColor *)colorForPoint:(CGPoint)point
            withEdgeInsets:(UIEdgeInsets)edgeInsets;

// For The Abyss in Timerverse
+ (UIColor *)colorAbyssInterpolatingBetweenColor:(UIColor *)sourceColor
                                        andColor:(UIColor *)destinationColor
                                  withPercentage:(CGFloat)percentage;

// Returns the interpolating color of a gradient at the specified percentage
+ (UIColor *)colorInterpolatingBetweenColor:(UIColor *)sourceColor
                                   andColor:(UIColor *)destinationColor
                             withPercentage:(CGFloat)percentage;

// Blend colors together.
+ (UIColor *)colorBlendedFromColors:(NSArray *)colors;

// 0.5% will have an even mix.
+ (UIColor *)colorBlendedWithForegroundColor:(UIColor *)foregroundColor
                             backgroundColor:(UIColor *)backgroundColor
                                percentBlend:(CGFloat)percentBlend;

+ (UIColor *)gradientForRect:(CGRect)rect
          withColorFromColor:(UIColor *)sourceColor
                     toColor:(UIColor *)destinationColor;

+ (UIColor *)gradientForText:(id)textObject
          withColorFromColor:(UIColor *)sourceColor
                     toColor:(UIColor *)destinationColor;

@end

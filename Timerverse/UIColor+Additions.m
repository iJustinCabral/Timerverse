//
//  UIColor+Additions.m
//  Timerverse
//
//  Created by Larry Ryan on 2/26/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "UIColor+Additions.h"

@implementation UIColor (Additions)

- (void)logHSBA
{
    NSLog(@"%@", [self stringForHSBA]);
}

- (void)logRGBA
{
    NSLog(@"%@", [self stringForRGBA]);
}

- (NSString *)stringForHSBA
{
    CGFloat h, s, b, a;
    [self getHue:&h saturation:&s brightness:&b alpha:&a];
    
    return [NSString stringWithFormat:@"Hue = %f, Saturation = %f, Brightness = %f, Alpha = %f", h, s, b, a];
}

- (NSString *)stringForRGBA
{
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    
    return [NSString stringWithFormat:@"Red = %f, Green = %f, Blue = %f, Alpha = %f", r, g, b, a];
}

#pragma mark -

// Getters
- (CGFloat)hueValue
{
    CGFloat h, s, b, a;
    [self getHue:&h saturation:&s brightness:&b alpha:&a];
    
    return h;
}

- (CGFloat)saturationValue
{
    CGFloat h, s, b, a;
    [self getHue:&h saturation:&s brightness:&b alpha:&a];
    
    return s;
}

- (CGFloat)brightnessValue
{
    CGFloat h, s, b, a;
    [self getHue:&h saturation:&s brightness:&b alpha:&a];
    
    return b;
}


- (CGFloat)redValue
{
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    
    return r;
}

- (CGFloat)greenValue
{
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    
    return g;
}

- (CGFloat)blueValue
{
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    
    return b;
}

- (CGFloat)alphaValue
{
    CGFloat h, s, b, a;
    [self getHue:&h saturation:&s brightness:&b alpha:&a];
    
    return a;
}


#pragma mark -

- (UIColor *)colorWithHueComponent:(CGFloat)hue
{
    CGFloat h, s, b, a;
    [self getHue:&h saturation:&s brightness:&b alpha:&a];
    
    return [UIColor colorWithHue:hue saturation:s brightness:b alpha:a];
}

- (UIColor *)colorWithSaturationComponent:(CGFloat)saturation
{
    CGFloat h, s, b, a;
    [self getHue:&h saturation:&s brightness:&b alpha:&a];
    
    return [UIColor colorWithHue:h saturation:saturation brightness:b alpha:a];
}

- (UIColor *)colorWithBrightnessComponent:(CGFloat)brightness
{
    CGFloat h, s, b, a;
    [self getHue:&h saturation:&s brightness:&b alpha:&a];
    
    return [UIColor colorWithHue:h saturation:s brightness:brightness alpha:a];
}

- (UIColor *)colorWithRedComponent:(CGFloat)red
{
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    
    return [UIColor colorWithRed:red green:g blue:b alpha:a];
}

- (UIColor *)colorWithGreenComponent:(CGFloat)green
{
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    
    return [UIColor colorWithRed:r green:green blue:b alpha:a];
}

- (UIColor *)colorWithBlueComponent:(CGFloat)blue
{
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    
    return [UIColor colorWithRed:r green:g blue:blue alpha:a];
}

#pragma mark - Colors

+ (UIColor *)colorFromHexCode:(NSString *)hexString
{
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    
    if ([cleanString length] == 3)
    {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    
    if ([cleanString length] == 6)
    {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red = ((baseValue >> 24) & 0xFF) / 255.0f;
    float green = ((baseValue >> 16) & 0xFF) / 255.0f;
    float blue = ((baseValue >> 8) & 0xFF) / 255.0f;
    float alpha = ((baseValue >> 0) & 0xFF) / 255.0f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor *)turquoiseColor
{
    return [UIColor colorFromHexCode:@"1ABC9C"];
}

+ (UIColor *)greenSeaColor
{
    return [UIColor colorFromHexCode:@"16A085"];
}

+ (UIColor *)emerlandColor
{
    return [UIColor colorFromHexCode:@"2ECC71"];
}

+ (UIColor *)nephritisColor
{
    return [UIColor colorFromHexCode:@"27AE60"];
}

+ (UIColor *)peterRiverColor
{
    return [UIColor colorFromHexCode:@"3498DB"];
}

+ (UIColor *)belizeHoleColor
{
    return [UIColor colorFromHexCode:@"2980B9"];
}

+ (UIColor *)amethystColor
{
    return [UIColor colorFromHexCode:@"9B59B6"];
}

+ (UIColor *)wisteriaColor
{
    return [UIColor colorFromHexCode:@"8E44AD"];
}

+ (UIColor *)wetAsphaltColor
{
    return [UIColor colorFromHexCode:@"34495E"];
}

+ (UIColor *)midnightBlueColor
{
    return [UIColor colorFromHexCode:@"2C3E50"];
}

+ (UIColor *)sunflowerColor
{
    return [UIColor colorFromHexCode:@"F1C40F"];
}

+ (UIColor *)tangerineColor
{
    return [UIColor colorFromHexCode:@"F39C12"];
}

+ (UIColor *)carrotColor
{
    return [UIColor colorFromHexCode:@"E67E22"];
}

+ (UIColor *)pumpkinColor
{
    return [UIColor colorFromHexCode:@"D35400"];
}

+ (UIColor *)alizarinColor
{
    return [UIColor colorFromHexCode:@"E74C3C"];
}

+ (UIColor *)pomegranateColor
{
    return [UIColor colorFromHexCode:@"C0392B"];
}

+ (UIColor *)cloudsColor
{
    return [UIColor colorFromHexCode:@"ECF0F1"];
}

+ (UIColor *)silverColor
{
    return [UIColor colorFromHexCode:@"BDC3C7"];
}

+ (UIColor *)concreteColor
{
    return [UIColor colorFromHexCode:@"95A5A6"];
}

+ (UIColor *)asbestosColor
{
    return [UIColor colorFromHexCode:@"7F8C8D"];
}

+ (UIColor *)chatFeedGreen
{
    return [UIColor colorFromHexCode:@"4ad9af"];
}


#pragma mark - Timerverse Colors

+ (UIColor *)randomTimerverseColor
{
    NSArray *colorArray = @[[UIColor timerverseYellow],
                            [UIColor timerversePurple],
                            [UIColor timerversePink],
                            [UIColor timerverseBlue],
                            [UIColor timerverseLightBlue],
                            [UIColor timerverseOrange],
                            [UIColor timerverseSalmon],
                            [UIColor timerverseGreen]];
    
    NSInteger randomIndex = (NSUInteger)arc4random() % [colorArray count];
    UIColor *randomColor = [colorArray objectAtIndex:randomIndex];
    
    return randomColor;
}

+ (UIColor *)timerverseLightBlue
{
    return [UIColor colorFromHexCode:@"2da9c3"];
}

+ (UIColor *)timerverseGreen
{
    return [UIColor colorFromHexCode:@"67c4ad"];
}

+ (UIColor *)timerverseYellow
{
    return [UIColor colorFromHexCode:@"f8d942"];
}

+ (UIColor *)timerverseOrange
{
    return [UIColor colorFromHexCode:@"f88a57"];
}

+ (UIColor *)timerverseSalmon
{
    return [UIColor colorFromHexCode:@"f25f75"];
}

+ (UIColor *)timerversePink
{
    return [UIColor colorFromHexCode:@"f33f97"];
}

+ (UIColor *)timerversePurple
{
    return [UIColor colorFromHexCode:@"913cce"];
}

+ (UIColor *)timerverseBlue
{
    return [UIColor colorFromHexCode:@"358bd4"];
}


#pragma mark - Random

+ (UIColor *)randomColor
{
    return [self randomColorWithAlpha:1.0f];
}

+ (UIColor *)randomColorWithAlpha:(CGFloat)alpha
{
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

+ (UIColor *)colorAbyssInterpolatingBetweenColor:(UIColor *)sourceColor
                                        andColor:(UIColor *)destinationColor
                                  withPercentage:(CGFloat)percentage
{
    // Get the HSBA values of the source
    CGFloat sourceHue, sourceSaturation, sourceBrightness, sourceAlpha;
    [sourceColor getHue:&sourceHue saturation:&sourceSaturation brightness:&sourceBrightness alpha:&sourceAlpha];
    
    // Get the HSBA values of the destination
    CGFloat destinationHue, destinationSaturation, destinationBrightness, destinationAlpha;
    [destinationColor getHue:&destinationHue saturation:&destinationSaturation brightness:&destinationBrightness alpha:&destinationAlpha];
    
    // Get the range for each value
    CGFloat brightness = fabs(sourceBrightness - destinationBrightness);
    
    brightness = (brightness * percentage) + MIN(sourceBrightness, destinationBrightness);
    
    return [UIColor colorWithHue:destinationHue
                      saturation:destinationSaturation
                      brightness:brightness
                           alpha:destinationAlpha];
}

+ (UIColor *)colorInterpolatingBetweenColor:(UIColor *)sourceColor
                                   andColor:(UIColor *)destinationColor
                             withPercentage:(CGFloat)percentage
{
    // Get the HSBA values of the source
    CGFloat sourceHue, sourceSaturation, sourceBrightness, sourceAlpha;
    [sourceColor getHue:&sourceHue saturation:&sourceSaturation brightness:&sourceBrightness alpha:&sourceAlpha];
    
    // Get the HSBA values of the destination
    CGFloat destinationHue, destinationSaturation, destinationBrightness, destinationAlpha;
    [destinationColor getHue:&destinationHue saturation:&destinationSaturation brightness:&destinationBrightness alpha:&destinationAlpha];
    
    // Get the range for each value
    CGFloat hue = fabs(sourceHue - destinationHue);
    CGFloat saturation = (sourceSaturation - destinationSaturation);
    CGFloat brightness = (sourceBrightness - destinationBrightness);
    CGFloat alpha = (sourceAlpha - destinationAlpha);
    
    hue = (hue * percentage) + MIN(sourceHue, destinationHue);
    saturation = (saturation * percentage) + MIN(sourceSaturation, destinationSaturation);
    brightness = (brightness * percentage) + MIN(sourceBrightness, destinationBrightness);
    alpha = (alpha * percentage) + MIN(sourceAlpha, destinationAlpha);
    
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

+ (UIColor *)colorBlendedWithForegroundColor:(UIColor *)foregroundColor
                             backgroundColor:(UIColor *)backgroundColor
                                percentBlend:(CGFloat) percentBlend
{
    CGFloat onRed, offRed, newRed, onGreen, offGreen, newGreen, onBlue, offBlue, newBlue, onWhite, offWhite;
    
    if ([foregroundColor getWhite:&onWhite alpha:nil])
    {
        onRed = onWhite;
        onBlue = onWhite;
        onGreen = onWhite;
    }
    else
    {
        [foregroundColor getRed:&onRed green:&onGreen blue:&onBlue alpha:nil];
    }
    
    if ([backgroundColor getWhite:&offWhite alpha:nil])
    {
        offRed = offWhite;
        offBlue = offWhite;
        offGreen = offWhite;
    }
    else
    {
        [backgroundColor getRed:&offRed green:&offGreen blue:&offBlue alpha:nil];
    }
    
    newRed = onRed * percentBlend + offRed * (1 - percentBlend);
    newGreen = onGreen * percentBlend + offGreen * (1 - percentBlend);
    newBlue = onBlue * percentBlend + offBlue * (1 - percentBlend);
    
    return [UIColor colorWithRed:newRed green:newGreen blue:newBlue alpha:1.0];
}

+ (UIColor *)colorBlendedFrommColors:(NSArray *)colors
{
    if (!colors || colors.count == 0) return nil;
    
    if (colors.count == 1) return colors[0];
    
    NSMutableArray *hueArray = [@[] mutableCopy];
    NSMutableArray *saturationArray = [@[] mutableCopy];
    NSMutableArray *brightnessArray = [@[] mutableCopy];
    
    for (UIColor *color in colors)
    {
        CGFloat hue, saturation, brightness, alpha;
        [color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
        
        [hueArray addObject:@(hue)];
        [saturationArray addObject:@(saturation)];
        [brightnessArray addObject:@(brightness)];
    }
    
//    CGFloat precetageToBlend = colors.count > 1 ? 0.5f: 1.0f;
    CGFloat newHue = 0.0f, newSaturation = 0.0f, newBrightness = 0.0f;
    
    for (NSUInteger index = 0; index < hueArray.count; index++)
    {
        newHue += [hueArray[index] floatValue];
        newSaturation += [saturationArray[index] floatValue];
        newBrightness += [brightnessArray[index] floatValue];
    }
    
    newHue = (newHue / hueArray.count);
    newSaturation = (newSaturation / hueArray.count);
    newBrightness = (newBrightness / hueArray.count);
    
    return [UIColor colorWithHue:newHue saturation:newSaturation brightness:newBrightness alpha:1.0f];
}

+ (UIColor *)colorBlendedFromColors:(NSArray *)colors
{
    if (!colors || colors.count == 0) return nil;
    
    if (colors.count == 1) return colors[0];
    
    NSMutableArray *redArray = [NSMutableArray array];
    NSMutableArray *greenArray = [NSMutableArray array];
    NSMutableArray *blueArray = [NSMutableArray array];
    
    for (UIColor *color in colors)
    {
        CGFloat red, green, blue;
        
        [color getRed:&red green:&green blue:&blue alpha:nil];
        
        [redArray addObject:@(red)];
        [greenArray addObject:@(green)];
        [blueArray addObject:@(blue)];
    }
    
    CGFloat precetageToBlend = colors.count > 1 ? 0.8f: 1.0f; // > 1 == 0.5
    CGFloat newRed = 0.0f, newGreen = 0.0f, newBlue = 0.0f;
    
    for (NSUInteger index = 0; index < redArray.count; index++)
    {
        newRed += [redArray[index] floatValue];
        newGreen += [greenArray[index] floatValue];
        newBlue += [blueArray[index] floatValue];
    }
    
    newRed = (newRed / redArray.count) * precetageToBlend;
    newGreen = (newGreen / greenArray.count) * precetageToBlend;
    newBlue = (newBlue / blueArray.count) * precetageToBlend;
    
    UIColor *color = [UIColor colorWithRed:newRed green:newGreen blue:newBlue alpha:1.0];
    
    return color;
}

+ (UIColor *)colorForContentsContrastOverColor:(UIColor *)color
{
    NSUInteger threshold = 105;
    
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    
    NSUInteger delta = (r * 0.229) + (g * 0.587) + (b * 0.114);
    
    return (255 - delta < threshold) ? [UIColor blackColor] : [UIColor whiteColor];
}

+ (UIColor *)colorForPoint:(CGPoint)point
{
    return [self colorForPoint:point
                withEdgeInsets:UIEdgeInsetsZero];
}

+ (UIColor *)colorForPoint:(CGPoint)point
            withEdgeInsets:(UIEdgeInsets)edgeInsets
{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    CGFloat x = point.x;
    CGFloat y = point.y;
    
    CGFloat xPercentage = (x - edgeInsets.left) / (screenSize.width - (edgeInsets.left + edgeInsets.right));
    CGFloat yPercentage = (y - edgeInsets.top) / (screenSize.height - (edgeInsets.top + edgeInsets.bottom));
    
    if (xPercentage < 0.0f) xPercentage = 0.0f;
    if (xPercentage > 1.0f) xPercentage = 1.0f;
    if (yPercentage < 0.0f) yPercentage = 0.0f;
    if (yPercentage > 1.0f) yPercentage = 1.0f;
    
    // Adjust the x so the brightness can't go too low
    CGFloat minSaturation = 0.6f;
    xPercentage = ((1.0f - minSaturation) * xPercentage) + minSaturation;
    
    return [UIColor colorWithHue:yPercentage
                      saturation:1.0f
                      brightness:xPercentage
                           alpha:1.0f];
}

+ (UIColor *)gradientForRect:(CGRect)rect
          withColorFromColor:(UIColor *)sourceColor
                     toColor:(UIColor *)destinationColor
{
    UIImage *image = [self imageGradientFromRect:rect withColorFromColor:sourceColor toColor:destinationColor];
    
    return [UIColor colorWithPatternImage:image];
}

+ (UIColor *)gradientForText:(id)textObject
          withColorFromColor:(UIColor *)sourceColor
                     toColor:(UIColor *)destinationColor
{
    if (![textObject isKindOfClass:[UILabel class]]
        || ![textObject isKindOfClass:[UITextView class]])
    {
        return [UIColor darkGrayColor];
    }
    
    UIFont *font= (UIFont *)[textObject valueForKey:@"font"];
    
    CGSize textSize = [[textObject text] sizeWithAttributes:@{NSFontAttributeName: font}];
    
    CGRect textRect;
    textRect.origin = CGPointZero;
    textRect.size = textSize;
    
    UIImage *image = [self imageGradientFromRect:textRect
                              withColorFromColor:sourceColor
                                         toColor:destinationColor];
    
    return [UIColor colorWithPatternImage:image];
}

+ (UIImage *)imageGradientFromRect:(CGRect)rect
                withColorFromColor:(UIColor *)sourceColor
                           toColor:(UIColor *)destinationColor
{
    CGFloat width = rect.size.width;         // max 1024 due to Core Graphics limitations
    CGFloat height = rect.size.height;       // max 1024 due to Core Graphics limitations
    
    // create a new bitmap image context
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    // get context
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // push context to make it current (need to do this manually because we are not drawing in a UIView)
    UIGraphicsPushContext(context);
    
    // draw gradient
    CGGradientRef glossGradient;
    CGColorSpaceRef rgbColorspace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    
    CGFloat hue, saturation, brightness, alpha;
    [sourceColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
    CGFloat destinationHue, destinationSaturation, destinationBrightness, destinationAlpha;
    [destinationColor getHue:&destinationHue saturation:&destinationSaturation brightness:&destinationBrightness alpha:&destinationAlpha];
    
    CGFloat components[8] = { hue, saturation, brightness, alpha,  // Start color
        destinationHue, destinationSaturation, destinationBrightness, destinationAlpha }; // End color
    rgbColorspace = CGColorSpaceCreateDeviceRGB();
    glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);
    CGPoint topCenter = CGPointMake(0, 0);
    CGPoint bottomCenter = CGPointMake(0, rect.size.height);
    CGContextDrawLinearGradient(context, glossGradient, topCenter, bottomCenter, 0);
    
    CGGradientRelease(glossGradient);
    CGColorSpaceRelease(rgbColorspace);
    
    // pop context
    UIGraphicsPopContext();
    
    // get a UIImage from the image context
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // clean up drawing environment
    UIGraphicsEndImageContext();
    
    return gradientImage;
}

@end

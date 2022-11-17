//
//  UIImage+Overlay.m
//  Timerverse
//
//  Created by Justin Cabral on 2/19/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "UIImage+Overlay.h"

@implementation UIImage (Overlay)

- (UIImage *)imageWithColor:(UIColor *)newColor
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, self.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    CGContextClipToMask(context, rect, self.CGImage);
    [newColor setFill];
    CGContextFillRect(context, rect);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end

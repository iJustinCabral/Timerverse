//
//  Color.m
//  Timerverse
//
//  Created by Larry Ryan on 1/25/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "Color.h"
#import "Item.h"


@implementation Color

@dynamic alpha;
@dynamic brightness;
@dynamic hue;
@dynamic saturation;
@dynamic item;

- (UIColor *)UIColor
{
    return [UIColor colorWithHue:self.hue.floatValue
                      saturation:self.saturation.floatValue
                      brightness:self.brightness.floatValue
                           alpha:self.alpha.floatValue];
}

@end

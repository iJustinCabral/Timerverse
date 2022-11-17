//
//  TMVNonInteractiveScrollView.m
//  Timerverse
//
//  Created by Larry Ryan on 3/2/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVNonInteractiveScrollView.h"

@implementation TMVNonInteractiveScrollView

// Set the point to only effect subviews, and allow other touches to pass through
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    for (UIView *view in self.subviews)
    {
        if (!view.hidden && view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
            return [super pointInside:point withEvent:event];
    }
    
    return [super pointInside:point withEvent:event];
}

@end

//
//  TMVNonInteractiveView.m
//  Timerverse
//
//  Created by Larry Ryan on 2/28/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVNonInteractiveView.h"

@implementation TMVNonInteractiveView

- (void)setInteraction:(BOOL)interaction
{
    if (_interaction == interaction) return;
    
    _interaction = interaction;
}

// Set the point to only effect subviews, and allow other touches to pass through
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.interaction && CGRectContainsPoint(self.frame, point))
    {
        return [super pointInside:point withEvent:event];
    }
    else
    {
        for (UIView *view in self.subviews)
        {
            if (!view.hidden && view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
                return [super pointInside:point withEvent:event];
        }
    }
    
    return NO;
}

@end

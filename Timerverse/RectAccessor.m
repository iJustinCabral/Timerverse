//
//  RectAccessor.m
//  Fezicon
//
//  Created by Larry Ryan on 5/20/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "RectAccessor.h"

@implementation RectAccessor

CGPoint CGRectGetCenter(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

CGPoint CGRectGetTopLeft(CGRect rect)
{
    return CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
}

CGPoint CGRectGetTopRight(CGRect rect)
{
    return CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
}

CGPoint CGRectGetBottomLeft(CGRect rect)
{
    return CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
}

CGPoint CGRectGetBottomRight(CGRect rect)
{
    return CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
}

CGPoint CGRectGetTopMid(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
}

CGPoint CGRectGetBottomMid(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
}

CGPoint CGRectGetLeftMid(CGRect rect)
{
    return CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect));
}

CGPoint CGRectGetRightMid(CGRect rect)
{
    return CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect));
}

CGFloat CGRectGetHalfWidth(CGRect rect)
{
    return rect.size.width / 2;
}

CGFloat CGRectGetHalfHeight(CGRect rect)
{
    return rect.size.height / 2;
}

CGRect CGRectWithOrigin(CGRect rect, CGPoint origin)
{
    rect.origin = origin;
    
    return rect;
}

CGRect CGRectWithX(CGRect rect, CGFloat x)
{
    rect.origin.x = x;
    
    return rect;
}

CGRect CGRectWithY(CGRect rect, CGFloat y)
{
    rect.origin.y = y;
    
    return rect;
}

CGRect CGRectWithSize(CGRect rect, CGSize size)
{
    rect.size = size;
    
    return rect;
}

CGRect CGRectWithWidth(CGRect rect, CGFloat width)
{
    rect.size.width = width;
    
    return rect;
}

CGRect CGRectWithHeight(CGRect rect, CGFloat height)
{
    rect.size.height = height;
    
    return rect;
}

CGRect CGRectWithCenter(CGRect rect, CGPoint center)
{
    rect.origin.x = center.x - (rect.size.width / 2);
    rect.origin.y = center.y - (rect.size.height / 2);
    
    return rect;
}

CGRect CGRectWithSizeSameCenter(CGRect rect, CGSize size)
{
    CGRect oldRect = rect;
    
    rect.size = size;
    
    CGFloat widthDifference = (oldRect.size.width - rect.size.width) / 2;
    CGFloat heightDifference = (oldRect.size.height - rect.size.height) / 2;
    
    rect.origin.x += widthDifference;
    rect.origin.y += heightDifference;
    
    return rect;
}

CGRect CGRectWithWidthSameCenter(CGRect rect, CGFloat width)
{
    CGRect oldRect = rect;
    
    rect.size.width = width;
    
    CGFloat widthDifference = (oldRect.size.width - rect.size.width) / 2;
    
    rect.origin.x += widthDifference;
    
    return rect;
}

CGRect CGRectWithHeightSameCenter(CGRect rect, CGFloat height)
{
    CGRect oldRect = rect;
    
    rect.size.height = height;
    
    CGFloat heightDifference = (oldRect.size.height - rect.size.height) / 2;
    
    rect.origin.y += heightDifference;
    
    return rect;
}

CGFloat CGRectGetParimeter(CGRect rect)
{
    return (rect.size.width * 2) + (rect.size.height * 2);
}

CGFloat CGRectGetArea(CGRect rect)
{
    return rect.size.width * rect.size.height;
}

CGRect CGRectGetSmallerAreaRect(CGRect rect1, CGRect rect2)
{
    return CGRectGetArea(rect1) < CGRectGetArea(rect2) ? rect1 : rect2;
}

CGRect CGRectGetLargerAreaRect(CGRect rect1, CGRect rect2)
{
    return CGRectGetArea(rect1) > CGRectGetArea(rect2) ? rect1 : rect2;
}

CGRect CGRectGetSmallerWidthRect(CGRect rect1, CGRect rect2)
{
    return rect1.size.width < rect2.size.width ? rect1 : rect2;
}

CGRect CGRectGetLargerWidthRect(CGRect rect1, CGRect rect2)
{
    return rect1.size.width > rect2.size.width ? rect1 : rect2;
}

CGRect CGRectGetSmallerHeightRect(CGRect rect1, CGRect rect2)
{
    return rect1.size.height < rect2.size.height ? rect1 : rect2;
}

CGRect CGRectGetLargerHeightRect(CGRect rect1, CGRect rect2)
{
    return rect1.size.height > rect2.size.height ? rect1 : rect2;
}

CGSize CGRectIntersectionDistance(CGRect rect1, CGRect rect2)
{
    if (CGRectIntersectsRect(rect1, rect2)) return CGSizeZero;
    
    CGFloat widthDifference, heightDifference;
    
    if (CGRectGetMaxX(rect1) < CGRectGetMinX(rect2))
    {
        widthDifference = CGRectGetMaxX(rect1) - CGRectGetMinX(rect2);
    }
    else if (CGRectGetMaxX(rect2) < CGRectGetMinX(rect1))
    {
        widthDifference = CGRectGetMaxX(rect2) - CGRectGetMinX(rect1);
    }
    else
    {
        widthDifference = 0.0f;
    }
    
    if (CGRectGetMaxY(rect1) < CGRectGetMinY(rect2))
    {
        heightDifference = CGRectGetMaxY(rect1) - CGRectGetMinY(rect2);
    }
    else if (CGRectGetMaxY(rect2) < CGRectGetMinY(rect1))
    {
        heightDifference = CGRectGetMaxY(rect2) - CGRectGetMinY(rect1);
    }
    else
    {
        heightDifference = 0.0f;
    }
    
    return CGSizeMake(widthDifference, heightDifference);
}

CGSize CGRectIntersectionAbsoluteDistance(CGRect rect1, CGRect rect2)
{
    CGSize distanceSize = CGRectIntersectionDistance(rect1, rect2);
    
    return CGSizeMake(fabs(distanceSize.width), fabs(distanceSize.height));
}

BOOL CGRectIntersectsRectWithProximity(CGRect rect1, CGRect rect2, CGFloat proximity)
{
    rect1 = CGRectWithSizeSameCenter(rect1, CGSizeMake(rect1.size.width + (proximity * 2),
                                                       rect1.size.height + (proximity * 2)));
    
    return CGRectIntersectsRect(rect1, rect2);
}

BOOL CGRectIntersectsRectOverHalf(CGRect rect1, CGRect rect2)
{
    if (!CGRectIntersectsRect(rect1, rect2)) return NO;
    
    CGFloat area = CGRectGetArea(CGRectIntersection(rect1, rect2));
    
    return area > CGRectGetArea(rect1) / 2;
}

@end

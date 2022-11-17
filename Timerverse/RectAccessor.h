//
//  RectAccessor.h
//  Fezicon
//
//  Created by Larry Ryan on 5/20/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RectAccessor : NSObject

CGPoint CGRectGetCenter(CGRect rect);

CGPoint CGRectGetTopLeft(CGRect rect);
CGPoint CGRectGetTopRight(CGRect rect);
CGPoint CGRectGetBottomLeft(CGRect rect);
CGPoint CGRectGetBottomRight(CGRect rect);

CGPoint CGRectGetTopMid(CGRect rect);
CGPoint CGRectGetBottomMid(CGRect rect);
CGPoint CGRectGetLeftMid(CGRect rect);
CGPoint CGRectGetRightMid(CGRect rect);

CGFloat CGRectGetHalfWidth(CGRect rect);
CGFloat CGRectGetHalfHeight(CGRect rect);

CGRect CGRectWithCenter(CGRect rect, CGPoint center);

CGRect CGRectWithOrigin(CGRect rect, CGPoint origin);
CGRect CGRectWithX(CGRect rect, CGFloat x);
CGRect CGRectWithY(CGRect rect, CGFloat y);

CGRect CGRectWithSize(CGRect rect, CGSize size);
CGRect CGRectWithWidth(CGRect rect, CGFloat width);
CGRect CGRectWithHeight(CGRect rect, CGFloat height);

CGRect CGRectWithSizeSameCenter(CGRect rect, CGSize size);
CGRect CGRectWithWidthSameCenter(CGRect rect, CGFloat width);
CGRect CGRectWithHeightSameCenter(CGRect rect, CGFloat height);

CGFloat CGRectGetParimeter(CGRect rect);
CGFloat CGRectGetArea(CGRect rect);

CGRect CGRectGetSmallerAreaRect(CGRect rect1, CGRect rect2);
CGRect CGRectGetLargerAreaRect(CGRect rect1, CGRect rect2);

CGRect CGRectGetSmallerWidthRect(CGRect rect1, CGRect rect2);
CGRect CGRectGetLargerWidthRect(CGRect rect1, CGRect rect2);

CGRect CGRectGetSmallerHeightRect(CGRect rect1, CGRect rect2);
CGRect CGRectGetLargerHeightRect(CGRect rect1, CGRect rect2);

CGSize CGRectIntersectionDistance(CGRect rect1, CGRect rect2);
CGSize CGRectIntersectionAbsoluteDistance(CGRect rect1, CGRect rect2);

BOOL CGRectIntersectsRectWithProximity(CGRect rect1, CGRect rect2, CGFloat proximity);
BOOL CGRectIntersectsRectOverHalf(CGRect rect1, CGRect rect2);

@end

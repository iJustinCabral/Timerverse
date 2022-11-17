//
//  ViewFrameAccessor.m
//  ViewFrameAccessor
//
//  Created by Alex Denisov on 18.03.12.
//  Copyright (c) 2013 okolodev.org. All rights reserved.
//

#import "ViewFrameAccessor.h"

@implementation View (FrameAccessor)

#pragma mark - Frame

#pragma mark Frame

- (CGPoint)origin
{
    return self.frame.origin;
}

- (void)setOrigin:(CGPoint)newOrigin
{
    CGRect newFrame = self.frame;
    newFrame.origin = newOrigin;
    self.frame = newFrame;
}

- (CGSize)size
{
    return self.frame.size;
}

- (void)setSize:(CGSize)newSize
{
    CGRect newFrame = self.frame;
    newFrame.size = newSize;
    self.frame = newFrame;
}


#pragma mark Frame Origin

- (CGFloat)x
{
    return self.frame.origin.x;
}

- (void)setX:(CGFloat)newX
{
    CGRect newFrame = self.frame;
    newFrame.origin.x = newX;
    self.frame = newFrame;
}

- (CGFloat)y
{
    return self.frame.origin.y;
}

- (void)setY:(CGFloat)newY
{
    CGRect newFrame = self.frame;
    newFrame.origin.y = newY;
    self.frame = newFrame;
}


#pragma mark Corners

- (void)setTopLeft:(CGPoint)topLeft
{
    self.origin = topLeft;
}

- (CGPoint)topLeft
{
    return CGPointMake(self.left, self.top);
}

- (void)setTopRight:(CGPoint)topRight
{
    self.origin = CGPointMake(topRight.x - self.width, topRight.y);
}

- (CGPoint)topRight
{
    return CGPointMake(self.right, self.top);
}

- (void)setBottomLeft:(CGPoint)bottomLeft
{
    self.origin = CGPointMake(bottomLeft.x, bottomLeft.y - self.height);
}

- (CGPoint)bottomLeft
{
    return CGPointMake(self.left, self.bottom);
}

- (void)setBottomRight:(CGPoint)bottomRight
{
    self.origin = CGPointMake(bottomRight.x - self.width, bottomRight.y - self.height);
}

- (CGPoint)bottomRight
{
    return CGPointMake(self.right, self.bottom);
}

#pragma mark Frame Size

- (CGFloat)halfHeight
{
    return self.height / 2;
}

- (CGFloat)height
{
    return self.frame.size.height;
}

- (void)setHeight:(CGFloat)newHeight
{
    CGRect newFrame = self.frame;
    newFrame.size.height = newHeight;
    self.frame = newFrame;
}

- (CGFloat)halfWidth
{
    return self.width / 2;
}

- (CGFloat)width
{
    return self.frame.size.width;
}

- (void)setWidth:(CGFloat)newWidth
{
    CGRect newFrame = self.frame;
    newFrame.size.width = newWidth;
    self.frame = newFrame;
}


#pragma mark Frame Borders

- (CGFloat)left
{
    return self.x;
}

- (void)setLeft:(CGFloat)left
{
    self.x = left;
}

- (CGFloat)right
{
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setRight:(CGFloat)right
{
    self.x = right - self.width;
}

- (CGFloat)top
{
    return self.y;
}

- (void)setTop:(CGFloat)top
{
    self.y = top;
}

- (CGFloat)bottom
{
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setBottom:(CGFloat)bottom
{
    self.y = bottom - self.height;
}

#pragma mark - Frame Additives

- (void)setOriginWithAdditive:(CGPoint)additiveOrigin
{
    [self setOrigin:CGPointMake(self.x + additiveOrigin.x, self.y + additiveOrigin.y)];
}

- (void)setSizeWithAdditive:(CGSize)additiveSize
{
    [self setSize:CGSizeMake(self.width + additiveSize.width, self.height + additiveSize.height)];
}


#pragma mark Frame Origin

- (void)setXWithAdditive:(CGFloat)additiveX
{
    [self setX:self.x + additiveX];
}

- (void)setYWithAdditive:(CGFloat)additiveY
{
    [self setY:self.y + additiveY];
}


#pragma mark Frame Size

- (void)setHeightWithAdditive:(CGFloat)additiveHeight
{
    [self setHeight:self.size.height + additiveHeight];
}

- (void)setWidthWithAdditive:(CGFloat)additiveWidth
{
    [self setWidth:self.size.width + additiveWidth];
}

#pragma mark - Center Point

#if !IS_IOS_DEVICE
- (CGPoint)center
{
    return CGPointMake(self.left + self.middleX, self.top + self.middleY);
}

- (void)setCenter:(CGPoint)newCenter
{
    self.left = newCenter.x - self.middleX;
    self.top = newCenter.y - self.middleY;
}
#endif

- (CGFloat)centerX
{
    return self.center.x;
}

- (void)setCenterX:(CGFloat)newCenterX
{
    self.center = CGPointMake(newCenterX, self.center.y);
}

- (CGFloat)centerY
{
    return self.center.y;
}

- (void)setCenterY:(CGFloat)newCenterY
{
    self.center = CGPointMake(self.center.x, newCenterY);
}

- (void)setCenterXWithAdditive:(CGFloat)additiveX
{
    [self setCenterX:self.center.x + additiveX];
}

- (void)setCenterYWithAdditive:(CGFloat)additiveY
{
    [self setCenterY:self.center.y + additiveY];
}


#pragma mark Middle Point

- (CGPoint)middlePoint
{
    return CGPointMake(self.middleX, self.middleY);
}

- (CGFloat)middleX
{
    return self.width / 2;
}

- (CGFloat)middleY
{
    return self.height / 2;
}

@end
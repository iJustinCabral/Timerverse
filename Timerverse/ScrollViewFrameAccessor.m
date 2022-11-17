//
//  ScrollViewFrameAccessor.m
//  ScrollViewFrameAccessor
//
//  Created by Ivanenko Dmitry on 28.10.13.
//  Copyright (c) 2013 Artox Lab. All rights reserved.
//

#import "ScrollViewFrameAccessor.h"


@implementation UIScrollView (FrameAccessor)

#pragma mark Content Offset

- (CGFloat)contentOffsetX
{
    return self.contentOffset.x;
}

- (CGFloat)contentOffsetY
{
    return self.contentOffset.y;
}

- (void)setContentOffsetX:(CGFloat)newContentOffsetX
{
    self.contentOffset = CGPointMake(newContentOffsetX, self.contentOffsetY);
}

- (void)setContentOffsetY:(CGFloat)newContentOffsetY
{
    self.contentOffset = CGPointMake(self.contentOffsetX, newContentOffsetY);
}


#pragma mark Content Size

- (CGFloat)contentSizeWidth
{
    return self.contentSize.width;
}

- (CGFloat)contentSizeHeight
{
    return self.contentSize.height;
}

- (void)setContentSizeWidth:(CGFloat)newContentSizeWidth
{
    self.contentSize = CGSizeMake(newContentSizeWidth, self.contentSizeHeight);
}

- (void)setContentSizeHeight:(CGFloat)newContentSizeHeight
{
    self.contentSize = CGSizeMake(self.contentSizeWidth, newContentSizeHeight);
}


#pragma mark Content Inset

- (CGFloat)contentInsetTop
{
    return self.contentInset.top;
}

- (CGFloat)contentInsetRight
{
    return self.contentInset.right;
}

- (CGFloat)contentInsetBottom
{
    return self.contentInset.bottom;
}

- (CGFloat)contentInsetLeft
{
    return self.contentInset.left;
}

- (void)setContentInsetTop:(CGFloat)newContentInsetTop
{
    UIEdgeInsets newContentInset = self.contentInset;
    newContentInset.top = newContentInsetTop;
    self.contentInset = newContentInset;
}

- (void)setContentInsetRight:(CGFloat)newContentInsetRight
{
    UIEdgeInsets newContentInset = self.contentInset;
    newContentInset.right = newContentInsetRight;
    self.contentInset = newContentInset;
}

- (void)setContentInsetBottom:(CGFloat)newContentInsetBottom
{
    UIEdgeInsets newContentInset = self.contentInset;
    newContentInset.bottom = newContentInsetBottom;
    self.contentInset = newContentInset;
}

- (void)setContentInsetLeft:(CGFloat)newContentInsetLeft
{
    UIEdgeInsets newContentInset = self.contentInset;
    newContentInset.left = newContentInsetLeft;
    self.contentInset = newContentInset;
}

#pragma mark - Additives

#pragma mark Content Offset

- (void)setContentOffsetXWithAdditive:(CGFloat)additiveContentOffsetX
{
    [self setContentOffsetX:self.contentOffsetX + additiveContentOffsetX];
}

- (void)setContentOffsetYWithAdditive:(CGFloat)additiveContentOffsetY
{
    [self setContentOffsetY:self.contentOffsetY + additiveContentOffsetY];
}


#pragma mark Content Size

- (void)setContentSizeWidthWithAdditive:(CGFloat)additiveContentSizeWidth
{
    [self setContentSizeWidth:self.contentSizeWidth + additiveContentSizeWidth];
}

- (void)setContentSizeHeightWithAdditive:(CGFloat)additiveContentSizeHeight
{
    [self setContentSizeHeight:self.contentSizeHeight + additiveContentSizeHeight];
}


#pragma mark Content Inset

- (void)setContentInsetTopWithAdditive:(CGFloat)additiveContentInsetTop
{
    [self setContentInsetTop:self.top + additiveContentInsetTop];
}

- (void)setContentInsetRightWithAdditive:(CGFloat)additiveContentInsetRight
{
    [self setContentInsetRight:self.right + additiveContentInsetRight];
}

- (void)setContentInsetBottomWithAdditive:(CGFloat)additiveContentInsetBottom
{
    [self setContentInsetBottom:self.bottom + additiveContentInsetBottom];
}

- (void)setContentInsetLeftWithAdditive:(CGFloat)additiveContentInsetLeft
{
    [self setContentInsetLeft:self.left + additiveContentInsetLeft];
}

@end
//
//  ScrollViewFrameAccessor.h
//  ScrollViewFrameAccessor
//
//  Created by Ivanenko Dmitry on 28.10.13.
//  Copyright (c) 2013 Artox Lab. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIScrollView (FrameAccessor)

// Content Offset
@property (nonatomic) CGFloat contentOffsetX;
@property (nonatomic) CGFloat contentOffsetY;

// Content Size
@property (nonatomic) CGFloat contentSizeWidth;
@property (nonatomic) CGFloat contentSizeHeight;

// Content Inset
@property (nonatomic) CGFloat contentInsetTop;
@property (nonatomic) CGFloat contentInsetLeft;
@property (nonatomic) CGFloat contentInsetBottom;
@property (nonatomic) CGFloat contentInsetRight;

#pragma mark - Additives

// Content Offset Additives
- (void)setContentOffsetXWithAdditive:(CGFloat)additiveContentOffsetX;
- (void)setContentOffsetYWithAdditive:(CGFloat)additiveContentOffsetY;

// Content Size Additives
- (void)setContentSizeWidthWithAdditive:(CGFloat)additiveContentSizeWidth;
- (void)setContentSizeHeightWithAdditive:(CGFloat)additiveContentSizeHeight;

// Content Inset Additives
- (void)setContentInsetTopWithAdditive:(CGFloat)additiveContentInsetTop;
- (void)setContentInsetRightWithAdditive:(CGFloat)additiveContentInsetRight;
- (void)setContentInsetBottomWithAdditive:(CGFloat)additiveContentInsetBottom;
- (void)setContentInsetLeftWithAdditive:(CGFloat)additiveContentInsetLeft;

@end
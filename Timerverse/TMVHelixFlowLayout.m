
//
//  TMVHelixFlowLayout.m
//  LRHelixTableView
//
//  Created by Larry Ryan on 4/13/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVHelixFlowLayout.h"

static BOOL const kEffectOpacityEnabled = NO;
static CGFloat const kMaxTwistingAngleFactor = .3f;

@implementation TMVHelixFlowLayout

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.minimumLineSpacing = 100.0f;
        self.collectionView.pagingEnabled = YES;
    }
    return self;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *attributesArray = [super layoutAttributesForElementsInRect:rect];
    
    CGRect visibleRect;
    visibleRect.origin = self.collectionView.contentOffset;
    visibleRect.size = self.collectionView.bounds.size;
    
    for (UICollectionViewLayoutAttributes *attributes in attributesArray)
    {
        if (CGRectIntersectsRect(attributes.frame, rect))
        {
            [self setCellAttributes:attributes forVisibleRect:visibleRect];
        }
    }
    
    return attributesArray;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    CGRect visibleRect;
    visibleRect.origin = self.collectionView.contentOffset;
    visibleRect.size = self.collectionView.bounds.size;
    
    [self setCellAttributes:attributes forVisibleRect:visibleRect];
    
    return attributes;
}

- (void)setCellAttributes:(UICollectionViewLayoutAttributes *)attributes forVisibleRect:(CGRect)visibleRect
{
    CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
    rotationAndPerspectiveTransform.m34 = 1.0 / -1000;
    
    CGPoint cellCenterPoint = [self.collectionView convertPoint:attributes.center toView:self.collectionView.superview];
    
    CGFloat percentage = cellCenterPoint.y / [[UIApplication sharedApplication].delegate window].frame.size.height;
    
    if (self.shouldFadeOutNonFocusedAttributes)
    {
        if (cellCenterPoint.y < self.collectionView.frame.size.height / 2 - 80
            || cellCenterPoint.y > self.collectionView.frame.size.height / 2 + 80)
        {
            if (attributes.alpha != 0.0f)
            {
                attributes.alpha = 0.0f;
//                rotationAndPerspectiveTransform = CATransform3DMakeScale(1.5, 1.5, 0.0);
            }
        }
    }
    else
    {
        if (attributes.alpha != 1.0f)
        {
            attributes.alpha = 1.0f;
//            rotationAndPerspectiveTransform = CATransform3DMakeScale(1.0, 1.0, 0.0);
        }
    }
    
    if (cellCenterPoint.y < self.collectionView.frame.size.height / 2)
    {
        percentage = percentage / 0.5f;
        
        if (percentage < 0.0f) percentage = 0.0f;
        if (percentage > 1.0f) percentage = 1.0f;
        
        if (kEffectOpacityEnabled)  attributes.alpha = percentage;
        
        percentage = percentage * kMaxTwistingAngleFactor;
        
        percentage = kMaxTwistingAngleFactor - percentage;
        
        rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, M_PI * percentage, 0.0f, 1.0f, 0.1f);
//        rotationAndPerspectiveTransform = CATransform3DMakeRotation(M_PI * percentage, 0.0f, 1.0f, 0.1f);
    }
    else if (cellCenterPoint.y == self.collectionView.frame.size.height / 2)
    {
        rotationAndPerspectiveTransform = CATransform3DIdentity;
    }
    else
    {
        percentage = (percentage - 0.5f) / 0.5f;
        
        if (percentage < 0.0f) percentage = 0.0f;
        if (percentage > 1.0f) percentage = 1.0f;
        
        if (kEffectOpacityEnabled) attributes.alpha = 1.0f - percentage;
        
        percentage = percentage * kMaxTwistingAngleFactor;
        rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, -M_PI * percentage, 0.0f, 1.0f, 0.1f);
//        rotationAndPerspectiveTransform = CATransform3DMakeRotation(-M_PI * percentage, 0.0f, 1.0f, 0.1f);
    }
    
    attributes.transform3D = rotationAndPerspectiveTransform;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    CGFloat offsetAdjustment = MAXFLOAT;
    CGFloat verticalCenter = proposedContentOffset.y + (CGRectGetHeight(self.collectionView.bounds) / 2.0);
    
    CGRect targetRect = CGRectMake(0.0f, proposedContentOffset.y, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
    
    NSArray *array = [super layoutAttributesForElementsInRect:targetRect];
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in array)
    {
        CGFloat itemVerticalCenter = layoutAttributes.center.y;
        
        if (ABS(itemVerticalCenter - verticalCenter) < ABS(offsetAdjustment))
        {
            offsetAdjustment = itemVerticalCenter - verticalCenter;
        }
    }
    
    return CGPointMake(proposedContentOffset.x, proposedContentOffset.y + offsetAdjustment);
}

@end

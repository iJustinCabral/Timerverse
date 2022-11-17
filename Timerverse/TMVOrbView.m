//
//  TMVOrbView.m
//  Timerverse
//
//  Created by Larry Ryan on 3/29/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVOrbView.h"

@interface TMVOrbView ()

@property (nonatomic, weak) TMVOrbViewCell *currentSelectedOrb;

@property (nonatomic) NSMutableArray *orbArray;
@property (nonatomic) NSMutableArray *subOrbArray;

@property (nonatomic, getter = isShowingSubOrbs) BOOL showingSubOrbs;

@end

@implementation TMVOrbView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.orbArray = [NSMutableArray array];
        self.subOrbArray = [NSMutableArray array];
        
        self.backgroundColor = [UIColor darkGrayColor];
    }
    return self;
}

- (void)setDataSource:(id<TMVOrbDataSource>)dataSource
{
    _dataSource = dataSource;
    
    for (NSUInteger index = 0; index < [self.dataSource numberOfOrbsForOrbView:self]; index++)
    {
        TMVOrbViewCell *cell = [self.dataSource orbView:self orbCellForIndex:index];
        cell.center = [self positionForIndex:index
                           outOfTotalIndexes:[self.dataSource numberOfOrbsForOrbView:self]
                                    isSubOrb:NO];
        cell.exclusiveTouch = YES;
        [cell addTarget:self action:@selector(didSelectOrb:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:cell];
        
        [self.orbArray addObject:cell];
    }
}

- (void)didSelectOrb:(TMVOrbViewCell *)orb
{
    if ([orb isEqual:self.currentSelectedOrb])
    {
        self.showingSubOrbs = NO;
        
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             orb.center = [self positionForIndex:[self.orbArray indexOfObject:orb]
                                               outOfTotalIndexes:self.orbArray.count
                                                        isSubOrb:NO];
                             
                             for (TMVOrbViewCell *orbObject in self.orbArray)
                             {
                                 if (![orbObject isEqual:orb])
                                 {
                                     orbObject.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                                     orbObject.layer.opacity = 1.0f;
                                 }
                             }
                             for (TMVOrbViewCell *orbObject in self.subOrbArray)
                             {
                                 if (![orbObject isEqual:orb])
                                 {
                                     orbObject.transform = CGAffineTransformMakeScale(0.3f, 0.3f);
                                     orbObject.layer.opacity = 0.0f;
                                 }
                             }
                         }
                         completion:^(BOOL finished) {
                             self.currentSelectedOrb = nil;
                             [self.subOrbArray removeAllObjects];
                         }];
    }
    else
    {
        self.showingSubOrbs = YES;
        
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             orb.center = [self positionForIndex:0
                                               outOfTotalIndexes:1
                                                        isSubOrb:NO];
                             
                             for (TMVOrbViewCell *orbObject in self.orbArray)
                             {
                                 if (![orbObject isEqual:orb])
                                 {
                                     orbObject.transform = CGAffineTransformMakeScale(0.3f, 0.3f);
                                     orbObject.layer.opacity = 0.0f;
                                 }
                             }
                         }
                         completion:^(BOOL finished) {
                             
                             self.currentSelectedOrb = orb;
                             
                             NSUInteger orbIndex = [self.orbArray indexOfObject:orb];
                             NSUInteger numberOfSubOrbs = [self.dataSource numberOfSubOrbsForIndex:orbIndex forOrbView:self];
                             
                             for (NSUInteger index = 0; index < numberOfSubOrbs; index++)
                             {
                                 TMVOrbViewCell *cell = [self.dataSource orbView:self subOrbCellAtIndex:index forOrbAtIndex:orbIndex];
                                 cell.center = orb.center;
                                 cell.layer.opacity = 0.0f;
                                 cell.exclusiveTouch = YES;
                                 [cell addTarget:self action:@selector(didSelectSubOrb:) forControlEvents:UIControlEventTouchUpInside];
                                 [self addSubview:cell];
                                 
                                 [self.subOrbArray addObject:cell];
                             }
                             
                             [self showSubOrbsForIndex:[self.orbArray indexOfObject:orb]];
                         }];
    }
}

- (void)didSelectSubOrb:(TMVOrbViewCell *)orb
{
    [self.delegate orbView:self
    didSelectSubOrbAtIndex:[self.subOrbArray indexOfObject:orb]
             forOrbAtIndex:[self.orbArray indexOfObject:self.currentSelectedOrb]];
}

- (void)showSubOrbsForIndex:(NSUInteger)index
{
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         [self.subOrbArray enumerateObjectsUsingBlock:^(TMVOrbViewCell *orbObject, NSUInteger index, BOOL *stop) {
                             orbObject.layer.opacity = 1.0f;
                             orbObject.center = [self positionForIndex:index
                                                     outOfTotalIndexes:self.subOrbArray.count
                                                              isSubOrb:YES];
                         }];
                     }
                     completion:^(BOOL finished) {
                         self.currentSelectedOrb = self.orbArray[index];
                     }];
    
}

- (CGPoint)positionForIndex:(NSUInteger)index
          outOfTotalIndexes:(NSUInteger)numberOfIndexes
                   isSubOrb:(BOOL)isSubOrb
{
    NSUInteger numberOfRows = self.isShowingSubOrbs ? 2 : 1;
    NSUInteger row = isSubOrb ? 1 : 0;
    CGSize cellSize = CGSizeMake(70.0f, 70.0f);
    
    // X
    CGFloat cellMassX = cellSize.width * numberOfIndexes;
    CGFloat marginMassX = self.bounds.size.width - cellMassX;
    CGFloat marginSizeX = marginMassX / (numberOfIndexes + 1);
    CGFloat marginSizeForIndexX = marginSizeX * (index + 1);
    CGFloat xSegment = marginSizeForIndexX + (cellSize.width / 2) + (cellSize.width * index);
    
    // Y
    CGFloat cellMassY = cellSize.height * numberOfRows;
    CGFloat marginMassY = self.bounds.size.height - cellMassY;
    CGFloat marginSizeY = marginMassY / (numberOfRows + 1);
    CGFloat marginSizeForIndexY = marginSizeY * (row + 1);
    CGFloat ySegment = marginSizeForIndexY + (cellSize.height / 2) + (cellSize.height * row);
    
    CGPoint point = CGPointMake(xSegment, ySegment);
    
    return point;
}

@end

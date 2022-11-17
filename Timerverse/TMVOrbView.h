//
//  TMVOrbView.h
//  Timerverse
//
//  Created by Larry Ryan on 3/29/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMVOrbViewCell.h"

@protocol TMVOrbDataSource, TMVOrbDelegate;

@interface TMVOrbView : UIView

@property (nonatomic, weak) id <TMVOrbDataSource> dataSource;
@property (nonatomic, weak) id <TMVOrbDelegate> delegate;

@end

@protocol TMVOrbDataSource <NSObject>

- (NSUInteger)numberOfOrbsForOrbView:(TMVOrbView *)orbView;
- (NSUInteger)numberOfSubOrbsForIndex:(NSUInteger)index forOrbView:(TMVOrbView *)orbView;
- (TMVOrbViewCell *)orbView:(TMVOrbView *)orbView orbCellForIndex:(NSUInteger)index;
- (TMVOrbViewCell *)orbView:(TMVOrbView *)orbView subOrbCellAtIndex:(NSUInteger)subIndex forOrbAtIndex:(NSUInteger)index;

@end

@protocol TMVOrbDelegate <NSObject>

- (void)orbView:(TMVOrbView *)orbView didSelectSubOrbAtIndex:(NSInteger)subIndex forOrbAtIndex:(NSUInteger)index;

@end
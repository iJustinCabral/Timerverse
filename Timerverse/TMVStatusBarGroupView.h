//
//  TMVStatusBarGroupView.h
//  Timerverse
//
//  Created by Larry Ryan on 7/12/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

@import UIKit;

@protocol TMVStatusBarGroupViewDatasource, TMVStatusBarGroupViewDelegate;


@interface TMVStatusBarGroupView : UIView

@property (nonatomic, weak) id <TMVStatusBarGroupViewDatasource> dataSource;
@property (nonatomic, weak) id <TMVStatusBarGroupViewDelegate> delegate;

@property (nonatomic, readonly) CGFloat apparentWidth;

- (void)hideItemAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)showItemAtIndex:(NSUInteger)index animated:(BOOL)animated;

@end


#pragma mark - Datasource
@protocol TMVStatusBarGroupViewDatasource <NSObject>

- (NSUInteger)numberOfItemsForGroupView:(TMVStatusBarGroupView *)groupView;
- (UIView *)groupView:(TMVStatusBarGroupView *)groupView itemForIndex:(NSUInteger)index;

@end

#pragma mark - Delegate
@protocol TMVStatusBarGroupViewDelegate <NSObject>

@optional
- (void)groupView:(TMVStatusBarGroupView *)groupView didHideItemAtIndex:(NSInteger)index;
- (void)groupView:(TMVStatusBarGroupView *)groupView didShowItemAtIndex:(NSInteger)index;
- (void)groupView:(TMVStatusBarGroupView *)groupView didSelectItemAtIndex:(NSInteger)index;

@end
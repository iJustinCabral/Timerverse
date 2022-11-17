//
//  CHFKickOutBehavior.h
//  ChatStack
//
//  Created by Larry Ryan on 7/8/13.
//  Copyright (c) 2013 Thinkr LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSUInteger, TMVKickOutType)
{
    TMVKickOutTypeDefault = 0,
    TMVKickOutTypeAbyss,
    TMVKickOutTypeDud
};

@protocol TMVKickOutDelegate;

@interface TMVKickOutBehavior : UIDynamicBehavior

@property (nonatomic, weak) id <TMVKickOutDelegate> delegate;

+ (instancetype)kickOutItemView:(TMVItemView *)itemView
                withKickOutType:(TMVKickOutType)type
                    andDelegate:(id <TMVKickOutDelegate>)delegate;

+ (instancetype)kickOutItemViews:(NSArray *)itemViews
                 withKickOutType:(TMVKickOutType)type
                     andDelegate:(id <TMVKickOutDelegate>)delegate;

@end

@protocol TMVKickOutDelegate <NSObject>

- (void)kickOutBehavior:(TMVKickOutBehavior *)kickOutBehavior
     didKickOutItemView:(TMVItemView *)itemView;

- (void)kickOutBehaviorClearedQueue:(TMVKickOutBehavior *)kickOutBehavior;

@end
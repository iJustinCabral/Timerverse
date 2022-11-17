//
//  CHFKickOutBehavior.m
//  ChatStack
//
//  Created by Larry Ryan on 7/8/13.
//  Copyright (c) 2013 Thinkr LLC. All rights reserved.
//

#import "TMVKickOutBehavior.h"

@interface TMVKickOutBehavior ()

@property (nonatomic) NSMutableArray *itemViews;
@property (nonatomic) TMVKickOutType type;

@end

@implementation TMVKickOutBehavior

+ (instancetype)kickOutItemView:(TMVItemView *)itemView
                withKickOutType:(TMVKickOutType)type
                    andDelegate:(id <TMVKickOutDelegate>)delegate
{
    TMVKickOutBehavior *kickoutBehavior = [[self alloc] initWithItemViews:@[itemView]
                                                                  inAybss:type == TMVKickOutTypeAbyss
                                                                 colorize:type == TMVKickOutTypeDud];
    
    kickoutBehavior.delegate = delegate;
    kickoutBehavior.type = type;
    
    return kickoutBehavior;
}

+ (instancetype)kickOutItemViews:(NSArray *)itemViews
                 withKickOutType:(TMVKickOutType)type
                     andDelegate:(id <TMVKickOutDelegate>)delegate
{
    TMVKickOutBehavior *kickoutBehavior = [[self alloc] initWithItemViews:itemViews
                                                                  inAybss:type == TMVKickOutTypeAbyss
                                                                 colorize:type == TMVKickOutTypeDud];
    kickoutBehavior.delegate = delegate;
    kickoutBehavior.type = type;
    
    return kickoutBehavior;
}

- (instancetype)initWithItemViews:(NSArray *)itemViews
                          inAybss:(BOOL)inAbyss
                         colorize:(BOOL)colorize
{
    self = [super init];
    
    if (self)
    {
        for (TMVItemView *itemView in itemViews)
        {
            // Remove just the item from the itemView array so the snap doesn't get confused
            [AppContainer.itemManager removeItemViewFromItemViewArray:itemView];
         
            itemView.userInteractionEnabled = NO;
            itemView.kickingOut = YES;
            
            if (inAbyss)
            {
                [itemView removeAllBehaviors];
            }
            else
            {
                
                [itemView removeAllBehaviorsExceptFlick];
                
                if (!colorize)
                {
//                    [itemView beginObservingAbyss]; // Makes the item scale down when it gets to the abyss
                }
            }
            
            if (colorize)
            {
                [AppContainer.itemManager removeItemViewFromUniversalCollisionBehavior:itemView];
                [AppContainer.itemManager beginObservingColorForItemView:itemView];
            }
            
            [AppContainer.itemManager addItemViewToUniversalGravityBehavior:itemView];
        }
        
        [self addBoundsObserverWithItemViews:itemViews];
        
        // Animator
        [AppContainer.itemManager.animator addBehavior:self];
    }
    
    return self;
}

- (void)addBoundsObserverWithItemViews:(NSArray *)itemViews
{
    __weak typeof(self) weakSelf = self;
    __block UIDynamicItemBehavior *observer = [[UIDynamicItemBehavior alloc] initWithItems:itemViews];
    __weak UIDynamicItemBehavior *weakObserver = observer;
    
    observer.action = ^{
        
        for (TMVItemView *itemView in weakObserver.items)
        {
            // If the itemView doesn't intersect rect anymore and has left out one of the sides
            // Expand the rect of the window so the hiccup in the deletion is offscreen
            if (!CGRectIntersectsRect(CGRectWithSizeSameCenter(AppDelegate.window.frame, CGSizeMake(AppDelegate.window.frame.size.width * 1.5, AppDelegate.window.frame.size.height * 1.5)), itemView.frame))
            {
                if ([weakSelf.delegate respondsToSelector:@selector(kickOutBehavior:didKickOutItemView:)])
                {
                    [weakSelf.delegate kickOutBehavior:weakSelf
                                    didKickOutItemView:itemView];
                }
                
                [weakObserver removeItem:itemView];
                
                if (weakObserver.items.count == 0)
                {
                    [weakSelf.dynamicAnimator removeBehavior:weakSelf];
                    
                    if (weakSelf.type != TMVKickOutTypeDud)
                    {
                        if ([self.delegate respondsToSelector:@selector(kickOutBehaviorClearedQueue:)])
                        {
                            [self.delegate kickOutBehaviorClearedQueue:weakSelf];
                        }
                    }
                }
            }
        }
    };
    
    [self addChildBehavior:observer];
}

@end

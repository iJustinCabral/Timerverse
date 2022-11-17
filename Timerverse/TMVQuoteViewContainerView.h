//
//  TMVQuoteViewContainerView.h
//  Timerverse
//
//  Created by Larry Ryan on 4/19/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSUInteger, TMVQuoteState)
{
    TMVQuoteStateSingle,
    TMVQuoteStateList
};

@protocol TMVQuoteViewContainerDelegate;

@interface TMVQuoteViewContainerView : UIScrollView

@property (nonatomic, weak) id <TMVQuoteViewContainerDelegate> quoteContainerDelegate;

@property (nonatomic) TMVQuoteState state;

@end

@protocol TMVQuoteViewContainerDelegate <NSObject>

- (void)didUpdateState:(TMVQuoteState)state;
- (void)didUpdatePercentageForShareAction:(CGFloat)percentage;

@end

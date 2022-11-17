//
//  TMVQuoteViewContainerView.m
//  Timerverse
//
//  Created by Larry Ryan on 4/19/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVQuoteViewContainerView.h"
#import "TMVQuoteViewController.h"

static TMVQuoteState const kDefaultQuoteState = TMVQuoteStateSingle;

@interface TMVQuoteViewContainerView () <TMVQuoteViewDelegate, UIScrollViewDelegate>

@property (nonatomic) TMVQuoteViewController *quoteViewController;

@end

@implementation TMVQuoteViewContainerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.clipsToBounds = NO;
        self.delegate = self;
        
        [self configureQuoteViewController];
        
        _state = kDefaultQuoteState;
    }
    return self;
}

- (void)setState:(TMVQuoteState)state
{
    _state = state;
    
    switch (state)
    {
        case TMVQuoteStateSingle:
        {
            self.frame = CGRectMake(0, 0, self.superview.width, 80.0f);
            self.center = self.superview.center;
            self.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height + 0.5);
            
            self.quoteViewController.view.frame = self.superview.frame;
            self.quoteViewController.view.y = -self.y;
        }
            break;
        case TMVQuoteStateList:
        {
            self.frame = CGRectMake(0, 0, self.superview.width, self.superview.height);
            self.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height + 0.5);
            
            self.quoteViewController.view.y = 0.0f;
        }
            break;
    }
    
    if ([self.quoteContainerDelegate respondsToSelector:@selector(didUpdateState:)])
    {
        [self.quoteContainerDelegate didUpdateState:state];
    }
}

#pragma mark - QuoteViewController

- (void)configureQuoteViewController
{
    if (!self.quoteViewController)
    {
        self.quoteViewController = [TMVQuoteViewController new];
        
        self.quoteViewController.delegate = self;
        
        [AppContainer addChildViewController:self.quoteViewController];
        
        [self addSubview:self.quoteViewController.view];
        
        [self.quoteViewController didMoveToParentViewController:AppContainer];
    }
    
}

#pragma mark Delegate

- (void)didEnableScrolling:(BOOL)scrollingEnabled
{
    self.state = scrollingEnabled ? TMVQuoteStateList : TMVQuoteStateSingle;
}

#pragma mark - UIScollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat maxOffset = 44.0f;
    CGFloat percentage = fabs(scrollView.contentOffsetY) / maxOffset;
    
    if (percentage < 0.0f) percentage = 0.0f;
    if (percentage > 1.0f) percentage = 1.0f;
    
    if (scrollView.contentOffsetY < 0.0f)
    {
        if ([self.quoteContainerDelegate respondsToSelector:@selector(didUpdatePercentageForShareAction:)])
        {
            [self.quoteContainerDelegate didUpdatePercentageForShareAction:percentage];
        }
    }
    else
    {
        if ([self.quoteContainerDelegate respondsToSelector:@selector(didUpdatePercentageForShareAction:)])
        {
            [self.quoteContainerDelegate didUpdatePercentageForShareAction:0.0f];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView.contentOffsetY < -44.0f)
    {
        UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[[self.quoteViewController currentQuoteAndPerson]]
                                                                         applicationActivities:nil];
        
        [AppContainer presentViewController:vc
                                   animated:YES
                                 completion:nil];
    }
}

@end

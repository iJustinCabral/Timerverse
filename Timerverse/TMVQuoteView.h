//
//  TMVQuoteView.h
//  Timerverse
//
//  Created by Larry Ryan on 2/7/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TMVQuoteViewDelegate;

@interface TMVQuoteView : UIScrollView

@property (nonatomic, weak) id <TMVQuoteViewDelegate> quoteViewDelegate;

@property (nonatomic, readonly, getter = shouldUseExclusionPaths) BOOL useExclusionPaths;
@property (nonatomic, readonly, getter = isShowing) BOOL showing;

- (void)updateExclusionPaths:(NSArray *)exclusionPaths;

- (void)updateMotionEffects;

#pragma mark - Animation

- (void)showAnimatingKeywordsWithCompletion:(void (^)(void))completion;
- (void)hideAnimatingKeywordsWithCompletion:(void (^)(void))completion;


- (void)showAnimated:(BOOL)animated
      withCompletion:(void (^)(void))completion;

- (void)dismissAnimated:(BOOL)animated
         withCompletion:(void (^)(void))completion;


- (void)showAnimated:(BOOL)animated
               scale:(BOOL)scale
                fade:(BOOL)fade
      withCompletion:(void (^)(void))completion;

- (void)dismissAnimated:(BOOL)animated
                  scale:(BOOL)scale
                   fade:(BOOL)fade
         withCompletion:(void (^)(void))completion;

@end

@protocol TMVQuoteViewDelegate <NSObject>

- (void)didBeginPanning;
- (void)didUpdatePercentageForShareAction:(CGFloat)percentage;
- (void)didEndPanningWithPercentage:(CGFloat)percentage;
- (void)didDecelerateShareAction;

@end

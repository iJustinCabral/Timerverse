//
//  TMVQuoteViewController.h
//  Timerverse
//
//  Created by Larry Ryan on 4/16/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

@import UIKit;

@protocol TMVQuoteViewDelegate;

@interface TMVQuoteViewController : UIViewController

@property (nonatomic, weak) id <TMVQuoteViewDelegate> delegate;
@property (nonatomic, readonly, getter = isShowing) BOOL showing;

- (NSString *)currentQuoteAndPerson;

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

- (void)didEnableScrolling:(BOOL)scrollingEnabled;

@end
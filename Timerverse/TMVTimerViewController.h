//
//  TMVTimerViewController.h
//  Timerverse
//
//  Created by Justin Cabral on 1/11/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TMVTimerViewController : UIViewController

@property (nonatomic) TMVItemView *itemView;

@property (nonatomic, assign, getter = isPresenting) BOOL presenting;

@end

@protocol TMVTimerViewControllerDelegate <NSObject>

@end

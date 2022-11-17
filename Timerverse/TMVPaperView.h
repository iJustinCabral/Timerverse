//
//  TMVPaperView.h
//  Timerverse
//
//  Created by Larry Ryan on 1/11/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMVPaperView : UIView

@property (nonatomic) BOOL translucent; //do you want blur effect? (default: YES)
@property (nonatomic) CGFloat translucentAlpha; //alpha of translucent  effect (default: 1)
@property (nonatomic) UIBarStyle translucentStyle; //blur style, Default or Black
@property (nonatomic, strong) UIColor *translucentTintColor; //tint color of blur, [UIColor clearColor] is default


@end

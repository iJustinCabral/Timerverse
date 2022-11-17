//
//  TMVAboutCell.h
//  Timerverse
//
//  Created by Larry Ryan on 3/28/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMVOrbViewCell : UIControl

- (instancetype)initWithImage:(UIImage *)image
                        color:(UIColor *)color
                 andSubscript:(NSString *)subscript;

- (instancetype)initWithText:(NSString *)text
                       color:(UIColor *)color
                andSubscript:(NSString *)subscript;

@end

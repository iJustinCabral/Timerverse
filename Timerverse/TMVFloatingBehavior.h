//
//  TMVFloatingBehavior.h
//  Timerverse
//
//  Created by Larry Ryan on 2/2/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMVFloatingBehavior : NSObject

- (instancetype)initWithItem:(UIView *)item;

- (void)addFloatingBehaviorToItem:(UIView *)item;
- (void)removeFloatingBehaviorToItem:(UIView *)item;

@end

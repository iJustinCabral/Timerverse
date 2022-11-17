//
//  AbyssView.h
//  AbyssView
//
//  Created by Larry Ryan on 10/26/13.
//  Copyright (c) 2013 Thinkr LLC. All rights reserved.
//

#import "TMVNonInteractiveView.h"

typedef NS_ENUM (NSUInteger, AbyssParticleType)
{
    AbyssParticleTypeTimer = 0,
    AbyssParticleTypeAlarm,
    AbyssParticleTypeAll
};

@interface AbyssView : TMVNonInteractiveView

- (instancetype)initWithFrame:(CGRect)frame
                         type:(AbyssParticleType)type
             andParticleColor:(UIColor *)color;

@property (nonatomic) UIColor *particleColor;
@property (nonatomic) AbyssParticleType type;

@end
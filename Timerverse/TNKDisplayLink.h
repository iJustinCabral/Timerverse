//
//  TNKDisplayLink.h
//
//  Created by Larry Ryan on 1/18/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

@import Foundation;

typedef void (^ProgressBlock)(CGFloat progress, NSUInteger repeatIteration);
typedef void (^ElapsedTimeBlock)(CFTimeInterval elapsedTime);

@interface TNKDisplayLink : NSObject

@property (nonatomic, getter = isRunning, readonly) BOOL running;
@property (nonatomic, getter = isPaused, readonly) BOOL paused;
@property (nonatomic) CFTimeInterval elapsedTime;

- (instancetype)initWithProgressBlock:(ProgressBlock)block
                             duration:(CFTimeInterval)duration
                autoReversePercentage:(BOOL)autoReversePercentage
                          repeatCount:(CGFloat)repeatCount;

- (instancetype)initContinuousAnimationWithBlock:(ElapsedTimeBlock)block;

+ (instancetype)sharedContinuousDisplayLinkWithBlock:(ElapsedTimeBlock)block;

+ (void)animateContinuouslyWithBlock:(ElapsedTimeBlock)block;

+ (void)animateWithDuration:(CFTimeInterval)duration
              repeatCount:(CGFloat)repeatCount
    autoReversePercentage:(BOOL)autoReversePercentage
            progressBlock:(ProgressBlock)block;

- (void)start;
- (void)stop;
- (void)pause;
- (void)resume;

@end

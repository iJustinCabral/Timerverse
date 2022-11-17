//
//  TNKDisplayLink.m
//
//  Created by Larry Ryan on 1/18/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TNKDisplayLink.h"

static NSUInteger kFrameInterval = 1;

@interface TNKDisplayLink ()

@property (nonatomic, copy) ProgressBlock progressBlock;
@property (nonatomic, copy) ElapsedTimeBlock elapsedTimeBlock;
@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) CFTimeInterval duration;
@property (nonatomic) CFTimeInterval startTime;
@property (nonatomic) NSUInteger repeatCount;
@property (nonatomic) NSUInteger currentRepeatIteration;
@property (nonatomic, getter = shouldAutoReversePercentage) BOOL autoReversePercentage;
@property (nonatomic, getter = isReversingIteration) BOOL reverseIteration;
@property (nonatomic, getter = isContinuous) BOOL continuous;

@property (nonatomic, getter = isRunning, readwrite) BOOL running;
@property (nonatomic, getter = isPaused, readwrite) BOOL paused;

@end

@implementation TNKDisplayLink

#pragma mark - Lifecycle

- (instancetype)initWithProgressBlock:(ProgressBlock)block
                             duration:(CFTimeInterval)duration
                autoReversePercentage:(BOOL)autoReversePercentage
                          repeatCount:(CGFloat)repeatCount
{
    self = [super init];
    if (self)
    {
        self.autoReversePercentage = autoReversePercentage;
        self.duration = autoReversePercentage ? duration / 2: duration;
        self.repeatCount = repeatCount;
        self.progressBlock = block;
    }
    return self;
}

- (instancetype)initContinuousAnimationWithBlock:(ElapsedTimeBlock)block
{
    self = [super init];
    if (self)
    {
        self.continuous = YES;
        self.elapsedTimeBlock = block;
    }
    return self;
}

#pragma mark Class Methods

+ (instancetype)sharedContinuousDisplayLinkWithBlock:(ElapsedTimeBlock)block
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initContinuousAnimationWithBlock:block];
    });
    return instance;
}

+ (void)animateContinuouslyWithBlock:(ElapsedTimeBlock)block
{
    TNKDisplayLink *displayLink = [[TNKDisplayLink alloc] initContinuousAnimationWithBlock:block];
    
    [displayLink start];
}

+ (void)animateWithDuration:(CFTimeInterval)duration
                repeatCount:(CGFloat)repeatCount
      autoReversePercentage:(BOOL)autoReversePercentage
              progressBlock:(ProgressBlock)block


{
    TNKDisplayLink *displayLink = [[TNKDisplayLink alloc] initWithProgressBlock:block
                                                                     duration:duration
                                                        autoReversePercentage:autoReversePercentage
                                                                  repeatCount:repeatCount];
    
    [displayLink start];
}

#pragma mark - Properites

- (BOOL)isPaused
{
    return self.displayLink.isPaused;
}

#pragma mark - Display Link

- (void)configureDisplayLink
{
    if (!self.displayLink)
    {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self
                                                       selector:@selector(tick:)];
        self.displayLink.frameInterval = kFrameInterval;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                               forMode:NSRunLoopCommonModes];
    }
}

- (void)tick:(CADisplayLink *)displayLink
{
    if (self.startTime == 0) self.startTime = displayLink.timestamp;
    
    self.elapsedTime = displayLink.timestamp - self.startTime;
    
    if (self.isContinuous)
    {
        __weak typeof(self) weakSelf = self;
        self.elapsedTimeBlock(weakSelf.elapsedTime);
    }
    else
    {
        if (self.elapsedTime > self.duration)
        {
            if (self.isReversingIteration)
            {
                __weak typeof(self) weakSelf = self;
                self.progressBlock(0.0f, weakSelf.currentRepeatIteration);
                
                if (self.currentRepeatIteration <= self.repeatCount)
                {
                    self.startTime = 0;
                    self.reverseIteration = NO;
                }
                else
                {
                    [self stop];
                }
            }
            else
            {
                __weak typeof(self) weakSelf = self;
                self.progressBlock(1.0f, weakSelf.currentRepeatIteration);
                
                if (self.shouldAutoReversePercentage)
                {
                    self.reverseIteration = YES;
                    self.startTime = 0;
                }
                else
                {
                    if (self.currentRepeatIteration < self.repeatCount)
                    {
                        self.startTime = 0;
                    }
                    else
                    {
                        [self stop];
                    }
                }
            }
            
            self.currentRepeatIteration += 1;
        }
        else
        {
            CGFloat durationPercentage = self.elapsedTime / self.duration;
            CGFloat percentage = self.reverseIteration ? 1.0f - durationPercentage : durationPercentage;
            
            __weak typeof(self) weakSelf = self;
            self.progressBlock(percentage, weakSelf.currentRepeatIteration);
        }
    }
}

#pragma mark Controls

- (void)start
{
    [self configureDisplayLink];
    
    self.running = YES;
}

- (void)stop
{
    [self.displayLink invalidate];
    self.displayLink = nil;
    
    self.running = NO;
}

- (void)pause
{
    self.displayLink.paused = YES;
}

- (void)resume
{
    self.displayLink.paused = NO;
}

@end

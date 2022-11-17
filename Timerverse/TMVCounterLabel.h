//
//  TMVCounterLabel.h
//  Timerverse
//
//  Created by Larry Ryan on 1/24/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

@import UIKit;

@class TMVItemView;

typedef NS_ENUM (NSInteger, TMVCounterDirection)
{
    TMVCounterDirectionUp = 0,
    TMVCounterDirectionDown
};

typedef NS_ENUM (NSUInteger, TMVCounterType)
{
    TMVCounterTypeStopWatch,
    TMVCounterTypeTimer
};

NSString * NSStringFromCounterDirection(TMVCounterDirection direction);
NSString * NSStringFromCounterType(TMVCounterType type);

@protocol TMVCounterLabelDelegate;

@interface TMVCounterLabel : UILabel

@property (nonatomic, weak) id <TMVCounterLabelDelegate> delegate;

@property (nonatomic, weak) TMVItemView *itemView;

@property (nonatomic) TMVCounterDirection countDirection;
@property (nonatomic) TMVCounterType counterType;
@property (nonatomic) unsigned long long startValue;
@property (nonatomic) unsigned long long currentValue;
@property (nonatomic, getter = shouldCountUpAfterFinish) BOOL countUpAfterFinish;

@property (nonatomic, readonly) unsigned long long value;
@property (nonatomic, readonly) NSString *valueString;
@property (nonatomic, readonly) CGFloat currentPercentage;
@property (nonatomic, readonly) NSUInteger repeatCount;
@property (nonatomic, readonly, getter = isRunning) BOOL running;
@property (nonatomic, readonly) NSTimeInterval timeElapsed;
@property (nonatomic, readonly) NSTimeInterval iterationTimeElapsed;

// Only used when the countdown has ended and is waiting to be reset
@property (nonatomic, readonly, getter = isFinished) BOOL finished;

@property (nonatomic, readonly, getter = isPaused) BOOL paused;

#pragma mark - Public Methods

// Dynamically change the time value while it is running
- (void)changeToValue:(unsigned long long)value
   withCountDirection:(TMVCounterDirection)direction;
- (void)updateRepeatCount;

- (void)setStartValueWithHours:(NSUInteger)hours
                       minutes:(NSUInteger)minutes
                       seconds:(NSUInteger)seconds
                  milliSeconds:(NSUInteger)milliSeconds;

- (void)start;
- (void)pause;
- (void)stop;
- (void)reset;

- (void)stopAndReset;

- (void)updatePercentage;

- (void)startPulsing;
- (void)stopPulsing;

@end


#pragma mark - TMVCounterLabelDelegate

@protocol TMVCounterLabelDelegate <NSObject>
@optional

- (void)countDidChange;
- (void)countdownChangedPercentage:(CGFloat)percentage;
- (void)countdownDidStart;
- (void)countdownDidStop;
- (void)countdownDidReset;
- (void)countdownDidEnd;
- (void)countdownDidStartCountingUpAfterFinish;
- (void)countdownDidRepeat;
- (void)countdownDidPause;
- (void)countdownDidResume;

@end


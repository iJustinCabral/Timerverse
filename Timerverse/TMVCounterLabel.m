//
//  TMVCounterLabel.m
//  Timerverse
//
//  Created by Larry Ryan on 1/24/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVCounterLabel.h"

NSString * NSStringFromCounterDirection(TMVCounterDirection direction)
{
    switch (direction)
    {
        case TMVCounterDirectionUp:
            return @"TMVCounterDirectionUp";
            break;
        case TMVCounterDirectionDown:
            return @"TMVCounterDirectionDown";
            break;
        default:
            return @"Invalid TMVCounterDirection";
            break;
    }
}

NSString * NSStringFromCounterType(TMVCounterType type)
{
    switch (type)
    {
        case TMVCounterTypeStopWatch:
            return @"TMVCounterTypeStopWatch";
            break;
        case TMVCounterTypeTimer:
            return @"TMVCounterTypeTimer";
            break;
        default:
            return @"Invalid TMVCounterType";
            break;
    }
}

@interface TMVCounterLabel ()

@property (nonatomic) NSTimeInterval startTime;
@property (nonatomic) NSTimeInterval iterationStartTime;
@property (nonatomic) unsigned long long resetValue;

@property (nonatomic, readwrite) NSString *valueString;
@property (nonatomic, readwrite) NSUInteger repeatCount;
@property (nonatomic, readwrite) CGFloat currentPercentage;
@property (nonatomic, readwrite) unsigned long long value;

@property (nonatomic, readwrite, getter = isRunning) BOOL running;
@property (nonatomic, readwrite, getter = isFinished) BOOL finished;
@property (nonatomic, readwrite, getter = isPaused) BOOL paused;

// Used for stats
@property (nonatomic) NSUInteger totalTimeElapsed;

@end

@implementation TMVCounterLabel

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.font = [UIFont fontWithName:@"HelveticaNeue-Light"
                                size:22];
    self.textColor = [UIColor whiteColor];
    self.textAlignment = NSTextAlignmentCenter;
    self.adjustsFontSizeToFitWidth = YES;
    self.minimumScaleFactor = 0.1;
    
    self.center = self.center;
    
    _counterType = TMVCounterTypeStopWatch;
    _countDirection = TMVCounterDirectionUp;
    _startValue = 0;
    _repeatCount = 0;
    _valueString = @"0.00";
    _countUpAfterFinish = YES;
}

#pragma mark - Properties

- (NSTimeInterval)timeElapsed
{
    NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    
    return (currentTime - self.startTime) * 1000;
}

- (NSTimeInterval)iterationTimeElapsed
{
    NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    
    return (currentTime - self.iterationStartTime) * 1000;
}

- (void)setItemView:(TMVItemView *)itemView
{
    _itemView = itemView;
    
    self.startValue = itemView.item.time.longLongValue;
    self.startTime = itemView.item.startTime.doubleValue;
    self.iterationStartTime = itemView.item.iterationStartTime.doubleValue;
    
    self.running = itemView.item.running.boolValue;
    
    if (self.isRunning)
    {
        [self listenToMainTimer];
    }
}

- (void)setStartTime:(NSTimeInterval)startTime
{
    _startTime = startTime;
    
    self.itemView.item.startTime = @(startTime);
}

- (void)setIterationStartTime:(NSTimeInterval)iterationStartTime
{
    _iterationStartTime = iterationStartTime;
    
    self.itemView.item.iterationStartTime = @(iterationStartTime);
}

- (void)setRunning:(BOOL)running
{
    _running = running;
    
    self.itemView.item.running = @(running);
    
    [DataManager saveContext];
}

- (void)setStartValueWithHours:(NSUInteger)hours
                       minutes:(NSUInteger)minutes
                       seconds:(NSUInteger)seconds
                  milliSeconds:(NSUInteger)milliSeconds
{
    unsigned long long totalSum = [self milliSecondsFromHours:hours
                                                      minutes:minutes
                                                      seconds:seconds
                                                 milliSeconds:milliSeconds];
    
    self.startValue = totalSum;
}

- (void)setCounterType:(TMVCounterType)counterType
{
    _counterType = counterType;
    
    self.countDirection = counterType == TMVCounterTypeStopWatch ? TMVCounterDirectionUp : TMVCounterDirectionDown;
}

- (void)setStartValue:(unsigned long long)startValue
{
    self.counterType = startValue == 0 ? TMVCounterTypeStopWatch : TMVCounterTypeTimer;
    
    if (startValue < ULONG_LONG_MAX)
    {
        _startValue = startValue;
    }
    else
    {
        _startValue = (ULONG_LONG_MAX - 1);
    }
    
    self.itemView.item.time = @(startValue);
    
    [DataManager saveContext];
    
    self.resetValue = startValue;
}

- (void)setResetValue:(unsigned long long)resetValue
{
    _resetValue = resetValue;
    
    self.value = resetValue;
}

- (void)setValue:(unsigned long long)value
{
    if (value < ULONG_LONG_MAX)
    {
        _value = value;
    }
    else
    {
        _value = (ULONG_LONG_MAX - 1);
    }
    
    self.currentValue = value;
    
    [self updateDisplay];
}


#pragma mark - Private Methods

- (void)clockDidTick:(NSNotification *)notification
{
    switch (self.counterType)
    {
        case TMVCounterTypeStopWatch:
        {
            self.value = self.startValue + self.iterationTimeElapsed;
        }
            break;
        case TMVCounterTypeTimer:
        {
            switch (self.countDirection)
            {
                case TMVCounterDirectionUp:
                {
                    self.value = self.iterationTimeElapsed - self.startValue;
                }
                    break;
                case TMVCounterDirectionDown:
                {
                    self.value = self.startValue - self.iterationTimeElapsed;\
                    
                    [self updatePercentage];
                }
                    break;
            }
        }
            break;
    }
    
    if ([self.delegate respondsToSelector:@selector(countDidChange)])
    {
        [self.delegate countDidChange];
    }
}

- (void)updatePercentage
{
    // Percentage completed
    NSTimeInterval percentage = self.iterationTimeElapsed / self.startValue;
    
    if (percentage < 0.0) percentage = 0.0;
    if (percentage > 1.0) percentage = 1.0;
    
    self.currentPercentage = percentage;
    
    if ([self.delegate respondsToSelector:@selector(countdownChangedPercentage:)])
    {
        [self.delegate countdownChangedPercentage:percentage];
    }
}

- (void)updateRepeatCount
{
    NSTimeInterval timesIterated = (self.timeElapsed / self.startValue);
    
    NSTimeInterval percentageThroughIteration = fmod((float)timesIterated, 1.0);
    
    self.repeatCount = (NSUInteger)timesIterated;
    
    unsigned long long milliSeconds = percentageThroughIteration * self.startValue;
    
    double now = CFAbsoluteTimeGetCurrent();
    
    self.iterationStartTime = now - (milliSeconds / 1000);
    
    self.value = self.startValue - milliSeconds;
}

// Dynamically change the time value while it is running
- (void)changeToValue:(unsigned long long)value
   withCountDirection:(TMVCounterDirection)direction
{
    self.countDirection = direction;
    
    [self updateIterationStartTimeToNow];
    
    // Access the ivar instead of the property since it would go through and assign the new start value to the resetValue, value and current value which we don't want in this instance
    _startValue = value;
}

- (void)updateDisplay
{
    // The control only displays the 10th of a millisecond, and 50 ms is enough to
    // ensure we see the last digit go to zero.
    if ((self.countDirection == TMVCounterDirectionDown && self.value < 50 && self.isRunning))
    {
        if (self.itemView.item.repeat.boolValue)
        {
            [self reset];
            [self updateIterationStartTimeToNow];
            
            self.repeatCount++;
            
            if ([self.delegate respondsToSelector:@selector(countdownDidRepeat)])
            {
                [self.delegate performSelector:@selector(countdownDidRepeat)];
            }
        }
        else if (self.shouldCountUpAfterFinish)
        {
            self.countDirection = TMVCounterDirectionUp;
            
            self.finished = YES;
            
            if ([self.delegate respondsToSelector:@selector(countdownDidStartCountingUpAfterFinish)])
            {
                [self.delegate performSelector:@selector(countdownDidStartCountingUpAfterFinish)];
            }
        }
        else
        {
            [self stopAndReset];
        }
        
        if ([self.delegate respondsToSelector:@selector(countdownDidEnd)])
        {
            [self.delegate performSelector:@selector(countdownDidEnd)];
        }
    }
    else
    {
        _valueString = [self timeFormattedStringForValue:self.value];
    }
    
    self.text = self.valueString;
}

- (void)updateStartTimeToNow
{
    self.startTime = CFAbsoluteTimeGetCurrent();
}

- (void)updateIterationStartTimeToNow
{
    self.iterationStartTime = CFAbsoluteTimeGetCurrent();
}

#pragma mark - Public Methods

- (void)start
{
    if (self.isRunning) return;
    
    if (self.isPaused)
    {
        self.paused = NO;
        
        // Get time paused and remove it from the start times
        //TODO: finish pause
        
        [self stopPulsing];
        
        if ([self.delegate respondsToSelector:@selector(countdownDidResume)])
        {
            [self.delegate countdownDidResume];
        }
    }
    else
    {
        [self updateIterationStartTimeToNow];
        [self updateStartTimeToNow];
    }
    
    self.running = YES;
    
    [self listenToMainTimer];
    
    if ([self.delegate respondsToSelector:@selector(countdownDidStart)])
    {
        [self.delegate countdownDidStart];
    }
}

- (void)listenToMainTimer
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clockDidTick:)
                                                 name:@"mainTimerUpdated"
                                               object:nil];
}

- (void)stopAndReset
{
    [self stop];
    [self reset];
}

- (void)stop
{
//    if (!self.isRunning) return;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"mainTimerUpdated"
                                                  object:nil];
    
    // Update stats
    DataManager.settings.totalCountedSeconds = @(DataManager.settings.totalCountedSeconds.integerValue + ([self timeElapsed] / 1000));
    
    [DataManager saveContext];
    
    if (self.counterType == TMVCounterTypeTimer)
    {
        self.countDirection = TMVCounterDirectionDown;
    }
    
    if (self.isPaused) [self stopPulsing];
    
    self.running = NO;
    self.finished = NO;
    self.paused = NO;
    
    self.repeatCount = 0;
    
    self.iterationStartTime = 0;
    self.startTime = 0;
    
    if ([self.delegate respondsToSelector:@selector(countdownDidStop)])
    {
        [self.delegate countdownDidStop];
    }
}

- (void)reset
{
    self.startValue = self.resetValue;
    
    if ([self.delegate respondsToSelector:@selector(countdownDidReset)])
    {
        [self.delegate countdownDidReset];
    }
}

- (void)pause
{
    if (!self.running) return;
    
    self.running = NO;
    self.paused = YES;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"mainTimerUpdated"
                                                  object:nil];
    
    [self startPulsing];
    
    if ([self.delegate respondsToSelector:@selector(countdownDidPause)])
    {
        [self.delegate countdownDidPause];
    }
}

#pragma mark Pulsing

- (void)startPulsing
{
//    if (self.isPaused) return;
    
    [self.layer removeAllAnimations];
    
    [UIView animateWithDuration:1.0f
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.layer.opacity = 0.5f;
                     }
                     completion:^(BOOL finished) {}];
}

- (void)stopPulsing
{
//    if (!self.isPaused) return;
    
    [UIView animateWithDuration:1.0f - self.layer.opacity
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.layer.opacity = 1.0f;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

#pragma mark - Helpers

- (unsigned long long)milliSecondsFromHours:(NSUInteger)hours
                                    minutes:(NSUInteger)minutes
                                    seconds:(NSUInteger)seconds
                               milliSeconds:(NSUInteger)milliSeconds
{
    unsigned long long msperhour = 3600000;
    unsigned long long mspermin = 60000;
    unsigned long long mspersec = 1000;
    
    unsigned long long totalHours = hours * msperhour;
    unsigned long long totalMinutes = minutes * mspermin;
    unsigned long long totalSeconds = seconds * mspersec;
    unsigned long long totalMiliSeconds = milliSeconds * 10;
    
    unsigned long long totalSum = totalHours + totalMinutes + totalSeconds + totalMiliSeconds;
    
    return totalSum;
}

- (NSString *)timeFormattedStringForValue:(unsigned long long)value
{
    unsigned long long msperhour = 3600000;
    unsigned long long mspermin = 60000;
    
    unsigned long long hrs = value / msperhour;
    unsigned long long mins = (value % msperhour) / mspermin;
    unsigned long long secs = ((value % msperhour) % mspermin) / 1000;
    unsigned long long frac = value % 1000 / 10;
    
    NSString *formattedString = @"";
    
    if (hrs == 0)
    {
        if (mins == 0)
        {
            formattedString = [NSString stringWithFormat:@"%02llu.%02llu", secs, frac];
        }
        else
        {
            formattedString = [NSString stringWithFormat:@"%02llu:%02llu", mins, secs];
        }
    }
    else
    {
        formattedString = [NSString stringWithFormat:@"%02llu:%02llu:%02llu", hrs, mins, secs];
    }
    
    // Get rid of unnecessary "0"
    if ([formattedString hasPrefix:@"0"])
    {
        NSMutableString *fixedTime = [formattedString mutableCopy];
        [fixedTime deleteCharactersInRange:NSMakeRange(0, 1)];
        
        formattedString = [fixedTime copy];
    }
    
    return formattedString;
}

@end

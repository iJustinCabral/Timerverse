//
//  TMVClockLabel.m
//  Timerverse
//
//  Created by Larry Ryan on 2/1/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVClockLabel.h"
#import "FBShimmeringLayer.h"

static CGFloat const kClockMargin = 10.0f;

static BOOL const kTimeTestingEnabled = NO;

@interface TMVClockLabel ()

@property (nonatomic) NSDateFormatter *timeFormatter;
@property (nonatomic) NSTimer *timer;

@property (nonatomic) CGSize lastHourMinuteLabelSize;
@property (nonatomic) UILabel *hourMinuteLabel;
@property (nonatomic, readwrite) UILabel *secondLabel;
@property (nonatomic) UILabel *ampmLabel;

@property (nonatomic, readwrite, getter = isShowingSeconds) BOOL showSeconds;
@property (nonatomic, getter = isMilitaryTime) BOOL militaryTime;
@property (nonatomic, getter = hasTwoDigitHours) BOOL twoDigitHours;

@property (nonatomic) BOOL timeTestingSwitcher; // Used to switch from start to end and vice-versa

@property (nonatomic) FBShimmeringLayer *shimmerLayer;

@end


@implementation TMVClockLabel

@synthesize hourMinuteLabel = _hourMinuteLabel;


#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        // Check if the time should show seconds
        self.showSeconds = DataManager.settings.clockSecondsEnabled.boolValue;
        
        // Set up the time and determine our views demensions
        [self updateTime];
        
        // Set if the clock should show seconds.
        [self showSeconds:self.showSeconds];
        
        [self configureTimer]; // Timer which calls updateTime every second
        [self configureTapGesture]; // Gesture to show/hide seconds
        [self listenToApplicationActivity];
        
        [self configureShimmerLayer];
        
        // Set our views center point
        [self snapToCorner:DataManager.settings.clockCorner.integerValue
                  animated:NO];
    }
    
    return self;
}

- (void)configureShimmerLayer
{
    if (!self.shimmerLayer)
    {
        self.shimmerLayer = [FBShimmeringLayer layer];
        
        self.shimmerLayer.frame = self.frame;
        self.shimmerLayer.shimmeringDirection = FBShimmerDirectionRight;
        
        [self.superview.layer addSublayer:self.shimmerLayer];
        
        self.shimmerLayer.contentLayer = self.layer;
    }
}

- (void)startShimmering
{
//    [self.shimmerLayer.presentationLayer setFrame:self.frame];
    
    self.shimmerLayer.shimmering = YES;
    
    if (!self.isDragging)
    {
        // For some reason the first time the clock shimmers it sets the origin to zero, zero, so we prevent that by setting it back to its last corner
        [self snapToCorner:DataManager.settings.clockCorner.integerValue
                  animated:NO];
    }
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self stopShimmering];
    });
}

- (void)stopShimmering
{
    self.shimmerLayer.shimmering = NO;
}


#pragma mark - Properties

- (void)setShowSeconds:(BOOL)showSeconds
{
    if (_showSeconds == showSeconds) return;
    
    _showSeconds = showSeconds;
    
    DataManager.settings.clockSecondsEnabled = showSeconds ? @YES : @NO;
    
    [DataManager saveContext];
}

- (CGFloat)apparentWidth
{
    CGFloat marginMass = kClockMargin * 2;
    CGFloat width = marginMass + self.hourMinuteLabel.width;
    
    if (self.isShowingSeconds) width += self.secondLabel.width;
    
    if (!self.isMilitaryTime) width += self.ampmLabel.width;
    
    return width;
}


#pragma mark ClockLabels

- (UILabel *)hourMinuteLabel
{
    if (!_hourMinuteLabel)
    {
        _hourMinuteLabel = [UILabel new];
        _hourMinuteLabel.textColor = AppContainer.atmosphere.elementColorTop;
        _hourMinuteLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        _hourMinuteLabel.textAlignment = NSTextAlignmentCenter;
        
        [self addSubview:_hourMinuteLabel];
    }
    
    return _hourMinuteLabel;
}

- (UILabel *)secondLabel
{
    if (!_secondLabel)
    {
        _secondLabel = [UILabel new];
        _secondLabel.textColor = AppContainer.atmosphere.elementColorTop;
        _secondLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        _secondLabel.textAlignment = NSTextAlignmentCenter;
        
        [self addSubview:_secondLabel];
    }
    
    return _secondLabel;
}

- (UILabel *)ampmLabel
{
    if (!_ampmLabel)
    {
        _ampmLabel = [UILabel new];
        _ampmLabel.textColor = AppContainer.atmosphere.elementColorTop;
        _ampmLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        _ampmLabel.textAlignment = NSTextAlignmentCenter;
        
        CGFloat xValue = self.isShowingSeconds ? self.secondLabel.right : self.hourMinuteLabel.right;
        [self.ampmLabel setOrigin:CGPointMake(xValue, kClockMargin)];
        
        [self addSubview:_ampmLabel];
    }
    
    return _ampmLabel;
}


#pragma mark - Notifications

- (void)listenToApplicationActivity
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)didBecomeActive:(NSNotification *)notification
{
    [self updateTime];
}


#pragma mark - Timer

- (void)configureTimer
{
    if (!self.timer)
    {
        self.timer = [NSTimer timerWithTimeInterval:1.0f
                                             target:self
                                           selector:@selector(updateTime)
                                           userInfo:nil
                                            repeats:YES];
        
        
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
}


#pragma mark - Methods (Private)

- (void)updateLocale
{
    if (!self.timeFormatter) self.timeFormatter = [NSDateFormatter new];
    
    self.timeFormatter.dateStyle = NSDateFormatterNoStyle;
    self.timeFormatter.timeStyle = NSDateFormatterShortStyle;
    self.timeFormatter.locale = [NSLocale currentLocale];
}

- (void)setTwoDigitHours:(BOOL)twoDigitHours
{
    if (_twoDigitHours == twoDigitHours) return;
    
    _twoDigitHours = twoDigitHours;
    
    if (!self.isDragging)
    {
        if (self.centerX > self.superview.halfWidth)
        {
            CGFloat secondsWidth = self.showSeconds ? 0.0f : self.secondLabel.width;
            self.left = self.superview.right - (self.width - secondsWidth);
        }
    }
}

- (void)updateTime
{
    // Update the current locale incase of timezone change or local was switched to military time
    [self updateLocale];
    
    NSString *format = [self.timeFormatter dateFormat];
    
    NSDate *date = [NSDate date];
    
    if (kTimeTestingEnabled)
    {
        NSCalendar *gregorian = [[NSCalendar alloc]
                                 initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *weekdayComponents = [gregorian components:(NSCalendarUnitDay | NSCalendarUnitWeekday)
                                                           fromDate:date];
        
        weekdayComponents.hour = self.timeTestingSwitcher ? 12 : 1;
        weekdayComponents.minute = self.timeTestingSwitcher ? 10 : 14;
        weekdayComponents.second = self.timeTestingSwitcher ? 34 : 19;
        
        date = [gregorian dateFromComponents:weekdayComponents];
        
//        self.backgroundColor = [UIColor randomColor];
    }
   
    self.militaryTime = [format rangeOfString:@" a"].location == NSNotFound;

    // Hours and Minutes
    format = self.isMilitaryTime ? @"HH:mm" : @"hh:mm";
    [self.timeFormatter setDateFormat:format];
    self.hourMinuteLabel.text = [self.timeFormatter stringFromDate:date];
    
    BOOL hasPrefix = NO;
    
    if ([self.hourMinuteLabel.text hasPrefix:@"0"]) //!self.isMilitaryTime &&
    {
        NSMutableString *mutableHourMinute = [self.hourMinuteLabel.text mutableCopy];
        [mutableHourMinute deleteCharactersInRange:NSMakeRange(0, 1)];
        
        self.hourMinuteLabel.text = [mutableHourMinute copy];
        
        hasPrefix = YES;
    }
    
    [self.hourMinuteLabel sizeToFit];
    [self.hourMinuteLabel setOrigin:CGPointMake(kClockMargin, kClockMargin)];
    
    
    // Seconds
    format = @":ss";
    [self.timeFormatter setDateFormat:format];
    self.secondLabel.text = [self.timeFormatter stringFromDate:date];
    [self.secondLabel sizeToFit];
    [self.secondLabel setOrigin:CGPointMake(self.hourMinuteLabel.right, kClockMargin)];
    
    
    // AM PM
    if (self.isMilitaryTime)
    {
        if (_ampmLabel)
        {
            [self.ampmLabel removeFromSuperview];
            self.ampmLabel = nil;
        }
    }
    else
    {
        format = @" a";
        [self.timeFormatter setDateFormat:format];
        self.ampmLabel.text = [self.timeFormatter stringFromDate:date];
        [self.ampmLabel sizeToFit];
        
        if (!CGSizeEqualToSize(self.lastHourMinuteLabelSize, self.hourMinuteLabel.size))
        {
            self.ampmLabel.x = self.isShowingSeconds ? self.secondLabel.right : self.hourMinuteLabel.right;
        }
    }
    
    self.lastHourMinuteLabelSize = self.hourMinuteLabel.size;
    
    // Update the frame to be the same as the label
    CGFloat ampmWidth = self.isMilitaryTime ? 0.0f : self.ampmLabel.width;
    
    self.width = self.hourMinuteLabel.width + self.secondLabel.width + ampmWidth + (kClockMargin * 2);
    self.height = self.hourMinuteLabel.height + (kClockMargin * 2);
    
    self.twoDigitHours = hasPrefix;
    
    if ([self.hourMinuteLabel.text rangeOfString:@":00"].location != NSNotFound && [self.secondLabel.text rangeOfString:@":00"].location != NSNotFound)
    {
        [self startShimmering];
    }
    
    // Shimmer the clock when the hour hits // IOS 8
//    if ([self.hourMinuteLabel.text containsString:@":00"] && [self.secondLabel.text containsString:@":00"])
//    {
//        [self startShimmering];
//    }
}

- (void)showSeconds:(BOOL)showSeconds
{
    self.showSeconds = showSeconds;
    
    [self updateTime];
    
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         self.secondLabel.layer.opacity = showSeconds ? 1.0f : 0.0f;
                         
                     }
                     completion:^(BOOL finished) {}];
}


#pragma mark - Methods (Public)

- (void)updateColor:(UIColor *)color
      withAnimation:(BOOL)animation
{
    for (UILabel *label in self.subviews)
    {
        if ([label isKindOfClass:[UILabel class]])
        {
            if (animation)
            {
                [UIView transitionWithView:label
                                  duration:AppContainer.atmosphere.transitionDuration
                                   options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    label.textColor = color;
                                }
                                completion:^(BOOL finished) { }];
            }
            else
            {
                label.textColor = color;
            }
        }
    }
}


#pragma mark - Snapping

- (UIRectCorner)currentCorner
{
    CGFloat apparentCenterX = self.origin.x + ([self apparentWidth] / 2);
    CGFloat statusBarEdge = AppContainer.statusBarView.center.y;
    
    return [self currentCornerForPoint:CGPointMake(apparentCenterX, statusBarEdge)];
}

- (UIRectCorner)currentCornerForPoint:(CGPoint)point
{
    UIRectCorner corner = UIRectCornerAllCorners;
    
    if (point.x <= self.superview.halfWidth)
    {
        if (point.y < AppContainer.statusBarView.superview.halfHeight)
        {
            corner = UIRectCornerTopLeft;
        }
        else
        {
            corner = UIRectCornerBottomLeft;
        }
    }
    else
    {
        if (point.y < AppContainer.statusBarView.superview.halfHeight)
        {
            corner = UIRectCornerTopRight;
        }
        else
        {
            corner = UIRectCornerBottomRight;
        }
    }
    
    return corner;
}

- (void)snapToCorner:(UIRectCorner)corner
            animated:(BOOL)animated
{
    CGPoint snappingPoint = CGPointZero;
    CGFloat yOffset = self.halfHeight;
    CGFloat xOffset = self.halfWidth;
    
    DataManager.settings.clockCorner = @(corner);
    
    [DataManager saveContext];
    
    switch (corner)
    {
        case UIRectCornerTopLeft:
        case UIRectCornerBottomLeft:
        {
             snappingPoint.x = xOffset;
        }
            break;
        case UIRectCornerTopRight:
        case UIRectCornerBottomRight:
        {
            if (self.isShowingSeconds)
            {
                snappingPoint.x = [UIScreen mainScreen].bounds.size.width - xOffset;
            }
            else
            {
                snappingPoint.x = ([UIScreen mainScreen].bounds.size.width + self.secondLabel.width) - xOffset;
            }
        }
            break;
        default:
        {
            snappingPoint.x = xOffset;
        }
            break;
    }
    
    
    // Set Y
    snappingPoint.y = yOffset;
    
    [self snapToPoint:snappingPoint
             animated:animated];
}

- (void)snapToPoint:(CGPoint)point
           animated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.5f
                              delay:0.0f
             usingSpringWithDamping:0.9f
              initialSpringVelocity:1.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self snapToPoint:point animated:NO];
                         }
                         completion:^(BOOL finished) {}];
    }
    else
    {
        if (!self.isMilitaryTime)
        {
            if (self.isShowingSeconds)
            {
                self.ampmLabel.x = self.secondLabel.right;
            }
            else
            {
                self.ampmLabel.x = self.hourMinuteLabel.right;
            }
        }
        
        self.center = point;
        
        [DataManager saveContext];
    }
}

- (void)snapToNearestCornerAnimated:(BOOL)animated
{
    [self snapToCorner:[self currentCorner]
              animated:animated];
}


#pragma mark - TapGesture

- (void)configureTapGesture
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [self addGestureRecognizer:tapGesture];
}

- (void)didTap:(UITapGestureRecognizer *)tapGesture
{
    if (kTimeTestingEnabled)
    {
        self.timeTestingSwitcher = self.timeTestingSwitcher ? NO : YES;
    }
    else
    {
        [self showSeconds:self.isShowingSeconds ? NO : YES];
        [self snapToNearestCornerAnimated:YES];
    }
}


@end

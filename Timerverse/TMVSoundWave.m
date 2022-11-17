//
//  PTRSoundWave.m
//  PathTester
//
//  Created by Larry Ryan on 1/18/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVSoundWave.h"
#import "TNKDisplayLink.h"

static SoundWaveVibrationType const kDefaultVibrationType = SoundWaveVibrationTypeTravel;
static NSUInteger const kNumberOfWaves = 1;
static NSUInteger const kTicksBeforeTravel = 1;
static CGFloat const kMaxWaveAmplitude = 3.0f;
static CGFloat const kPolarityStepSize = 0.05f;
static CGFloat const kPolarityThreshold = 1.0f;
static BOOL const kWavesEnabled = NO;
static BOOL const kShimmeringEnabled = YES;
static BOOL const kShimmerChangesAngle = NO;
static BOOL const kWaveTestingEnabled = NO;

#pragma mark - PTR SoundWave Private Interface

@interface TMVSoundWave ()

@property (nonatomic) TNKDisplayLink *displayLink;

@property (nonatomic) NSMutableArray *amplitudeArray;
@property (nonatomic) NSNumber *lastAmplitude;

@property (nonatomic, getter = isAmplitudePositive) BOOL amplitudePositive;
@property (nonatomic) CGFloat amplitudePolarityValue; // Shifts the waves pos to neg

@property (nonatomic, getter = shouldRampDown) BOOL rampDown;
@property (nonatomic) CFTimeInterval rampDownTimeBegan;

@property (nonatomic) CGFloat currentPolarityThreshold;

@property (nonatomic) NSUInteger ticksTillTravel;

@property (nonatomic) CAShapeLayer *circleShape;
@property (nonatomic) FBShimmeringLayer *shimmerLayer;

@property (nonatomic) UIBezierPath *shimmerAngleTestLayer;

@property (nonatomic, readwrite) BOOL wavesEnabled;
@property (nonatomic, readwrite) BOOL shimmeringEnabled;

@end

#pragma mark - PTR SoundWave Implementation

@implementation TMVSoundWave

#pragma mark - Lifecycle

- (instancetype)init
{
    return [self initWithColor:[UIColor randomColor]
              andVibrationType:kDefaultVibrationType];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithColor:[UIColor randomColor]
              andVibrationType:kDefaultVibrationType];
}

- (instancetype)initWithColor:(UIColor *)color
             andVibrationType:(SoundWaveVibrationType)vibrationType
{
    self = [super initWithFrame:CGRectMake(0,
                                           0,
                                           101 + kStrokeWidth,
                                           101 + kStrokeWidth)];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        self.wavesEnabled = kWavesEnabled;
        self.shimmeringEnabled = kShimmeringEnabled;
        
        self.color = color;
        self.lastAmplitude = @(0.0f);
        self.vibrationType = vibrationType;
        self.currentPolarityThreshold = kPolarityThreshold;
        self.strokeWidth = kStrokeWidth;
        
        if (kWaveTestingEnabled)
        {
            self.lastAmplitude = @(kMaxWaveAmplitude);
            [self startDisplayLink];
        }
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    for (NSUInteger waveIteration = 0; waveIteration < kNumberOfWaves; waveIteration++)
    {
        UIBezierPath *circlePath = [UIBezierPath bezierPath];
        CGPoint centerPoint = CGRectGetCenter(rect);
        CGFloat iterationMultiplier = (((float)waveIteration + 1.0f) / kNumberOfWaves);
        
        [[self circlePoints] enumerateObjectsUsingBlock:^(PTRPoint *point, NSUInteger index, BOOL *stop)
         {
             CGFloat offsetDistance = 0.0;
             
             switch (self.vibrationType)
             {
                 case SoundWaveVibrationTypeEven:
                 {
                     offsetDistance = self.lastAmplitude.floatValue;
                 }
                     break;
                 case SoundWaveVibrationTypeTravel:
                 {
                     offsetDistance = [self.amplitudeArray[index] floatValue];
                 }
                 default:
                     break;
             }
             
             if (waveIteration != kNumberOfWaves - 1)
             {
                 offsetDistance = (offsetDistance * 0.8);
             }
             
             
             // Decrease the amplitude at the beginning and end of the wave
             NSUInteger numberOfPointsToDecrement = 10;
             CGFloat amplitude = [self.amplitudeArray[index] floatValue];
             CGFloat decrementer = amplitude / numberOfPointsToDecrement;
             NSUInteger amplitudeCount = self.amplitudeArray.count;
             
             if (index < numberOfPointsToDecrement)
             {
                 offsetDistance = index * decrementer;
             }
             
             if (index > amplitudeCount - numberOfPointsToDecrement)
             {
                 offsetDistance = (amplitudeCount - index) * decrementer;
             }
             
             CGFloat iterationOffsetDistance = offsetDistance * iterationMultiplier;
             CGFloat amplitudeForIteration = iterationOffsetDistance * self.amplitudePolarityValue;
             
             CGFloat angle = [self angleBetweenPoint:centerPoint andPoint:point.point];
             CGFloat angleInRadians = [self degreesToRadians:angle];
             
             CGPoint updatedPoint = point.point;
             CGPoint updatedControlPoint1 = point.controlPoint1;
             CGPoint updatedControlPoint2 = point.controlPoint2;
             
             // Move the even points the opposite of the negative points
             if (index % 2 == 0)
             {
                 updatedPoint.x -= cos(angleInRadians) * amplitudeForIteration;
                 updatedPoint.y -= sin(angleInRadians) * amplitudeForIteration;
                 
                 updatedControlPoint1.x += cos(angleInRadians) * amplitudeForIteration;
                 updatedControlPoint1.y += sin(angleInRadians) * amplitudeForIteration;
                 
                 updatedControlPoint2.x -= cos(angleInRadians) * amplitudeForIteration;
                 updatedControlPoint2.y -= sin(angleInRadians) * amplitudeForIteration;
             }
             else
             {
                 updatedPoint.x += cos(angleInRadians) * amplitudeForIteration;
                 updatedPoint.y += sin(angleInRadians) * amplitudeForIteration;
                 
                 updatedControlPoint1.x -= cos(angleInRadians) * amplitudeForIteration;
                 updatedControlPoint1.y -= sin(angleInRadians) * amplitudeForIteration;
                 
                 updatedControlPoint2.x += cos(angleInRadians) * amplitudeForIteration;
                 updatedControlPoint2.y += sin(angleInRadians) * amplitudeForIteration;
             }
             
             if (index == 0)
             {
                 [circlePath moveToPoint:updatedPoint];
             }
             else
             {
                 [circlePath addCurveToPoint:updatedPoint
                               controlPoint1:updatedControlPoint1
                               controlPoint2:updatedControlPoint2];
             }
         }];
        
        [circlePath closePath];
        
        if (waveIteration == 0)
        {
            // Make the path the main circlePath
            self.path = circlePath;
            [self.color setStroke];
        }
        else
        {
            // For every wave iteration we turn down the alpha
            UIColor *iterationColor = [self.color colorWithAlphaComponent:iterationMultiplier / 3.0 * 2 + 1.0 / 3.0];
            
            [iterationColor setStroke];
        }
        
        circlePath.lineWidth = self.strokeWidth * iterationMultiplier;
        [circlePath stroke];
    }
    
    [self configureShimmerLayer];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    self.layer.superlayer.masksToBounds = NO;
    self.layer.masksToBounds = NO;
    self.clipsToBounds = NO;
    self.superview.clipsToBounds = NO;
    self.layer.frame = CGRectMake(0, 0, self.width, self.height);
}

#pragma mark - Shimmering

- (void)configureShimmerLayer
{
    if (!kShimmeringEnabled) return;
    
    if (!self.shimmerLayer)
    {
        self.shimmerLayer = [FBShimmeringLayer layer];
        self.shimmerLayer.frame = CGRectMake(-kStrokeWidth / 2, -kStrokeWidth / 2, kItemViewSize + kStrokeWidth, kItemViewSize + kStrokeWidth);
        self.shimmerLayer.shimmeringDirection = FBShimmerDirectionRight;
        self.shimmerLayer.shimmeringSpeed = 120;
        self.shimmerLayer.shimmeringPauseDuration = 0.5;
        self.shimmerLayer.shimmeringHighlightWidth = 0.5f;
        
        if (kShimmerChangesAngle)
        {
            [self updateShimmerAngle];
        }
        else
        {
            self.shimmerLayer.transform = CATransform3DMakeRotation(M_PI_2, 0.0, 0.0, 1.0);
        }
        
        [self.superview.layer addSublayer:self.shimmerLayer];
        
        self.shimmerLayer.contentLayer = self.layer;
    }
}

- (void)shimmerOnce
{
    if (!kShimmeringEnabled) return;
    
    self.shimmerLayer.shimmering = YES;
    
    CGFloat delay = (self.shimmerLayer.shimmeringSpeed / kItemViewSize) + (self.shimmerLayer.shimmeringPauseDuration / 2);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        self.shimmerLayer.shimmering = NO;
    });
}

- (void)startShimmering
{
    if (!self.shimmeringEnabled) return;
    
    if (self.itemView.item.repeat.boolValue)
    {
        [self shimmerOnce];
    }
    else
    {
        self.shimmerLayer.shimmering = YES;
    }
}

- (void)stopShimmering
{
    if (!kShimmeringEnabled) return;
    
    self.shimmerLayer.shimmering = NO;
}

- (void)updateShimmerAngle
{
    if (!kShimmeringEnabled || !kShimmerChangesAngle) return;
    
    CGFloat angle = [self angleBetweenPoint:CGPointMake(AppDelegate.window.middleX, AppDelegate.window.top)
                                   andPoint:[self convertPoint:self.center toView:nil]];
    
    CGFloat angleInRadians = [self degreesToRadians:angle];
    
    self.shimmerLayer.transform = CATransform3DMakeRotation(angleInRadians, 0.0, 0.0, 1.0);
}

#pragma mark - Properties

- (void)setVibrationType:(SoundWaveVibrationType)vibrationType
{
    _vibrationType = vibrationType;
    
    switch (self.vibrationType)
    {
        case SoundWaveVibrationTypeNone:
        {
            
        }
            break;
        case SoundWaveVibrationTypeEven:
        {
            if (self.amplitudeArray)
            {
                self.amplitudeArray = nil;
            }
        }
            break;
        case SoundWaveVibrationTypeTravel:
        {
            if (!self.amplitudeArray)
            {
                self.amplitudeArray = [NSMutableArray array];
                
                for (NSUInteger index = 0; index <= 48; index++)
                {
                    [self.amplitudeArray addObject:self.lastAmplitude];
                }
            }
        }
    }
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    
    [self setNeedsDisplay];
}

- (void)setStrokeWidth:(CGFloat)strokeWidth
{
    _strokeWidth = strokeWidth;
    
    [self setNeedsDisplay];
}

- (void)setPath:(UIBezierPath *)path
{
    _path = path;
    
    if ([self.delegate respondsToSelector:@selector(didUpdatePath:)])
    {
        [self.delegate didUpdatePath:path];
    }
}

#pragma mark - Display Link

- (void)startDisplayLink
{
    if (self.displayLink.isRunning || self.vibrationType == SoundWaveVibrationTypeNone) return;
    
    self.displayLink = [[TNKDisplayLink alloc] initContinuousAnimationWithBlock:^(CFTimeInterval elapsedTime) {
        [self animateWaveWithElapsedTime:elapsedTime];
    }];
    
    [self.displayLink start];
}

// Called from the display link
- (void)animateWaveWithElapsedTime:(CFTimeInterval)elapsedTime
{
    if (self.shouldRampDown)
    {
        self.lastAmplitude = @(self.lastAmplitude.floatValue - 0.1f);
        
        if (self.lastAmplitude.floatValue <= 0.0f) self.lastAmplitude = @0.0f;
    }
    
    // Determine if the amplitude needs to change from pos to neg or vice-versa
    if (self.amplitudePolarityValue >= self.currentPolarityThreshold)
    {
        self.amplitudePositive = NO;
    }
    else if (self.amplitudePolarityValue <= -self.currentPolarityThreshold)
    {
        self.amplitudePositive = YES;
    }
    
    // Update the amplitude polarity value
    if (self.isAmplitudePositive)
    {
        self.amplitudePolarityValue += kPolarityStepSize;
    }
    else
    {
        self.amplitudePolarityValue -= kPolarityStepSize;
    }
    
    self.ticksTillTravel++;
    
    if (self.vibrationType == SoundWaveVibrationTypeTravel && self.ticksTillTravel == kTicksBeforeTravel)
    {
        self.ticksTillTravel = 0;
        [self addNumberToAmplitudeArray:self.lastAmplitude];
    }
    
    [self setNeedsDisplay];
}

#pragma mark - Methods (Public)

// AVAudio player determines the percentage of its current power compared to its max power, and called this method. This method will stop being called on once the av audio player has finished
- (void)updateAmplitudeWithPercentage:(CGFloat)percentage
{
    [self startDisplayLink];
    
    self.lastAmplitude = @(kMaxWaveAmplitude * percentage);
}

// This will be called once the av audio player has finished playing
- (void)rampDown
{
    if (!self.wavesEnabled) return;
    
    self.rampDown = YES;
    self.rampDownTimeBegan = self.displayLink.elapsedTime;
}

#pragma mark - Methods (Private)

- (void)addNumberToAmplitudeArray:(NSNumber *)number
{
    if (self.amplitudeArray.count > 0)
    {
        [self.amplitudeArray removeObjectAtIndex:self.amplitudeArray.count - 1];
    }
    
//    if (self.shouldRampDown)
    {
        if (number.floatValue == 0.0f && [self.amplitudeArray.lastObject floatValue] == 0.0f)
        {
            [self.displayLink stop];
            
            [self startShimmering];
        }
    }
    
    [self.amplitudeArray insertObject:number atIndex:0];
}

- (void)drawLineFromPoint:(CGPoint)point1
                  toPoint:(CGPoint)point2
                withColor:(UIColor *)color
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    [path moveToPoint:point1];
    [path addLineToPoint:point2];
    [path closePath];
    [color setStroke];
    path.lineWidth = 1;
    [path stroke];
}

#pragma mark - Helpers

- (CGFloat)degreesToRadians:(CGFloat)degrees
{
    return degrees * M_PI / 180;
};

- (CGFloat)angleBetweenPoint:(CGPoint)point1 andPoint:(CGPoint)point2
{
    CGFloat deltaX = point2.x - point1.x;
    CGFloat deltaY = point2.y - point1.y;
    
    return atan2(deltaY, deltaX) * (180 / M_PI);
}

- (NSArray *)circlePoints
{
    NSMutableArray *array = [NSMutableArray array];
    

    // 29
    [array addObject:[PTRPoint point:CGPointMake(50.52, 0.5) controlPoint1:CGPointZero controlPoint2:CGPointZero]];
    
    [array addObject:[PTRPoint point:CGPointMake(43.95, 0.93) controlPoint1: CGPointMake(48.32, 0.5) controlPoint2: CGPointMake(46.13, 0.64)]];
    [array addObject:[PTRPoint point:CGPointMake(37.39, 2.24) controlPoint1: CGPointMake(41.75, 1.22) controlPoint2: CGPointMake(39.55, 1.66)]];
    [array addObject:[PTRPoint point:CGPointMake(31.49, 4.24) controlPoint1: CGPointMake(35.39, 2.78) controlPoint2: CGPointMake(33.42, 3.45)]];
    [array addObject:[PTRPoint point:CGPointMake(25.76, 7.03) controlPoint1: CGPointMake(29.53, 5.04) controlPoint2: CGPointMake(27.62, 5.97)]];
    [array addObject:[PTRPoint point:CGPointMake(19.82, 11.02) controlPoint1: CGPointMake(23.71, 8.2) controlPoint2: CGPointMake(21.72, 9.53)]];
    [array addObject:[PTRPoint point:CGPointMake(15.14, 15.14) controlPoint1: CGPointMake(18.19, 12.28) controlPoint2: CGPointMake(16.63, 13.65)]];
    [array addObject:[PTRPoint point:CGPointMake(10.98, 19.86) controlPoint1: CGPointMake(13.64, 16.65) controlPoint2: CGPointMake(12.25, 18.22)]];
    [array addObject:[PTRPoint point:CGPointMake(7.36, 25.2) controlPoint1: CGPointMake(9.65, 21.58) controlPoint2: CGPointMake(8.44, 23.36)]];
    [array addObject:[PTRPoint point:CGPointMake(4.18, 31.63) controlPoint1: CGPointMake(6.14, 27.28) controlPoint2: CGPointMake(5.08, 29.43)]];
    [array addObject:[PTRPoint point:CGPointMake(2.12, 37.84) controlPoint1: CGPointMake(3.36, 33.66) controlPoint2: CGPointMake(2.67, 35.74)]];
    // 40
    [array addObject:[PTRPoint point:CGPointMake(0.91, 44.06) controlPoint1: CGPointMake(1.59, 39.89) controlPoint2: CGPointMake(1.18, 41.97)]];
    [array addObject:[PTRPoint point:CGPointMake(0.5, 50.52) controlPoint1: CGPointMake(0.64, 46.21) controlPoint2: CGPointMake(0.5, 48.36)]];
    [array addObject:[PTRPoint point:CGPointMake(0.91, 56.94) controlPoint1: CGPointMake(0.5, 52.67) controlPoint2: CGPointMake(0.64, 54.81)]];
    [array addObject:[PTRPoint point:CGPointMake(2.09, 63.03) controlPoint1: CGPointMake(1.18, 58.99) controlPoint2: CGPointMake(1.57, 61.03)]];
    [array addObject:[PTRPoint point:CGPointMake(4.38, 69.85) controlPoint1: CGPointMake(2.69, 65.35) controlPoint2: CGPointMake(3.45, 67.63)]];
    [array addObject:[PTRPoint point:CGPointMake(7.34, 75.77) controlPoint1: CGPointMake(5.23, 71.87) controlPoint2: CGPointMake(6.22, 73.85)]];
    [array addObject:[PTRPoint point:CGPointMake(10.85, 80.96) controlPoint1: CGPointMake(8.39, 77.55) controlPoint2: CGPointMake(9.56, 79.29)]];
    [array addObject:[PTRPoint point:CGPointMake(15.14, 85.86) controlPoint1: CGPointMake(12.15, 82.66) controlPoint2: CGPointMake(13.59, 84.3)]];
    [array addObject:[PTRPoint point:CGPointMake(20.36, 90.41) controlPoint1: CGPointMake(16.8, 87.51) controlPoint2: CGPointMake(18.55, 89.03)]];
    
    //0
    [array addObject:[PTRPoint point:CGPointMake(25.78, 93.98) controlPoint1: CGPointMake(22.11, 91.73) controlPoint2: CGPointMake(23.92, 92.92)]];
    [array addObject:[PTRPoint point:CGPointMake(31.47, 96.75) controlPoint1: CGPointMake(27.63, 95.03) controlPoint2: CGPointMake(29.53, 95.95)]];
    [array addObject:[PTRPoint point:CGPointMake(37.43, 98.77) controlPoint1: CGPointMake(33.42, 97.55) controlPoint2: CGPointMake(35.41, 98.23)]];
    [array addObject:[PTRPoint point:CGPointMake(43.96, 100.07) controlPoint1: CGPointMake(39.58, 99.35) controlPoint2: CGPointMake(41.76, 99.78)]];
    [array addObject:[PTRPoint point:CGPointMake(50.51, 100.5) controlPoint1: CGPointMake(46.13, 100.36) controlPoint2: CGPointMake(48.32, 100.5)]];
    [array addObject:[PTRPoint point:CGPointMake(56.99, 100.08) controlPoint1: CGPointMake(52.67, 100.5) controlPoint2: CGPointMake(54.84, 100.36)]];
    [array addObject:[PTRPoint point:CGPointMake(63.36, 98.83) controlPoint1: CGPointMake(59.13, 99.8) controlPoint2: CGPointMake(61.26, 99.38)]];
    [array addObject:[PTRPoint point:CGPointMake(69.4, 96.8) controlPoint1: CGPointMake(65.4, 98.28) controlPoint2: CGPointMake(67.42, 97.61)]];
    [array addObject:[PTRPoint point:CGPointMake(75.57, 93.78) controlPoint1: CGPointMake(71.51, 95.94) controlPoint2: CGPointMake(73.57, 94.93)]];
    [array addObject:[PTRPoint point:CGPointMake(81, 90.12) controlPoint1: CGPointMake(77.44, 92.69) controlPoint2: CGPointMake(79.26, 91.47)]];
    [array addObject:[PTRPoint point:CGPointMake(85.86, 85.86) controlPoint1: CGPointMake(82.69, 88.82) controlPoint2: CGPointMake(84.31, 87.4)]];
    [array addObject:[PTRPoint point:CGPointMake(89.84, 81.37) controlPoint1: CGPointMake(87.29, 84.42) controlPoint2: CGPointMake(88.62, 82.93)]];
    [array addObject:[PTRPoint point:CGPointMake(93.64, 75.8) controlPoint1: CGPointMake(91.24, 79.58) controlPoint2: CGPointMake(92.51, 77.72)]];
    [array addObject:[PTRPoint point:CGPointMake(96.74, 69.56) controlPoint1: CGPointMake(94.83, 73.78) controlPoint2: CGPointMake(95.86, 71.7)]];
    [array addObject:[PTRPoint point:CGPointMake(98.88, 63.17) controlPoint1: CGPointMake(97.6, 67.47) controlPoint2: CGPointMake(98.31, 65.33)]];
    [array addObject:[PTRPoint point:CGPointMake(100.07, 57.04) controlPoint1: CGPointMake(99.4, 61.15) controlPoint2: CGPointMake(99.8, 59.1)]];
    [array addObject:[PTRPoint point:CGPointMake(100.5, 50.5) controlPoint1: CGPointMake(100.36, 54.87) controlPoint2: CGPointMake(100.5, 52.68)]];
    [array addObject:[PTRPoint point:CGPointMake(100.14, 44.47) controlPoint1: CGPointMake(100.5, 48.48) controlPoint2: CGPointMake(100.38, 46.47)]];
    [array addObject:[PTRPoint point:CGPointMake(98.82, 37.6) controlPoint1: CGPointMake(99.86, 42.16) controlPoint2: CGPointMake(99.42, 39.86)]];
    [array addObject:[PTRPoint point:CGPointMake(96.56, 31.01) controlPoint1: CGPointMake(98.22, 35.36) controlPoint2: CGPointMake(97.47, 33.16)]];
    [array addObject:[PTRPoint point:CGPointMake(93.59, 25.11) controlPoint1: CGPointMake(95.71, 28.99) controlPoint2: CGPointMake(94.72, 27.02)]];
    [array addObject:[PTRPoint point:CGPointMake(90.04, 19.88) controlPoint1: CGPointMake(92.53, 23.31) controlPoint2: CGPointMake(91.34, 21.56)]];
    [array addObject:[PTRPoint point:CGPointMake(85.86, 15.14) controlPoint1: CGPointMake(88.76, 18.24) controlPoint2: CGPointMake(87.37, 16.65)]];
    [array addObject:[PTRPoint point:CGPointMake(80.86, 10.76) controlPoint1: CGPointMake(84.27, 13.55) controlPoint2: CGPointMake(82.6, 12.09)]];
    [array addObject:[PTRPoint point:CGPointMake(75.45, 7.16) controlPoint1: CGPointMake(79.12, 9.43) controlPoint2: CGPointMake(77.31, 8.23)]];
    [array addObject:[PTRPoint point:CGPointMake(69.41, 4.2) controlPoint1: CGPointMake(73.49, 6.03) controlPoint2: CGPointMake(71.47, 5.04)]];
    [array addObject:[PTRPoint point:CGPointMake(63.49, 2.21) controlPoint1: CGPointMake(67.47, 3.41) controlPoint2: CGPointMake(65.5, 2.75)]];
    //28
    [array addObject:[PTRPoint point:CGPointMake(56.95, 0.92) controlPoint1: CGPointMake(61.34, 1.63) controlPoint2: CGPointMake(59.15, 1.2)]];
    
    [array addObject:[PTRPoint point:CGPointMake(50.52, 0.5) controlPoint1: CGPointMake(54.82, 0.64) controlPoint2: CGPointMake(52.67, 0.5)]];
    
    return [array copy];
}

@end

#pragma mark - PTR Point Implementation

@implementation PTRPoint

- (instancetype)initWithPoint:(CGPoint)point controlPoint1:(CGPoint)controlPoint1 controlPoint2:(CGPoint)controlPoint2
{
    self = [super init];
    if (self) {
        
        CGFloat offsetY = kStrokeWidth / 2;
        CGFloat offsetX = kStrokeWidth / 2;
        
        self.point = CGPointMake(point.x + offsetX, point.y + offsetY);
        self.controlPoint1 = CGPointMake(controlPoint1.x + offsetX, controlPoint1.y + offsetY);
        self.controlPoint2 = CGPointMake(controlPoint2.x + offsetX, controlPoint2.y + offsetY);
    }
    return self;
}

+ (PTRPoint *)point:(CGPoint)point
      controlPoint1:(CGPoint)controlPoint1
      controlPoint2:(CGPoint)controlPoint2
{
    return [[self alloc] initWithPoint:point controlPoint1:controlPoint1 controlPoint2:controlPoint2];
}

@end
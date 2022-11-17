//
//  TMVGalaxy.m
//  Timerverse
//
//  Created by Larry Ryan on 2/25/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVGalaxy.h"

#define ARC4RANDOM_MAX 0x100000000
#define ARC4RANDOM_BOOL arc4random_uniform(2) % 2 == 0

static CGFloat const kMinimumStarSize = 1.0f;
static CGFloat const kMaximumStarSize = 4.0f;

static CGFloat const kMinimumStarOpacity = 0.1f;
static CGFloat const kMaximumStarOpacity = 1.0f;

static NSUInteger const kMinimumNumberOfShiningStars = 8;
static NSUInteger const kMaximumNumberOfShiningStars = 20;

static NSUInteger const kNumberOfStarLayers = 3;
static NSUInteger const kNumberOfStarsPerLayer = 140;

static BOOL const kShootingStars = NO;
static CGFloat const kShootingStarInterval = 15.0f;


// Used in all implementations
CGFloat floatInRange(CGFloat minRange, CGFloat maxRange)
{
    return ((float)arc4random() / ARC4RANDOM_MAX * (maxRange - minRange)) + minRange;
}

CGFloat degreesToRadians(CGFloat degrees)
{
    return degrees * M_PI / 180;
}


@interface TMVGalaxy ()

@property (nonatomic) NSMutableArray *starArray;
@property (nonatomic) NSTimer *shootingStarTimer;
@property (nonatomic, readwrite, getter = isAnimating) BOOL animating;

@property (nonatomic) NSMutableArray *starLayerArray;
@property (nonatomic) NSUInteger numberOfStarLayers;
@property (nonatomic) NSUInteger numberOfStarsPerLayer;

@end


#pragma mark - TMVGalaxy Implementation

@implementation TMVGalaxy


#pragma mark - Lifecycle

- (instancetype)init
{
    return [self initWithFrame:self.superview.frame];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame
                     colorMode:TMVGalaxyColorModeGrayscale
                numberOfLayers:kNumberOfStarLayers
                    starsPerLayer:kNumberOfStarsPerLayer
                 shootingStars:kShootingStars
                     animation:NO];
}

- (instancetype)initWithFrame:(CGRect)frame
                    colorMode:(TMVGalaxyColorMode)colorMode
               numberOfLayers:(NSUInteger)numberOfLayers
                starsPerLayer:(NSUInteger)starsPerLayer
                shootingStars:(BOOL)shootingStars
                    animation:(BOOL)animation
{
    CGFloat width = frame.size.width + (frame.size.width / 2);
    CGFloat height = frame.size.height + (frame.size.height / 2);
    CGFloat xAxisPoint = -((width - frame.size.width) / 2);
    CGFloat yAxisPoint = -((height - frame.size.height) / 2);
    
    CGRect newFrame = frame;
    newFrame.size = CGSizeMake(width, height);
    newFrame.origin = CGPointMake(xAxisPoint, yAxisPoint);
    
    self = [super initWithFrame:newFrame];
    
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        self.colorMode = colorMode;
        self.numberOfStarLayers = numberOfLayers;
        self.numberOfStarsPerLayer = starsPerLayer == 0 ? kNumberOfStarsPerLayer : starsPerLayer;
        self.shootingStars = shootingStars;
        
        self.starArray = [@[] mutableCopy];
        
        NSUInteger shiningStarsIterated = 0;
        CGFloat shiningStarsToIterate = floatInRange(kMinimumNumberOfShiningStars, kMaximumNumberOfShiningStars);
        
        for (NSUInteger layerIndex = 0; layerIndex < numberOfLayers; layerIndex++)
        {
            UIView *layer = [self starLayer];
            
            for (NSUInteger starIndex = 0; starIndex < self.numberOfStarsPerLayer; starIndex++)
            {
                Class objectClass;
                
                if (shiningStarsIterated < shiningStarsToIterate && ARC4RANDOM_BOOL)
                {
                    objectClass = [TMVShiningStar class];
                    shiningStarsIterated++;
                }
                else
                {
                    objectClass = [TMVStar class];
                }
                
                id star = [[objectClass alloc] initWithGalaxySize:self.size
                                                        colorMode:self.colorMode
                                                 andShouldFlicker:YES];
                
                [self.starArray addObject:star];
                
                [layer addSubview:star];
            }
            
            [self.starLayerArray addObject:layer];
        }
        
        if (animation) [self startAnimating];
        
        [self updateMotionEffects];
    }
    
    return self;
}

- (NSMutableArray *)starLayerArray
{
    if (!_starLayerArray)
    {
        _starLayerArray = [NSMutableArray arrayWithCapacity:self.numberOfStarLayers * self.numberOfStarsPerLayer];
    }
    
    return _starLayerArray;
}

- (UIView *)starLayer
{
    UIView *starLayer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];

    [self addSubview:starLayer];
    
    return starLayer;
}

- (void)zoomInStarsAnimated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.5f
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self zoomInStarsAnimated:NO];
                         }
                         completion:^(BOOL finished) { }];
    }
    else
    {
        for (UIView *starLayer in self.starLayerArray)
        {
            starLayer.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        }
    }
}

- (void)zoomOutStarsAnimated:(BOOL)animated
{
    [self.starLayerArray enumerateObjectsUsingBlock:^(UIView *starLayer, NSUInteger idx, BOOL *stop) {
        
        NSUInteger index = (self.starLayerArray.count - 1) - idx;
        CGFloat scale = 0.7 + ((index / 10.0f) * 0.5f);
        
        if (animated)
        {
            [UIView animateWithDuration:0.5f
                                  delay:0.0f
                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 starLayer.transform = CGAffineTransformMakeScale(scale, scale);
                             }
                             completion:^(BOOL finished) {}];
        }
        else
        {
            starLayer.transform = CGAffineTransformMakeScale(scale, scale);
        }
        
    }];
}

#pragma mark - Animation (Flickering, ShootingStars)

- (void)startAnimating
{
    if (!self.isAnimating)
    {
        self.animating = YES;
        [self.starArray makeObjectsPerformSelector:@selector(startFlickering)];
        
        [self shootStarsForInterval:kShootingStarInterval];
    }
}

- (void)resumeAnimating
{
    self.animating = YES;
    
    [self.starArray makeObjectsPerformSelector:@selector(resumeFlickering)];
    
    [self shootStarsForInterval:kShootingStarInterval];
}

- (void)stopAnimating
{
    if (self.isAnimating)
    {
        self.animating = NO;
        [self.starArray makeObjectsPerformSelector:@selector(stopFlickering)];
        
        [self stopShootingStars];
    }
}


#pragma mark - Shooting Star

- (void)shootStarsForInterval:(NSTimeInterval)interval
{
    if (!self.shootingStarTimer)
    {
        self.shootingStarTimer = [NSTimer timerWithTimeInterval:interval
                                                         target:self
                                                       selector:@selector(shootStar)
                                                       userInfo:nil
                                                        repeats:YES];
        
        
        [[NSRunLoop mainRunLoop] addTimer:self.shootingStarTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)stopShootingStars
{
    [self.shootingStarTimer invalidate];
    self.shootingStarTimer = nil;
}

- (void)shootStar
{
    __block TMVShootingStar *shootingStar = [[TMVShootingStar alloc] initWithGalaxySize:self.size
                                                                              colorMode:self.colorMode
                                                                       andShouldFlicker:YES];
    
    [self.starLayerArray[arc4random_uniform((u_int32_t)self.starLayerArray.count)] addSubview:shootingStar];
    
    [shootingStar shootStarWithCompletion:^{
        [shootingStar removeFromSuperview];
        shootingStar = nil;
    }];
}


#pragma mark - Motion Effect

- (void)updateMotionEffects
{
    for (UIView *starLayer in self.starLayerArray.reverseObjectEnumerator)
    {
        [self updateMotionEffectForView:starLayer
                             withOffset:[self.starLayerArray indexOfObject:starLayer]];
    }
}

- (void)updateMotionEffectForView:(UIView *)view withOffset:(NSUInteger)offset
{
    // Make sure the item doesn't already have a motion effect
    for (UIMotionEffectGroup *effect in view.motionEffects)
    {
        [view removeMotionEffect:effect];
    }
    
    float maximumTilt = kMotionEffectFactor * (offset + 1);
    CGFloat alertViewTilt = AppContainer.isShowingAlertView ? kMotionEffectFactor : 0.0f;
    maximumTilt += alertViewTilt;
    UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    xAxis.minimumRelativeValue = [NSNumber numberWithFloat:maximumTilt];
    xAxis.maximumRelativeValue = [NSNumber numberWithFloat:-maximumTilt];
    
    UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    yAxis.minimumRelativeValue = [NSNumber numberWithFloat:maximumTilt];
    yAxis.maximumRelativeValue = [NSNumber numberWithFloat:-maximumTilt];
    
    UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
    group.motionEffects = @[xAxis, yAxis];
    
    [view addMotionEffect:group];
}


@end


#pragma mark - TMVStar Implementation

@interface TMVStar ()

@property (nonatomic, readwrite, getter = isFlickering) BOOL flickering;
@property (nonatomic) TMVGalaxyColorMode colorMode;
@property (nonatomic) CGFloat currentOpacity;

@end

@implementation TMVStar

- (instancetype)initWithGalaxySize:(CGSize)galaxySize
                         colorMode:(TMVGalaxyColorMode)colorMode
                  andShouldFlicker:(BOOL)shouldFlicker
{
    self = [super init];
    if (self)
    {
        self.shouldFlicker = shouldFlicker;
        self.colorMode = colorMode;
        
        NSInteger xAxis = arc4random_uniform(galaxySize.width);
        NSInteger yAxis = arc4random_uniform(galaxySize.height);
        CGPoint center = CGPointMake(xAxis, yAxis);
        
        CGFloat size = floatInRange(kMinimumStarSize, kMaximumStarSize);
        
        self.currentOpacity = floatInRange(kMinimumStarOpacity, kMaximumStarOpacity);
        
        self.frame = CGRectMake(0, 0, size, size);
        self.center = center;
        self.clipsToBounds = NO;
        self.backgroundColor = [UIColor clearColor];
        
        self.layer.masksToBounds = NO;
        self.layer.opacity = self.currentOpacity;
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    // Color
    UIColor *color;
    
    switch (self.colorMode)
    {
        case TMVGalaxyColorModeGrayscale:
        {
            color = [UIColor colorWithWhite:1.0f
                                      alpha:1.0f];
        }
            break;
        case TMVGalaxyColorModeHSB:
        {
            color = [UIColor colorWithHue:drand48()
                               saturation:0.3f
                               brightness:1.0f
                                    alpha:1.0f];
        }
            break;
        case TMVGalaxyColorModeGradient:
        {
            color = [UIColor colorForPoint:self.center];
        }
            break;
        default:
            break;
    }
    
    [self commonDrawRect:rect
               withColor:color];
}

- (void)commonDrawRect:(CGRect)rect
             withColor:(UIColor *)color
{
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:rect];
    [color setFill];
    [circlePath fill];
}


#pragma mark - Animation



- (void)startFlickering
{
    if (!self.isFlickering && self.shouldFlicker)
    {
        self.flickering = YES;
        
        CGFloat randomDuration = floatInRange(1.0f, 3.0f);
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
//        animation.fromValue = [NSNumber numberWithFloat:1.0];
        animation.toValue = [NSNumber numberWithFloat:1.0];
        animation.duration = randomDuration;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        [self applyBasicAnimation:animation
                          toLayer:self.layer
              withCompletionBlock:^{
            
                  
                  CABasicAnimation *repeatAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                  //        animation.fromValue = [NSNumber numberWithFloat:1.0];
                  repeatAnimation.toValue = [NSNumber numberWithFloat:floatInRange(0.1f, 0.3f)];
                  repeatAnimation.duration = randomDuration;
                  repeatAnimation.repeatCount = NSIntegerMax;
                  repeatAnimation.autoreverses = YES;
                  repeatAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                  repeatAnimation.fillMode = kCAFillModeForwards;
                  repeatAnimation.removedOnCompletion = NO;
                  
                  [self applyBasicAnimation:repeatAnimation
                                    toLayer:self.layer
                        withCompletionBlock:^{}];
        }];
    }
}

- (void)resumeFlickering
{
    self.flickering = YES;
    
    CFTimeInterval pausedTime = [self.layer timeOffset];
    self.layer.speed = 1.0;
    self.layer.timeOffset = 0.0;
    self.layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [self.layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    self.layer.beginTime = timeSincePause;
}

- (void)stopFlickering
{
    if (self.isFlickering)
    {
        self.flickering = NO;
        
        CFTimeInterval pausedTime = [self.layer convertTime:CACurrentMediaTime() fromLayer:nil];
        self.layer.speed = 0.0;
        self.layer.timeOffset = pausedTime;
    }
}

- (void)applyBasicAnimation:(CABasicAnimation *)animation
                    toLayer:(CALayer *)layer
        withCompletionBlock:(void (^)(void))completion
{
    animation.fromValue = [layer.presentationLayer ?: layer valueForKeyPath:animation.keyPath];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [CATransaction setCompletionBlock:^{ completion(); }];
    
    [layer setValue:animation.toValue forKeyPath:animation.keyPath];
    
    [layer addAnimation:animation forKey:animation.keyPath];
    
    [CATransaction commit];
}

@end


#pragma mark - TMVShootingStar Implementation

typedef NS_ENUM (NSUInteger, ShootingSide)
{
    ShootingSideLeft = 0,
    ShootingSideRight
};

@interface TMVShootingStar ()

@property (nonatomic) CGFloat angle;
@property (nonatomic) ShootingSide side;
@property (nonatomic) CGPoint destinationPoint;

@end

@implementation TMVShootingStar

- (instancetype)initWithGalaxySize:(CGSize)galaxySize
                         colorMode:(TMVGalaxyColorMode)colorMode
                  andShouldFlicker:(BOOL)shouldFlicker
{
    self = [super init];
    if (self)
    {
        self.shouldFlicker = shouldFlicker;
        self.colorMode = colorMode;
        
        self.frame = CGRectMake(0, 0, 134, 4);
        self.clipsToBounds = NO;
        self.backgroundColor = [UIColor clearColor];
        
        self.layer.masksToBounds = NO;
        self.layer.opacity = floatInRange(0.5f, kMaximumStarOpacity);
        
        // Scale
        CGFloat randomScale = floatInRange(0.2f, 0.8f);
        //        CGFloat randomXScale = floatInRange(randomScale, randomScale * 1.5);
        self.transform = CGAffineTransformMakeScale(randomScale, randomScale);
        
        // Side
        self.side = ARC4RANDOM_BOOL ? ShootingSideLeft : ShootingSideRight;
        
        CGSize sizeWithScale = CGSizeMake(self.width * randomScale, self.height * randomScale);
        
        //        self.layer.anchorPoint = CGPointMake(1.0f, 0.5f);
        
        // Angle
        CGRect frame = AppContainer.atmosphere.galaxy.frame;
        CGFloat margin = 50.0f;
        
        CGPoint leftSidePoint = CGPointMake(-margin, arc4random_uniform(frame.size.height));
        CGPoint rightSidePoint = CGPointMake(frame.size.width + margin, arc4random_uniform(frame.size.height));
        
        self.angle = [self angleBetweenPoint:leftSidePoint andPoint:rightSidePoint];
        self.transform = CGAffineTransformRotate(self.transform, self.angle);
        
        // Set the location for the star to start at
        switch (self.side)
        {
            case ShootingSideLeft:
            {
                self.center = CGPointMake(leftSidePoint.x - (sizeWithScale.width / 2), leftSidePoint.y - (sizeWithScale.height / 2));
            }
                break;
            case ShootingSideRight:
            {
                self.center = CGPointMake(rightSidePoint.x + (sizeWithScale.width / 2), rightSidePoint.y - (sizeWithScale.height / 2));
            }
                break;
            default:
                break;
        }
        
        // Set the destination point for the shooting star to animate to
        self.destinationPoint = self.side == ShootingSideLeft ? rightSidePoint : leftSidePoint;
    }
    return self;
}

- (void)commonDrawRect:(CGRect)rect
             withColor:(UIColor *)color
{
    UIBezierPath *path;
    
    // Draw Star
    switch (self.side)
    {
        case ShootingSideLeft:
        {
            UIBezierPath *ovalPath = [UIBezierPath bezierPath];
            [ovalPath moveToPoint: CGPointMake(120.28, 3.99)];
            [ovalPath addCurveToPoint: CGPointMake(120.28, 0.01) controlPoint1: CGPointMake(138.57, 3.82) controlPoint2: CGPointMake(138.57, 0.18)];
            [ovalPath addCurveToPoint: CGPointMake(13.72, 1.7) controlPoint1: CGPointMake(101.98, -0.15) controlPoint2: CGPointMake(32.02, 1.54)];
            [ovalPath addCurveToPoint: CGPointMake(13.72, 2.3) controlPoint1: CGPointMake(-4.57, 1.87) controlPoint2: CGPointMake(-4.57, 2.13)];
            [ovalPath addCurveToPoint: CGPointMake(120.28, 3.99) controlPoint1: CGPointMake(32.02, 2.46) controlPoint2: CGPointMake(101.98, 4.15)];
            [ovalPath closePath];
            [[color colorWithSaturationComponent:0.15f] setFill];
            [ovalPath fill];
            
            path = ovalPath;
        }
            break;
        case ShootingSideRight:
        {
            UIBezierPath *ovalPath = [UIBezierPath bezierPath];
            [ovalPath moveToPoint: CGPointMake(13.72, 3.99)];
            [ovalPath addCurveToPoint: CGPointMake(13.72, 0.01) controlPoint1: CGPointMake(-4.57, 3.82) controlPoint2: CGPointMake(-4.57, 0.18)];
            [ovalPath addCurveToPoint: CGPointMake(120.28, 1.7) controlPoint1: CGPointMake(32.02, -0.15) controlPoint2: CGPointMake(101.98, 1.54)];
            [ovalPath addCurveToPoint: CGPointMake(120.28, 2.3) controlPoint1: CGPointMake(138.57, 1.87) controlPoint2: CGPointMake(138.57, 2.13)];
            [ovalPath addCurveToPoint: CGPointMake(13.72, 3.99) controlPoint1: CGPointMake(101.98, 2.46) controlPoint2: CGPointMake(32.02, 4.15)];
            [ovalPath closePath];
            [[UIColor whiteColor] setFill];
            [ovalPath fill];
            
            path = ovalPath;
        }
            break;
    }
    
    // Give the star a glow now that we have the path
    self.layer.shadowColor = [color colorWithHueComponent:0.8f].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 0);
    self.layer.shadowRadius = 5.0;
    self.layer.shadowOpacity = 1.0f;
    self.layer.shadowPath = path.CGPath;
}


#pragma mark - Public

- (void)shootStarWithCompletion:(void (^)(void))completion
{
    [UIView animateWithDuration:floatInRange(0.4f, 0.8f)
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.center = self.destinationPoint;
                     }
                     completion:^(BOOL finished) {
                         completion();
                     }];
}


#pragma mark - Helpers

- (CGFloat)angleBetweenPoint:(CGPoint)point1 andPoint:(CGPoint)point2
{
    CGFloat deltaX = point2.x - point1.x;
    CGFloat deltaY = point2.y - point1.y;
    
    return atan2(deltaY, deltaX);
}

@end



#pragma mark - TMVStar Implementation

@interface TMVShiningStar ()

@end

@implementation TMVShiningStar

- (instancetype)initWithGalaxySize:(CGSize)galaxySize
                         colorMode:(TMVGalaxyColorMode)colorMode
                  andShouldFlicker:(BOOL)shouldFlicker
{
    self = [super initWithGalaxySize:galaxySize
                           colorMode:colorMode
                    andShouldFlicker:shouldFlicker];
    if (self)
    {
        // Size
        self.size = CGSizeMake(10.0f, 10.0f);
        
        // Scale
        CGFloat randomScale = floatInRange(0.4f, 0.8f);
        self.transform = CGAffineTransformMakeScale(randomScale, randomScale);
        
        // Rotation
        self.transform = CGAffineTransformRotate(self.transform, degreesToRadians(floatInRange(0.0f, 360.0f)));
    }
    
    return self;
}

- (void)commonDrawRect:(CGRect)rect
             withColor:(UIColor *)color
{
    UIBezierPath *shiningStarPath = [UIBezierPath bezierPath];
    [shiningStarPath moveToPoint: CGPointMake(5, 0)];
    [shiningStarPath addLineToPoint: CGPointMake(4, 4)];
    [shiningStarPath addLineToPoint: CGPointMake(0, 5)];
    [shiningStarPath addLineToPoint: CGPointMake(4, 6)];
    [shiningStarPath addLineToPoint: CGPointMake(5, 10)];
    [shiningStarPath addCurveToPoint: CGPointMake(6, 6) controlPoint1: CGPointMake(5, 10) controlPoint2: CGPointMake(5.89, 5.76)];
    [shiningStarPath addCurveToPoint: CGPointMake(10, 5) controlPoint1: CGPointMake(6.11, 6.24) controlPoint2: CGPointMake(10, 5)];
    [shiningStarPath addLineToPoint: CGPointMake(6, 4)];
    [shiningStarPath addLineToPoint: CGPointMake(5, 0)];
    [shiningStarPath closePath];
    [color setFill];
    [shiningStarPath fill];
}

@end

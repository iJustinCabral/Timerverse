//
//  TMVAboutCell.m
//  Timerverse
//
//  Created by Larry Ryan on 3/28/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVOrbViewCell.h"

static CGFloat const kOrbSize = 70.0f;
static CGFloat const kPadding = 26.0f;
static CGFloat const kFadeDuration = 0.15;
static CGFloat const kHighlightWithColor = NO;

@interface TMVOrbViewCell ()

@property (nonatomic) CAShapeLayer *ringLayer;
@property (nonatomic) CAShapeLayer *dashLayer;

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIColor *color;
@property (nonatomic) UILabel *textLabel;
@property (nonatomic) UILabel *subscriptLabel;

@end


@implementation TMVOrbViewCell

#pragma mark - Lifecycle

- (instancetype)initWithImage:(UIImage *)image
                        color:(UIColor *)color
                 andSubscript:(NSString *)subscript
{
    self = [super init];
    if (self)
    {
        [self commonInitWithColor:color
                     andSubscript:subscript];
        
        // Image
        self.imageView = [[UIImageView alloc] initWithImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.imageView.frame = CGRectMake(0, 0, kOrbSize - kPadding, kOrbSize - kPadding);
        self.imageView.center = self.center;
        self.imageView.tintColor = color;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.imageView];
    }
    return self;
}

- (instancetype)initWithText:(NSString *)text
                       color:(UIColor *)color
                andSubscript:(NSString *)subscript
{
    self = [super init];
    if (self)
    {
        [self commonInitWithColor:color
                     andSubscript:subscript];
        
        // Text
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kOrbSize - kPadding, kOrbSize - kPadding)];
        self.textLabel.text = text;
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        self.textLabel.minimumScaleFactor = 0.1f;
        self.textLabel.textColor = color;
        self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30];
        self.textLabel.center = self.center;
        
        [self addSubview:self.textLabel];
    }
    return self;
}

- (void)commonInitWithColor:(UIColor *)color
               andSubscript:(NSString *)subScript
{
    self.color = color;
    
    self.frame = CGRectMake(0, 0, kOrbSize, kOrbSize);
    self.backgroundColor = [UIColor clearColor];
    
    [self.layer addSublayer:self.ringLayer];
    [self.layer addSublayer:self.dashLayer];
    
    // Subscript
    if (subScript)
    {
        self.subscriptLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kOrbSize, 30)];
        self.subscriptLabel.text = subScript;
        self.subscriptLabel.textAlignment = NSTextAlignmentCenter;
        self.subscriptLabel.textColor = self.color;
        self.subscriptLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        [self.subscriptLabel sizeToFit];
        self.subscriptLabel.top = self.bottom + 5.0f;
        self.subscriptLabel.centerX = self.centerX;
        
        [self addSubview:self.subscriptLabel];
    }
}

#pragma mark - Properties

#pragma mark Setters

- (void)setHighlighted:(BOOL)highlighted
{
    if (self.highlighted == highlighted) return;
    
    [super setHighlighted:highlighted];
    
    if (highlighted)
    {
        if (kHighlightWithColor)
        {
            [self updateUIColor:[self.color colorWithBrightnessComponent:0.4f]];
        }
        else
        {
            [self startSpinning];
            
            [self showDashLayer:YES
                       animated:YES
             withCompletionBlock:^{
                 
             }];
        }
    }
    else
    {
        if (kHighlightWithColor)
        {
            [self updateUIColor:self.color];
        }
        else
        {
            [self showDashLayer:NO
                       animated:YES
            withCompletionBlock:^{
                           [self stopSpinning];
                       }];
        }
    }
}


#pragma mark Getters

- (CAShapeLayer *)ringLayer
{
    if (!_ringLayer)
    {
        _ringLayer = [CAShapeLayer layer];
        _ringLayer.frame = self.frame;
        _ringLayer.path = [UIBezierPath bezierPathWithOvalInRect:self.frame].CGPath;
        _ringLayer.strokeColor = self.color.CGColor;
        _ringLayer.fillColor = [UIColor clearColor].CGColor;
        _ringLayer.lineWidth = 2.0;
    }
    
    return _ringLayer;
}

- (CAShapeLayer *)dashLayer
{
    if (!_dashLayer)
    {
        CGFloat parimeter = M_PI * self.width;
        CGFloat patternLength = parimeter / 30; // Must be even
        
        _dashLayer = [CAShapeLayer layer];
        _dashLayer.frame = self.frame;
        _dashLayer.path = [[UIBezierPath bezierPathWithOvalInRect:self.frame] CGPath];
        
        _dashLayer.strokeColor = self.color.CGColor;
        _dashLayer.fillColor = [UIColor clearColor].CGColor;
        
        _dashLayer.lineWidth = 2.0;
        _dashLayer.lineJoin = kCALineCapRound;
        _dashLayer.lineDashPattern = @[@(patternLength), @(patternLength)];
        
        _dashLayer.opacity = 0.0f;
    }
    
    return _dashLayer;
}


#pragma mark - Methods (Private)

- (void)updateUIColor:(UIColor *)color
{
    self.imageView.tintColor = color;
    self.textLabel.textColor = color;
    self.ringLayer.strokeColor = color.CGColor;
    self.subscriptLabel.textColor = color;
}


#pragma mark Dash Layer Methods

- (void)showDashLayer:(BOOL)show
             animated:(BOOL)animated
  withCompletionBlock:(void (^)(void))completion
{
    if (animated)
    {
        CABasicAnimation *ringAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        
        ringAnimation.duration = kFadeDuration;
        ringAnimation.toValue = show ? @0.0f : @1.0f;
        
        [self applyBasicAnimation:ringAnimation
                          toLayer:self.ringLayer
              withCompletionBlock:^{
                  completion();
              }];
        
        CABasicAnimation *dashAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        
        dashAnimation.duration = kFadeDuration;
        dashAnimation.toValue = show ? @1.0f : @0.0f;
        
        [self applyBasicAnimation:dashAnimation
                          toLayer:self.dashLayer
              withCompletionBlock:^{
                  completion();
              }];
    }
    else
    {
        self.ringLayer.opacity = show ? 0.0f : 1.0f;
        self.dashLayer.opacity = show ? 1.0f : 0.0f;
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

- (void)startSpinning
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.duration = 8.0f;
    animation.repeatCount = NSIntegerMax;
    animation.byValue = @(M_PI * 2.0f);
    
    [self.dashLayer addAnimation:animation
                          forKey:nil];
}

- (void)stopSpinning
{
    [self.dashLayer removeAllAnimations];
}

@end

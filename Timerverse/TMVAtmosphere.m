//
//  TMVAtmosphere.m
//  Timerverse
//
//  Created by Larry Ryan on 1/29/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVAtmosphere.h"

static CGFloat const kTransitionDuration = 0.5;
static BOOL const kStarsEnabled = YES;

NSString * NSStringFromAtmosphereState(TMVAtmosphereState state)
{
    switch (state)
    {
        case TMVAtmosphereStateNight:
            return @"TMVAtmosphere Night";
            break;
        case TMVAtmosphereStateDay:
            return @"TMVAtmosphere Day";
            break;
        default:
            return @"Invalid TMVAtmosphere State";
            break;
    }
}

@interface TMVAtmosphere ()

@property (nonatomic) NSTimer *timer;
@property (nonatomic, readwrite) UIColor *currentColor;
@property (nonatomic) NSArray *nightColors;

@property (nonatomic, readwrite) TMVAtmosphereState state;
@property (nonatomic, readwrite) CGFloat transitionDuration;
@property (nonatomic, readwrite) TMVGalaxy *galaxy;

@end


@implementation TMVAtmosphere

@synthesize currentColor = _currentColor;


#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
                  andDelegate:(id <TMVAtmosphereDelegate>)delegate
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.delegate = delegate;
        
        self.transitionDuration = kTransitionDuration;
        self.locations = @[@0.0f, @1.0f];
        
        self.nightColors = @[[UIColor blackColor], [UIColor colorWithHue:0.72 saturation:1.0 brightness:0.2 alpha:1.0]];
        
        _state = TMVAtmosphereStateNight;
        
        [super setColors:self.nightColors];
        
        [self showGalaxyAnimated:NO];
    }
    
    return self;
}

#pragma mark - Properties

- (void)setState:(TMVAtmosphereState)state
{
    if (_state == state) return;
    
    _state = state;
    
    [self.delegate didChangeAtmosphereToState:state];
}

- (void)setColors:(NSArray *)colors
{
    if ([self.colors isEqualToArray:colors]) return;
    
    [super setColors:colors];
    
    if ([self.delegate respondsToSelector:@selector(didChangeAtmosphereToTopColor:andBottomColor:withState:)])
    {
        [self.delegate didChangeAtmosphereToTopColor:colors.firstObject
                                      andBottomColor:colors.lastObject
                                           withState:self.state];
    }
}

- (UIColor *)elementColorTop
{
    switch (self.state)
    {
        case TMVAtmosphereStateDay:
        {
            return self.currentColor;
        }
            break;
        case TMVAtmosphereStateNight:
        {
            return [UIColor whiteColor];
        }
            break;
    }
}

- (UIColor *)elementColorBottom
{
    switch (self.state)
    {
        case TMVAtmosphereStateDay:
        {
            return self.derivedColor;
        }
            break;
        case TMVAtmosphereStateNight:
        {
            return [UIColor whiteColor];
        }
            break;
    }
}

- (UIColor *)currentColor
{
    return self.colors.lastObject;
}

- (UIColor *)derivedColor
{
    return self.colors.firstObject;
}

- (NSArray *)derivedColorsFromColor:(UIColor *)color
{
    return @[[self derivedColorFromColor:color], color];
}

- (UIColor *)derivedColorFromColor:(UIColor *)color
{
    CGFloat derivedOffset = 0.25;
    
    return [color colorWithBrightnessComponent:[color brightnessValue] * derivedOffset];
}

#pragma mark - (Public)

- (void)updateColorAnimated:(BOOL)animated
{
    if (AppContainer.itemManager.itemViewBeingEdited)
    {
        if (animated)
        {
            [self transitionToColor:AppContainer.itemManager.itemViewBeingEdited.apparentColor];
        }
        else
        {
            [self changeToColor:AppContainer.itemManager.itemViewBeingEdited.apparentColor];
        }
    }
    else if ([AppContainer.itemManager hasInteractiveItems])
    {
        UIColor *color = [UIColor colorBlendedFromColors:[AppContainer.itemManager colorsFromItemViews:AppContainer.itemManager.interactingItemsArray]];
        
        if (animated)
        {
            [self transitionToColor:color];
        }
        else
        {
            [self changeToColor:color];
        }
    }
    else if ([AppContainer.itemManager hasActiveItems])
    {
        NSMutableArray *itemViews = [@[] mutableCopy];
        
        if ([AppContainer.itemManager hasActiveTimerItems])
        {
            [itemViews addObjectsFromArray:AppContainer.itemManager.activeTimerItemsArray];
        }
        
        if ([AppContainer.itemManager hasActiveStopWatchItems])
        {
            [itemViews addObjectsFromArray:AppContainer.itemManager.activeStopWatchItemsArray];
        }
        
        UIColor *color = [UIColor colorBlendedFromColors:[AppContainer.itemManager colorsFromItemViews:itemViews]];
        
        if (animated)
        {
            [self transitionToColor:color];
        }
        else
        {
            [self changeToColor:color];
        }
    }
    else
    {
        if (animated)
        {
            [self transitionToNight];
        }
        else
        {
            [self changeToNight];
        }
    }
    
//    if ([self.delegate respondsToSelector:@selector(didChangeAtmosphereToTopColor:andBottomColor:withState:)])
//    {
//        [self.delegate didChangeAtmosphereToTopColor:self.colors[0]
//                                      andBottomColor:self.colors[1]
//                                           withState:TMVAtmosphereStateDay];
//    }
}

#pragma mark - Galaxy

- (void)configureGalaxy
{
    if (!self.galaxy)
    {
        self.galaxy = [[TMVGalaxy alloc] initWithFrame:self.frame
                                             colorMode:TMVGalaxyColorModeHSB
                                        numberOfLayers:3
                                         starsPerLayer:[self numberOfStarsForScreenHeight]
                                         shootingStars:NO
                                             animation:YES];
        
        self.galaxy.layer.opacity = 0.0f;
        [self addSubview:self.galaxy];
        [self sendSubviewToBack:self.galaxy];
    }
}

- (NSUInteger)numberOfStarsForScreenHeight
{
    //TODO: Support for the number of layers
    return MAX(self.height, self.width) / 12;
}

- (void)showGalaxyAnimated:(BOOL)animated
{
    if (!kStarsEnabled || self.galaxy.layer.opacity == 1.0f) return;
    
    [self configureGalaxy];
    
    if (animated)
    {
        [UIView animateWithDuration:1.0
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self showGalaxyAnimated:NO];
                         }
                         completion:^(BOOL finished) {}];
    }
    else
    {
        self.galaxy.layer.opacity = 1.0f;
    }
}

- (void)hideGalaxyAnimated:(BOOL)animated
{
    if (!kStarsEnabled || self.galaxy.layer.opacity == 0.0f) return;
    
    if (animated)
    {
        [UIView animateWithDuration:1.0
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self hideGalaxyAnimated:NO];
                         }
                         completion:^(BOOL finished) {
                             [self.galaxy removeFromSuperview];
                         }];
    }
    else
    {
        self.galaxy.layer.opacity = 0.0f;
    }
}


#pragma mark - Color Transition

- (void)changeToNight
{
    if (self.state == TMVAtmosphereStateNight) return;
    
    self.state = TMVAtmosphereStateNight;
    
    self.colors = self.nightColors;
    //    [self showGalaxyAnimated:NO];
}

- (void)transitionToNight
{
    if (self.state == TMVAtmosphereStateNight) return;
    
    self.state = TMVAtmosphereStateNight;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"colors"];
    
    animation.fromValue = self.colors;
    animation.toValue = self.nightColors;
    animation.duration = self.transitionDuration;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    [self.layer addAnimation:animation forKey:@"animateColors"];
    
    self.colors = self.nightColors;
    //    [self showGalaxyAnimated:YES];
}

- (void)changeToColor:(UIColor *)color
{
    if (!color)
    {
        [self changeToNight];
        return;
    }
    
    self.state = TMVAtmosphereStateDay;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    self.colors = [self derivedColorsFromColor:color];
    
    [CATransaction commit];
    
    [self showGalaxyAnimated:NO];
}

- (void)transitionToColor:(UIColor *)color
{
    if (!color)
    {
        [self transitionToNight];
        return;
    }
    self.state = TMVAtmosphereStateDay;
    
    NSArray *derivedColors = [self derivedColorsFromColor:color];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"colors"];
    
    animation.fromValue = self.colors;
    animation.toValue = derivedColors;
    animation.duration = self.transitionDuration;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    [self.layer addAnimation:animation forKey:@"animateColors"];
    
    self.colors = derivedColors;
    
    if ([TimeManager nightTimeAtLocale])
    {
        [self showGalaxyAnimated:YES];
    }
    else
    {
        [self hideGalaxyAnimated:YES];
    }
}

- (void)flashColor:(UIColor *)color
{
    
}

- (void)applyBasicAnimation:(CABasicAnimation *)animation
                    toLayer:(CALayer *)layer
        withCompletionBlock:(void (^)(void))completion
{
    animation.fromValue = [layer.presentationLayer ?: layer valueForKeyPath:animation.keyPath];
    
    [CATransaction begin];
    {
        [CATransaction setDisableActions:YES];
        [CATransaction setCompletionBlock:^{ completion(); }];
        
        //    [layer setValue:animation.toValue forKeyPath:animation.keyPath];
        
        [layer addAnimation:animation forKey:animation.keyPath];
        
    }
    [CATransaction commit];
}

@end

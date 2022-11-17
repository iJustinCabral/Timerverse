//
//  TMVGalaxy.h
//  Timerverse
//
//  Created by Larry Ryan on 2/25/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSUInteger, TMVGalaxyColorMode)
{
    TMVGalaxyColorModeGrayscale = 0,
    TMVGalaxyColorModeHSB,
    TMVGalaxyColorModeGradient
};

#pragma mark - TMVGalaxy Interface

@interface TMVGalaxy : UIView

@property (nonatomic) BOOL shootingStars;
@property (nonatomic, readonly, getter = isAnimating) BOOL animating;

@property (nonatomic) TMVGalaxyColorMode colorMode;

- (instancetype)initWithFrame:(CGRect)frame
                    colorMode:(TMVGalaxyColorMode)colorMode
               numberOfLayers:(NSUInteger)numberOfLayers
                starsPerLayer:(NSUInteger)starsPerLayer
                shootingStars:(BOOL)shootingStars
                    animation:(BOOL)animation;

- (void)startAnimating;
- (void)resumeAnimating;
- (void)stopAnimating;

- (void)zoomInStarsAnimated:(BOOL)animated;
- (void)zoomOutStarsAnimated:(BOOL)animated;

- (void)updateMotionEffects;

@end


#pragma mark - TMVStar Interface

@interface TMVStar : UIView

@property (nonatomic) BOOL shouldFlicker;
@property (nonatomic, readonly, getter = isFlickering) BOOL flickering;

- (instancetype)initWithGalaxySize:(CGSize)galaxySize
                         colorMode:(TMVGalaxyColorMode)colorMode
                  andShouldFlicker:(BOOL)shouldFlicker;

- (void)commonDrawRect:(CGRect)rect
             withColor:(UIColor *)color;

- (void)startFlickering;
- (void)resumeFlickering;
- (void)stopFlickering;

@end


#pragma mark - TMVShootingStar Interface

@interface TMVShootingStar : TMVStar

- (void)shootStarWithCompletion:(void (^)(void))completion;

@end


#pragma mark - TMVShiningStar Interface

@interface TMVShiningStar : TMVStar

@end

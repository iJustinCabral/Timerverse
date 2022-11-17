//
//  PTRSoundWave.h
//  PathTester
//
//  Created by Larry Ryan on 1/18/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBShimmeringView.h"

typedef NS_ENUM (NSUInteger, SoundWaveVibrationType)
{
    SoundWaveVibrationTypeNone,
    SoundWaveVibrationTypeEven,
    SoundWaveVibrationTypeTravel
};

#pragma mark - PTR SoundWave Interface

@protocol TMVSoundWaveDelegate;

@class TMVItemView;

@interface TMVSoundWave : UIView

@property (nonatomic, weak) id <TMVSoundWaveDelegate> delegate;

@property (nonatomic) SoundWaveVibrationType vibrationType;
@property (nonatomic) UIColor *color;
@property (nonatomic) CGFloat strokeWidth;
@property (nonatomic) UIBezierPath *path;
@property (nonatomic, weak) TMVItemView *itemView;

@property (nonatomic, readonly) BOOL wavesEnabled;
@property (nonatomic, readonly) BOOL shimmeringEnabled;

- (instancetype)initWithColor:(UIColor *)color
             andVibrationType:(SoundWaveVibrationType)vibrationType;

- (void)updateAmplitudeWithPercentage:(CGFloat)percentage; // 0.0 - 1.0

- (void)rampDown;

// Shimmer
- (void)shimmerOnce;
- (void)startShimmering;
- (void)stopShimmering;
// Keeps the angle of the shimmer from the top middle of the screen
- (void)updateShimmerAngle;

@end

@protocol TMVSoundWaveDelegate <NSObject>

- (void)didUpdatePath:(UIBezierPath *)path;

@end

#pragma mark - PTR Point Interface

@interface PTRPoint : NSObject

@property (nonatomic) CGPoint point;
@property (nonatomic) CGPoint controlPoint1;
@property (nonatomic) CGPoint controlPoint2;

- (instancetype)initWithPoint:(CGPoint)point
                controlPoint1:(CGPoint)controlPoint1
                controlPoint2:(CGPoint)controlPoint2;

+ (PTRPoint *)point:(CGPoint)point
      controlPoint1:(CGPoint)controlPoint1
      controlPoint2:(CGPoint)controlPoint2;

@end
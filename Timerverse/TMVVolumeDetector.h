//
//  TMVVolumeDetector.h
//  Timerverse
//
//  Created by Larry Ryan on 7/10/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

@import UIKit;

#define VolumeDetector \
((TMVVolumeDetector *)[TMVVolumeDetector sharedVolumeDetector])

// Success if traversed properly, Volume current volume
typedef void(^TMVVolumeDetectorBlock)(BOOL success, CGFloat volume);

@protocol TMVVolumeDetecorDelegate;

@interface TMVVolumeDetector : UIView

@property (nonatomic, readonly) CGFloat volume;

@property (nonatomic, weak) id <TMVVolumeDetecorDelegate> delegate;

+ (instancetype)sharedVolumeDetector;

- (void)checkVolume:(TMVVolumeDetectorBlock)detector;

- (BOOL)volumeIsOn;

@end

#pragma mark - Delegate
@protocol TMVVolumeDetecorDelegate <NSObject>

- (void)didChangeVolumeToValue:(CGFloat)value;

@end
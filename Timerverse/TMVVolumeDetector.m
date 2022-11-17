//
//  TMVVolumeDetector.m
//  Timerverse
//
//  Created by Larry Ryan on 7/10/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVVolumeDetector.h"
#import <MediaPlayer/MediaPlayer.h>

@interface TMVVolumeDetector ()

@property (nonatomic) MPVolumeView *volumeView;
@property (nonatomic, readwrite) CGFloat volume;
@property (nonatomic) UISlider *slider;

@end

@implementation TMVVolumeDetector

@synthesize volume = _volume;

+ (instancetype)sharedVolumeDetector
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.slider = [self slider];
    }
    return self;
}

- (void)setDelegate:(id<TMVVolumeDetecorDelegate>)delegate
{
    _delegate = delegate;
    
    [self.slider addTarget:self
                    action:@selector(changedVolume:)
          forControlEvents:UIControlEventValueChanged];
}

- (void)changedVolume:(UISlider *)slider
{
    if ([self.delegate respondsToSelector:@selector(didChangeVolumeToValue:)])
    {
        [self.delegate didChangeVolumeToValue:slider.value];
    }
}

- (BOOL)volumeIsOn
{
    return [[self slider] value] > 0.0f;
}

- (void)checkVolume:(TMVVolumeDetectorBlock)detector
{
    detector(self.slider != nil, self.slider.value);
}

- (UISlider *)slider
{
    for (id view in self.volumeView.subviews)
    {
        if ([view isKindOfClass:[UISlider class]])
        {
            return view;
        }
    }
    
    return nil;
}

- (MPVolumeView *)volumeView
{
    if (!_volumeView)
    {
        _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectZero];
        _volumeView.showsRouteButton = NO;
    }
    
    return _volumeView;
}

- (void)setVolume:(CGFloat)volume
{
    [[self slider] setValue:volume];
}

- (CGFloat)volume
{
    return [[self slider] value];
}

@end

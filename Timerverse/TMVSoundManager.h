//
//  TMVSoundManager.h
//  Timerverse
//
//  Created by Larry Ryan on 1/24/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SoundManager \
((TMVSoundManager *)[TMVSoundManager sharedSoundManager])

@protocol TMVSoundManagerDelegate;

@class TMVSoundItem, Sound, TMVSoundWave;

#pragma mark - TMVSoundManager Interface

@interface TMVSoundManager : NSObject

+ (instancetype)sharedSoundManager;

@property (nonatomic, weak) id <TMVSoundManagerDelegate> delegate;

@property (nonatomic, readonly, getter = isPaused) BOOL paused;
@property (nonatomic, readonly, getter = isPlayingSound) BOOL playingSound;

- (void)addSound:(Sound *)sound
   withSoundWave:(TMVSoundWave *)soundWave
andWantsToBeDisplayedNext:(BOOL)wantsNext;

- (void)addSoundItem:(TMVSoundItem *)item;

- (void)isSystemMuted:(void (^)(BOOL muted))block;
- (void)isSystemVolumeDown:(void (^)(BOOL volumeDown))block;

- (NSUInteger)countOfEnqueuedItems;

- (Sound *)randomSound;
- (NSArray *)allSounds;

- (void)resume;
- (void)pause;
- (void)stop;

- (void)lowerSystemSound;
- (void)raiseSystemSound;

@end

@protocol TMVSoundManagerDelegate <NSObject>

- (void)didBeginPlayingSoundItem:(TMVSoundItem *)item;
- (void)didEndPlayingSoundItem:(TMVSoundItem *)item;

@end

#pragma mark - TMVSoundItem Interface

@interface TMVSoundItem : NSObject

- (instancetype)initWithSound:(Sound *)sound
                withSoundWave:(TMVSoundWave *)soundWave
       wantsToBeDisplayedNext:(BOOL)wantsNext;

@property (nonatomic, readonly) Sound *sound;
@property (nonatomic, readonly) TMVSoundWave *soundWave;
@property (nonatomic, readonly) BOOL wantsToBeDisplayedNext;

@end


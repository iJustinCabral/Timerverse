//
//  TMVSoundManager.m
//  Timerverse
//
//  Created by Larry Ryan on 1/24/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVSoundManager.h"
#import "TMVAppContainerViewController.h"
#import "SKMuteSwitchDetector.h"
#import "TMVVolumeDetector.h"

@import AVFoundation;

// If the volume is less than this threshold then the volume is considered off
static CGFloat const kVolumeDownThreshold = 0.0f;

@interface TMVSoundManager () <AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic) NSTimer *playerTimer;

@property (nonatomic) TMVSoundItem *currentPlayingSoundItem;

@property (nonatomic, readwrite, getter = isPaused) BOOL paused;
@property (nonatomic, readwrite, getter = isPlayingSound) BOOL playingSound;

@property (nonatomic) BOOL isSilent;

@end

@implementation TMVSoundManager

#pragma mark - Lifecycle

+ (instancetype)sharedSoundManager
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
        [self initializer];
    }
    return self;
}

- (void)initializer
{
    if (!self.queue)
    {
        self.queue = [[NSMutableArray alloc] init];
    }
    
    [self configureSounds];
}

- (void)lowerSystemSound
{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                     withOptions:AVAudioSessionCategoryOptionDuckOthers
                                           error:nil];
}

- (void)raiseSystemSound
{
    [[AVAudioSession sharedInstance] setActive:NO
                                   withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                         error:nil];
}

- (void)configureSounds
{
    if ([self allSounds].count == 0)
    {
        NSArray *sounds = @[@"Alert", @"Alert 2", @"Alert 3", @"Alert 4", @"Alert 5", @"Buzzer", @"Cut Out", @"Dropped", @"Elevator Ding", @"Enchanted", @"GT", @"1Up", @"Ring", @"Bell 1", @"Bell 2", @"Mystical"];
        
        for (NSString *soundPath in sounds)
        {
            Sound *sound = [DataManager insertObjectForEntityName:@"Sound"];
            sound.name = soundPath;
            sound.sourceURL = soundPath;
            sound.sourceExt = @"mp3";
            sound.vibration = @YES;
            sound.vibrationDuration = @0.2;
            sound.volume = @100;
        }
    }
}

#pragma mark - Queue Methods

- (void)addSound:(Sound *)sound
   withSoundWave:(TMVSoundWave *)soundWave
andWantsToBeDisplayedNext:(BOOL)wantsNext
{
    TMVSoundItem *soundItem = [[TMVSoundItem alloc] initWithSound:sound
                                                    withSoundWave:soundWave
                                           wantsToBeDisplayedNext:wantsNext];
    
    [self addSoundItem:soundItem];
}

- (void)addSoundItem:(TMVSoundItem *)item;
{
    [self enqueueItem:item];
}

- (void)enqueueItem:(TMVSoundItem *)item
{
    if (item.wantsToBeDisplayedNext)
    {
        [self.queue insertObject:item atIndex:0];
    }
    else
    {
        [self.queue insertObject:item atIndex:self.queue.count];
    }
    
    if (self.queue.count > 0 && self.isPlayingSound == NO)
    {
        [self dequeueNextItem];
    }
}

- (TMVSoundItem *)dequeueItem
{
    TMVSoundItem *item = self.queue[0];
    
    [self.queue removeObjectAtIndex:0];
    
    return item;
}

- (void)dequeueNextItem
{
    
    if (!self.isPaused)
    {
        TMVSoundItem *item = [self dequeueItem];
        
        if (!self.isPlayingSound)
        {
            [self playSoundWithSoundItem:item];
        }
    }
}

- (void)playSoundWithSoundItem:(TMVSoundItem *)item
{
    [self lowerSystemSound];
    
    // AVAudioPlayer only can be given a URL during init. So we replace the old one with the new sound
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:item.sound.sourceURL
                                                                        ofType:item.sound.sourceExt]];
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.audioPlayer.delegate = self;
    self.audioPlayer.meteringEnabled = item.soundWave.wavesEnabled;
    
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
    
    if (SettingsController.alertVibrationEnabled)
    {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    
    self.playingSound = YES;
    self.currentPlayingSoundItem = item;
    
    // Shimmering
    [self.currentPlayingSoundItem.soundWave startShimmering];
    
    if ([self.delegate respondsToSelector:@selector(didBeginPlayingSoundItem:)])
    {
        [self.delegate didBeginPlayingSoundItem:item];
    }
    
    if (!self.playerTimer && self.audioPlayer.meteringEnabled)
    {
        self.playerTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                            target:self
                                                          selector:@selector(monitorAudioPlayer)
                                                          userInfo:nil
                                                           repeats:YES];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self.playerTimer invalidate];
    self.playerTimer = nil;
    
    [self.currentPlayingSoundItem.soundWave rampDown];
    
    self.playingSound = NO;
    self.currentPlayingSoundItem = nil;
    
    if (self.queue.count > 0)
    {
        [self dequeueNextItem];
    }
    else
    {
        [self raiseSystemSound];
    }
}

#pragma mark - Controls

- (void)resume
{
    if (self.queue.count > 0)
    {
        self.paused = NO;
    }
}

- (void)pause
{
    self.paused = YES;
}

- (void)stop
{
    [self.queue removeAllObjects];
}

#pragma mark - Helpers

- (NSUInteger)countOfEnqueuedItems
{
    return self.queue.count;
}

- (Sound *)randomSound
{
    NSArray *sounds = [self allSounds];
    
    return sounds[arc4random_uniform((u_int32_t)sounds.count)];
}

- (NSArray *)allSounds
{
    return [DataManager fetchObjectsForEntityName:@"Sound"];
}

#pragma mark Mute Switch Check

- (void)isSystemMuted:(void (^)(BOOL muted))block
{
    [SKMuteSwitchDetector checkSwitch:^(BOOL success, BOOL muted)
     {
         if (success)
         {
             block(muted);
         }
     }];
}

- (void)isSystemVolumeDown:(void (^)(BOOL volumeDown))block
{
    [VolumeDetector checkVolume:^(BOOL success, CGFloat volume) {
        if (success)
        {
            block(volume <= kVolumeDownThreshold);
        }
    }];
}

#pragma mark - Monitoring

- (void)monitorAudioPlayer
{
    [self.audioPlayer updateMeters];
    
    CGFloat averageChannelPower = 0.0;
    
    for (int i = 0; i < self.audioPlayer.numberOfChannels; i++)
    {
        averageChannelPower += fabs([self.audioPlayer averagePowerForChannel:i]);
    }
    
    averageChannelPower = averageChannelPower / (float)self.audioPlayer.numberOfChannels;
    
    CGFloat maxPower = 25.0;
    CGFloat percentage = averageChannelPower / maxPower;
    
    if (percentage > 1.0) percentage = 1.0;
    if (percentage < 0.0) percentage = 0.0;
    
    [self.currentPlayingSoundItem.soundWave updateAmplitudeWithPercentage:percentage];
}

@end

#pragma mark - Item Implementation

@interface TMVSoundItem ()

@property (nonatomic, readwrite) Sound *sound;
@property (nonatomic, readwrite) TMVSoundWave *soundWave;
@property (nonatomic, readwrite) BOOL wantsToBeDisplayedNext;

@end

@implementation TMVSoundItem

- (instancetype)initWithSound:(Sound *)sound
                withSoundWave:(TMVSoundWave *)soundWave
       wantsToBeDisplayedNext:(BOOL)wantsNext
{
    self = [super init];
    
    if (self)
    {
        self.sound = sound;
        self.soundWave = soundWave;
        self.wantsToBeDisplayedNext = wantsNext;
    }
    
    return self;
}


@end


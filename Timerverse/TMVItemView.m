 //
//  TMVItem.m
//  Timerverse
//
//  Created by Larry Ryan on 1/11/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVItemView.h"
#import "TMVFloatingBehavior.h"
#import "TMVNotificationManager.h"
#import "TMVVolumeDetector.h"

static CGFloat const kMinimumScale = 0.5f; // Size the item goes to when starting
static CGFloat const kMaximumScale = 1.2f; // Size the item expands too
static CGFloat const kDefaultScale = 1.0f; // Normal state scale
static CGFloat const kPointScale = 0.3f; // Point state scale
static CGFloat const kMinimumTimeZoomingThreshold = 5000; // Milliseconds
static CGFloat const kItemBackgroundAlpha = 0.6f; // The alpha of the backgroundView
static BOOL const kNotificationsForRepeatingItems = NO; // System Notification for repeating items. If out of app the notification only plays once, which is why it is NO.

NSString * NSStringFromItemViewState(TMVItemViewState layout)
{
    switch (layout)
    {
        case TMVItemViewStateDefault:
            return @"ItemStateDefault";
            break;
        case TMVItemViewStatePoint:
            return @"ItemStatePoint";
            break;
        case TMVItemViewStateLocked:
            return @"ItemStatePoint";
            break;
        default:
            return @"Invalid ItemViewState";
            break;
    }
}

@interface TMVItemView () <TMVCounterLabelDelegate, TMVSoundWaveDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, readwrite) TMVSoundWave *soundWave; // The stroke
@property (nonatomic, readwrite) TMVDashView *dashView; // Dash view is own by this but is added the the ItemManager.animatorView
@property (nonatomic) UIView *backgroundView; // A subview of the containerView. The background view of the item which will be the items color

@property (nonatomic) UIView *contentView; // A subview of the containerView. Holds the following labels and imageViews...
@property (nonatomic, readwrite) TMVCounterLabel *counterLabel;
@property (nonatomic, readwrite) UILabel *nameLabel; // Hold the name the user has chosen. Either this nameLable or the glyph will be visible
@property (nonatomic, readwrite) UILabel *detailLabel; // Holds the repeat count
@property (nonatomic, readwrite) UIImageView *glyphImageView; // Hold the glyph image. Either this glyph or the nameLabel will be visible
@property (nonatomic, readwrite) UIImageView *repeatImageView; // When the item has not repeated yet, this imageView will be in place of the detail label which shows the repeat count
@property (nonatomic) UIActivityIndicatorView *activityIndicatorView; //

@property (nonatomic, readwrite, getter = isDragging) BOOL dragging; // When the user is panning the item around
@property (nonatomic, readwrite, getter = isPulsing) BOOL pulsing; // If the item is pulsing that means that the timer has finished

// Used for the snapping hint items. They start from out of bounds which would stop the color observer right away, so we let the itemView come on screen then start observing if the frames intersect
@property (nonatomic, getter = shouldObserveIntersection) BOOL observeIntersection;

// Behaviors
@property (nonatomic) UIDynamicItemBehavior *abyssObserverBehavior; // Used for KickOut. As the itemView gets closer to Abyss, the abyss will open up
@property (nonatomic) TMVFloatingBehavior *floatingBehavior; // An effect while being untouched, the itemView will float around a bit (NOT USED)
@property (nonatomic) UISnapBehavior *snapBehavior; // Used for gridlock, when using dynamic snapping
@property (nonatomic) UIDynamicItemBehavior *snapOptionsBehavior; // Used with the snapBehavior to add a few for attributes like no rotation

@end

@implementation TMVItemView

#pragma mark - Lifecycle

+ (instancetype)testItem
{
    TMVTimerItemView *item = [[TMVTimerItemView alloc] initWithColor:[UIColor randomColor]];
    
    [item setTimeHours:0
               minutes:0
               seconds:arc4random_uniform(30)];
    
    return item;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithColor:[UIColor randomColor]];
}

- (instancetype)initWithState:(TMVItemViewState)state
{
    self = [super initWithFrame:CGRectMake(0, 0, kItemViewSize, kItemViewSize)];
    if (self)
    {
        [self commonInitWithState:state
                         andColor:[UIColor randomColor]];
    }
    return self;
}

- (instancetype)initWithState:(TMVItemViewState)state
                andPanGesture:(UIPanGestureRecognizer *)panGesture
{
    self = [super initWithFrame:CGRectMake(0, 0, kItemViewSize, kItemViewSize)];
    if (self)
    {
        self.center = [panGesture locationInView:panGesture.view.superview];
        
        [self commonInitWithState:state
                         andColor:[UIColor randomColor]];
    }
    return self;
}

- (instancetype)initWithState:(TMVItemViewState)state
                      andItem:(Item *)item
{
    self = [super initWithFrame:CGRectMake(0, 0, kItemViewSize, kItemViewSize)];
    if (self)
    {
        _item = item;
        _gridLockIndex = item.gridLockIndex.integerValue;
        
        self.center = CGPointMake(item.location.x.floatValue, item.location.y.floatValue);
        
        [self commonInitWithState:state
                         andColor:[UIColor colorWithHue:item.color.hue.floatValue
                                             saturation:item.color.saturation.floatValue
                                             brightness:item.color.brightness.floatValue
                                                  alpha:item.color.alpha.floatValue]];
    }
    return self;
}

- (instancetype)initWithColor:(UIColor *)color
{
    self = [super initWithFrame:CGRectMake(0, 0, kItemViewSize, kItemViewSize)];
    if (self)
    {
        [self commonInitWithState:TMVItemViewStateDefault
                         andColor:color];
    }
    return self;
}

- (void)commonInitWithState:(TMVItemViewState)state
                   andColor:(UIColor *)color
{
    _apparentColor = color;
    
    [self configureContainerView];
    [self configureGestureRecognizers];
    
    self.state = state;
}

#pragma mark - Properties

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    [super setUserInteractionEnabled:userInteractionEnabled];
    
    for (UIGestureRecognizer *gesture in self.gestureRecognizers)
    {
        gesture.enabled = userInteractionEnabled;
    }
}

- (void)setItem:(Item *)item
{
    _item = item;
    
    // Time
    if (item.time.integerValue == NSNotFound || item.time.integerValue == 0)
    {
        self.counterLabel.countDirection = TMVCounterDirectionUp;
        self.counterLabel.startValue = 0;
    }
    else
    {
        self.counterLabel.countDirection = TMVCounterDirectionDown;
        self.counterLabel.startValue = _item.time.unsignedLongLongValue;
    }
    
    // Name Label
    if (item.name.length > 12)
    {
        self.nameLabel.text = nil;
    }
    else
    {
        self.nameLabel.text = item.name;
    }
    
    // Glyph
    if (!item.glyphURL)
    {
        item.glyphURL = nil;
        
        self.glyphImageView.image = nil;
    }
    else
    {
        self.glyphImageView.image = [UIImage imageNamed:item.glyphURL];
    }
    
    // Color
    self.apparentColor = [UIColor colorWithHue:item.color.hue.floatValue
                                    saturation:item.color.saturation.floatValue
                                    brightness:item.color.brightness.floatValue
                                         alpha:item.color.alpha.floatValue];
    
    // Detail Label
    self.detailLabel.text = @"";
}

- (void)setCenter:(CGPoint)center
{
    [super setCenter:center];
    
    // Update the MO
    self.item.location.x = @(center.x);
    self.item.location.y = @(center.y);
    
    // Update the animator so it knows where it is at all times
    [AppContainer.itemManager.animator updateItemUsingCurrentState:self];
    
    [self.soundWave updateShimmerAngle];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [AppContainer.itemManager.animator updateItemUsingCurrentState:self];
}

- (void)setApparentColor:(UIColor *)apparentColor
{
    _apparentColor = apparentColor;
    
    // Refrain from update the soundwave color when the itemView is at point state since the soundwave is hidden. Once the itemView is done choosing a color, the soundwave color is directly set before fading in when going into the default state
    if (self.state != TMVItemViewStatePoint) self.soundWave.color = apparentColor;
    
    [self updateBackgroundViewColorWithOpacity:self.state == TMVItemViewStateDefault ? kItemBackgroundAlpha : 1.0f];
    
    // Not important right now but if color can be changed dynamically while item exist we must update the dash color
    //self.dash.shapelayer.strokecolor...
    
    // Update the MO
    CGFloat hue, saturation, brightness, alpha;
    [apparentColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
    self.item.color.hue = @(hue);
    self.item.color.saturation = @(saturation);
    self.item.color.brightness = @(brightness);
    self.item.color.alpha = @(alpha);
}

- (void)setState:(TMVItemViewState)state
{
    [self setState:state
          animated:NO];
}

- (void)setState:(TMVItemViewState)state
        animated:(BOOL)animated
{
    // Added to prevent restoring purchases make timers that are running glitch scale
    if (self.counterLabel.isRunning) return;
    
    TMVItemViewState sourceState = _state;
    
    if ([self.delegate respondsToSelector:@selector(willChangeFromState:toState:)])
    {
        [self.delegate willChangeFromState:sourceState
                                   toState:state];
    }
    
    if (animated)
    {
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self setState:state
                                   animated:NO];
                         }
                         completion:^(BOOL finished) {
                         }];
    }
    else
    {
        _state = state;
        
        switch (state)
        {
            case TMVItemViewStateDefault:
            case TMVItemViewStateLocked:
            {
                [self updateBackgroundViewColorWithOpacity:kItemBackgroundAlpha];
                self.soundWave.layer.opacity = 1.0f;
                self.contentView.layer.opacity = 1.0f;
                //                self.containerView.layer.shadowOpacity = kItemShadowAlpha;
                [self configureDashView];
                
                [self scaleToSize:kDefaultScale];
                
                // Because of fall through
                if (state == TMVItemViewStateLocked)
                {
                    self.item.enabled = @NO;
                    self.counterLabel.text = NSLocalizedString(@"Upgrade", Upgrade);
                    self.counterLabel.transform = CGAffineTransformMakeScale(0.8, 0.8);
                    
                    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                    numberFormatter.formatterBehavior = NSNumberFormatterBehavior10_4;
                    numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
                    numberFormatter.locale = [IAPManager.productArray.firstObject priceLocale];
                    
                    self.nameLabel.text = [numberFormatter stringFromNumber:[IAPManager.productArray.firstObject price]];
                }
                else
                {
                    if (!self.item.enabled.boolValue)
                    {
                        [self hideActivityIndicatorAnimated:YES];
                        
                        [UIView transitionWithView:self.counterLabel
                                          duration:1.0f
                                           options:UIViewAnimationOptionTransitionCrossDissolve
                                        animations:^{
                                            self.counterLabel.text = self.counterLabel.valueString;
                                            
                                            self.counterLabel.transform = CGAffineTransformMakeScale(1.0, 1.0);
                                        }
                                        completion:^(BOOL finished) {}];
                        
                        [UIView animateWithDuration:1.0f
                                              delay:0.0f
                                            options:UIViewAnimationOptionBeginFromCurrentState
                                         animations:^{
                                             self.nameLabel.layer.opacity = 0.0f;
                                         }
                                         completion:^(BOOL finished) {
                                             self.nameLabel.layer.opacity = 1.0f;
                                             self.nameLabel.text = @"";
                                         }];
                    }
                    
                    
                    self.item.enabled = @YES;
                }
                
                [DataManager saveContext];
            }
                break;
            case TMVItemViewStatePoint:
            {
                [self updateBackgroundViewColorWithOpacity:1.0f];
                self.soundWave.layer.opacity = 0.0f;
                self.contentView.layer.opacity = 0.0f;
                //                self.containerView.layer.shadowOpacity = kItemShadowAlpha;
                
                [self scaleToSize:kPointScale];
            }
                break;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(didChangeFromState:toState:)])
    {
        [self.delegate didChangeFromState:sourceState
                                  toState:state];
    }
}

- (void)setGridLockIndex:(NSUInteger)gridLockIndex
{
    _gridLockIndex = gridLockIndex;
    
    self.item.gridLockIndex = @(gridLockIndex);
    
    if ([self.delegate respondsToSelector:@selector(didUpdateGridLockIndexForItemView:)])
    {
        [self.delegate didUpdateGridLockIndexForItemView:self];
    }
}

- (void)setEditing:(BOOL)editing
{
    if (_editing == editing) return;
    
    _editing = editing;
    
    if (editing)
    {
        if ([self.delegate respondsToSelector:@selector(didBeginEditingItemView:)])
        {
            [self.delegate didBeginEditingItemView:self];
        }
    }
    else
    {
        if ([self.delegate respondsToSelector:@selector(didEndEditingItemView:)])
        {
            [self.delegate didEndEditingItemView:self];
        }
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@; state = %@; currentTime = %@;", [super description], NSStringFromItemViewState(self.state), self.counterLabel];
}


#pragma mark - Superview Management

- (void)sendToWindow
{
    if (![self.superview isEqual:AppDelegate.window])
    {
        CGPoint convertedPoint = [self.superview convertPoint:self.center toView:nil];
        
        self.center = convertedPoint;
        [AppDelegate.window addSubview:self];
        [AppDelegate.window bringSubviewToFront:self];
    }
}

- (void)sendToAnimatorView
{
    if (![self.superview isEqual:AppContainer.itemManager.animatorView])
    {
        CGPoint convertedPoint = [AppContainer.itemManager.animatorView convertPoint:self.center fromView:nil];
        
        self.center = convertedPoint;
        [AppContainer.itemManager.animatorView addSubview:self];
        [AppContainer.itemManager.animatorView bringSubviewToFront:self];
    }
}

#pragma mark - ContainerView

- (void)configureContainerView
{
    if (!self.containerView)
    {
        self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
        [self addSubview:self.containerView];
        
        // Setup the content of the itemView
        [self configureSoundWave];
        [self configureContentView];
    }
}

#pragma mark - SoundWave

- (void)configureSoundWave
{
    if (!self.soundWave)
    {
        // Make a transparent, stroked layer which will dispay the stroke.
        self.soundWave = [[TMVSoundWave alloc] initWithColor:self.apparentColor
                                            andVibrationType:SoundWaveVibrationTypeTravel];
        
        self.soundWave.center = self.center;
        self.soundWave.delegate = self;
        self.soundWave.itemView = self;
        
        [self.containerView addSubview:self.soundWave];
    }
}

#pragma mark Delegate

- (void)didUpdatePath:(UIBezierPath *)path
{
    CGFloat widthDifference = (self.soundWave.width - self.backgroundView.width) / 2;
    CGFloat heightDifference = (self.soundWave.height - self.backgroundView.height) / 2;
    
    CGRect frame;
    frame.origin = CGPointMake(-widthDifference, -heightDifference);
    frame.size = self.backgroundView.size;
    
    // Mask the itemView to the soundwave Shape
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = path.CGPath;
    maskLayer.frame = frame;
    
    self.backgroundView.layer.mask = maskLayer;
}


#pragma mark - DashView

- (void)configureDashView
{
    if (!self.dashView)
    {
        self.dashView = [[TMVDashView alloc] initWithFrame:CGRectMake(0, 0, kItemViewSize, kItemViewSize)
                                        attachedToItemView:self];
        
        [self scaleDashView:self.currentScale.width];
    }
}

- (void)showDashViewAtPoint:(CGPoint)point
{
    if (self.state == TMVItemViewStatePoint) return;
    
    self.dashView.center = point;
    
    if (self.counterLabel.isRunning)
    {
        [self.dashView startSpinning];
    }
    
    [AppContainer.contentContainerView addSubview:self.dashView];
    [AppContainer.contentContainerView sendSubviewToBack:self.dashView];
}

- (void)snapDashToPoint:(CGPoint)point
{
    if (!_dashView) return;
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.dashView.center = point;
                     }
                     completion:^(BOOL finished) {}];
}

- (void)removeDashViewAnimated:(BOOL)animated
{
    [self hideDashViewAnimated:animated withCompletion:^{
        [self.dashView removeFromSuperview];
        self.dashView = nil;
    }];
}

- (void)hideDashViewAnimated:(BOOL)animated
              withCompletion:(void (^)(void))completion
{
    if (animated)
    {
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.dashView.layer.opacity = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             completion();
                         }];
    }
    else
    {
        self.dashView.layer.opacity = 0.0f;
    }
}

- (void)hideDashViewAnimated:(BOOL)animated
{
    [self hideDashViewAnimated:animated
                withCompletion:^{
                    
                }];
}

- (void)scaleDashView:(CGFloat)scale
{
    if (_dashView) self.dashView.layer.transform = CATransform3DMakeScale(scale, scale, 1.0f);
}

- (void)updateDashViewOpacityForItemViewPosition
{
    if (AppContainer.itemManager.layout == TMVItemManagerLayoutDynamics) return;
    
    if (_dashView)
    {
        CGFloat thresholdDistance = self.height;
        
        CGPoint convertedPoint = [self.superview convertPoint:self.center toView:nil];
        CGPoint convertedDashPoint = [self.dashView.superview convertPoint:self.dashView.center toView:nil];
        
        CGFloat distance = hypotf(convertedDashPoint.x - convertedPoint.x, convertedDashPoint.y - convertedPoint.y);
        
        if (distance >= thresholdDistance)
        {
            self.dashView.layer.opacity = 1.0f;
        }
        else
        {
            CGFloat percentage = distance / thresholdDistance;
            
            self.dashView.layer.opacity = percentage;
        }
    }
}

#pragma mark - ContentView

- (void)configureContentView
{
    if (!self.contentView)
    {
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        [self.containerView addSubview:self.contentView];
        [self.containerView bringSubviewToFront:self.contentView];
    }
    
    [self configureLabel];
    [self configureName];
    [self configureDetailLabel];
    [self configureGlyphImageView];
    
    if (self.item.repeat.boolValue && self.counterLabel.repeatCount == 0)
    {
        [self showRepeatImageViewAnimated:NO];
    }
    
    [self configureBackgroundView];
}

- (void)configureBackgroundView
{
    if (!self.backgroundView)
    {
        // Make the background view larger than the item for the soundwaves masking
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(-self.halfWidth, -self.halfHeight, self.width * 2, self.height * 2)];
        [self updateBackgroundViewColorWithOpacity:kItemBackgroundAlpha];
        [self.containerView addSubview:self.backgroundView];
        [self.containerView sendSubviewToBack:self.backgroundView];
    }
}

- (void)updateBackgroundViewColorWithOpacity:(CGFloat)opacity
{
    self.backgroundView.backgroundColor = [self.apparentColor colorWithAlphaComponent:opacity];
}

#pragma mark Labels

- (void)configureName
{
    if (!self.nameLabel)
    {
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
        self.nameLabel.textColor = [UIColor whiteColor];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.adjustsFontSizeToFitWidth = YES;
        self.nameLabel.minimumScaleFactor = 0.1;
        self.nameLabel.layer.opacity = 0.8;
        self.nameLabel.center = CGPointMake(self.halfWidth, self.height - (self.height / 4 - 2));
        self.nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
        self.nameLabel.text = self.item.name;
        
        [self.contentView addSubview:self.nameLabel];
    }
}

- (void)configureGlyphImageView
{
    if (!self.glyphImageView)
    {
        self.glyphImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        self.glyphImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        if (self.item.glyphURL && self.item.glyphURL.length > 0)
        {
            self.glyphImageView.image = [UIImage imageNamed:self.item.glyphURL];
        }
        
        self.glyphImageView.center = CGPointMake(self.halfWidth, self.height - (self.height / 4 - 2));
        
        [self.contentView addSubview:self.glyphImageView];
    }
}

- (void)showActivityIndicatorAnimated:(BOOL)animated
{
    if (!self.activityIndicatorView)
    {
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.activityIndicatorView.center = CGPointMake(self.halfWidth, self.height / 4 - 2);
        self.activityIndicatorView.hidesWhenStopped = YES;
        
        [self.contentView addSubview:self.activityIndicatorView];
        
        [self.activityIndicatorView startAnimating];
        
        if (animated)
        {
            self.activityIndicatorView.layer.opacity = 0.0f;
            
            [UIView animateWithDuration:0.4
                                  delay:0.0f
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 self.activityIndicatorView.layer.opacity = 1.0f;
                             }
                             completion:^(BOOL finished) {
                                 
                             }];
        }
    }
}

- (void)hideActivityIndicatorAnimated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.4
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.activityIndicatorView.layer.opacity = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             [self.activityIndicatorView stopAnimating];
                             self.activityIndicatorView = nil;
                         }];
    }
    else
    {
        [self.activityIndicatorView stopAnimating];
        self.activityIndicatorView = nil;
    }
    
}

- (void)configureRepeatImageView
{
    if (!self.repeatImageView)
    {
        self.repeatImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"repeat"]];
        self.repeatImageView.frame = CGRectMake(0, 0, 20, 20);
        self.repeatImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.repeatImageView.center = CGPointMake(self.halfWidth, self.height / 4 - 2);
        
        [self.contentView addSubview:self.repeatImageView];
    }
}

- (void)showRepeatImageViewAnimated:(BOOL)animated
{
    [self configureRepeatImageView];
    
    if (animated)
    {
        [UIView animateWithDuration:0.3
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.repeatImageView.layer.opacity = 1.0f;
                         }
                         completion:^(BOOL finished) {
                             
                         }];
    }
    else
    {
        self.repeatImageView.layer.opacity = 1.0f;
    }
}

- (void)hideRepeatImageViewAnimated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.3
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self hideRepeatImageViewAnimated:NO];
                         }
                         completion:^(BOOL finished) {
                             
                         }];
    }
    else
    {
        self.repeatImageView.layer.opacity = 0.0f;
    }
}

- (void)configureDetailLabel
{
    if (!self.detailLabel)
    {
        self.detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
        self.detailLabel.textColor = [UIColor whiteColor];
        self.detailLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.adjustsFontSizeToFitWidth = YES;
        self.nameLabel.minimumScaleFactor = 0.1;
        self.detailLabel.layer.opacity = 0.8;
        self.detailLabel.font = self.counterLabel.font;
        self.detailLabel.center = CGPointMake(self.halfWidth, self.height / 4 - 2);
        
        [self.contentView addSubview:self.detailLabel];
    }
}

#pragma mark - CounterLabel

- (void)configureLabel
{
    if (!self.counterLabel)
    {
        self.counterLabel = [[TMVCounterLabel alloc] initWithFrame:CGRectMake(0, 0, self.width - (self.soundWave.strokeWidth * 2), self.height - (self.soundWave.strokeWidth * 2))];
        self.counterLabel.center = CGPointMake(self.halfWidth, self.halfHeight);
        self.counterLabel.delegate = self;
        self.counterLabel.itemView = self;
        
        [self.contentView addSubview:self.counterLabel];
    }
}

// These states are from what the item was before the app went to the background. Now that the app is active agian we need to determine what everything should be doing.
- (void)updateTimeFromStartDate
{
    if (!self.counterLabel.isRunning || !self.item.running.boolValue) return;
    
    switch (self.counterLabel.counterType)
    {
        case TMVCounterTypeStopWatch:
        {
            
        }
            break;
        case TMVCounterTypeTimer:
        {
            // UpdatePercentage will call SELF as the delegate which will update the scale of SELF's scale
            [self.counterLabel updatePercentage];
            
            switch (self.counterLabel.countDirection)
            {
                case TMVCounterDirectionUp:
                {
                    [self startPulsing];
                }
                    break;
                case TMVCounterDirectionDown:
                {
                    if (self.item.repeat.boolValue)
                    {
                        [self.counterLabel updateRepeatCount];
                        [self updateForRepeat];
                    }
                    else
                    {
                        if (self.counterLabel.timeElapsed > self.counterLabel.startValue)
                        {
                            self.counterLabel.countDirection = TMVCounterDirectionUp;
                            
                            [self startPulsing];
                            [self.soundWave startShimmering];
                        }
                    }
                }
                    break;
            }
        }
            break;
    }
}

- (void)setTimeHours:(NSUInteger)hours
             minutes:(NSUInteger)minutes
             seconds:(NSUInteger)seconds
{
    [self.counterLabel setStartValueWithHours:hours
                                      minutes:minutes
                                      seconds:seconds
                                 milliSeconds:0];
}

- (void)startCounting
{
    if (self.state == TMVItemViewStateDefault)
    {
        [self.counterLabel start];
    }
}

- (void)stopCounting
{
    if (self.state == TMVItemViewStateDefault)
    {
        [self.counterLabel stopAndReset];
    }
}

#pragma mark Delegate

- (void)countdownDidStart
{
    [self.dashView startSpinning];
    
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.detailLabel.layer.opacity = 0.0;
                     }
                     completion:^(BOOL finished) { }];
    
    // Scale the itemView for the time
    switch (self.counterLabel.countDirection)
    {
        case TMVCounterDirectionDown:
        {
            CGFloat minimizingDuration = 1.0f;
            
            if (self.counterLabel.startValue >= kMinimumTimeZoomingThreshold)
            {
                [self scaleToSize:kMinimumScale
                     withDuration:minimizingDuration
                   dynamicEffects:YES
                       completion:^(BOOL finished) {
                           if (finished)
                           {
                           }
                       }];
            }
            
            if ((self.item.repeat.boolValue && kNotificationsForRepeatingItems) || !self.item.repeat.boolValue)
            {
                // Give the notificationManager
                NSDate *newDate = [[NSDate date] dateByAddingTimeInterval:self.counterLabel.currentValue / 1000];
                
                [NotificationManager scheduleTimerForDate:newDate
                                        withTimerItemView:(TMVTimerItemView *)self];
            }
        }
            break;
        case TMVCounterDirectionUp:
        {
        }
            break;
    }
    
    // Let the delegate know
    if ([self.delegate respondsToSelector:@selector(didStartCountItem:)])
    {
        [self.delegate didStartCountItem:self];
    }
}

- (void)countDidChange
{
    // Keep the item inbounds when it begins going offscreen because of the scaling
    //    [self fixOriginForBounds];
    
    if ([self.delegate respondsToSelector:@selector(didCountItem:)])
    {
        [self.delegate didCountItem:self];
    }
}

- (void)countdownChangedPercentage:(CGFloat)percentage
{
    if (self.counterLabel.countDirection == TMVCounterDirectionUp) return;
    
    
    switch (self.state)
    {
        case TMVItemViewStateDefault:
        {
            [self scaleToSizeForPercentage:percentage];
        }
            break;
        case TMVItemViewStatePoint:
            break;
        case TMVItemViewStateLocked:
        {
            [self transitionToPointWithPercentage:percentage];
        }
            break;
    }
    
    
}

- (void)countdownDidStartCountingUpAfterFinish
{
    [self startPulsing];
}

- (void)countdownDidRepeat
{
    [self scaleToSize:kMinimumScale
         withDuration:1.0f
       dynamicEffects:YES
           completion:^(BOOL finished) {}];
    
    [self updateForRepeat];
}

- (void)updateForRepeat
{
    if ((self.item.repeat.boolValue && kNotificationsForRepeatingItems) || !self.item.repeat.boolValue)
    {
        // Give the notificationManager
        NSDate *newDate = [[NSDate date] dateByAddingTimeInterval:self.counterLabel.currentValue / 1000];
        
        [NotificationManager scheduleTimerForDate:newDate
                                withTimerItemView:(TMVTimerItemView *)self];
    }
    
    if (self.counterLabel.repeatCount > 0)
    {
        if (self.repeatImageView)
        {
            [self hideRepeatImageViewAnimated:YES];
        }
        
        self.detailLabel.text = [NSString stringWithFormat:@"x%lu", (unsigned long)self.counterLabel.repeatCount];
        
        // Hard coded itemView size. When theitemView is scaling and its bounds is changing, the detail label wont be placed right unless it is the default size
        self.detailLabel.center = CGPointMake(kItemViewSize / 2, kItemViewSize / 4 - 2);
        self.detailLabel.transform = CGAffineTransformMakeScale(0.6f, 0.6f);
        
        if (self.detailLabel.layer.opacity == 0.0f)
        {
            [UIView animateWithDuration:0.3f
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 self.detailLabel.layer.opacity = 1.0f;
                             }
                             completion:^(BOOL finished) { }];
        }
    }
}

- (void)countdownDidEnd
{
    switch (self.state) {
        case TMVItemViewStateDefault:
        {
            [SoundManager addSound:self.item.sound
                     withSoundWave:self.soundWave
         andWantsToBeDisplayedNext:NO];
        }
            break;
        case TMVItemViewStatePoint:
            break;
        case TMVItemViewStateLocked:
        {
            [AppContainer.itemManager kickoutItemView:self
                                      withKickOutType:TMVKickOutTypeDefault];
        }
            break;
        default:
            break;
    }
    
    
}

- (void)countdownDidReset
{
    if ([self.delegate respondsToSelector:@selector(didResetCountItem:)])
    {
        [self.delegate didResetCountItem:self];
    }
}

- (void)countdownDidStop
{
    [self.dashView stopSpinning];
    
    [self.soundWave stopShimmering];
    
    switch (self.counterLabel.countDirection)
    {
        case TMVCounterDirectionDown:
        {
            if (self.item.repeat.boolValue)
            {
                [UIView animateWithDuration:0.3f
                                      delay:0.0f
                                    options:UIViewAnimationOptionCurveEaseInOut
                                 animations:^{
                                     self.detailLabel.layer.opacity = 0.0f;
                                     self.repeatImageView.layer.opacity = 1.0f;
                                 }
                                 completion:^(BOOL finished) {
                                     self.detailLabel.text = @"";
                                 }];
            }
            
            [self stopPulsing];
        }
            break;
        case TMVCounterDirectionUp:
        {
            self.counterLabel.layer.opacity = 0.0f;
            self.counterLabel.transform = CGAffineTransformMakeScale(0.2f, 0.2f);
            
            self.detailLabel.centerY = self.counterLabel.centerY;
            self.detailLabel.text = [NSString stringWithFormat:@"%@", self.counterLabel.valueString];
            self.detailLabel.transform = CGAffineTransformIdentity;
            self.detailLabel.layer.opacity = 1.0f;
            
            [UIView animateWithDuration:0.3f
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 self.counterLabel.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                                 self.counterLabel.layer.opacity = 1.0f;
                                 
                                 self.detailLabel.center = CGPointMake(self.halfWidth, self.height / 4 - 2);
                                 self.detailLabel.transform = CGAffineTransformMakeScale(0.6f, 0.6f);
                             }
                             completion:^(BOOL finished) { }];
        }
            break;
    }
    
    [NotificationManager cancelTimerNotificationForItemView:(TMVTimerItemView *)self];
    
    // Scale the itemView back to the normal size
    [self scaleToSize:kDefaultScale
         withDuration:1.0
       dynamicEffects:YES
           completion:^(BOOL finished) {}];
    
    if ([self.delegate respondsToSelector:@selector(didStopCountItem:)])
    {
        [self.delegate didStopCountItem:self];
    }
}

- (void)countdownDidPause
{
    
}

- (void)countdownDidResume
{
    
}

#pragma mark - Scaling

- (CGFloat)scaleForCurrentTime:(NSTimeInterval)currentTime
                    ofDuration:(NSTimeInterval)duration
{
    CGFloat percentageOfDuration = currentTime / duration;
    
    CGFloat relativeMaxScale = kMaximumScale - kMinimumScale;
    CGFloat scale = relativeMaxScale * percentageOfDuration + kMinimumScale;
    
    return scale;
}

- (CGFloat)scaleForPercentage:(CGFloat)percentage
{
    CGFloat relativeMaxScale = kMaximumScale - kMinimumScale;
    CGFloat scale = (relativeMaxScale * percentage) + kMinimumScale;
    
    return scale;
}

- (CGFloat)percentageForCurrentScale
{
    CGFloat currentScale = [self currentScale].width;
    CGFloat relativeMaxScale = kMaximumScale - kMinimumScale;
    CGFloat percentage = (currentScale - kMinimumScale) / relativeMaxScale;
    
    return percentage;
}

- (void)scaleToSize:(CGFloat)percentage
{
    // Some reason when the item state is a point and is dragged out, the animator never updates the size right after it is set to the default state. To "fix" this we just keep the size of the item default even tho it might be in the point state
    
    // Set bounds for the dynamic animator
    CGFloat size = kItemViewSize * (self.state == TMVItemViewStateDefault ? percentage : 1.0f);
    CGFloat scale = percentage;
    
    if (self.counterLabel.startValue < kMinimumTimeZoomingThreshold && self.counterLabel.isRunning && self.counterLabel.counterType == TMVCounterTypeTimer)
    {
        size = (((kItemViewSize * kMaximumScale) - kItemViewSize) * percentage) + kItemViewSize;
        
        scale = ((kMaximumScale - kDefaultScale) * percentage) + kDefaultScale;
    }
    
    
    self.bounds = CGRectMake(0, 0, size, size);
    
    self.containerView.layer.transform = CATransform3DMakeScale(scale, scale, 1.0f);
    
    self.containerView.layer.anchorPoint = CGPointMake(0.5, 0.5);
    self.containerView.layer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    [AppContainer.itemManager.animator updateItemUsingCurrentState:self];
    
    // DashView
    [self scaleDashView:scale];
}

- (CGFloat)fixPercentage:(CGFloat)percentage
{
    if (percentage < 0.0) percentage = 0.0;
    if (percentage > 1.0) percentage = 1.0;
    
    return percentage;
}

- (void)scaleToSizeForPercentage:(CGFloat)percentage
{
    if (self.counterLabel.isRunning)
    {
        if (self.counterLabel.startValue < kMinimumTimeZoomingThreshold)
        {
            [self scaleToSize:percentage];
        }
        else
        {
            [self scaleToSize:[self scaleForPercentage:percentage]];
        }
    }
    else
    {
        [self scaleToSize:kDefaultScale];
    }
}

- (void)scaleToSize:(CGFloat)scale
       withDuration:(NSUInteger)duration
     dynamicEffects:(BOOL)dynamics
         completion:(void (^)(BOOL finished))completion
{
    if (dynamics)
    {
        if (duration < 1.0f) duration = 1.0f;
        
        [UIView animateWithDuration:duration
                              delay:0.0
             usingSpringWithDamping:0.7
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [self scaleToSize:scale];
                         }
                         completion:^(BOOL finished) {
                             completion(finished);
                         }];
    }
    else
    {
        [UIView animateWithDuration:duration
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [self scaleToSize:scale];
                         }
                         completion:^(BOOL finished) {
                             completion(finished);
                         }];
    }
}


// When the user is paning an item we don't want the item to go outside the bounds. Here we get the current size for the current scale and fix the origin to keep the itemView in bounds.
- (void)fixOriginForBounds
{
    CGFloat radius = [self sizeForCurrentScale].width / 2;
    
    CGFloat top = self.centerY - radius;
    CGFloat bottom = self.centerY + radius;
    CGFloat left = self.centerX - radius;
    CGFloat right = self.centerX + radius;
    
    if (left < 0)
    {
        self.centerX = radius;
    }
    if (right > self.superview.width)
    {
        self.centerX = self.superview.width - radius;
    }
    
    CGFloat offset = AppContainer.isAdLoaded ? AppContainer.adBanner.height : 0.0f;
    
    if (top < 0 + offset)
    {
        self.centerY = radius + offset;
    }
    
    // Timers that are running cannot be deleted so we need to make sure they don't enter the abyss
    if (self.counterLabel.isRunning && [AppContainer.itemManager.interactingItemsArray containsObject:self])
    {
        if (bottom > self.superview.height - AppContainer.view.contentOffsetY)
        {
            self.centerY = self.superview.height - AppContainer.view.contentOffsetY - radius;
        }
    }
}

- (CGSize)sizeForCurrentScale
{
    CGFloat width = kItemViewSize * [self currentXScale];
    CGFloat height = kItemViewSize * [self currentYScale];
    
    return CGSizeMake(width, height);
}

- (CGSize)currentScale
{
    return CGSizeMake([self currentXScale], [self currentYScale]);
}

- (CGFloat)currentXScale
{
    CGAffineTransform t = self.containerView.transform;
    
    return sqrt(t.a * t.a + t.c * t.c);
}

- (CGFloat)currentYScale
{
    CGAffineTransform t = self.containerView.transform;
    
    return sqrt(t.b * t.b + t.d * t.d);
}

#pragma mark - Helper Methods

- (CGFloat)secondsFromMilliSeconds:(unsigned long long)milliSeconds
{
    CGFloat convertedNumber = [NSNumber numberWithLongLong:milliSeconds].floatValue;
    
    return convertedNumber / 1000;
}


- (CGPoint)percentageForPoint:(CGPoint)point
                       inView:(UIView *)view
                    withInset:(CGSize)inset
{
    // X Percentage
    CGFloat xPointMax = view.width - inset.width;
    CGFloat xPercentage = (point.x - inset.width) / (view.width - (inset.width * 2));
    
    if (point.x < inset.width) xPercentage = 0.0;
    if (point.x > xPointMax) xPercentage = 1.0;
    
    // Y Percentage
    CGFloat yPointMax = view.height - inset.height;
    CGFloat yPercentage = (point.y - inset.height) / (view.height - (inset.height * 2));
    
    if (point.y < inset.height) yPercentage = 0.0;
    if (point.y > yPointMax) yPercentage = 1.0;
    
    return CGPointMake(xPercentage, yPercentage);
}


#pragma mark - UIDynamics

// Used from kickout behavior
- (void)removeAllBehaviorsExceptFlick
{
    [self removeFloating];
    [self removeSnap];
    
    [AppContainer.itemManager stopObservingColorForItemView:self];
    [AppContainer.itemManager removeItemViewFromUniversalOptionsBehavior:self];
    [AppContainer.itemManager removeItemViewFromUniversalCollisionBehavior:self];
}

- (void)removeAllBehaviors
{
    [self removeFloating];
    [self removeSnap];
    
    [AppContainer.itemManager removeItemViewFromUniversalFlickBehavior:self];
    [AppContainer.itemManager stopObservingColorForItemView:self];
    [AppContainer.itemManager removeItemViewFromUniversalOptionsBehavior:self];
    [AppContainer.itemManager removeItemViewFromUniversalCollisionBehavior:self];
}

#pragma mark Color Observer

- (void)observeColor
{
    self.apparentColor = [AppContainer.itemManager colorForItemViewPointWithAbyssInset:self];
    
    if (CGRectIntersectsRect(AppContainer.itemManager.animatorView.frame, self.frame))
    {
        self.observeIntersection = YES;
    }
    else
    {
        if (self.shouldObserveIntersection)
        {
            [AppContainer.itemManager stopObservingColorForItemView:self];
        }
    }
}

#pragma mark Snap Behavior

- (void)configureSnapOptionsBehavior
{
    if (!self.snapOptionsBehavior)
    {
        self.snapOptionsBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self]];
        self.snapOptionsBehavior.resistance = 20.0f;
        //        self.snapOptionsBehavior.allowsRotation = NO;
        [AppContainer.itemManager.animator addBehavior:self.snapOptionsBehavior];
    }
}

- (void)removeSnapOptions
{
    if ([AppContainer.itemManager.animator.behaviors containsObject:self.snapOptionsBehavior])
    {
        [AppContainer.itemManager.animator removeBehavior:self.snapOptionsBehavior];
    }
    
    self.snapOptionsBehavior = nil;
}


- (void)snapToPoint:(CGPoint)point
{
    [self configureSnapOptionsBehavior];
    
    self.snapBehavior = [[UISnapBehavior alloc] initWithItem:self
                                                 snapToPoint:point];
    self.snapBehavior.damping = 0.4f;
    [AppContainer.itemManager.animator addBehavior:self.snapBehavior];
}

- (void)snapToPoint:(CGPoint)point
     withCompletion:(void (^)(void))completion
{
    self.snapBehavior = [[UISnapBehavior alloc] initWithItem:self snapToPoint:point];
    
    __block UISnapBehavior *snapBehavior = self.snapBehavior;
    
    snapBehavior.damping = 0.7;
    
    __block CGPoint observingPoint = CGPointZero;
    
    __weak typeof(self) weakSelf = self;
    __weak UISnapBehavior *weakSnap = snapBehavior;
    
    snapBehavior.action = ^{
        
        if (CGPointEqualToPoint(weakSelf.center, observingPoint) && !CGPointEqualToPoint(weakSelf.center, point))
        {
            completion();
            
            [AppContainer.itemManager.animator removeBehavior:weakSnap];
        }
        else
        {
            observingPoint = weakSelf.center;
        }
        
    };
    
    [AppContainer.itemManager.animator addBehavior:self.snapBehavior];
}

- (void)removeSnap
{
    [self removeSnapOptions];
    
    if ([AppContainer.itemManager.animator.behaviors containsObject:self.snapBehavior])
    {
        [AppContainer.itemManager.animator removeBehavior:self.snapBehavior];
    }
    
    self.snapBehavior = nil;
}

#pragma mark - Floating Behavior

- (void)addFloatingBehavior
{
    if (!self.floatingBehavior)
    {
        self.floatingBehavior = [TMVFloatingBehavior new];
    }
    
    [self.floatingBehavior addFloatingBehaviorToItem:self];
}

- (void)removeFloating
{
    [self.floatingBehavior removeFloatingBehaviorToItem:self];
}


#pragma mark - Pulsing

- (void)startPulsing
{
    if (self.isPulsing) return;
    
    self.pulsing = YES;
    
    [self.layer removeAllAnimations];
    
    [UIView animateWithDuration:1.0f
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         [self updateBackgroundViewColorWithOpacity:0.3f];
                     }
                     completion:^(BOOL finished) {}];
}

- (void)stopPulsing
{
    if (!self.isPulsing) return;
    
    self.pulsing = NO;
    
    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         [self updateBackgroundViewColorWithOpacity:kItemBackgroundAlpha];
                     }
                     completion:^(BOOL finished) {}];
}


#pragma mark - Motion Effect

- (void)updateMotionEffectWithOffset:(NSUInteger)offset
{
    // Make sure the item doesn't already have a motion effect
    for (UIMotionEffectGroup *effect in self.containerView.motionEffects)
    {
        [self.containerView removeMotionEffect:effect];
    }
    
    // The mid motion in the galaxy is 16.0f
    CGFloat maximumTilt = kMotionEffectFactor;
    CGFloat minimumTilt = maximumTilt / (AppContainer.itemManager.itemViewArray.count + 1);
    
    CGFloat relativeMaxScale = maximumTilt - minimumTilt;
    CGFloat tilt = (relativeMaxScale * [self percentageForCurrentScale]) + minimumTilt;
    CGFloat alertViewTilt = AppContainer.isShowingAlertView ? kMotionEffectFactor : 0.0f;
    tilt += alertViewTilt;
    
    CGFloat modifier = AppContainer.isShowingAlertView ? 0.0f : 1.0f;
    
    UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    xAxis.minimumRelativeValue = [NSNumber numberWithFloat:-tilt * modifier];
    xAxis.maximumRelativeValue = [NSNumber numberWithFloat:tilt * modifier];
    
    UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    yAxis.minimumRelativeValue = [NSNumber numberWithFloat:-tilt * modifier];
    yAxis.maximumRelativeValue = [NSNumber numberWithFloat:tilt * modifier];
    
    UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
    group.motionEffects = @[xAxis, yAxis];
    
    [self.containerView addMotionEffect:group];
}


#pragma mark - Abyss Transition

- (void)interactiveTransitionToAbyssWithPercentage:(CGFloat)percentage
{
    // Adjust the percentage so we accomplish the transitions at the half point
    percentage = percentage / 0.5f;
    
    [self transitionToPointWithPercentage:percentage];
}

- (void)transitionToPointWithPercentage:(CGFloat)percentage
{
    if (percentage < 0.0f) percentage = 0.0f;
    if (percentage > 1.0f) percentage = 1.0f;
    
    CGFloat reversedPercentage = 1.0f - percentage;
    
    switch (self.state)
    {
        case TMVItemViewStateDefault:
        case TMVItemViewStateLocked:
        {
            [self updateBackgroundViewColorWithOpacity:((1.0f - kItemBackgroundAlpha) * percentage) + kItemBackgroundAlpha];
            self.soundWave.layer.opacity = reversedPercentage;
            self.contentView.layer.opacity = reversedPercentage;
            //            self.containerView.layer.shadowOpacity = kItemShadowAlpha * reversedPercentage;
            
            // Here we need to have the range between the two scales offseted to go from 0.0 to X.X
            CGFloat range = fabsf(kDefaultScale - kPointScale);
            CGFloat scaleAdditive = range * reversedPercentage;
            CGFloat scale = MIN(kDefaultScale, kPointScale) + scaleAdditive;
            
            [self scaleToSize:scale];
        }
            break;
            
        case TMVItemViewStatePoint:
        {
            //            self.containerView.layer.shadowOpacity = kItemShadowAlpha * reversedPercentage;
        }
            break;
    }
}

#pragma mark Color Observer

// Used by KickOut
- (void)beginObservingAbyss
{
    if (!self.abyssObserverBehavior)
    {
        self.abyssObserverBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self]];
        [AppContainer.itemManager.animator addBehavior:self.abyssObserverBehavior];
    }
    
    if ([self.abyssObserverBehavior.items containsObject:self])
    {
        __weak typeof(self) weakSelf = self;
        
        [self.abyssObserverBehavior addItem:self];
        
        self.abyssObserverBehavior.action = ^{
            [weakSelf performSelector:@selector(observeAbyss) withObject:nil];
        };
    }
}

- (void)stopObservingAbyss
{
    if ([AppContainer.itemManager.animator.behaviors containsObject:self.abyssObserverBehavior])
    {
        [AppContainer.itemManager.animator removeBehavior:self.abyssObserverBehavior];
    }
    
    self.abyssObserverBehavior = nil;
}

- (void)observeAbyss
{
    CGFloat percentage = [AppContainer percentageToAbyssForPoint:self.center];
    
    // Adjust the percentage so the items transform to a point sooner
    percentage = percentage / 0.5f;
    
    [self interactiveTransitionToAbyssWithPercentage:percentage];
    
    if (!CGRectContainsRect(AppContainer.itemManager.animatorView.frame, self.frame))
    {
        [self stopObservingAbyss];
    }
}

#pragma mark - Gesture Methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    if (AppContainer.itemManager.isLongPressingItem) return;
    
    [self.layer removeAllAnimations];
    [self removeAllBehaviors];
    
    if ([self.delegate respondsToSelector:@selector(didTouchItem:)])
    {
        [self.delegate didTouchItem:self];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    if ([self.delegate respondsToSelector:@selector(didEndTouchingItem:)])
    {
        [self.delegate didEndTouchingItem:self];
    }
}

- (void)configureGestureRecognizers
{
    // Apply tap gesture (Reset)
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedItem:)];
    doubleTap.delegate = self;
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];
    
    // Apply tap gesture (Pause)
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedItem:)];
    tap.delegate = self;
    tap.numberOfTapsRequired = 1;
    [tap requireGestureRecognizerToFail:doubleTap];
    [self addGestureRecognizer:tap];
    
    // Apply long press gesture
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(longPressedItem:)];
    longPress.delegate = self;
    [self addGestureRecognizer:longPress];
    
    // Apply pan gesture
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pannedItem:)];
    panGesture.delegate = self;
    [self addGestureRecognizer:panGesture];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    //    if (AppContainer.itemManager.isLongPressingItem) return NO;
    
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])
    {
        if (self.counterLabel.isRunning || self.state == TMVItemViewStateLocked || self.state == TMVItemViewStatePoint)
        {
            return NO;
        }
        else
        {
            AppContainer.itemManager.longPressingItem = YES;
        }
    }
    
    return YES;
}

- (void)panFromEdgePanGesture:(UIPanGestureRecognizer *)panGesture
{
    [self pannedItem:panGesture];
}

- (void)cancelGestures
{
    for (UIGestureRecognizer *gesture in self.gestureRecognizers)
    {
        gesture.enabled = NO;
        gesture.enabled = YES;
    }
}

#pragma mark Tap

- (void)tappedItem:(UITapGestureRecognizer *)tapGesture
{
    [AppContainer.statusBarView checkVolumeAndMuteStateAnimated:YES];
    
    switch (self.state)
    {
        case TMVItemViewStateLocked:
        {
        }
            break;
        case TMVItemViewStatePoint:
        {
            self.gridLockIndex = AppContainer.itemManager.itemViewArray.count;
            
            // If the item is for example is tapped when it is a "Hint", we need to go to that items settings
            self.apparentColor = [AppContainer.itemManager colorForItemViewPointWithAbyssInset:self];

            self.soundWave.color = self.apparentColor;
            
            [AppContainer.itemManager addItemView:self];
        }
            break;
        case TMVItemViewStateDefault:
        {
            if (tapGesture.numberOfTapsRequired == 1 && !self.counterLabel.isFinished)
            {
                if (self.counterLabel.isRunning)
                {
                    [self stopCounting];
//                    [self.counterLabel pause];
//                    
//                    if ([self.delegate respondsToSelector:@selector(didPauseCountItem:)])
//                    {
//                        [self.delegate didPauseCountItem:self];
//                    }
                }
                else
                {
                    [self startCounting];
                }
            }
            else
            {
                [self.counterLabel stopAndReset];
                
                [NotificationManager cancelTimerNotificationForItemView:(TMVTimerItemView *)self];
                
                // Scale the itemView back to the normal size
                [self scaleToSize:kDefaultScale
                     withDuration:1.0
                   dynamicEffects:YES
                       completion:^(BOOL finished) {}];
                
                if ([self.delegate respondsToSelector:@selector(didResetCountItem:)])
                {
                    [self.delegate didResetCountItem:self];
                }
                
                if ([self.delegate respondsToSelector:@selector(didStopCountItem:)])
                {
                    [self.delegate didStopCountItem:self];
                }
            }
            
            if (tapGesture.state == UIGestureRecognizerStateEnded)
            {
                if (AppContainer.itemManager.layout == TMVItemManagerLayoutDynamics)
                {
                    [AppContainer.itemManager addItemViewToUniversalOptionsBehavior:self];
                    [AppContainer.itemManager addItemViewToUniversalCollisionBehavior:self];
                }
            }
        }
            break;
    }
    
    if ([self.delegate respondsToSelector:@selector(didTapItem:withGesture:)])
    {
        [self.delegate didTapItem:self withGesture:tapGesture];
    }
}


#pragma mark Long Press

- (void)longPressedItem:(UILongPressGestureRecognizer *)longPressGesture
{
    if (longPressGesture.state == UIGestureRecognizerStateBegan)
    {
        switch (self.state)
        {
            case TMVItemViewStateDefault:
                break;
            case TMVItemViewStatePoint: // Disabled in gestureRecognizerShouldBegin
                break;
            case TMVItemViewStateLocked: // Disabled in gestureRecognizerShouldBegin
                break;
        }
        
        if ([self.delegate respondsToSelector:@selector(didLongPressItem:withGesture:)])
        {
            [self.delegate didLongPressItem:self withGesture:longPressGesture];
        }
    }
    else if (longPressGesture.state == UIGestureRecognizerStateEnded || longPressGesture.state == UIGestureRecognizerStateCancelled)
    {
        if (AppContainer.itemManager.layout == TMVItemManagerLayoutDynamics)
        {
            [AppContainer.itemManager addItemViewToUniversalOptionsBehavior:self];
            [AppContainer.itemManager addItemViewToUniversalCollisionBehavior:self];
        }
    }
}

#pragma mark Pan

- (void)pannedItem:(UIPanGestureRecognizer *)panGesture
{
    // Tell the delegate we're about to pan the item
    if ([self.delegate respondsToSelector:@selector(willPanItem:withGesture:)])
    {
        [self.delegate willPanItem:self withGesture:panGesture];
    }
    
    // Update the orgin for the pan
    [self setOriginWithAdditive:[panGesture translationInView:AppContainer.view]];
    
    switch (self.state)
    {
        case TMVItemViewStateDefault:
            break;
        case TMVItemViewStateLocked:
            break;
        case TMVItemViewStatePoint:
        {
            // Pick the color of the item by dragging it around
            self.apparentColor = [AppContainer.itemManager colorForItemViewPointWithAbyssInset:self];
            
            // The item escapse the touchPoint when dragging in an itemView fast with the ScreenEdge pan gesture, this is a fix for that. LocationInView needs to be the app window or the itemView moves away from the touch point as it goes towards the abyss
            CGPoint center = [panGesture locationInView:AppDelegate.window];
            
            if (!CGPointEqualToPoint(self.center, center)) self.center = center;
        }
            break;
    }
    
    // The item can be at any size at any time, here we get the size of the current scale and make sure it doesn't go out of bounds while panning.
    [self fixOriginForBounds];
    
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            self.dragging = YES;
            
            // Now that the all behaviors are removed, we can move the itemView from the animatorView to the app window
            [self sendToWindow];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            [panGesture setTranslation:CGPointZero
                                inView:self];
            
            [self updateDashViewOpacityForItemViewPosition];
            
            [self.soundWave updateShimmerAngle];
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            self.dragging = NO;
            
            // Move the itemView back to the animatorView before we add any behaviors
            [self sendToAnimatorView];
            
            if (AppContainer.itemManager.layout == TMVItemManagerLayoutDynamics)
            {
                [AppContainer.itemManager addItemViewToUniversalOptionsBehavior:self];
                [AppContainer.itemManager addItemViewToUniversalCollisionBehavior:self];
            }
            
            if (panGesture.state != UIGestureRecognizerStateCancelled)
            {
                [AppContainer.itemManager addItemViewToUniversalFlickBehavior:self
                                                                 withVelocity:[panGesture velocityInView:AppDelegate.window]];
            }
            
            // Directly set the soundwave color since it is ignored by the apparentColor setter when the itemView is in the point state. So once the itemView is done being dragged in the point state we can update its color.
            if (self.state == TMVItemViewStatePoint)
            {
                self.gridLockIndex = AppContainer.itemManager.itemViewArray.count;
                
                self.soundWave.color = self.apparentColor;
            }
            
            [self hideDashViewAnimated:YES];
        }
            break;
        default:
            break;
    }
    
    // Tell the delegate we did pan the item
    if ([self.delegate respondsToSelector:@selector(didPanItem:withGesture:)])
    {
        [self.delegate didPanItem:self withGesture:panGesture];
    }
}

@end

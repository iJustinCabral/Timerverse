//
//  TMVItemManager.m
//  Timerverse
//
//  Created by Larry Ryan on 1/11/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVItemManager.h"
#import "TNKDisplayLink.h"

static CGFloat const kMinimumVelocityForFlickBeahavior = 80.0f;
static BOOL const kItemMotionEffectEnabled = YES;
static BOOL const kItemViewCanCopyColor = NO;
static BOOL const kDynamicSnappingEnabled = NO;
static BOOL const kSnapWithInteractionEnabled = NO;
static BOOL const kUseEvenMarginForGridLock = YES;
static NSInteger const kDefaultSortingMode = TMVItemManagerSortingModeManual;
static NSInteger const kMaxDemoItemCount = 2;
//static BOOL const kUseDemoItems = NO;


@interface TMVItemManager () <TMVKickOutDelegate>

@property (nonatomic, readwrite) NSInteger maxItemCount;
@property (nonatomic, readwrite) NSInteger maxDemoItemCount;

@property (nonatomic, readwrite) CGFloat minimumVelocityForFlickBeahavior;
@property (nonatomic, readwrite) BOOL itemMotionEffectEnabled;
@property (nonatomic, readwrite) BOOL itemViewCanCopyColor;
@property (nonatomic, readwrite) BOOL dynamicSnappingEnabled;
@property (nonatomic, readwrite) BOOL snapWithInteractionEnabled;
@property (nonatomic, readwrite) BOOL useEvenMarginForGridLock;

@property (nonatomic, readwrite, getter = isShowingHint) BOOL showingHint;
//@property (nonatomic, readwrite, getter = isLongPressingItem) BOOL longPressingItem;

@property (nonatomic, readwrite) UIDynamicAnimator *animator;

// Holds all types of items eg. Timers, Alarms
@property (nonatomic, readwrite) NSArray *itemViewArray;
@property (nonatomic, readwrite) NSMutableArray *activeTimerItemsArray;
@property (nonatomic, readwrite) NSMutableArray *activeStopWatchItemsArray;
@property (nonatomic, readwrite) NSMutableArray *interactingItemsArray;
@property (nonatomic, readwrite) NSMutableArray *pendingCompletionItemsArray;
@property (nonatomic) NSMutableSet *snappingItemViewsSet;
@property (nonatomic) NSMutableSet *hintItemViews;
@property (nonatomic, getter = isSnappingItemViews) BOOL snappingItemViews;

@property (nonatomic) UIDynamicItemBehavior *universalOptionsBehavior;
@property (nonatomic, readwrite) UICollisionBehavior *universalCollisionBehavior; // Public to support Ad dyanmics
@property (nonatomic) UIGravityBehavior *universalGravityBehavior;
@property (nonatomic) UIDynamicItemBehavior *universalColorObserverBehavior;
@property (nonatomic) UIDynamicItemBehavior *universalFlickBehavior;

// Used to keep track of the last itemView whose color is being copied by a new item in the Point state
@property (nonatomic, weak) TMVItemView *itemToCopyColorFrom;
@property (nonatomic, readwrite, weak) TMVItemView *itemViewBeingEdited;

@end


@implementation TMVItemManager

#pragma mark - Lifecycle

- (instancetype)initWithAnimatorView:(UIView *)animatorView
                          dataSource:(id <TMVItemManagerDataSource>)dataSource
                         andDelegate:(id <TMVItemManagerDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        _minimumVelocityForFlickBeahavior = kMinimumVelocityForFlickBeahavior;
        _itemMotionEffectEnabled = kItemMotionEffectEnabled;
        _itemViewCanCopyColor = kItemViewCanCopyColor;
        _dynamicSnappingEnabled = kDynamicSnappingEnabled;
        _snapWithInteractionEnabled = kSnapWithInteractionEnabled;
        _useEvenMarginForGridLock = kItemMotionEffectEnabled;
        
        _layout = SettingsController.effectGridLockEnabled ? TMVItemManagerLayoutGridLock : TMVItemManagerLayoutDynamics;
        _sortingMode = kDefaultSortingMode;
        
        _animatorView = animatorView;
        _dataSource = dataSource;
        _delegate = delegate;
        
        _maxItemCount = [self maxItemCountForScreenDemensions];
        _maxDemoItemCount = kMaxDemoItemCount;
        
        [self listenToMainTimer];
        [self listenToApplicationEnterForeground];
        [self listenToApplicationBackground];
        
        // Make itemViews from the persisted items
        self.itemViewArray = [self itemViewsFromItems:[self allItems]];
        
        [self updateItemArrayOrderByGridIndexes];
        
        // Add the itemViews to the animator view
        if ([self hasItems])
        {
            for (TMVItemView *itemView in self.itemViewArray)
            {
                itemView.delegate = self;
                
                [self.animatorView addSubview:itemView];
                
                if (self.layout == TMVItemManagerLayoutDynamics)
                {
                    // Now that the animatorView is set we can add the item to the collision behavior
                    [self addItemViewToUniversalOptionsBehavior:itemView];
                    [self addItemViewToUniversalCollisionBehavior:itemView];
                }
            }
        }
        
        [TimeManager start];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.001f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            
            [self updateTimeForAllItemViews];
            
            [self snapItemViewsToGridLockAnimated:NO];
            
        });
    }
    
    return self;
}

#pragma mark - _______________________Notifications_______________________
#pragma mark -

#pragma mark MainTimer Observer

- (void)listenToMainTimer
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mainClockDidTick:)
                                                 name:@"mainTimerUpdated"
                                               object:nil];
}

- (void)mainClockDidTick:(NSNotification *)notification
{
    if (self.sortingMode == TMVItemManagerSortingModeAuto && [self hasActiveItems])
    {
        [self sortItems];
    }
}

#pragma mark - App Activity

- (void)listenToApplicationEnterForeground
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)willEnterForeground:(NSNotification *)notification
{
    [AppContainer.statusBarView checkVolumeAndMuteStateAnimated:NO];
    
    [self updateTimeForAllItemViews];
    
    [TimeManager start];
}

- (void)listenToApplicationBackground
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)didEnterBackground:(NSNotification *)notification
{
    [TimeManager stop];
    
    for (TMVItemView *itemView in self.itemViewArray)
    {
        if (itemView.counterLabel.isFinished)
        {
            [itemView stopPulsing];
        }
        
        if (itemView.dashView.isSpinning)
        {
            [itemView.dashView stopSpinning];
        }
    }
}

- (void)updateTimeForAllItemViews
{
    for (TMVItemView *itemView in self.itemViewArray)
    {
        [itemView updateTimeFromStartDate];
        
        if (itemView.counterLabel.isRunning || itemView.item.running.boolValue)
        {
            if (itemView.counterLabel.counterType == TMVCounterTypeTimer)
            {
                [self addItemViewToActiveTimerArray:itemView animated:YES];
            }
            else
            {
                [self addItemViewToActiveStopWatchArray:itemView animated:YES];
            }
        }
    }
}

#pragma mark - _______________________Properties_______________________
#pragma mark -

#pragma mark Setters

- (void)setLayout:(TMVItemManagerLayout)layout
{
    _layout = layout;
    
    switch (layout)
    {
        case TMVItemManagerLayoutGridLock:
        {
            [self snapItemViewsToGridLock];
        }
            break;
        case TMVItemManagerLayoutDynamics:
        {
            [self addDynamics];
        }
            break;
    }
}

#pragma mark - _______________________Helpers_______________________
#pragma mark -

#pragma mark Colors

- (UIColor *)colorFromActiveItemWithLeastTime
{
    return [[self allActiveItemViews] valueForKeyPath:@"@min.counterLabel.currentValue"];
}

- (UIColor *)colorForItemViewPointWithAbyssInset:(TMVItemView *)itemView
{
    CGSize currentSize = [itemView sizeForCurrentScale];
    CGFloat radiusX = currentSize.width / 2;
    CGFloat radiusY = currentSize.height / 2;
    
    CGFloat bottomInset = radiusY + AppContainer.theAbyss.halfHeight;
    
    CGFloat topInset = AppContainer.isAdLoaded ? radiusY + AppContainer.adBanner.bottom : radiusY;
    
    return [UIColor colorForPoint:itemView.center
                   withEdgeInsets:UIEdgeInsetsMake(topInset, radiusX, bottomInset, radiusX)];
}

- (UIColor *)colorFromItemWithLeastTime
{
    return [self.itemViewArray valueForKeyPath:@"@min.counterLabel.currentValue"];
}

- (NSArray *)colorsFromItemViews:(NSArray *)itemViews
{
    NSMutableArray *colors = [@[] mutableCopy];
    
    for (TMVItemView *itemView in itemViews)
    {
        [colors addObject:itemView.apparentColor];
    }
    
    return colors;
}

#pragma mark DataManager

- (NSArray *)allItems
{
    NSMutableArray *items = [@[] mutableCopy];
    
    //    [items addObjectsFromArray:[self allCounterItems]];
    [items addObjectsFromArray:[self allTimerItems]];
    //    [items addObjectsFromArray:[self allAlarmItems]];
    
    return items;
}

- (NSArray *)allCounterItems
{
    return [DataManager fetchObjectsForEntityName:@"CounterItem"];
}

- (NSArray *)allTimerItems
{
    return [DataManager fetchObjectsForEntityName:@"TimerItem"];
}

- (NSArray *)allAlarmItems
{
    return [DataManager fetchObjectsForEntityName:@"AlarmItem"];
}

#pragma mark Collections

- (BOOL)hasHintingItems
{
    return self.hintItemViews.count > 0;
}

- (BOOL)hasItems
{
    return self.itemViewArray.count > 0;
}

- (BOOL)hasInteractiveItems
{
    return self.interactingItemsArray.count > 0;
}

- (BOOL)hasActiveItems
{
    return [self hasActiveTimerItems] || [self hasActiveStopWatchItems];
}

- (BOOL)hasActiveTimerItems
{
    return self.activeTimerItemsArray.count > 0;
}

- (BOOL)hasActiveStopWatchItems
{
    return self.activeStopWatchItemsArray.count > 0;
}

- (BOOL)allItemViewsAreActive
{
    NSUInteger countOfItemViewsInDefaultState = 0;
    
    for (TMVItemView *itemView in self.itemViewArray)
    {
        if (itemView.state == TMVItemViewStateDefault)
        {
            countOfItemViewsInDefaultState++;
        }
    }
    
    return [self allActiveItemViews].count == countOfItemViewsInDefaultState;
}

#pragma mark ItemView

- (id)itemForItemView:(TMVItemView *)itemView
{
    BOOL isAlarmItemView = [itemView isKindOfClass:[TMVAlarmItemView class]];
    
    // Add a new item to the context
    Item *itemObject = [DataManager insertObjectForEntityName:isAlarmItemView ? @"AlarmItem" : @"TimerItem"];
    
    // Unique ID
    [itemObject setUniqueID:[[NSUUID UUID] UUIDString]];
    
    // Location
    Location *location = [DataManager insertObjectForEntityName:@"Location"];
    location.x = @(itemView.center.x);
    location.y = @(itemView.center.y);
    
    [itemObject setLocation:location];
    
    // Time
    [itemObject setTime:@(0)]; //arc4random_uniform(60) * 1000
    
    // Color
    UIColor *colorValue = [self colorForItemViewPointWithAbyssInset:itemView];
    
    CGFloat hue, saturation, brightness, alpha;
    [colorValue getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
    Color *colorObject = [DataManager insertObjectForEntityName:@"Color"];
    
    colorObject.hue = @(hue);
    colorObject.saturation = @(saturation);
    colorObject.brightness = @(brightness);
    colorObject.alpha = @(alpha);
    
    itemObject.color = colorObject;
    
    // Sound
    Sound *soundObject = [[[SoundManager allSounds] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                                                                ascending:YES]]] firstObject];
    
    [itemObject setSound:soundObject];
    
    // GridLock Index
    itemObject.gridLockIndex = @(self.itemViewArray.count);
    
    // Running
    itemObject.running = @(itemView.counterLabel.isRunning);
    
    return itemObject;
}

- (NSArray *)itemViewsFromItems:(NSArray *)items
{
    NSMutableArray *array = [@[] mutableCopy];
    
    for (id item in items)
    {
        if ([item isKindOfClass:[TimerItem class]])
        {
            TMVTimerItemView *itemView = [[TMVTimerItemView alloc] initWithState:[(TimerItem *)item enabled].boolValue ? TMVItemViewStateDefault : TMVItemViewStateLocked
                                                                         andItem:item];
            [array addObject:itemView];
        }
        else if ([item isKindOfClass:[AlarmItem class]])
        {
            TMVAlarmItemView *itemView = [[TMVAlarmItemView alloc] initWithState:TMVItemViewStateDefault
                                                                         andItem:item];
            [array addObject:itemView];
        }
        else if ([item isKindOfClass:[CounterItem class]])
        {
        }
        else
        {
        }
    }
    
    // Get rid of unwanted itemView
    if (array.count > self.maxItemCount)
    {
        [items enumerateObjectsUsingBlock:^(Item *item, NSUInteger index, BOOL *stop) {
            if (index >= self.maxItemCount)
            {
                [DataManager deleteObject:item];
            }
            
        }];
        
        [array removeObjectsInRange:NSMakeRange(self.maxItemCount, array.count - self.maxItemCount)];
    }
    
    return [array copy];
}

#pragma mark - _______________________Shoved Under Bed_______________________
#pragma mark -

// Used by the appcontainers edge pan. We don't know if the itemView is going to stick around so we postpone adding it the the itemViewArray
- (void)setupItemView:(TMVItemView *)itemView
              atPoint:(CGPoint)point
{
    itemView.delegate = self;
    
    itemView.center = point;
    
    itemView.item = [self itemForItemView:itemView];
    
    [self addItemViewToInteractiveTimerItemsArray:itemView];
    
    // Give the animatorView the new itemView so it can be influcenced by behaviors
    [self.animatorView addSubview:itemView];
    
    [AppContainer.statusBarView checkVolumeAndMuteStateAnimated:YES];
}

- (void)cancelGesturesForAllItems
{
    NSArray *array = [NSArray arrayWithArray:self.interactingItemsArray];
    
    for (TMVItemView *itemView in array)
    {
        [itemView cancelGestures];
    }
}

- (NSUInteger)maxItemCountForScreenDemensions
{
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    if (screenHeight < 700)
    {
        return 6;
    }
    else
    {
        return 12;
    }
}

#pragma mark - KickOut Methods

- (void)kickoutAllItems
{
    [self kickoutItemViews:self.itemViewArray];
}

- (void)kickoutAllActiveItems
{
    [self kickoutItemViews:[self allActiveItemViews]];
}

- (void)kickoutAllNonActiveItems
{
    [self kickoutItemViews:[self allNonActiveItemViews]];
}

- (void)kickoutItemViews:(NSArray *)itemViews
{
    [TMVKickOutBehavior kickOutItemViews:itemViews
                         withKickOutType:TMVKickOutTypeDefault
                             andDelegate:self];
}

- (void)kickoutItemView:(TMVItemView *)itemView
        withKickOutType:(TMVKickOutType)type
{
    [TMVKickOutBehavior kickOutItemView:itemView
                        withKickOutType:type
                            andDelegate:self];
}


#pragma mark Delegate

- (void)kickOutBehavior:(TMVKickOutBehavior *)kickOutBehavior
     didKickOutItemView:(TMVItemView *)itemView
{
    [self removeItemViewFromUniversalGravityBehavior:itemView];
    
    [AppContainer.itemManager removeItemView:itemView];
    
    [self updateGridLockIndexesToArrayIndex];
}

- (void)kickOutBehaviorClearedQueue:(TMVKickOutBehavior *)kickOutBehavior
{
    if (![self hasItems]) return;
    
    if (!kSnapWithInteractionEnabled)
    {
        [self snapItemViewsToGridLock];
    }
    
    //    [self updateMotionEffectsForAllItems];
}


#pragma mark - Show / Hide ItemViews

- (void)showItemsAnimated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.5f
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self showItemsAnimated:NO];
                         }
                         completion:^(BOOL finished) {
                             
                         }];
    }
    else
    {
        self.animatorView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    }
}

- (void)hideItemsAnimated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.5f
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self hideItemsAnimated:NO];
                         }
                         completion:^(BOOL finished) {}];
    }
    else
    {
        // 0.0 value was making the items just disappear for some reason
        self.animatorView.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    }
}

#pragma mark - Start/Stop All Counters

- (void)startAllItems
{
    [self.itemViewArray makeObjectsPerformSelector:@selector(startCounting)];
}

- (void)stopAllItems
{
    [self.itemViewArray makeObjectsPerformSelector:@selector(stopCounting)];
}

#pragma mark - Snapping Hint

- (void)showSnapHintForRandomPoint
{
    if (self.isShowingHint || self.interactingItemsArray.count > 0) return;
    
    CGFloat inset = 40;
    CGFloat heightWithInset = self.animatorView.height - (inset * 2);
    
    [self showSnapHintForPoint:CGPointMake(self.animatorView.halfWidth, arc4random_uniform(heightWithInset) + inset)
         andShouldSnapForXAxis:NO
                    completion:^{}];
}

- (void)showSnapHintForPoint:(CGPoint)point
       andShouldSnapForXAxis:(BOOL)xAxisSnapping
                  completion:(void (^)(void))hintCompletion
{
    if (self.isShowingHint || self.interactingItemsArray.count > 0) return;
    
    self.showingHint = YES;
    
    [AppContainer.statusBarView checkVolumeAndMuteStateAnimated:YES];
    
    __block BOOL alreadyCompleted = NO; // Once one of the snapping items complete it will call the hintCompletion block. This prevents the other item from doing so.
    
    __block TMVTimerItemView *leftItemView = [[TMVTimerItemView alloc] initWithState:TMVItemViewStatePoint];
    leftItemView.item = [self itemForItemView:leftItemView];
    leftItemView.delegate = self;
    
    [self addItemViewToHintArray:leftItemView];
    
    __block TMVTimerItemView *rightItemView = [[TMVTimerItemView alloc] initWithState:TMVItemViewStatePoint];
    rightItemView.item = [self itemForItemView:rightItemView];
    rightItemView.delegate = self;
    
    [self addItemViewToHintArray:rightItemView];
    
    // As of right now the items will be the same size so we don't need to have a left and right Y inset
    CGFloat yInset = (leftItemView.height - [leftItemView sizeForCurrentScale].height) / 2;
    
    if (point.y < yInset) point.y = yInset;
    if (point.y > self.animatorView.height - yInset) point.y = self.animatorView.height - yInset;
    
    CGFloat xOffset = 50.0f;
    
    CGFloat leftYPoint = point.y;
    CGFloat rightYPoint = point.y;
    
    // Make the starting and ending points
    CGPoint leftStartingPoint = CGPointMake(-leftItemView.width, leftYPoint);
    CGPoint rightStartingPoint = CGPointMake(self.animatorView.width + rightItemView.width, rightYPoint);
    
    // Give the items their starting points
    leftItemView.center = leftStartingPoint;
    rightItemView.center = rightStartingPoint;
    
    // Give the items their colors
    leftItemView.apparentColor = [self colorForItemViewPointWithAbyssInset:leftItemView];
    rightItemView.apparentColor = [self colorForItemViewPointWithAbyssInset:rightItemView];
    
    // Add the itemViews to the animatorView
    [self.animatorView addSubview:leftItemView];
    [self.animatorView addSubview:rightItemView];
    
    if (kDynamicSnappingEnabled)
    {
        
        CGFloat rightXPoint = xAxisSnapping ? point.x + xOffset : [self positionForRow:0
                                                                      withNumberOfRows:1
                                                                             andColumn:1
                                                                   withNumberOfColumns:2].x;
        
        CGFloat leftXPoint = xAxisSnapping ? point.x - xOffset : [self positionForRow:0
                                                                     withNumberOfRows:1
                                                                            andColumn:0
                                                                  withNumberOfColumns:2].x;
        
        CGPoint leftEndingPoint = CGPointMake(leftXPoint, leftYPoint);
        CGPoint rightEndingPoint = CGPointMake(rightXPoint, rightYPoint);
        
        // Start changing color
        [self beginObservingColorForItemView:leftItemView];
        [self beginObservingColorForItemView:rightItemView];
        
        // Snap the itemViews onto the screen
        [leftItemView snapToPoint:leftEndingPoint
                   withCompletion:^{
                       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                           if (leftItemView.isDragging || leftItemView.state == TMVItemViewStateDefault)
                           {
                               [self stopObservingColorForItemView:leftItemView];
                               self.showingHint = NO;
                           }
                           else
                           {
                               // It's too late to drag the item before it disappears, so stop the user interaction
                               leftItemView.userInteractionEnabled = NO;
                               
                               [leftItemView snapToPoint:leftStartingPoint
                                          withCompletion:^{
                                              [DataManager deleteObject:leftItemView.item];
                                              self.showingHint = NO;
                                              
                                              if (![self hasInteractiveItems]
                                                  && !alreadyCompleted
                                                  && ![self hasItems])
                                              {
                                                  alreadyCompleted = YES;
                                                  hintCompletion();
                                              }
                                          }];
                               
                           }
                       });
                   }];
        
        [rightItemView snapToPoint:rightEndingPoint
                    withCompletion:^{
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            if (rightItemView.isDragging || [self.interactingItemsArray containsObject:rightItemView] || rightItemView.state == TMVItemViewStateDefault || ![self.hintItemViews containsObject:rightItemView])
                            {
                                [self stopObservingColorForItemView:rightItemView];
                                self.showingHint = NO;
                            }
                            else
                            {
                                // It's too late to drag the item before it disappears, so stop the user interaction
                                rightItemView.userInteractionEnabled = NO;
                                
                                [rightItemView snapToPoint:rightStartingPoint
                                            withCompletion:^{
                                                [DataManager deleteObject:rightItemView.item];
                                                self.showingHint = NO;
                                                
                                                if (![self hasInteractiveItems]
                                                    && !alreadyCompleted
                                                    && ![self hasItems])
                                                {
                                                    alreadyCompleted = YES;
                                                    hintCompletion();
                                                }
                                            }];
                            }
                        });
                    }];
    }
    else
    {
        for (TMVItemView *itemView in self.hintItemViews)
        {
            [self snapHintInForItemView:itemView
                                atPoint:point
                         withCompletion:^{
                             hintCompletion();
                             
                         }];
        }
    }
}

- (void)snapHintInForItemView:(TMVItemView *)itemView
                      atPoint:(CGPoint)point
               withCompletion:(void (^)(void))hintCompletion
{
    [UIView animateWithDuration:0.8f
                          delay:0.0
         usingSpringWithDamping:0.55f
          initialSpringVelocity:1.0f
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         
                         NSUInteger column = itemView.centerX < AppContainer.view.halfWidth ? 0 : 1;
                         
                         itemView.centerX = [self positionForRow:0
                                                withNumberOfRows:0
                                                       andColumn:column
                                             withNumberOfColumns:2].x;
                         
                         itemView.apparentColor = [self colorForItemViewPointWithAbyssInset:itemView];
                         
                     }
                     completion:^(BOOL finished) {
                         
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                             
                             // Determine if the hinting itemViews have already been removed by some other action
                             if ([self.hintItemViews containsObject:itemView])
                             {
                                 [self snapHintOutForItemView:itemView
                                               withCompletion:^{
                                                   hintCompletion();
                                               }];
                             }
                             
                         });
                         
                     }];
}

// If the itemViews are hinting and the user drags out an item we use this method to hide the hinting itemViews early
- (void)snapHintOutForAllHintingItemViews
{
    for (TMVItemView *itemView in self.hintItemViews)
    {
        [self snapHintOutForItemView:itemView
                      withCompletion:^{
                          
                      }];
    }
}

- (void)snapHintOutForItemView:(TMVItemView *)itemView
                withCompletion:(void (^)(void))hintCompletion
{
    if (itemView.isDragging || [self.interactingItemsArray containsObject:itemView] || itemView.state == TMVItemViewStateDefault)
    {
        self.showingHint = NO;
        
        //!!!:
        //        [self removeItemViewFromHintArray:itemView];
    }
    else
    {
        itemView.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.5f
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             
                             if (itemView.centerX < AppContainer.view.halfWidth)
                             {
                                 itemView.centerX = -(itemView.width * 2);
                             }
                             else
                             {
                                 itemView.centerX = AppContainer.view.width + (itemView.width * 2);
                             }
                             
                             itemView.apparentColor = [self colorForItemViewPointWithAbyssInset:itemView];
                         }
                         completion:^(BOOL finished) {
                             
                             [self removeItemView:itemView];
                             self.showingHint = NO;
                             
                             [self removeItemViewFromHintArray:itemView];
                             
                             if (self.hintItemViews == 0)
                             {
                                 hintCompletion();
                             }
                             
                         }];
    }
}


#pragma mark - MotionEffects

- (void)updateMotionEffectsForAllItems
{
    if (kItemMotionEffectEnabled)
    {
        [self.itemViewArray enumerateObjectsUsingBlock:^(TMVItemView *item, NSUInteger index, BOOL *stop) {
            [item updateMotionEffectWithOffset:0]; //index
        }];
    }
}


#pragma mark - _______________________ItemView Delegate_______________________
#pragma mark -

#pragma mark Timer

- (void)didStartCountItem:(TMVTimerItemView *)itemView
{
    switch (itemView.counterLabel.countDirection)
    {
        case TMVCounterDirectionDown:
        {
            [self addItemViewToActiveTimerArray:itemView];
        }
            break;
        case TMVCounterDirectionUp:
        {
            [self addItemViewToActiveStopWatchArray:itemView];
        }
            break;
    }
    
    if (self.sortingMode == TMVItemManagerSortingModeAuto)
    {
        [self sortItems];
    }
}

- (void)didPauseCountItem:(TMVItemView *)itemView
{
    
}

- (void)didResumeCountItem:(TMVItemView *)itemView
{
    
}

- (void)didResetCountItem:(TMVTimerItemView *)itemView
{
    if (self.sortingMode == TMVItemManagerSortingModeAuto)
    {
        [self snapItemViewsToGridLock];
    }
}

- (void)didStopCountItem:(TMVTimerItemView *)itemView
{
    [self snapItemViewsToGridLock];
    
    switch (itemView.counterLabel.countDirection)
    {
        case TMVCounterDirectionDown:
        {
            [self removeItemViewFromActiveTimerArray:itemView];
        }
            break;
        case TMVCounterDirectionUp:
        {
            [self removeItemViewFromActiveStopWatchArray:itemView];
        }
            break;
    }
}

- (void)didCountItem:(TMVItemView *)itemView
{
    if ([self hasActiveTimerItems])
    {
        if ([self.activeTimerItemsArray indexOfObject:itemView] == 0)
        {
            [AppContainer refreshStats];
        }
    }
    else
    {
        if ([self.activeStopWatchItemsArray indexOfObject:itemView] == 0)
        {
            [AppContainer refreshStats];
        }
    }
}

#pragma mark - Grid Lock

- (void)didUpdateGridLockIndexForItemView:(TMVItemView *)itemView
{
    if (self.sortingMode == TMVItemManagerSortingModeAuto)
    {
        [self snapItemViewsToGridLock];
    }
}

#pragma mark - Events

- (void)didTouchItem:(TMVItemView *)itemView
{
    if (AppContainer.isSidePanning) return;
    
    [self addItemViewToInteractiveTimerItemsArray:itemView];
    
    if (SettingsController.effectGridLockEnabled && itemView.state != TMVItemViewStatePoint)
    {
        CGPoint point = [self pointForGridLockIndex:[self.itemViewArray indexOfObject:itemView]
                                withNumberOfIndexes:self.itemViewArray.count];
        
        [itemView showDashViewAtPoint:point];
    }
}

- (void)didEndTouchingItem:(TMVItemView *)itemView
{
    if (itemView.state == TMVItemViewStatePoint)
    {
        itemView.gridLockIndex = AppContainer.itemManager.itemViewArray.count;
        
        // If the item is for example is tapped when it is a "Hint", we need to go to that items settings
        itemView.apparentColor = [AppContainer.itemManager colorForItemViewPointWithAbyssInset:itemView];
        
        itemView.soundWave.color = itemView.apparentColor;
        
        [AppContainer.itemManager addItemView:itemView];
        
        [self removeItemViewFromHintArray:itemView];
        
        if (!IAPManager.purchased && IAPManager.purchaseType == IAPHelperPurchaseTypeDemo && self.itemViewArray.count > self.maxDemoItemCount)
        {
            [itemView setState:TMVItemViewStateLocked
                      animated:YES];
        }
        else
        {
            [itemView setState:TMVItemViewStateDefault
                      animated:YES];
        }
    }
    
    [self removeItemViewFromInteractiveTimerItemsArray:itemView];
}

#pragma mark - Gestures

- (void)didPanItem:(TMVTimerItemView *)itemView
       withGesture:(UIPanGestureRecognizer *)panGesture
{
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            // If the itemview is hinting and is interacted with the animation to send it offscreen will never be called, as well as the item being removed from the hintItemViews array
            if ([self.hintItemViews containsObject:itemView])
            {
                [self removeItemViewFromHintArray:itemView];
            }
            
            [self.animator updateItemUsingCurrentState:itemView];
            
            switch (itemView.state)
            {
                case TMVItemViewStateDefault:
                case TMVItemViewStateLocked:
                {
                    if (self.layout == TMVItemManagerLayoutGridLock)
                    {
                        // Sorting
                        [[self rectsForGridLockWithNumberOfIndexes:self.itemViewArray.count] enumerateObjectsUsingBlock:^(NSValue *gridRect, NSUInteger index, BOOL *stop) {
                            
                            // The current itemView can't intersect its own spot
                            if ([self.itemViewArray indexOfObject:itemView] != index)
                            {
                                if (CGRectIntersectsRectOverHalf(itemView.frame, gridRect.CGRectValue))
                                {
                                    [self moveSourceIndex:[self.itemViewArray indexOfObject:itemView]
                                       toDestinationIndex:index];
                                }
                            }
                            
                        }];
                    }
                }
                    break;
                case TMVItemViewStatePoint:
                {
                    if (kItemViewCanCopyColor)
                    {
                        BOOL isOverItemViewToCopyColorFrom = NO;
                        TMVItemView *itemViewToCopy;
                        
                        for (TMVItemView *itemViewObject in self.itemViewArray)
                        {
                            if (![itemViewObject isEqual:itemView])
                            {
                                if (CGRectContainsPoint(itemViewObject.frame, itemView.center))
                                {
                                    itemView.apparentColor = itemViewObject.apparentColor;
                                    itemViewToCopy = itemViewObject;
                                    isOverItemViewToCopyColorFrom = YES;
                                    
                                    break;
                                }
                            }
                        }
                        
                        if (isOverItemViewToCopyColorFrom)
                        {
                            if (![itemViewToCopy isEqual:self.itemToCopyColorFrom])
                            {
                                self.itemToCopyColorFrom = itemViewToCopy;
                            }
                        }
                        else
                        {
                            self.itemToCopyColorFrom = nil;
                        }
                    }
                    
                    if (self.itemViewArray.count < self.maxItemCount)
                    {
                        if (IAPManager.purchased)
                        {
                            [AppContainer.atmosphere updateColorAnimated:NO];
                        }
                        else
                        {
                            switch (IAPManager.purchaseType)
                            {
                                case IAPHelperPurchaseTypeDemo:
                                {
                                    if (IAPManager.purchaseType == IAPHelperPurchaseTypeDemo && self.itemViewArray.count <= self.maxDemoItemCount)
                                    {
                                        [AppContainer.atmosphere updateColorAnimated:NO];
                                    }
                                }
                                    break;
                                case IAPHelperPurchaseTypeAd:
                                {
                                    [AppContainer.atmosphere updateColorAnimated:NO];
                                }
                                    break;
                            }
                        }
                    }
                }
                    break;
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
        }
            break;
        default:
            break;
    }
    
    // When the items are running we don't want them to be deleted
    if (!itemView.counterLabel.isRunning)
    {
        [AppContainer interactiveTransitionToAbyssWithItemView:itemView
                                                withPanGesture:panGesture
                                                andUpdateBlock:^(BOOL finished, BOOL inAbyss)
         {
             if (finished)
             {
                 [self removeItemViewFromInteractiveTimerItemsArray:itemView];
                 
                 // ItemView was dropped inside of the abyss or out of bounds
                 if (inAbyss || !CGRectContainsPoint(self.animatorView.frame, itemView.center))
                 {
                     [itemView setState:TMVItemViewStatePoint
                               animated:YES];
                     
                     // Once the kickout behaviors ends it tells the ItemManager to remove the item
                     [self kickoutItemView:itemView
                           withKickOutType:TMVKickOutTypeAbyss];
                 }
                 else // ItemView was dropped outside of the abyss (IN BOUNDS)
                 {
                     switch (itemView.state)
                     {
                         case TMVItemViewStatePoint:
                         {
                             if (IAPManager.purchased || IAPManager.purchaseType == IAPHelperPurchaseTypeAd)
                             {
                                 if (self.itemViewArray.count >= self.maxItemCount)
                                 {
                                     [self kickoutItemView:itemView
                                           withKickOutType:TMVKickOutTypeDud];
                                 }
                                 else
                                 {
                                     [itemView setState:TMVItemViewStateDefault
                                               animated:YES];
                                     
                                     [self addItemView:itemView];
                                 }
                             }
                             else // Not Purchased and type is DEMO
                             {
                                 if (self.itemViewArray.count < self.maxDemoItemCount)
                                 {
                                     [itemView setState:TMVItemViewStateDefault
                                               animated:YES];
                                     
                                     [self addItemView:itemView];
                                 }
                                 else if (self.itemViewArray.count == self.maxDemoItemCount)
                                 {
                                     [itemView setState:TMVItemViewStateLocked
                                               animated:YES];
                                     
                                     [self addItemView:itemView];
                                 }
                                 else
                                 {
                                     [self kickoutItemView:itemView
                                           withKickOutType:TMVKickOutTypeDud];
                                 }
                             }
                             
                             [DataManager saveContext];
                         }
                             break;
                         case TMVItemViewStateDefault:
                         case TMVItemViewStateLocked:
                         {
                             // Set the default back to default or demo state incase it was scaled by the abyss
                             [itemView setState:itemView.state
                                       animated:YES];
                             
                             [self addItemViewToUniversalCollisionBehavior:itemView];
                             
                             [self snapItemViewsToGridLock];
                         }
                             break;
                     }
                 }
             }
         }];
    }
    else
    {
        if (panGesture.state == UIGestureRecognizerStateEnded || panGesture.state == UIGestureRecognizerStateCancelled)
        {
            [self removeItemViewFromInteractiveTimerItemsArray:itemView];
            
            [self addItemViewToUniversalCollisionBehavior:itemView];
            
            [self snapItemViewsToGridLock];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(didPanItem:withGesture:)])
    {
        [self.delegate didPanItem:itemView
                      withGesture:panGesture];
    }
}

- (void)didTapItem:(TMVTimerItemView *)itemView
       withGesture:(UITapGestureRecognizer *)gesture
{
    if ([self.delegate respondsToSelector:@selector(didTapItem:withGesture:)])
    {
        [self.delegate didTapItem:itemView withGesture:gesture];
    }
    
    [self removeItemViewFromInteractiveTimerItemsArray:itemView];
    
    switch (itemView.state)
    {
        case TMVItemViewStateDefault:
            break;
        case TMVItemViewStatePoint: // If tapped when the state is a point, the itemView is probably a hinting item
        {
            [self removeItemViewFromHintArray:itemView];
            
            if (IAPManager.purchased || IAPManager.purchaseType == IAPHelperPurchaseTypeAd)
            {
                [itemView setState:TMVItemViewStateDefault
                          animated:YES];
            }
            else // Not Purchased and type is DEMO
            {
                if (self.itemViewArray.count < self.maxDemoItemCount)
                {
                    [itemView setState:TMVItemViewStateDefault
                              animated:YES];
                }
                else if (self.itemViewArray.count == self.maxDemoItemCount)
                {
                    [itemView setState:TMVItemViewStateLocked
                              animated:YES];
                }
                else
                {
                    [self kickoutItemView:itemView
                          withKickOutType:TMVKickOutTypeDud];
                }
            }
        }
            break;
        case TMVItemViewStateLocked:
            break;
    }
}

- (void)didLongPressItem:(TMVTimerItemView *)itemView
             withGesture:(UILongPressGestureRecognizer *)gesture
{
    NSArray *itemViews = [[self interactingItemsArray] copy];
    
    for (TMVItemView *itemViewObject in itemViews)
    {
        if (![itemView isEqual:itemViewObject])
        {
            [itemViewObject cancelGestures];
            
            [self.interactingItemsArray removeObject:itemView];
        }
    }
    
    [self removeItemViewFromInteractiveTimerItemsArray:itemView];
    
    if (itemView.state == TMVItemViewStatePoint)
    {
        [self removeItemViewFromHintArray:itemView];
        
        [itemView setState:TMVItemViewStateDefault
                  animated:YES];
    }
    
    [self.delegate didLongPressItem:itemView
                        withGesture:gesture];
    
    self.longPressingItem = NO;
}

#pragma mark - Editing

- (void)didBeginEditingItemView:(TMVItemView *)itemView
{
    self.itemViewBeingEdited = itemView;
    
    [AppContainer.atmosphere updateColorAnimated:YES];
}

- (void)didEndEditingItemView:(TMVItemView *)itemView
{
    if ([self.itemViewBeingEdited isEqual:itemView])
    {
        self.itemViewBeingEdited = nil;
    }
}

#pragma mark - _______________________Array Management_______________________
#pragma mark -

#pragma mark Item Array

- (void)addItemView:(TMVItemView *)itemView
{
    // Update the array with our new item
    NSMutableArray *itemViews = [self.itemViewArray mutableCopy];
    [itemViews addObject:itemView];
    self.itemViewArray = [itemViews copy];
    
    [self snapItemViewsToGridLock];
    
    // All on the same parallax plain now so they don't have to update as the gridlock index changes
    //    [self updateMotionEffectsForAllItems];
    
    if ([self.delegate respondsToSelector:@selector(didAddItemView:)])
    {
        [self.delegate didAddItemView:itemView];
    }
}

- (void)removeItemViewFromItemViewArray:(TMVItemView *)itemView
{
    if ([self.itemViewArray containsObject:itemView])
    {
        NSMutableArray *array = [self.itemViewArray mutableCopy];
        [array removeObject:itemView];
        self.itemViewArray = [array copy];
    }
}

- (void)removeItemView:(TMVItemView *)itemView
{
    if ([self.delegate respondsToSelector:@selector(willRemoveItemView:)])
    {
        [self.delegate willRemoveItemView:itemView];
    }
    
    if (itemView.counterLabel.isRunning)
    {
        [itemView stopCounting];
    }
    
    [itemView removeDashViewAnimated:YES];
    
    [itemView.layer removeAllAnimations];
    [itemView removeAllBehaviors];
    [itemView removeFromSuperview];
    
    if ([itemView isKindOfClass:[TMVAlarmItemView class]])
    {
        [NotificationManager cancelAlarmNotificationForItemView:(TMVAlarmItemView *)itemView];
    }
    else if ([itemView isKindOfClass:[TMVTimerItemView class]])
    {
        [NotificationManager cancelTimerNotificationForItemView:(TMVTimerItemView *)itemView];
    }
    
    // Update Array. In some instances the itemView being removed might not be owned by the itemViewArray. One case is where the itemView(s) being kickout out are removed from the itemViewArray and the kickOutBehavior takes ownership of them until they go offscreen, which inturn calls this method to clean up that kicked out itemView.
    [self removeItemViewFromItemViewArray:itemView];
    
    switch (itemView.counterLabel.counterType)
    {
        case TMVCounterTypeStopWatch:
        {
            [self removeItemViewFromActiveStopWatchArray:itemView];
        }
            break;
        case TMVCounterTypeTimer:
        {
            [self removeItemViewFromActiveTimerArray:itemView];
        }
            break;
    }
    
    // Update the MO Context. When an item is deleted it cascades deletion to the location and color MO's.
    [DataManager deleteObjects:@[itemView.item]];
    
    // Update the Atmosphere
    if (![self hasItems])
    {
        [AppContainer.atmosphere updateColorAnimated:YES];
        
        if ([self.delegate respondsToSelector:@selector(didRemoveAllItemViews)])
        {
            [self.delegate didRemoveAllItemViews];
        }
    }
    else
    {
        if (!IAPManager.purchased)
        {
            if (self.itemViewArray.count == 1)
            {
                TMVItemView *itemViewObject = self.itemViewArray.firstObject;
                if (itemViewObject.state == TMVItemViewStateLocked)
                {
                    [itemViewObject setState:TMVItemViewStateDefault
                                    animated:YES];
                }
            }
        }
    }
}

- (void)addItemViewToSnappingItemViewSet:(TMVItemView *)itemView
{
    if (!self.snappingItemViewsSet) self.snappingItemViewsSet = [NSMutableSet set];
    
    if (![self.snappingItemViewsSet containsObject:itemView])
    {
        [self.snappingItemViewsSet addObject:itemView];
    }
}

- (void)removeItemViewFromSnappingItemViewSet:(TMVItemView *)itemView
{
    if ([self.snappingItemViewsSet containsObject:itemView])
    {
        [self.snappingItemViewsSet removeObject:itemView];
    }
    
    if (self.snappingItemViewsSet.count == 0)
    {
        self.snappingItemViews = NO;
    }
}

#pragma mark - Hint Array

- (void)addItemViewToHintArray:(TMVItemView *)itemView
{
    if (!self.hintItemViews) self.hintItemViews = [@[] mutableCopy];
    
    [self.hintItemViews addObject:itemView];
}

- (void)removeItemViewFromHintArray:(TMVItemView *)itemView
{
    if ([self.hintItemViews containsObject:itemView])
    {
        [self.hintItemViews removeObject:itemView];
    }
    
    if (self.hintItemViews.count == 0)
    {
        self.showingHint = NO;
        self.hintItemViews = nil;
    }
}

#pragma mark - Active Timer Array Methods

- (void)addItemViewToActiveTimerArray:(TMVItemView *)itemView
{
    [self addItemViewToActiveTimerArray:itemView
                               animated:YES];
}

- (void)addItemViewToActiveTimerArray:(TMVItemView *)itemView
                             animated:(BOOL)animated
{
    if (!self.activeTimerItemsArray) self.activeTimerItemsArray = [@[] mutableCopy];
    
    if (![self.activeTimerItemsArray containsObject:itemView])
    {
        [self.activeTimerItemsArray addObject:itemView];
    }
    
    [AppContainer.atmosphere updateColorAnimated:animated];
    
    if ([self.delegate respondsToSelector:@selector(didAddActiveTimerItemView:)])
    {
        [self.delegate didAddActiveTimerItemView:itemView];
    }
    
    if ([self.delegate respondsToSelector:@selector(didAddActiveItemView:)])
    {
        [self.delegate didAddActiveItemView:itemView];
    }
}

- (void)removeItemViewFromActiveTimerArray:(TMVItemView *)itemView
{
    if ([self.activeTimerItemsArray containsObject:itemView])
    {
        [self.activeTimerItemsArray removeObject:itemView];
    }
    
    [AppContainer.atmosphere updateColorAnimated:YES];
    
    if (self.activeTimerItemsArray.count == 0)
    {
        self.activeTimerItemsArray = nil;
        
        if ([self.delegate respondsToSelector:@selector(didRemoveAllActiveTimerItemViews)])
        {
            [self.delegate didRemoveAllActiveTimerItemViews];
        }
        
        if (self.activeStopWatchItemsArray.count == 0)
        {
            if ([self.delegate respondsToSelector:@selector(didRemoveAllActiveItemViews)])
            {
                [self.delegate didRemoveAllActiveItemViews];
            }
        }
    }
}

#pragma mark Active Stopwatch Array Methods

- (void)addItemViewToActiveStopWatchArray:(TMVItemView *)itemView
{
    [self addItemViewToActiveStopWatchArray:itemView
                                   animated:YES];
}

- (void)addItemViewToActiveStopWatchArray:(TMVItemView *)itemView
                                 animated:(BOOL)animated
{
    if (!self.activeStopWatchItemsArray) self.activeStopWatchItemsArray = [@[] mutableCopy];
    
    if (![self.activeStopWatchItemsArray containsObject:itemView])
    {
        [self.activeStopWatchItemsArray addObject:itemView];
    }
    
    [AppContainer.atmosphere updateColorAnimated:animated];
    
    if ([self.delegate respondsToSelector:@selector(didAddActiveStopWatchItemView:)])
    {
        [self.delegate didAddActiveStopWatchItemView:itemView];
    }
    
    if ([self.delegate respondsToSelector:@selector(didAddActiveItemView:)])
    {
        [self.delegate didAddActiveItemView:itemView];
    }
}

- (void)removeItemViewFromActiveStopWatchArray:(TMVItemView *)itemView
{
    if ([self.activeStopWatchItemsArray containsObject:itemView])
    {
        [self.activeStopWatchItemsArray removeObject:itemView];
    }
    
    [AppContainer.atmosphere updateColorAnimated:YES];
    
    if (self.activeStopWatchItemsArray.count == 0)
    {
        self.activeStopWatchItemsArray = nil;
        
        if ([self.delegate respondsToSelector:@selector(didRemoveAllActiveStopWatchItemViews)])
        {
            [self.delegate didRemoveAllActiveStopWatchItemViews];
        }
        
        if (self.activeTimerItemsArray.count == 0)
        {
            if ([self.delegate respondsToSelector:@selector(didRemoveAllActiveItemViews)])
            {
                [self.delegate didRemoveAllActiveItemViews];
            }
        }
    }
}

#pragma mark Interactive Array Methods

- (void)addItemViewToInteractiveTimerItemsArray:(TMVItemView *)itemView
{
    if (!self.interactingItemsArray) self.interactingItemsArray = [@[] mutableCopy];
    
    if (![self.interactingItemsArray containsObject:itemView])
    {
        [self.interactingItemsArray addObject:itemView];
    }
    
    if (itemView.state != TMVItemViewStatePoint)
    {
        [AppContainer.atmosphere updateColorAnimated:YES];
    }
    else if (self.itemViewArray.count < self.maxItemCount)
    {
        if (IAPManager.purchased)
        {
            [AppContainer.atmosphere updateColorAnimated:YES];
        }
        else
        {
            if (self.itemViewArray.count <= self.maxDemoItemCount)
            {
                [AppContainer.atmosphere updateColorAnimated:YES];
            }
        }
    }
    
    if (kSnapWithInteractionEnabled) [self snapItemViewsToGridLock];
    
    if ([self.delegate respondsToSelector:@selector(didAddInteractiveItemView:)])
    {
        [self.delegate didAddInteractiveItemView:itemView];
    }
}

- (void)removeItemViewFromInteractiveTimerItemsArray:(TMVItemView *)itemView
{
    if (![self.interactingItemsArray containsObject:itemView]) return;
    
    [self.interactingItemsArray removeObject:itemView];
    
    [AppContainer.atmosphere updateColorAnimated:YES];
    
    [itemView hideDashViewAnimated:YES];
    
    if (kSnapWithInteractionEnabled) [self snapItemViewsToGridLock];
    
    if ([self.delegate respondsToSelector:@selector(didRemoveInteractiveItemView:)])
    {
        [self.delegate didRemoveInteractiveItemView:itemView];
    }
    
    if (self.interactingItemsArray.count == 0)
    {
        self.interactingItemsArray = nil;
        
        if ([self.delegate respondsToSelector:@selector(didRemoveAllInteractiveItemViews)])
        {
            [self.delegate didRemoveAllInteractiveItemViews];
        }
    }
}

- (NSArray *)allActiveItemViews
{
    NSMutableArray *itemViews = [NSMutableArray arrayWithArray:self.activeTimerItemsArray];
    [itemViews addObjectsFromArray:self.activeStopWatchItemsArray];
    
    return itemViews;
}

- (NSArray *)allNonActiveItemViews
{
    NSMutableArray *itemViews = [self.itemViewArray mutableCopy];
    [itemViews removeObjectsInArray:[self allActiveItemViews]];
    
    return itemViews;
}

- (NSArray *)interactiveItemViewsNotActive
{
    NSMutableArray *array = [self.interactingItemsArray mutableCopy];
    
    [array removeObjectsInArray:self.activeTimerItemsArray];
    [array removeObjectsInArray:self.activeStopWatchItemsArray];
    
    return [array copy];
}

- (NSArray *)itemViewsNotBeingInteractedWith
{
    NSMutableArray *array = [self.itemViewArray mutableCopy];
    
    [array removeObjectsInArray:self.interactingItemsArray];
    
    return [array copy];
}

- (TMVItemView *)interactiveItemViewNotActiveNearestToBottomOfScreen
{
    return [self itemViewNearestToBottomOfScreenForItemViews:[[self interactiveItemViewsNotActive] copy]];
}

- (TMVItemView *)interactiveItemViewNearestToBottomOfScreen
{
    return [self itemViewNearestToBottomOfScreenForItemViews:[self.interactingItemsArray copy]];
}

- (TMVItemView *)itemViewNearestToBottomOfScreenForItemViews:(NSArray *)itemViews
{
    if (itemViews.count > 1)
    {
        TMVItemView *lowestItem = nil;
        
        for (TMVItemView *itemViewObject in itemViews)
        {
            if (lowestItem == nil)
            {
                lowestItem = itemViewObject;
            }
            else
            {
                if (itemViewObject.centerY > lowestItem.centerY)
                {
                    lowestItem = itemViewObject;
                }
            }
        }
        
        return lowestItem;
    }
    else if (itemViews.count == 1)
    {
        return itemViews.firstObject;
    }
    
    return nil;
}

#pragma mark - _______________________Grid Lock_______________________
#pragma mark -

- (void)sortItems
{
    if (self.isSnappingItemViews) return;
    
    BOOL useSortDescriptor = YES;
    
    if (useSortDescriptor)
    {
        NSSortDescriptor *finishedDescriptor = [[NSSortDescriptor alloc] initWithKey:@"counterLabel.isFinished"
                                                                           ascending:YES];
        NSSortDescriptor *currentTimeDescriptor = [[NSSortDescriptor alloc] initWithKey:@"counterLabel.currentValue"
                                                                              ascending:NO];
        NSSortDescriptor *countDirectionDescriptor = [[NSSortDescriptor alloc] initWithKey:@"counterLabel.countDirection"
                                                                                 ascending:YES];
        NSSortDescriptor *uuidDescriptor = [[NSSortDescriptor alloc] initWithKey:@"item.uniqueID.integerValue"
                                                                       ascending:YES];
        
        
        self.itemViewArray = [self.itemViewArray sortedArrayUsingDescriptors:@[finishedDescriptor,
                                                                               countDirectionDescriptor,
                                                                               currentTimeDescriptor
                                                                               , uuidDescriptor
                                                                               ]];
    }
    else
    {
        self.itemViewArray = [self.itemViewArray sortedArrayUsingComparator:^NSComparisonResult(TMVItemView *itemView1, TMVItemView *itemView2) {
            
            // Finished - currentValue >
            // Count direction - down > up, up
            
            NSComparisonResult result = NSOrderedSame;
            
            if (itemView1.counterLabel.isFinished == itemView2.counterLabel.isFinished)
            {
                if (itemView1.counterLabel.currentValue == itemView2.counterLabel.currentValue)
                {
                    if (itemView1.counterLabel.countDirection == itemView2.counterLabel.countDirection)
                    {
                        result = itemView1.item.uniqueID.integerValue < itemView1.item.uniqueID.integerValue ? NSOrderedAscending : NSOrderedDescending;
                    }
                    else
                    {
                        result = itemView1.counterLabel.countDirection < itemView2.counterLabel.countDirection ? NSOrderedDescending : NSOrderedAscending;
                    }
                }
                else
                {
                    result = itemView1.counterLabel.currentValue < itemView2.counterLabel.currentValue ? NSOrderedAscending : NSOrderedDescending;
                }
            }
            else if (itemView1.counterLabel.isFinished && !itemView2.counterLabel.isFinished)
            {
                result = NSOrderedAscending;
            }
            else if (!itemView1.counterLabel.isFinished && itemView2.counterLabel.isFinished)
            {
                result = NSOrderedDescending;
            }
            
            //            if (itemView1.counterLabel.currentValue == itemView2.counterLabel.currentValue)
            //            {
            //                result = NSOrderedSame;
            //            }
            //
            //            if (itemView1.counterLabel.countDirection == itemView2.counterLabel.countDirection)
            //            {
            //                result = NSOrderedSame;
            //            }
            
            
            return result;
        }];
    }
    
    
    // Updating the gridlockindex with make the itemView call its delegate(self) that its index has changed. Once were notifier that it updated we update the itemViews gridlock positions
    //    [self.itemViewArray enumerateObjectsUsingBlock:^(TMVItemView *itemView, NSUInteger index, BOOL *stop) {
    //
    //        itemView.gridLockIndex = index; // make it to mo instead
    //
    //    }];
}

- (NSArray *)interactiveItemViewsWithState:(TMVItemViewState)state
{
    NSMutableArray *itemViews = [@[] mutableCopy];
    
    for (TMVItemView *itemView in [self interactingItemsArray])
    {
        if (itemView.state == state)
        {
            [itemViews addObject:itemView];
        }
    }
    
    return [itemViews copy];
}

- (void)updateItemArrayOrderByGridIndexes
{
    NSSortDescriptor *girdLockDescriptor = [[NSSortDescriptor alloc] initWithKey:@"gridLockIndex"
                                                                       ascending:YES];
    
    
    self.itemViewArray = [self.itemViewArray sortedArrayUsingDescriptors:@[girdLockDescriptor]];
}

- (void)updateGridLockIndexesToArrayIndex
{
    [self.itemViewArray enumerateObjectsUsingBlock:^(TMVItemView *itemView, NSUInteger index, BOOL *stop) {
        itemView.gridLockIndex = index;
    }];
    
    [DataManager saveContext];
}

- (void)shiftIndexesForRemovedIndex:(NSUInteger)removedIndex
{
    for (TMVItemView *itemView in self.itemViewArray)
    {
        if (itemView.gridLockIndex > removedIndex)
        {
            itemView.gridLockIndex -= 1;
        }
    }
}

- (void)moveSourceIndex:(NSInteger)sourceIndex
     toDestinationIndex:(NSInteger)destinationIndex
{
    NSMutableArray *itemViews = [self.itemViewArray mutableCopy];
    
    if ([[self.itemViewArray objectAtIndex:destinationIndex] isDragging]) return;
    
    // If the source is less than the destination we have to loop upwards
    if (sourceIndex < destinationIndex)
    {
        // Loop upwards.
        for (NSUInteger index = sourceIndex; index < destinationIndex; index++)
        {
            if (![itemViews[index] isDragging] || ([self.itemViewArray[sourceIndex] isEqual:itemViews[index]]))
            {
                // Each looped index is going to move to the next index; Unless the next item is being interacted with, which we would have to go and find the next index which is not being interacted with.
                NSUInteger iteratedIndexDestination = index + 1;
                
                if ([[self.itemViewArray objectAtIndex:iteratedIndexDestination] isDragging])
                {
                    // Find next index that its not interactive
                    // Get the number of index left to iterate
                    NSUInteger numberOfIndexesToIterate = destinationIndex - index - 1;
                    
                    for (NSUInteger draggingIndex = iteratedIndexDestination + 1; draggingIndex < numberOfIndexesToIterate + iteratedIndexDestination + 1; draggingIndex++)
                    {
                        if (![[self.itemViewArray objectAtIndex:draggingIndex] isDragging])
                        {
                            iteratedIndexDestination = draggingIndex;
                            break;
                        }
                    }
                }
                
                [itemViews exchangeObjectAtIndex:index
                               withObjectAtIndex:iteratedIndexDestination];
            }
        }
    }
    else if (sourceIndex > destinationIndex)
    {
        for (NSUInteger index = sourceIndex; index > destinationIndex; index--)
        {
            if (![[itemViews objectAtIndex:index] isDragging] || ([self.itemViewArray[sourceIndex] isEqual:itemViews[index]]))
            {
                // This is the destination for the current iterated index between the source and destination indexes
                NSUInteger iteratedIndexDestination = index - 1;
                
                if ([[self.itemViewArray objectAtIndex:index - 1] isDragging])
                {
                    NSUInteger numberOfIndexesToIterate = sourceIndex + index + 1;
                    
                    for (NSUInteger draggingIndex = iteratedIndexDestination - 1; draggingIndex < numberOfIndexesToIterate - iteratedIndexDestination - 1; draggingIndex++)
                    {
                        if (![[self.itemViewArray objectAtIndex:draggingIndex] isDragging])
                        {
                            iteratedIndexDestination = draggingIndex;
                            break;
                        }
                    }
                }
                
                [itemViews exchangeObjectAtIndex:index
                               withObjectAtIndex:iteratedIndexDestination];
            }
        }
    }
    
    self.itemViewArray = [itemViews copy];
    
    [self updateGridLockIndexesToArrayIndex];
    
    [self snapItemViewsToGridLock];
}

- (void)snapItemViewsToGridLock
{
    [self snapItemViewsToGridLockAnimated:YES];
}

- (void)snapItemViewsToGridLockAnimated:(BOOL)animated
{
    [self snapItemViewsToGridLock:kSnapWithInteractionEnabled ? [self itemViewsNotBeingInteractedWith] : self.itemViewArray
                         animated:animated];
}

- (void)snapItemViewsToGridLock:(NSArray *)itemViews
                       animated:(BOOL)animated
{
    if (self.layout != TMVItemManagerLayoutGridLock || self.isSnappingItemViews) return;
    
    //    self.snappingItemViews = YES;
    
    if (self.sortingMode == TMVItemManagerSortingModeAuto)
    {
        [self sortItems];
    }
    
    for (TMVItemView *itemView in itemViews)
    {
        if (itemView.isKickingOut) continue;
        
        CGPoint destinationPoint = [self pointForGridLockIndex:itemView.item.gridLockIndex.integerValue
                                           withNumberOfIndexes:itemViews.count];
        
        if (!itemView.isDragging)
        {
            [itemView removeAllBehaviors];
            
            [self snapItemView:itemView
                       toPoint:destinationPoint
                      animated:animated];
        }
        
        if (!kSnapWithInteractionEnabled)
        {
            [itemView snapDashToPoint:destinationPoint];
        }
    }
}

- (void)snapItemView:(TMVItemView *)itemView
             toPoint:(CGPoint)point
            animated:(BOOL)animated
{
    if (self.layout != TMVItemManagerLayoutGridLock || CGPointEqualToPoint(itemView.center, point) || itemView.isDragging)
    {
        return;
    }
    
    [self addItemViewToSnappingItemViewSet:itemView];
    
    if (animated)
    {
        if (kDynamicSnappingEnabled)
        {
            [itemView snapToPoint:point];
        }
        else
        {
            [UIView animateWithDuration:1.0
                                  delay:0.0
                 usingSpringWithDamping:0.7
                  initialSpringVelocity:1.0
                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear
                             animations:^{
                                 itemView.center = point;
                             }
                             completion:^(BOOL finished) {
                                 [self removeItemViewFromSnappingItemViewSet:itemView];
                             }];
        }
    }
    else
    {
        itemView.center = point;
        [self removeItemViewFromSnappingItemViewSet:itemView];
    }
}

- (CGPoint)positionForRow:(NSUInteger)row
         withNumberOfRows:(NSUInteger)numberOfRows
                andColumn:(NSUInteger)column
      withNumberOfColumns:(NSUInteger)numberOfColumns
{
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    CGFloat offset = 0.0f;
    
    if (AppContainer.adLoaded)
    {
        height -= AppContainer.adBanner.height;
        offset = AppContainer.adBanner.height;
    }
    
    // X
    CGFloat cellMassX = kItemViewSize * numberOfColumns;
    CGFloat marginMassX = width - cellMassX;
    CGFloat marginSizeX = marginMassX / (numberOfColumns + 1);
    CGFloat marginSizeForIndexX = marginSizeX * (column + 1);
    
    CGFloat xSegment = marginSizeForIndexX + (kItemViewSize / 2) + (kItemViewSize * column);
    
    // Y
    CGFloat ySegment = 0.0f;
    
    if (kUseEvenMarginForGridLock)
    {
        CGFloat cellMass = kItemViewSize * 2;
        CGFloat marginMass = width - cellMass;
        CGFloat margin = marginMass / 3;
        
        CGFloat cellMassY = kItemViewSize * numberOfRows;
        CGFloat totalMarginMassY = height - cellMassY;
        CGFloat innerMarginMassY = margin * (numberOfRows - 1);
        CGFloat outerMarginMassY = totalMarginMassY - innerMarginMassY;
        CGFloat outerMarginY = outerMarginMassY / 2;
        
        ySegment = outerMarginY + (kItemViewSize / 2) + (kItemViewSize * row) + (margin * row);
    }
    else
    {
        CGFloat cellMassY = kItemViewSize * numberOfRows;
        CGFloat marginMassY = height - cellMassY;
        CGFloat marginSizeY = marginMassY / (numberOfRows + 1);
        CGFloat marginSizeForIndexY = marginSizeY * (row + 1);
        
        ySegment = marginSizeForIndexY + (kItemViewSize / 2) + (kItemViewSize * row);
    }
    
    return CGPointMake(xSegment, ySegment + offset);
}

- (NSArray *)rectsForGridLockWithNumberOfIndexes:(NSUInteger)numberOfIndexes
{
    NSMutableArray *rects = [NSMutableArray arrayWithCapacity:numberOfIndexes];
    
    for (NSUInteger index = 0; index < numberOfIndexes; index++)
    {
        CGRect gridRect = [self rectForGridLockIndex:index
                                 withNumberOfIndexes:numberOfIndexes];
        gridRect.origin.y = gridRect.origin.y - AppContainer.view.contentOffsetY;
        
        [rects addObject:[NSValue valueWithCGRect:gridRect]];
    }
    
    return [rects copy];
}

- (CGRect)rectForGridLockIndex:(NSUInteger)index
           withNumberOfIndexes:(NSUInteger)numberOfIndexes
{
    CGPoint centerForIndex = [self pointForGridLockIndex:index
                                     withNumberOfIndexes:numberOfIndexes];
    return CGRectWithCenter(CGRectMake(0, 0, kItemViewSize, kItemViewSize), centerForIndex);
}

- (CGPoint)pointForGridLockIndex:(NSUInteger)index
             withNumberOfIndexes:(NSUInteger)numberOfIndexes
{
    switch (numberOfIndexes)
    {
        case 1:
        {
            return [self positionForRow:0
                       withNumberOfRows:1
                              andColumn:0
                    withNumberOfColumns:1];
        }
            break;
        case 2:
        {
            switch (index)
            {
                case 0:
                    return [self positionForRow:0
                               withNumberOfRows:1
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 1:
                    return [self positionForRow:0
                               withNumberOfRows:1
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
            }
        }
            break;
        case 3:
        {
            switch (index)
            {
                case 0:
                    return [self positionForRow:0
                               withNumberOfRows:2
                                      andColumn:0
                            withNumberOfColumns:1];
                    break;
                case 1:
                    return [self positionForRow:1
                               withNumberOfRows:2
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 2:
                    return [self positionForRow:1
                               withNumberOfRows:2
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
            }
        }
            break;
        case 4:
        {
            switch (index)
            {
                case 0:
                    return [self positionForRow:0
                               withNumberOfRows:2
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 1:
                    return [self positionForRow:0
                               withNumberOfRows:2
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 2:
                    return [self positionForRow:1
                               withNumberOfRows:2
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 3:
                    return [self positionForRow:1
                               withNumberOfRows:2
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
            }
        }
            break;
        case 5:
        {
            switch (index)
            {
                case 0:
                    return [self positionForRow:0
                               withNumberOfRows:3
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 1:
                    return [self positionForRow:0
                               withNumberOfRows:3
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 2:
                    return [self positionForRow:1
                               withNumberOfRows:3
                                      andColumn:0
                            withNumberOfColumns:1];
                    break;
                case 3:
                    return [self positionForRow:2
                               withNumberOfRows:3
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 4:
                    return [self positionForRow:2
                               withNumberOfRows:3
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
            }
        }
            break;
        case 6:
        {
            switch (index)
            {
                case 0:
                    return [self positionForRow:0
                               withNumberOfRows:3
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 1:
                    return [self positionForRow:0
                               withNumberOfRows:3
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 2:
                    return [self positionForRow:1
                               withNumberOfRows:3
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 3:
                    return [self positionForRow:1
                               withNumberOfRows:3
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 4:
                    return [self positionForRow:2
                               withNumberOfRows:3
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 5:
                    return [self positionForRow:2
                               withNumberOfRows:3
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
            }
        }
            break;
        case 7:
        {
            switch (index)
            {
                case 0:
                    return [self positionForRow:0
                               withNumberOfRows:4
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 1:
                    return [self positionForRow:0
                               withNumberOfRows:4
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 2:
                    return [self positionForRow:1
                               withNumberOfRows:4
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 3:
                    return [self positionForRow:1
                               withNumberOfRows:4
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 4:
                    return [self positionForRow:2
                               withNumberOfRows:4
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 5:
                    return [self positionForRow:2
                               withNumberOfRows:4
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 6:
                    return [self positionForRow:3
                               withNumberOfRows:4
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
            }
        }
            break;
        case 8:
        {
            switch (index)
            {
                case 0:
                    return [self positionForRow:0
                               withNumberOfRows:4
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 1:
                    return [self positionForRow:0
                               withNumberOfRows:4
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 2:
                    return [self positionForRow:1
                               withNumberOfRows:4
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 3:
                    return [self positionForRow:1
                               withNumberOfRows:4
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 4:
                    return [self positionForRow:2
                               withNumberOfRows:4
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 5:
                    return [self positionForRow:2
                               withNumberOfRows:4
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 6:
                    return [self positionForRow:3
                               withNumberOfRows:4
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 7:
                    return [self positionForRow:3
                               withNumberOfRows:4
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
            }
        }
            break;
        case 9:
        {
            switch (index)
            {
                case 0:
                    return [self positionForRow:0
                               withNumberOfRows:5
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 1:
                    return [self positionForRow:0
                               withNumberOfRows:5
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 2:
                    return [self positionForRow:1
                               withNumberOfRows:5
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 3:
                    return [self positionForRow:1
                               withNumberOfRows:5
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 4:
                    return [self positionForRow:2
                               withNumberOfRows:5
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 5:
                    return [self positionForRow:2
                               withNumberOfRows:5
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 6:
                    return [self positionForRow:3
                               withNumberOfRows:5
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 7:
                    return [self positionForRow:3
                               withNumberOfRows:5
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 8:
                    return [self positionForRow:4
                               withNumberOfRows:5
                                      andColumn:0
                            withNumberOfColumns:1];
                    break;
            }
        }
            break;
        case 10:
        {
            switch (index)
            {
                case 0:
                    return [self positionForRow:0
                               withNumberOfRows:5
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 1:
                    return [self positionForRow:0
                               withNumberOfRows:5
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 2:
                    return [self positionForRow:1
                               withNumberOfRows:5
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 3:
                    return [self positionForRow:1
                               withNumberOfRows:5
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 4:
                    return [self positionForRow:2
                               withNumberOfRows:5
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 5:
                    return [self positionForRow:2
                               withNumberOfRows:5
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 6:
                    return [self positionForRow:3
                               withNumberOfRows:5
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 7:
                    return [self positionForRow:3
                               withNumberOfRows:5
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
                case 8:
                    return [self positionForRow:4
                               withNumberOfRows:5
                                      andColumn:0
                            withNumberOfColumns:2];
                    break;
                case 9:
                    return [self positionForRow:4
                               withNumberOfRows:5
                                      andColumn:1
                            withNumberOfColumns:2];
                    break;
            }
        }
            break;
        default:
            break;
    }
    
    return CGPointZero;
}


#pragma mark - _______________________Dynamics Management_______________________
#pragma mark -

- (UIDynamicAnimator *)animator
{
    if (!_animator)
    {
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.animatorView];
    }
    
    return _animator;
}

- (void)addDynamics
{
    [self addAllItemViewsToUniversalOptionsBehavior];
    [self addAllItemViewsToUniversalCollisionBehavior];
}

- (void)removeDynamics
{
    for (TMVItemView *itemView in self.itemViewArray)
    {
        [itemView.layer removeAllAnimations];
        [itemView removeAllBehaviors];
    }
}

#pragma mark Universal Options Behavior

- (UIDynamicItemBehavior *)universalOptionsBehavior
{
    if (!_universalOptionsBehavior)
    {
        _universalOptionsBehavior = [UIDynamicItemBehavior new];
        _universalOptionsBehavior.allowsRotation = NO;
        
        [self.animator addBehavior:_universalOptionsBehavior];
    }
    
    return _universalOptionsBehavior;
}

- (void)addAllItemViewsToUniversalOptionsBehavior
{
    for (TMVItemView *itemView in self.itemViewArray)
    {
        [self.universalOptionsBehavior addItem:itemView];
    }
}

- (void)addItemViewToUniversalOptionsBehavior:(TMVItemView *)itemView
{
    [self.universalOptionsBehavior addItem:itemView];
}

- (void)removeItemViewFromUniversalOptionsBehavior:(TMVItemView *)itemView
{
    [self.universalOptionsBehavior removeItem:itemView];
    
    if (self.universalOptionsBehavior.items.count == 0)
    {
        [self.animator removeBehavior:self.universalOptionsBehavior];
        self.universalOptionsBehavior = nil;
    }
}

#pragma mark Universal Flick Behavior

- (UIDynamicItemBehavior *)universalFlickBehavior
{
    if (!_universalFlickBehavior)
    {
        _universalFlickBehavior = [UIDynamicItemBehavior new];
        _universalFlickBehavior.allowsRotation = NO;
        _universalFlickBehavior.resistance = 0.7;
        _universalFlickBehavior.friction = 0.7;
        
        [self.animator addBehavior:_universalFlickBehavior];
        
        //                if (!SettingsController.effectGridLockEnabled)
        //                {
        //                    __block NSUInteger count = self.countBeforeSnapping;
        //
        //                    self.flickBehavior.action = ^{
        //                        count++;
        //                        if (count == 20) {
        //
        //                        }
        //
        //                    };
        //                }
    }
    
    return _universalFlickBehavior;
}

- (void)addItemViewToUniversalFlickBehavior:(TMVItemView *)itemView
                               withVelocity:(CGPoint)velocity
{
    // If the velocity is great enough then let the itemView flick
    if (MAX(fabs(velocity.x), fabs(velocity.y)) > kMinimumVelocityForFlickBeahavior)
    {
        [self.universalFlickBehavior addItem:itemView];
        
        [self.universalFlickBehavior addLinearVelocity:velocity
                                               forItem:itemView];
    }
}

- (void)removeItemViewFromUniversalFlickBehavior:(TMVItemView *)itemView
{
    [self.universalFlickBehavior removeItem:itemView];
    
    if (self.universalFlickBehavior.items.count == 0)
    {
        [self.animator removeBehavior:self.universalFlickBehavior];
        self.universalFlickBehavior = nil;
    }
}

#pragma mark Universal Collision Behavior

- (UICollisionBehavior *)universalCollisionBehavior
{
    if (!_universalCollisionBehavior)
    {
        _universalCollisionBehavior = [[UICollisionBehavior alloc] init];
        _universalCollisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
        _universalCollisionBehavior.collisionMode = UICollisionBehaviorModeEverything;
        
        [self.animator addBehavior:_universalCollisionBehavior];
    }
    
    return _universalCollisionBehavior;
}

- (void)addAllItemViewsToUniversalCollisionBehavior
{
    for (TMVItemView *itemView in self.itemViewArray)
    {
        [self.universalCollisionBehavior addItem:itemView];
    }
}

- (void)addItemViewToUniversalCollisionBehavior:(TMVItemView *)itemView
{
    if (![self.universalCollisionBehavior.items containsObject:itemView])
    {
        [self.universalCollisionBehavior addItem:itemView];
    }
}

- (void)removeItemViewFromUniversalCollisionBehavior:(TMVItemView *)itemView
{
    [self.universalCollisionBehavior removeItem:itemView];
    
    if (self.universalCollisionBehavior.items.count == 0)
    {
        [self.animator removeBehavior:self.universalCollisionBehavior];
        self.universalCollisionBehavior = nil;
    }
}

- (void)addBoundaryToUniversalCollisionBehaviorWithIdentifier:(NSString *)identifier
                                                      forPath:(UIBezierPath *)path
{
    [self.universalCollisionBehavior addBoundaryWithIdentifier:identifier
                                                       forPath:path];
}


#pragma mark Universal Gravity Behavior

- (UIGravityBehavior *)universalGravityBehavior
{
    if (!_universalGravityBehavior)
    {
        _universalGravityBehavior = [UIGravityBehavior new];
        _universalGravityBehavior.magnitude = 2.0f;
        [self.animator addBehavior:_universalGravityBehavior];
    }
    
    return _universalGravityBehavior;
}

- (void)addItemViewToUniversalGravityBehavior:(TMVItemView *)itemView
{
    if (![self.universalGravityBehavior.items containsObject:itemView])
    {
        [self.universalGravityBehavior addItem:itemView];
    }
}

- (void)removeItemViewFromUniversalGravityBehavior:(TMVItemView *)itemView
{
    [self.universalGravityBehavior removeItem:itemView];
    
    if (self.universalGravityBehavior.items.count == 0)
    {
        [self.animator removeBehavior:self.universalGravityBehavior];
        self.universalGravityBehavior = nil;
    }
}

#pragma mark Universal Color Observer

- (UIDynamicItemBehavior *)universalColorObserverBehavior
{
    if (!_universalColorObserverBehavior)
    {
        _universalColorObserverBehavior = [UIDynamicItemBehavior new];
        [self.animator addBehavior:_universalColorObserverBehavior];
    }
    
    return _universalColorObserverBehavior;
}

- (void)beginObservingColorForItemView:(TMVItemView *)itemView
{
    if (![self.universalColorObserverBehavior.items containsObject:itemView])
    {
        [self.universalColorObserverBehavior addItem:itemView];
        
        // Made a weakself instead of univerColorObserver since I could set the colorObserver to nil once it has no items in the action block
        __weak typeof(self) weakSelf = self;
        
        self.universalColorObserverBehavior.action = ^{
            
            for (TMVItemView *itemViewObject in weakSelf.universalColorObserverBehavior.items)
            {
                [itemViewObject observeColor];
            }
            
            if (weakSelf.universalColorObserverBehavior.items.count == 0)
            {
                [weakSelf.animator removeBehavior:weakSelf.universalColorObserverBehavior];
                weakSelf.universalColorObserverBehavior = nil;
            }
        };
    }
}

- (void)stopObservingColorForItemView:(TMVItemView *)itemView
{
    if ([self.animator.behaviors containsObject:self.universalColorObserverBehavior])
    {
        [self.universalColorObserverBehavior removeItem:itemView];
        
        if (self.universalColorObserverBehavior.items == 0)
        {
            [self.animator removeBehavior:self.universalColorObserverBehavior];
            self.universalColorObserverBehavior = nil;
        }
    }
}

@end


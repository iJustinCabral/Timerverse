//
//  TMVQuoteViewController.m
//  Timerverse
//
//  Created by Larry Ryan on 4/16/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVQuoteViewController.h"
#import "TMVQuoteCell.h"
#import "TMVHelixFlowLayout.h"

@import QuartzCore;

static BOOL const kGradientMaskEnabled = NO;
static BOOL const kInfiniteScrollingEnabled = YES;
static NSInteger const kInfiniteScrollingMutliplier = 100;
static NSString * const kCellIdentifier = @"quoteCell";

@interface TMVQuoteViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSArray *quoteTextViews;
@property (nonatomic) TMVHelixFlowLayout *helixLayout;

@property (nonatomic, readwrite, getter = isShowing) BOOL showing;

@end


@implementation TMVQuoteViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    self.quoteTextViews = [[self quotes] copy];

    [self configureCollectionView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSUInteger randomIndex = arc4random_uniform((unsigned int)[self quotes].count);
    
    NSInteger multiplier = kInfiniteScrollingEnabled ? (kInfiniteScrollingMutliplier / 2) : 1;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:multiplier * randomIndex inSection:0];
    
    [self.collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                        animated:NO];
}

#pragma mark - Properties

- (TMVHelixFlowLayout *)helixLayout
{
    if (!_helixLayout)
    {
        _helixLayout = [TMVHelixFlowLayout new];
    }
    
    return _helixLayout;
}

- (NSString *)currentQuoteAndPerson
{
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.halfWidth, self.collectionView.contentOffsetY + self.view.halfHeight)];
    TMVQuoteCell *cell = (TMVQuoteCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    return [NSString stringWithFormat:@"%@ - %@", cell.quoteTextView.text, cell.signatureTextView.text];
}

#pragma mark - Helpers

- (NSUInteger)fixedRowForIndex:(NSUInteger)index
{
    return kInfiniteScrollingEnabled ? index % [self quotes].count : index;
}

- (CGSize)calculatedSizeForCellAtIndex:(NSUInteger)index
{
    NSDictionary *attributesDictionary = @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:16]};
    
    CGRect quoteFrame = [[self quotes][[self fixedRowForIndex:index]] boundingRectWithSize:CGSizeMake(self.collectionView.frame.size.width, CGFLOAT_MAX)
                                                                                   options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                                                attributes:attributesDictionary
                                                                                   context:nil];
    
    CGRect signitureFrame = [[self signatureForIndex:[self fixedRowForIndex:index]] boundingRectWithSize:CGSizeMake(self.collectionView.frame.size.width, CGFLOAT_MAX)
                                                                                                 options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                                                              attributes:attributesDictionary
                                                                                                 context:nil];
    
    return CGSizeMake(self.collectionView.frame.size.width, quoteFrame.size.height + 16.0f + signitureFrame.size.height + 16.0f);
}


#pragma mark - CollectionView

- (void)configureCollectionView
{
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame
                                             collectionViewLayout:self.helixLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsVerticalScrollIndicator = NO;
    [self.collectionView registerClass:[TMVQuoteCell class]
            forCellWithReuseIdentifier:kCellIdentifier];
    
    [self.view addSubview:self.collectionView];
    
    [self configureCollectionViewMask];
}

- (void)configureCollectionViewMask
{
    if (!kGradientMaskEnabled) return;
    
    CAGradientLayer *maskLayer = [CAGradientLayer layer];
    
    CGColorRef outerColor = [UIColor colorWithWhite:1.0 alpha:0.0].CGColor;
    CGColorRef innerColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
    
    maskLayer.colors = @[(__bridge id)outerColor, (__bridge id)innerColor, (__bridge id)innerColor, (__bridge id)outerColor];
    maskLayer.locations = @[@0.0, @0.4, @0.6, @1.0];
    
    maskLayer.bounds = CGRectMake(0, 0,
                                  self.collectionView.frame.size.width,
                                  self.collectionView.frame.size.height);
    maskLayer.anchorPoint = CGPointZero;
    
    self.collectionView.layer.mask = maskLayer;
}

#pragma mark DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return kInfiniteScrollingEnabled ? [self quotes].count * kInfiniteScrollingMutliplier : [self quotes].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TMVQuoteCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];
    
    NSUInteger row = [self fixedRowForIndex:indexPath.row];
    
    [cell setQuote:[self quotes][row]
            person:[self signatureForIndex:row]];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize cellSize = [self calculatedSizeForCellAtIndex:[self fixedRowForIndex:indexPath.row]];
    
    return cellSize;
}

#pragma mark  Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.scrollEnabled)
    {
        collectionView.scrollEnabled = NO;
        
        [collectionView performBatchUpdates:^{
            self.helixLayout.shouldFadeOutNonFocusedAttributes = YES;
        } completion:^(BOOL finished) {
            
        }];
    }
    else
    {
        collectionView.scrollEnabled = YES;
        
        [collectionView performBatchUpdates:^{
            self.helixLayout.shouldFadeOutNonFocusedAttributes = NO;
        } completion:^(BOOL finished) {
            
        }];
    }
    
    if ([self.delegate respondsToSelector:@selector(didEnableScrolling:)])
    {
        [self.delegate didEnableScrolling:collectionView.scrollEnabled];
    }
}


#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (kGradientMaskEnabled)
    {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.collectionView.layer.mask.position = CGPointMake(0, scrollView.contentOffset.y);
        [CATransaction commit];
    }
}

#pragma mark - Animation

- (void)showAnimated:(BOOL)animated
               scale:(BOOL)scale
                fade:(BOOL)fade
      withCompletion:(void (^)(void))completion
{
    if (animated)
    {
        [UIView animateWithDuration:0.4
                              delay:0.2
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             if (scale) self.view.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                             if (fade) self.view.layer.opacity = 1.0;
                         }
                         completion:^(BOOL finished) {
                             self.showing = YES;
                             completion();
                         }];
    }
    else
    {
        if (scale) self.view.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        if (fade) self.view.layer.opacity = 1.0f;
        
        self.showing = YES;
        completion();
    }
}

- (void)dismissAnimated:(BOOL)animated
                  scale:(BOOL)scale
                   fade:(BOOL)fade
         withCompletion:(void (^)(void))completion
{
    if (animated)
    {
        [UIView animateWithDuration:0.4
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             if (scale) self.view.transform = CGAffineTransformMakeScale(0.0f, 0.0f);
                             if (fade) self.view.layer.opacity = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             self.showing = NO;
                             completion();
                         }];
    }
    else
    {
        if (scale) self.view.transform = CGAffineTransformMakeScale(0.0f, 0.0f);
        if (fade) self.view.layer.opacity = 0.0f;
        self.showing = NO;
        completion();
    }
}


#pragma mark - Data Helpers

- (NSArray *)timeKeywords
{
    return @[@"time", @"yesterday", @"tomorrow", @"today", @"forever", @"past", @"future", @"present", @"year", @"always", @"day", @"moment", @"now", @"since"];
}

- (NSArray *)quotes
{
    return @[@"The best thing about the future is that it comes one day at a time.",
             @"We must use time wisely, and forever realize that the time is always ripe to do right.",
             @"Lost time is never found again.",
             @"Time you enjoy wasting, was not wasted.",
             @"The time is always right to do what’s right.",
             @"Your time is limited, so don’t waste it living someone else’s life.",
             @"Yesterday is gone. Tomorrow has not yet come. We have only today. Let us begin.",
             @"I am driven by two main philosophies, know more today about the world than I knew yesterday, and lessen the suffering of others.",
             @"We are like butterflies who flutter for a day and think it is forever.",
             @"Do not dwell in the past, do not dream of the future, concentrate the mind on the present moment.",
             @"A year from now you may wish you had started today.",
             @"Time crumbles things; everything grows old under the power of time and is forgotten through the lapse of time.",
             @"The secret of change is to focus all of your energy, not on fighting the old, but on building the new.",
             @"Time is the moving image of reality.",
             @"When you want to succeed as bad as you want to breath, then you'll be successful.",
             @"We cannot waste time, we can only waste ourselves.",
             @"The only reason for time is so that everything doesn't happen at once.",
             @"Time is what we want most, but what we use worst.",
             @"Realize that now, in this moment of time, you are creating. You are creating your next moment. That is what’s real.",
             @"To think too long about doing a thing often becomes its undoing.",
             @"The way I did it, every job was A+.",
             @"What takes us back to the past are the memories. What brings us forward is our dreams.",
             @"Even the wildest dreams have to start somewhere. Allow yourself the time and space to let your mind wander and your imagination fly.",
             @"A journey of a thousand miles begins with a single step.",
             @"The past is a ghost, the future a dream and all we ever have is now.",
             @"Don't spend time beating on a wall, hoping to transforms it into a door.",
             @"If your time to you is worth savin', then you better start swimmin' or you'll sink like a stone for the times they are a-changin.",
             @"We must use time as tool, not as a couch.",
             @"Time cools, time clarifies; no mood can be maintained quite unaltered through the course of hours.",
             @"I hated every minute of training, but I said, 'Don't quit. Suffer now and live the rest of your life as a champion.'",];
}

- (NSString *)signatureForIndex:(NSUInteger)index
{
    NSArray *persons = @[@"Abe Lincoln",
                         @"Nelson Mandela",
                         @"Benjamin Franklin",
                         @"John Lennon",
                         @"Dr. Martin Luther King Jr.",
                         @"Steve Jobs",
                         @"Mother Teresa",
                         @"Neil deGrasse Tyson",
                         @"Carl Sagan",
                         @"The Buddah",
                         @"Karen Lamb",
                         @"Aristotle",
                         @"Socrates",
                         @"Plato",
                         @"Eric Thomas",
                         @"Goerge M. Adams",
                         @"Albert Einstein",
                         @"William Penn",
                         @"Sara Paddison",
                         @"Eva Young",
                         @"Steve Wozniak",
                         @"Jeremy Irons",
                         @"Oprah Winfrey",
                         @"Lao Tzu",
                         @"Bill Cosby",
                         @"Coco Chanel",
                         @"Bob Dylan",
                         @"John F. Kennedy",
                         @"Mark Twain",
                         @"Muhammad Ali",];
    
    return persons[index];
}

@end

//
//  TMVQuoteView.m
//  Timerverse
//
//  Created by Larry Ryan on 2/7/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVQuoteView.h"

static BOOL const kExclusionPaths = NO;
static BOOL const kDynamicsEnabled = NO;
static BOOL const kMotionEffectsEnabled = YES;
static BOOL const kSharingPanGestureEnabled = YES;
static BOOL const kSharingLongPressGestureEnabled = NO;

@interface TMVQuoteView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, readwrite, getter = shouldUseExclusionPaths) BOOL useExclusionPaths;
@property (nonatomic, readwrite, getter = isShowing) BOOL showing;

@property (nonatomic) UITextView *quoteTextView;
@property (nonatomic) UITextView *keywordTextView;
@property (nonatomic) UITextView *signatureTextView;

@property (nonatomic) UIDynamicAnimator *animator;

@property (nonatomic) CGFloat lastScrollDelta;

@property (nonatomic) NSUInteger currentIndex;

@end


@implementation TMVQuoteView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.clipsToBounds = NO;
        self.delegate = self;
        
        self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
        
        self.showing = YES;
        self.useExclusionPaths = kExclusionPaths;
        
        [self configureTextViews];
        
        [self showAnimatingKeywordsWithCompletion:^{}];
        
        if (kSharingLongPressGestureEnabled) [self configureLongPress];
    }
    return self;
}


#pragma mark - Gestures

- (void)configureLongPress
{
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                   action:@selector(didLongPress:)];
    
    longPressGesture.delegate = self;
    [self addGestureRecognizer:longPressGesture];
}

- (void)didLongPress:(UILongPressGestureRecognizer *)longPressGesture
{
    NSMutableString *quote = [self.quoteTextView.text mutableCopy];
    [quote appendString:[NSString stringWithFormat:@" - %@", self.signatureTextView.text]];
    
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[[quote copy]]
                                                                     applicationActivities:nil];
    
    [AppContainer presentViewController:vc
                               animated:YES
                             completion:nil];
}

#pragma mark - UIScollView Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])
    {
        if ([self.quoteViewDelegate respondsToSelector:@selector(didBeginPanning)])
        {
            [self.quoteViewDelegate didBeginPanning];
        }
    }
    
    return YES;
}

- (CGFloat)percentageToShareAction
{
    CGFloat maxOffset = 44.0f;
    CGFloat percentage = fabs(self.contentOffsetY) / maxOffset;
    
    if (percentage < 0.0f) percentage = 0.0f;
    if (percentage > 1.0f) percentage = 1.0f;
    
    return percentage;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (kDynamicsEnabled) [self updateSprings];
    
    if (kSharingPanGestureEnabled)
    {
        if (scrollView.contentOffsetY < 0.0f)
        {
            if ([self.quoteViewDelegate respondsToSelector:@selector(didUpdatePercentageForShareAction:)])
            {
                [self.quoteViewDelegate didUpdatePercentageForShareAction:[self percentageToShareAction]];
            }
        }
        else
        {
            if ([self.quoteViewDelegate respondsToSelector:@selector(didUpdatePercentageForShareAction:)])
            {
                [self.quoteViewDelegate didUpdatePercentageForShareAction:0.0f];
            }
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.quoteViewDelegate respondsToSelector:@selector(didDecelerateShareAction)])
    {
        [self.quoteViewDelegate didDecelerateShareAction];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (kSharingPanGestureEnabled)
    {
        if (scrollView.contentOffsetY < -44.0f)
        {
            UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[[self currentQuoteAndPerson]]
                                                                             applicationActivities:nil];
            
            [AppContainer presentViewController:vc
                                       animated:YES
                                     completion:nil];
        }
        
        if ([self.quoteViewDelegate respondsToSelector:@selector(didEndPanningWithPercentage:)])
        {
            [self.quoteViewDelegate didEndPanningWithPercentage:[self percentageToShareAction]];
        }
    }
}


#pragma mark - TextViews

- (UITextView *)quoteTextView
{
    if (!_quoteTextView)
    {
        _quoteTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
        _quoteTextView.textAlignment = NSTextAlignmentLeft;
        _quoteTextView.backgroundColor = [UIColor clearColor];
        _quoteTextView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
        _quoteTextView.userInteractionEnabled = YES;
        _quoteTextView.scrollEnabled = NO;
        _quoteTextView.editable = NO;
        _quoteTextView.selectable = NO;
        _quoteTextView.layer.opacity = 0.0f;
    }
    
    return _quoteTextView;
}

- (UITextView *)keywordTextView
{
    if (!_keywordTextView)
    {
        _keywordTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
        _keywordTextView.textAlignment = NSTextAlignmentLeft;
        _keywordTextView.backgroundColor = [UIColor clearColor];
        _keywordTextView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
        _keywordTextView.userInteractionEnabled = YES;
        _keywordTextView.scrollEnabled = NO;
        _keywordTextView.editable = NO;
        _keywordTextView.selectable = NO;
        _keywordTextView.layer.opacity = 0.0f;
    }
    
    return _keywordTextView;
}

- (UITextView *)signatureTextView
{
    if (!_signatureTextView)
    {
        self.signatureTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, self.quoteTextView.height, self.width, 34)];
        
        _signatureTextView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        _signatureTextView.textAlignment = NSTextAlignmentRight;
        _signatureTextView.textColor = [UIColor grayColor];
        _signatureTextView.backgroundColor = [UIColor clearColor];
        _signatureTextView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
        _signatureTextView.userInteractionEnabled = YES;
        _signatureTextView.scrollEnabled = NO;
        _signatureTextView.editable = NO;
        _signatureTextView.selectable = NO;
        _signatureTextView.layer.opacity = 0.0f;
    }
    
    return _signatureTextView;
}

- (void)configureTextViews
{
    // Random Index for the Quote and the Sig
    NSUInteger randomIndex = arc4random_uniform((unsigned int)[self quotes].count);
    
    // Get a random quote
    NSMutableString *quote = [[self quoteForIndex:randomIndex] mutableCopy];
    
    // Setup the attributed string
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    UIColor *color = [UIColor whiteColor];
    
    NSMutableAttributedString *attributedQuote = [[NSMutableAttributedString alloc] initWithString:quote
                                                                                        attributes:@{NSFontAttributeName : font,
                                                                                                     NSForegroundColorAttributeName : color}];
    
    if (kDynamicsEnabled)
    {
        // Here we enumerate the quote and find all the time related keywords, and break them out into ranges
        __weak TMVQuoteView *weakSelf = self;
        __block NSArray *localKeywords = [self timeKeywords];
        
        __block NSMutableArray *keywordRanges = [NSMutableArray array];
        __block NSMutableArray *wordRanges = [NSMutableArray array];
        
        [quote enumerateSubstringsInRange:NSMakeRange(0, [quote length])
                                  options:NSStringEnumerationByWords | NSStringEnumerationLocalized
                               usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                   
                                   if ([weakSelf isString:substring containedIn:localKeywords])
                                   {
                                       [keywordRanges addObject:[NSValue valueWithRange:enclosingRange]];
                                   }
                                   else
                                   {
                                       [wordRanges addObject:[NSValue valueWithRange:enclosingRange]];
                                   }
                               }];
        
        
        
        for (NSValue *value in keywordRanges)
        {
            [attributedQuote addAttribute:NSForegroundColorAttributeName
                                    value:[UIColor clearColor]
                                    range:[value rangeValue]];
        }
        
        NSMutableAttributedString *keywordTextViewQuote = [[NSMutableAttributedString alloc] initWithString:quote
                                                                                                 attributes:@{NSFontAttributeName : font,
                                                                                                              NSForegroundColorAttributeName : color}];
        
        for (NSValue *value in wordRanges)
        {
            [keywordTextViewQuote addAttribute:NSForegroundColorAttributeName
                                         value:[UIColor clearColor]
                                         range:[value rangeValue]];
        }
        
        self.keywordTextView.attributedText = keywordTextViewQuote;
        
        [self.keywordTextView sizeToFit];
        
        [self addSubview:self.keywordTextView];
        
        // Add the dynamics
        if (kDynamicsEnabled)
        {
            //    [self addSpringToView:self.quoteTextView];
            [self addSpringToView:self.keywordTextView];
            //    [self addSpringToView:self.signatureTextView];
        }
    }
    
    self.quoteTextView.attributedText = attributedQuote;
    
    [self.quoteTextView sizeToFit];
    self.quoteTextView.width = self.width;
    
    [self addSubview:self.quoteTextView];
    
    self.signatureTextView.text = [NSString stringWithFormat:@"%@", [self signatureForIndex:randomIndex]];
    self.signatureTextView.y = self.quoteTextView.height - 5.0f;
    [self.signatureTextView removeFromSuperview];
    [self addSubview:self.signatureTextView];
    
    
    // Adjust the height of the view to fix both textViews
    self.height = self.quoteTextView.height + self.signatureTextView.height;
    
    // Get the scrollView to scroll by making the contentHeight higher than the frame
    self.contentSizeHeight = self.height + 0.5;
    
    self.center = self.superview.center;
    
    // Setup the motion effects
    [self updateMotionEffects];
}

- (NSArray *)textViews
{
    return @[self.quoteTextView, self.keywordTextView, self.signatureTextView];
}

- (void)resetTextViews
{
    [self.animator removeAllBehaviors];
    self.quoteTextView = nil;
    self.keywordTextView = nil;
    self.signatureTextView = nil;
}

#pragma mark - Exclusion Path

- (void)updateExclusionPaths:(NSArray *)exclusionPaths
{
    self.quoteTextView.textContainer.exclusionPaths = exclusionPaths;
    self.signatureTextView.textContainer.exclusionPaths = exclusionPaths;
}

#pragma mark - Helpers

- (NSString *)currentQuoteAndPerson
{
    return [NSString stringWithFormat:@"%@ - %@", self.quoteTextView.text, self.signatureTextView.text];
}

- (BOOL)isString:(NSString *)comparatorString containedIn:(NSArray *)array
{
    for (NSString *string in array)
    {
        if ([string caseInsensitiveCompare:comparatorString] == NSOrderedSame)
            return YES;
    }
    return NO;
}

BOOL isContainedIn(NSArray *bunchOfStrings, NSString *stringToCheck)
{
    for (NSString *string in bunchOfStrings)
    {
        if ([string caseInsensitiveCompare:stringToCheck] == NSOrderedSame)
        {
            return YES;
        }
    }
    return NO;
}

- (UIImage *)screenshotForView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale);
    
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (CGRect)frameOfTextRange:(NSRange)range inTextView:(UITextView *)textView
{
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [textView positionFromPosition:start offset:range.length];
    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    
    CGRect rect = [textView firstRectForRange:textRange];
    
    return [textView convertRect:rect fromView:textView.textInputView];
}


#pragma mark - Animations

- (void)showAnimatingKeywordsWithCompletion:(void (^)(void))completion
{
    NSTimeInterval duration = 0.8f;
    NSTimeInterval delay = 0.4f;
    
    [UIView animateWithDuration:duration
                          delay:delay
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.keywordTextView.layer.opacity = 1.0f;
                     }
                     completion:^(BOOL finished) {
                     }];
    
    
    [UIView animateWithDuration:duration
                          delay:duration / 2 + delay
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.quoteTextView.layer.opacity = 1.0f;
                         self.signatureTextView.layer.opacity = 1.0f;
                     }
                     completion:^(BOOL finished) {
                         completion();
                     }];
    
}

- (void)hideAnimatingKeywordsWithCompletion:(void (^)(void))completion
{
    NSTimeInterval duration = 0.5f;
    NSTimeInterval delay = 0.0f;
    
    [UIView animateWithDuration:duration
                          delay:delay
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.quoteTextView.layer.opacity = 0.0f;
                         self.signatureTextView.layer.opacity = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
    
    [UIView animateWithDuration:duration
                          delay:duration / 2 + delay
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.keywordTextView.layer.opacity = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         completion();
                     }];
}

- (void)showAnimated:(BOOL)animated
      withCompletion:(void (^)(void))completion
{
    [self showAnimated:animated
                 scale:NO
                  fade:YES
        withCompletion:^{
            completion();
        }];
}

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
                             if (scale) self.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                             if (fade) self.layer.opacity = 1.0;
                         }
                         completion:^(BOOL finished) {
                             self.showing = YES;
                             completion();
                         }];
    }
    else
    {
        if (scale) self.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        if (fade) self.layer.opacity = 1.0f;
        
        self.showing = YES;
        completion();
    }
}

- (void)dismissAnimated:(BOOL)animated
         withCompletion:(void (^)(void))completion
{
    [self dismissAnimated:animated
                    scale:NO
                     fade:YES
           withCompletion:^{
               completion();
           }];
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
                             if (scale) self.transform = CGAffineTransformMakeScale(0.0f, 0.0f);
                             if (fade) self.layer.opacity = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             self.showing = NO;
                             completion();
                         }];
    }
    else
    {
        if (scale) self.transform = CGAffineTransformMakeScale(0.0f, 0.0f);
        if (fade) self.layer.opacity = 0.0f;
        self.showing = NO;
        completion();
    }
}

#pragma mark - UIDynamic Behaviors

- (void)addSpringToView:(UIView *)view
{
    UIAttachmentBehavior *spring = [[UIAttachmentBehavior alloc] initWithItem:view
                                                             attachedToAnchor:view.center];
    
    spring.length = 0;
    spring.damping = 0.4;
    spring.frequency = 1.0;
    
    [self.animator addBehavior:spring];
}

- (void)updateSprings
{
    CGPoint touchLocation = [self.panGestureRecognizer locationInView:self];
    CGFloat scrollDelta = self.bounds.origin.y - self.lastScrollDelta;
    
    self.lastScrollDelta = self.bounds.origin.y;
    
    [self.animator.behaviors enumerateObjectsUsingBlock:^(UIAttachmentBehavior *spring, NSUInteger index, BOOL *stop) {
        
        UITextView *textView = spring.items.firstObject;
        
        CGPoint anchorPoint = spring.anchorPoint;
        CGFloat distanceFromTouch = fabs(touchLocation.y - anchorPoint.y);
        CGFloat scrollResistance = distanceFromTouch * (1.0f / 1000.0f);
        
        CGFloat axisValue = textView.center.y;
        
        if (scrollDelta < 0)
        {
            axisValue += scrollDelta * scrollResistance;
        }
        else
        {
            axisValue += scrollDelta * scrollResistance;
        }
        
        textView.center = CGPointMake(textView.origin.x + textView.width / 2, axisValue);
        
        [self.animator updateItemUsingCurrentState:textView];
    }];
}


#pragma mark - Motion Effect

- (void)updateMotionEffects
{
    if (!kMotionEffectsEnabled) return;
    
    // Make sure the item doesn't already have a motion effect
    for (UIMotionEffectGroup *effect in self.motionEffects)
    {
        [self removeMotionEffect:effect];
    }
    
    CGFloat alertViewTilt = AppContainer.isShowingAlertView ? kMotionEffectFactor : 0.0f;
    float maximumTilt = kMotionEffectFactor + alertViewTilt;
    
    UIInterpolatingMotionEffect *xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    xAxis.minimumRelativeValue = [NSNumber numberWithFloat:-maximumTilt];
    xAxis.maximumRelativeValue = [NSNumber numberWithFloat:maximumTilt];
    
    UIInterpolatingMotionEffect *yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    yAxis.minimumRelativeValue = [NSNumber numberWithFloat:-maximumTilt];
    yAxis.maximumRelativeValue = [NSNumber numberWithFloat:maximumTilt];
    
    UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
    group.motionEffects = @[xAxis, yAxis];
    
    [self addMotionEffect:group];
}

#pragma mark - Data

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
             @"Not only do we live among the stars, the stars live within us.",
             @"If you wish to make an apple pie from scratch, you must first invent the universe.",
             @"Do not dwell in the past, do not dream of the future, concentrate the mind on the present moment.",
             @"A year from now you may wish you had started today.",
             @"Time crumbles things; everything grows old under the power of time and is forgotten through the lapse of time.",
             @"The secret of change is to focus all of your energy, not on fighting the old, but on building the new.",
             @"Time is the moving image of reality.",
             @"When you want to succeed as bad as you want to breath, then you'll be successful.",
             @"We cannot waste time, we can only waste ourselves.",
             @"Imagination is more important than knowledge.",
             @"Time is what we want most, but what we use worst.",
             @"Realize that now, in this moment of time, you are creating. You are creating your next moment. That is what’s real.",
             @"To think too long about doing a thing often becomes its undoing.",
             @"The way I did it, every job was A+.",
             @"What takes us back to the past are the memories. What brings us forward is our dreams.",
             @"Even the wildest dreams have to start somewhere. Allow yourself the time and space to let your mind wander and your imagination fly.",
             @"A journey of a thousand miles begins with a single step.",
             @"The past is a ghost, the future a dream and all we ever have is now.",
             @"Don't spend your time beating on a wall, hoping it transforms into a door.",
             @"If your time to you is worth savin', then you better start swimmin' or you'll sink like a stone for the times they are a-changin.",
             @"Change is the law of life. Those who look only to the past or present are certain to miss the future.",
             @"Time cools, time clarifies; no mood can be maintained quite unaltered through the course of hours.",
             @"I hated every minute of training, but I said, 'Don't quit. Suffer now and live the rest of your life as a champion.'",
             @"The saddest aspect of life right now is that science gathers knowledge faster than society gathers wisdom.",
             @"Nothing will work unless you do.",
             @"If I have seen further than others, it is by standing upon the shoulders of giants.",
             @"Somewhere, something incredible is waiting to be known.",
             @"Nothing is too wonderful to be true, if it be consistent with the laws of nature",
             @"Equipped with five senses, we explore the universe around us and call the adventure science.",
             @"We build too many walls and not enough bridges.",
             @"Everything has beauty, but not everyone sees it.",
             @"Stay hungry, stay foolish.",
             @"Only those who dare to fail greatly can ever achieve greatly.",
             @"Any sufficiently advanced technology is indistinguishable from magic.",
             @"I've learned that people will forget what you said, forget what you did, but never forget how you made them feel.",
             @"Knowing how to think empowers you far beyond those who know only what to think.",
             @"Think lightly of yourself and deeply of the world.",
             @"A book, too, can be a star, a living fire to lighten the darkness, leading out into the expanding universe.",
             @"Constantly think about how you could be doing things better, and question yourself.",
             @"Success is a lousy teacher. It seduces smart people into thinking they can't lose.",
             @"Copy, art, and typography should be seen as a living entity; each element integrally related in harmony with the whole.",
             @"A person who dares to waste one hour of time has not discovered the value of life.",
             @"The best and most beautiful things in the world cannot be seen or even touched - they must be felt with the heart.",
             @"Adventure is worthwhile in itself.",
             ];
}

- (NSString *)quoteForIndex:(NSUInteger)index
{
    return [self quotes][index];
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
                         @"Muhammad Ali",
                         @"Issac Asimov",
                         @"Maya Angelou",
                         @"Isaac Newton",
                         @"Carl Sagan",
                         @"Michael Faraday",
                         @"Edwin Hubble",
                         @"Isaac Newton",
                         @"Confucius",
                         @"Steve Jobs",
                         @"Robert Kennedy",
                         @"Arthur C. Clarke",
                         @"Maya Angelou",
                         @"Neil deGrasse Tyson",
                         @"Miyamoto Musashi",
                         @"Madeleine L'Engle",
                         @"Elon Musk",
                         @"Bill Gates",
                         @"Paul Rand",
                         @"Charles Darwin",
                         @"Helen Keller",
                         @"Amelia Earhart",
                         ];
    
    return persons[index];
}


#pragma mark - PointInside Hook

//- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
//{
//    if (CGRectContainsPoint(self.quoteTextView.frame, point)
//        || CGRectContainsPoint(self.signatureTextView.frame, point))
//    {
//        return [super pointInside:point withEvent:event];
//    }
//    else
//    {
//        return [super pointInside:point withEvent:event];
//    }
//}

@end

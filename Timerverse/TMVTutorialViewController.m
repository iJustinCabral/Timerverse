//
//  TMVTutorialViewController.m
//  Timerverse
//
//  Created by Justin Cabral on 3/15/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVTutorialViewController.h"
#import "IFTTTJazzHands.h"
#import "TMVItemView.h"
#import "TMVPaperView.h"
#import "TMVIconView.h"
#import "FBShimmeringView.h"
#import "UIColor+Additions.h"

@import QuartzCore;

#define IS_IPHONE_5 ( [ [ UIScreen mainScreen ] bounds ].size.height >= 568 )
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))


@interface TMVTutorialViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) UIView *contentContainerView;
@property (nonatomic) UIPageControl *pageControl;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIButton *skipButton;
@property (nonatomic) UIButton *enterButton;

@property (nonatomic) IFTTTAnimator *animator;
@property (nonatomic) FBShimmeringView *shimmerView;


@end

@implementation TMVTutorialViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
    self.animator = [IFTTTAnimator new];
    
    [self configureScrollView];
    [self configurePageOne];
    [self configurePageTwo];
    [self configurePageThree];
    [self configurePageFour];
    [self configurePageFive];
    [self configurePageSix];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGRect shimmeringFrame = self.view.bounds;
    self.shimmerView.frame = shimmeringFrame;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


- (void)configureScrollView
{
    self.scrollView = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.contentSize = CGSizeMake(self.view.width * 6, self.view.height);
    
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(110, self.view.height - 70, 100, 30)];
    self.pageControl.currentPage = 1;
    self.pageControl.numberOfPages = 6;
    
    [self.view addSubview:self.pageControl];
    [self.view addSubview:self.scrollView];
    

    
}
- (void)configurePageOne
{
    
    UITextView *helloTextView = [[UITextView alloc] init];
    
    if (IS_IPHONE_5)
    {
        helloTextView.frame = CGRectMake(20, 230,280,60);
    }
    else
    {
        helloTextView.frame = CGRectMake(20, 190,280,60);

    }
    
    helloTextView.backgroundColor = [UIColor clearColor];
    helloTextView.textColor = [UIColor whiteColor];
    helloTextView.textAlignment = NSTextAlignmentCenter;
    helloTextView.userInteractionEnabled = NO;
    helloTextView.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:22];
    helloTextView.alpha = 1;
    helloTextView.text = NSLocalizedString(@"Welcome To Timerverse", Welcome);
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"timerverseIconAbout"]];
    imageView.frame = CGRectMake(0, 0, 95.0f, 100.0f);
    imageView.centerX = helloTextView.centerX;
    imageView.centerY = helloTextView.centerY - 100;
    imageView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:imageView];
    
    self.shimmerView = [[FBShimmeringView alloc] init];
    self.shimmerView.shimmeringDirection = FBShimmerDirectionLeft;
    self.shimmerView.shimmeringSpeed = 170;
    self.shimmerView.shimmering = YES;
    [self.scrollView addSubview:self.shimmerView];
    
    
    UILabel *swipeTextView = [[UILabel alloc] initWithFrame:self.shimmerView.bounds];
    swipeTextView.backgroundColor = [UIColor clearColor];
    swipeTextView.textColor = [UIColor whiteColor];
    swipeTextView.textAlignment = NSTextAlignmentCenter;
    swipeTextView.userInteractionEnabled = NO;
    swipeTextView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    swipeTextView.alpha = 1;
    swipeTextView.text = NSLocalizedString(@"    Slide to begin〈", Slide);
    
    self.skipButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.height - 46, 100, 40)];
    self.skipButton.centerY = self.pageControl.centerY + 30;
    self.skipButton.centerX = self.pageControl.centerX + 1;
    self.skipButton.titleLabel.font = [UIFont fontWithName:@"helveticaneue-Bold" size:18];
    [self.skipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.skipButton setTitleColor:[UIColor silverColor] forState:UIControlStateHighlighted];
    [self.skipButton setTitleColor:[UIColor silverColor] forState:UIControlStateSelected];
    [self.skipButton addTarget:self action:@selector(didPressSkip:) forControlEvents:UIControlEventTouchUpInside];


    [self.skipButton setTitle:NSLocalizedString(@"Skip", Skip) forState:UIControlStateNormal];
    self.skipButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.skipButton.titleLabel.minimumScaleFactor = 0.3f;
    
    self.shimmerView.contentView = swipeTextView;
    [self.scrollView addSubview:helloTextView];
    [self.scrollView addSubview:swipeTextView];
    [self.view addSubview:self.skipButton];
}

- (void)configurePageTwo
{
    
    TMVItemView *itemOne = [[TMVItemView alloc] init];
    itemOne.alpha = 0;
    itemOne.tag = 1;
    itemOne.userInteractionEnabled = NO;
    itemOne.frame = CGRectMake(280, 150, 100, 100);
    itemOne.apparentColor = [UIColor timerverseBlue];
    itemOne.state = TMVItemViewStatePoint;
    [self.scrollView addSubview:itemOne];
    
    TMVItemView *itemTwo = [[TMVItemView alloc] init];
    itemTwo.alpha = 0;
    itemTwo.userInteractionEnabled = NO;
    itemTwo.frame = CGRectMake(580, 150, 100, 100);
    itemTwo.apparentColor = [UIColor timerverseLightBlue];
    itemTwo.state = TMVItemViewStatePoint;
    [self.scrollView addSubview:itemTwo];

    
    UILabel *swipeLabel = [[UILabel alloc] initWithFrame:CGRectMake(440,260, 80, 80)];
    swipeLabel.textColor = [UIColor whiteColor];
    swipeLabel.text = NSLocalizedString(@"Swipe", Swipe);
    swipeLabel.textAlignment = NSTextAlignmentCenter;
    swipeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:24];
    [self.scrollView addSubview:swipeLabel];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(340, 320, 280, 100)];
    textView.editable = NO;
    textView.scrollEnabled = NO;
    textView.userInteractionEnabled = NO;
    textView.backgroundColor = [UIColor clearColor];
    textView.textAlignment = NSTextAlignmentCenter;
    textView.textColor = [UIColor whiteColor];
    textView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    textView.text = NSLocalizedString(@"the left or right edge of the screen to create a new timer.", Edges);
    [self.scrollView addSubview:textView];
    
    
    IFTTTAlphaAnimation *itemOneAnimation = [IFTTTAlphaAnimation new];
    itemOneAnimation.view = itemOne;
    [self.animator addAnimation:itemOneAnimation];
    [itemOneAnimation addKeyFrame:[[IFTTTAnimationKeyFrame alloc] initWithTime:240 andAlpha:0]];
    [itemOneAnimation addKeyFrame:[[IFTTTAnimationKeyFrame alloc] initWithTime:320 andAlpha:1]];
    [itemOneAnimation addKeyFrame:[[IFTTTAnimationKeyFrame alloc] initWithTime:440 andAlpha:0]];
    
    IFTTTAlphaAnimation *itemTwoAnimation = [IFTTTAlphaAnimation new];
    itemTwoAnimation.view = itemTwo;
    [self.animator addAnimation:itemTwoAnimation];
    [itemTwoAnimation addKeyFrame:[[IFTTTAnimationKeyFrame alloc] initWithTime:240 andAlpha:0]];
    [itemTwoAnimation addKeyFrame:[[IFTTTAnimationKeyFrame alloc] initWithTime:320 andAlpha:1]];
    [itemTwoAnimation addKeyFrame:[[IFTTTAnimationKeyFrame alloc] initWithTime:440 andAlpha:0]];
    
}

- (void)configurePageThree
{
    UILabel *tapLabel = [[UILabel alloc] initWithFrame:CGRectMake(760, 260, 80, 80)];
    tapLabel.textColor = [UIColor whiteColor];
    tapLabel.text = NSLocalizedString(@"Tap", Tap);
    tapLabel.adjustsFontSizeToFitWidth = YES;
    tapLabel.minimumScaleFactor = 0.1f;
    tapLabel.textAlignment = NSTextAlignmentCenter;
    tapLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:24];
    [self.scrollView addSubview:tapLabel];
    
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(660, 320, 280, 40)];
    [topLabel setTextColor:[UIColor whiteColor]];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.text = NSLocalizedString(@"a timer to start or stop.", Tap to start);
    topLabel.adjustsFontSizeToFitWidth = YES;
    topLabel.minimumScaleFactor = 0.1f;
    topLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    [self.scrollView addSubview:topLabel];

    TMVItemView *itemOne = [[TMVItemView alloc] init];
    itemOne.alpha = 1;
    itemOne.userInteractionEnabled = NO;
    itemOne.frame = CGRectMake(750, 160, 100, 100);
    itemOne.apparentColor = [UIColor timerversePurple];
    itemOne.state = TMVItemViewStateDefault;
    [itemOne.counterLabel setStartValue:0];
    [self.scrollView addSubview:itemOne];
    
    UIImageView *handImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hand"]];
    handImage.frame = CGRectMake(760, 240, 40, 40);
    handImage.transform = CGAffineTransformMakeRotation(45 * M_PI/180);
    [self.scrollView addSubview:handImage];
 

    
}

- (void)configurePageFour
{
    
    TMVItemView *itemTwo = [[TMVItemView alloc] init];
    itemTwo.alpha = 1;
    itemTwo.userInteractionEnabled = NO;
    itemTwo.frame = CGRectMake(1070, 160, 100, 100);
    itemTwo.nameLabel.text = NSLocalizedString(@"Gym Workout", GymWorkOut);
    itemTwo.apparentColor = [UIColor timerversePink];
    [itemTwo.counterLabel setStartValue:45000 * 60];
    itemTwo.state = TMVItemViewStateDefault;
    [self.scrollView addSubview:itemTwo];
    
    UIImageView *handImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hand"]];
    handImage.frame = CGRectMake(1130, 230, 40, 40);
    handImage.transform = CGAffineTransformMakeRotation(-45 * M_PI/180);
    [self.scrollView addSubview:handImage];
    
    UILabel *tapLabel = [[UILabel alloc] initWithFrame:CGRectMake(1050, 260, 140, 80)];
    tapLabel.textColor = [UIColor whiteColor];
    tapLabel.text = NSLocalizedString(@"Tap & Hold", Tap & Hold);
    tapLabel.adjustsFontSizeToFitWidth = YES;
    tapLabel.minimumScaleFactor = 0.1f;
    tapLabel.textAlignment = NSTextAlignmentCenter;
    tapLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:24];
    [self.scrollView addSubview:tapLabel];
    
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(980, 320, 280, 40)];
    [bottomLabel setTextColor:[UIColor whiteColor]];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = NSLocalizedString(@"a timer to edit its content.", Edit);
    bottomLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    bottomLabel.adjustsFontSizeToFitWidth = YES;
    bottomLabel.minimumScaleFactor = 0.1f;
    [self.scrollView addSubview:bottomLabel];

}

- (void)configurePageFive
{
    
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(1400, 260, 80, 80)];
    [topLabel setTextColor:[UIColor whiteColor]];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.text = NSLocalizedString(@"Drag", Drag);
    topLabel.adjustsFontSizeToFitWidth = YES;
    topLabel.minimumScaleFactor = 0.1f;
    topLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:24];
    [self.scrollView addSubview:topLabel];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(1300, 320, 280, 100)];
    textView.userInteractionEnabled = NO;
    textView.backgroundColor = [UIColor clearColor];
    textView.textAlignment = NSTextAlignmentCenter;
    textView.textColor = [UIColor whiteColor];
    textView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    textView.text = NSLocalizedString(@"a timer to the bottom edge of the screen and release to delete it.", Delete);
    [self.scrollView addSubview:textView];
    
    TMVItemView *itemOne = [[TMVItemView alloc] init];
    itemOne.alpha = 1;
    itemOne.userInteractionEnabled = NO;
    itemOne.frame = CGRectMake(1390, 184, 100, 100);
    itemOne.apparentColor = [UIColor timerverseYellow];
    itemOne.state = TMVItemViewStatePoint;
    [itemOne.counterLabel setStartValue:15000];
    [self.scrollView addSubview:itemOne];
    
    UIImageView *handImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hand"]];
    handImage.frame = CGRectMake(1390, 220, 40, 40);
    handImage.transform = CGAffineTransformMakeRotation(90 * M_PI/180);
    [self.scrollView addSubview:handImage];

}

- (void)configurePageSix
{
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(1620, 180, 280, 50)];
    [topLabel setTextColor:[UIColor whiteColor]];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.text = NSLocalizedString(@"Enjoy Your Time", Enjoy);
    topLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:40];
    [self.scrollView addSubview:topLabel];
    
    self.enterButton = [[UIButton alloc] initWithFrame:CGRectMake(1660, 300, 200, 40)];
    self.enterButton.layer.cornerRadius = 20;
    self.enterButton.layer.borderWidth = 1;
    self.enterButton.layer.borderColor = [UIColor timerverseLightBlue].CGColor;
    self.enterButton.backgroundColor = [UIColor timerverseLightBlue];
    self.enterButton.titleLabel.font = [UIFont fontWithName:@"helveticaneue" size:18];
    self.enterButton.titleLabel.textColor = [UIColor whiteColor];
    [self.enterButton setTitle:NSLocalizedString(@"Enter the Timerverse", Enter) forState:UIControlStateNormal];
    [self.enterButton addTarget:self action:@selector(didPressEnterTimerverse:) forControlEvents:UIControlEventTouchUpInside];
    [self.enterButton addTarget:self action:@selector(didDragOffEnterButton:) forControlEvents:UIControlEventTouchDragExit];
    [self.enterButton addTarget:self action:@selector(didTouchDownEnterButton:) forControlEvents:UIControlEventTouchDown];
    [self.scrollView addSubview:self.enterButton];
    
    IFTTTAlphaAnimation *skipButtonAnimation = [IFTTTAlphaAnimation new];
    skipButtonAnimation.view = self.skipButton;
    [self.animator addAnimation:skipButtonAnimation];
    [skipButtonAnimation addKeyFrame:[[IFTTTAnimationKeyFrame alloc] initWithTime:1400 andAlpha:1]];
    [skipButtonAnimation addKeyFrame:[[IFTTTAnimationKeyFrame alloc] initWithTime:1600 andAlpha:0]];
    
    IFTTTFrameAnimation *pageControlAnimation = [IFTTTFrameAnimation new];
    pageControlAnimation.view = self.pageControl;
    [self.animator addAnimation:pageControlAnimation];
    [pageControlAnimation addKeyFrame:[[IFTTTAnimationKeyFrame alloc] initWithTime:1480 andFrame:CGRectMake(110, self.view.height - 70, 100, 30)]];
    [pageControlAnimation addKeyFrame:[[IFTTTAnimationKeyFrame alloc] initWithTime:1600 andFrame:CGRectMake(110, self.view.height - 40, 100, 30)]];

}

#pragma mark - Scroll View Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Animation View Time based on ScrollView.ContentOffsetX
    [self.animator animate:scrollView.contentOffset.x];
    
    // Page Control Tracking
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    self.pageControl.currentPage = page;
    
}

#pragma mark - Button Actions
- (void)didPressEnterTimerverse:(UIButton *)button
{
    AppDelegate.firstLaunch = NO;
    
    [UIView animateWithDuration:0.5
                     animations:^{
        self.scrollView.layer.opacity = 0;
        self.pageControl.layer.opacity = 0;
        self.skipButton.layer.opacity = 0;
    }
                     completion:^(BOOL finished) {
                         
        [self.scrollView removeFromSuperview];
        [self.pageControl removeFromSuperview];
        
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        
        [AppContainer loadMainApplicationUI];

    }];
}

- (void)didTouchDownEnterButton:(UIButton *)button
{
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         button.layer.opacity = 0.7;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

- (void)didDragOffEnterButton:(UIButton *)button
{
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         button.layer.opacity = 1.0;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

- (void)didPressSkip:(UIButton *)button
{
    [self didPressEnterTimerverse:button];
}


@end

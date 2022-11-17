//
//  TMVAboutViewController.m
//  Timerverse
//
//  Created by Larry Ryan on 3/23/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVAboutViewController.h"
#import "TMVOrbView.h"
#import "TMVIconView.h"

@interface TMVAboutViewController () <TMVOrbDataSource, TMVOrbDelegate>

@property (nonatomic) UILabel *aboutLabel;
@property (nonatomic) TMVIconView *timerverseIconView;
@property (nonatomic) UILabel *timerverseLabel;
@property (nonatomic) TMVOrbView *orbView;
@property (nonatomic) UIImageView *timerverseIconImageView;

@end

#define IS_IPHONE_5 ([[UIScreen mainScreen] bounds].size.height >= 568)

@implementation TMVAboutViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        
    }
    return self;
}

- (void)applyTextColorEffect
{
    [UIView transitionWithView:self.aboutLabel
                      duration:4.0f
                       options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.aboutLabel.textColor = [UIColor randomTimerverseColor];
                    }
                    completion:^(BOOL finished) {
                        [self applyTextColorEffect];
                    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor clearColor];
    
    CGFloat headerHeight = IS_IPHONE_5 ? 100.0f : 80.0f;
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, headerHeight)];
    
    if (!self.aboutLabel)
    {
        self.aboutLabel = [[UILabel alloc] initWithFrame:containerView.frame];
        self.aboutLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:40.0f];
        self.aboutLabel.adjustsFontSizeToFitWidth = YES;
        self.aboutLabel.minimumScaleFactor = 0.1f;
        
        self.aboutLabel.textColor = [UIColor timerverseLightBlue];
        self.aboutLabel.text = NSLocalizedString(@"About", About);
        
        [self.aboutLabel sizeToFit];
        self.aboutLabel.center = containerView.center;
        [containerView addSubview:self.aboutLabel];
    }
    
    // Line Bottom
    UIView *lineViewBottom = [self lineViewForSection:0];
    lineViewBottom.bottom = containerView.bottom;
    
    [containerView addSubview:lineViewBottom];
    
    [self.view addSubview:containerView];
    
    [self.view addSubview:self.timerverseIconImageView];
    
    
//    [self applyTextColorEffect];
//    [self configureTimerverseIconView];
    [self configureTimerverseLabel];
    [self configureOffscreenView];
    [self configureOrbView];
}

- (UIView *)lineViewForSection:(NSUInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 1)];
    
    CGFloat lineWidth = 14;
    
    UIView *leftLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, lineWidth, 1)];
    leftLineView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    leftLineView.layer.opacity = 0.2;
    
    [view addSubview:leftLineView];
    
    UIView *rightLineView = [[UIView alloc] initWithFrame:CGRectMake((self.view.width - lineWidth), 0, lineWidth, 1)];
    rightLineView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    rightLineView.layer.opacity = 0.2;
    
    [view addSubview:rightLineView];
    
    return view;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureOffscreenView
{
    CGFloat margin = 10.0f;
    
    UIView *offscreenView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bottom, self.view.width, 82.0f)];
    [self.view addSubview:offscreenView];

    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, offscreenView.width, 20)];
    versionLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Version", Version), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.adjustsFontSizeToFitWidth = YES;
    versionLabel.minimumScaleFactor = 0.1f;
    versionLabel.textColor = [UIColor whiteColor];
    versionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    
    [offscreenView addSubview:versionLabel];
    
    UILabel *copyrightLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, versionLabel.bottom + margin, offscreenView.width, 20)];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
    NSInteger year = [components year];
    copyrightLabel.text = [NSString stringWithFormat:@"%@ © 2011-%ld Thinkr LLC.", NSLocalizedString(@"Copyright", Copyright), (long)year];
    copyrightLabel.textAlignment = NSTextAlignmentCenter;
    copyrightLabel.adjustsFontSizeToFitWidth = YES;
    copyrightLabel.minimumScaleFactor = 0.1f;
    copyrightLabel.textColor = [UIColor whiteColor];
    copyrightLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    
    [offscreenView addSubview:copyrightLabel];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Thinkr"]];
    imageView.frame = CGRectMake(0, copyrightLabel.bottom + margin, self.view.width, 50);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [offscreenView addSubview:imageView];
}

- (UIImageView *)timerverseIconImageView
{
    if (!_timerverseIconImageView)
    {
        _timerverseIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"timerverseIconAbout"]];
        
        CGFloat yInset = IS_IPHONE_5 ? 100.0f : 80.0f;
        
        _timerverseIconImageView.frame = CGRectMake((self.view.width - 95.0f) / 2, yInset + 30.0f, 95.0f, 100.0f);
    }
    
    return _timerverseIconImageView;
}

- (void)configureTimerverseIconView
{
    if (!self.timerverseIconView)
    {
        CGFloat yInset = IS_IPHONE_5 ? 100.0f : 80.0f;
        
        self.timerverseIconView = [[TMVIconView alloc] initWithFrame:CGRectMake(107.0f, yInset + 30.0f, 95.0f, 100.0f)];
        
        [self.view addSubview:self.timerverseIconView];
    }
}

- (void)configureTimerverseLabel
{
    if (!self.timerverseLabel)
    {
        self.timerverseLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.timerverseIconImageView.frame), self.view.width, 60.0f)];
        self.timerverseLabel.text = @"Timerverse";
        self.timerverseLabel.textAlignment = NSTextAlignmentCenter;
        self.timerverseLabel.textColor = [UIColor whiteColor];
        self.timerverseLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:34.0f];
        
        [self.view addSubview:self.timerverseLabel];
    }
}

- (void)configureOrbView
{
    if (!self.orbView)
    {
        self.orbView = [[TMVOrbView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.timerverseLabel.frame), self.view.width, self.view.height - CGRectGetMaxY(self.timerverseLabel.frame) - 20.0f)];
        self.orbView.dataSource = self;
        self.orbView.delegate = self;
        self.orbView.backgroundColor = [UIColor clearColor];
        
        [self.view addSubview:_orbView];
        [self.view bringSubviewToFront:_orbView];
    }
}

- (NSUInteger)numberOfOrbsForOrbView:(TMVOrbView *)orbView
{
    return 3;
}

- (NSUInteger)numberOfSubOrbsForIndex:(NSUInteger)index
                           forOrbView:(TMVOrbView *)orbView
{
    switch (index)
    {
        case 0:
            return 1;
            break;
        case 1:
            return 1;
            break;
        case 2:
            return 1;
            break;
        default:
            return 0;
            break;
    }
}

- (TMVOrbViewCell *)orbView:(TMVOrbView *)orbView
            orbCellForIndex:(NSUInteger)index
{
    switch (index)
    {
        case 0:
        {
            return [[TMVOrbViewCell alloc] initWithImage:[UIImage imageNamed:@"thinkrOrbIcon"]
                                                   color:[UIColor timerverseBlue]
                                            andSubscript:nil];
        }
            break;
        case 1:
        {
            return [[TMVOrbViewCell alloc] initWithText:@"LR"
                                                  color:[UIColor timerverseGreen]
                                           andSubscript:nil];
        }
            break;
        case 2:
        {
            return [[TMVOrbViewCell alloc] initWithText:@"JC"
                                                  color:[UIColor timerverseOrange]
                                           andSubscript:nil];
        }
            break;
    }
    
    return nil;
}

- (TMVOrbViewCell *)orbView:(TMVOrbView *)orbView
          subOrbCellAtIndex:(NSUInteger)subIndex
              forOrbAtIndex:(NSUInteger)index
{
    switch (index)
    {
        case 0:
        {
            switch (subIndex)
            {
                case 0:
                {
                    return [[TMVOrbViewCell alloc] initWithImage:[UIImage imageNamed:@"safariOrbIcon"]
                                                           color:[UIColor timerverseBlue]
                                                    andSubscript:NSLocalizedString(@"Website", Website)];
                }
                    break;
            }
        }
            break;
        case 1:
        {
            switch (subIndex)
            {
                case 0:
                {
                    return [[TMVOrbViewCell alloc] initWithImage:[UIImage imageNamed:@"twitterOrbIcon"]
                                                          color:[UIColor timerverseGreen]
                                                   andSubscript:@"Larry Ryan"];
                }
                    break;
            }
        }
            break;
        case 2:
        {
            switch (subIndex)
            {
                case 0:
                {
                    return [[TMVOrbViewCell alloc] initWithImage:[UIImage imageNamed:@"twitterOrbIcon"]
                                                          color:[UIColor timerverseOrange]
                                                   andSubscript:@"Justin Cabral"];
                }
                    break;
            }
        }
            break;
    }
    
    return nil;
}

- (void)orbView:(TMVOrbView *)orbView
didSelectSubOrbAtIndex:(NSInteger)subIndex
  forOrbAtIndex:(NSUInteger)index
{
    switch (index)
    {
        case 0:
        {
            switch (subIndex)
            {
                case 0:
                {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.thinkr.us"]];
                }
                    break;
                case 1:
                {
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]])
                    {
                        NSURL *url = [NSURL URLWithString:@"twitter:///user?screen_name=Thinkr_us"];
                        [[UIApplication sharedApplication] openURL:url];
                    }
                    else
                    {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/Thinkr_us"]];
                    }
                }
                    break;
                case 2:
                {
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]])
                    {
                        NSURL *url = [NSURL URLWithString:@"twitter:///user?screen_name=Timerverse"];
                        [[UIApplication sharedApplication] openURL:url];
                    }
                    else
                    {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/Timerverse"]];
                    }
                }
                    break;
            }
        }
            break;
        case 1:
        {
            switch (subIndex)
            {
                case 0:
                {
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]])
                    {
                        NSURL *url = [NSURL URLWithString:@"twitter:///user?screen_name=LarryRyan0824"];
                        [[UIApplication sharedApplication] openURL:url];
                    }
                    else
                    {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/LarryRyan0824"]];
                    }
                }
                    break;
            }
        }
            break;
        case 2:
        {
            switch (subIndex)
            {
                case 0:
                {
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]])
                    {
                        NSURL *url = [NSURL URLWithString:@"twitter:///user?screen_name=iJustinCabral"];
                        [[UIApplication sharedApplication] openURL:url];
                    }
                    else
                    {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/iJustinCabral"]];
                    }
                }
                    break;
            }
        }
            break;
    }
}

@end

//
//  TMVTimerViewController.m
//  Timerverse
//
//  Created by Justin Cabral on 1/11/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVTimerViewController.h"
#import "TMVPaperView.h"
#import "SATimerControl.h"
#import "TMVSoundCell.h"
#import "TMVGlyphCell.h"
#import "TMVCounterLabel.h"
#import "TNKArrayDataSource.h"
#import "TNKColorPickerDotView.h"

#import "UIImage+Overlay.h"
#import "NSLayoutConstraint+SimpleFormatLanguage.h"

@import QuartzCore;
@import AVFoundation;

static NSInteger const kMaxStringLength = 12;
static NSInteger const kSectorRadius = 44;
static NSInteger const kSectorRadiusSmall = 40;

static CGFloat const kLayerOpacityDimmed = 0.4f;
static CGFloat const kLayerOpacityFull = 1.0f;

//!!!:
//static NSString * const kPlaceholderText = @"Tap To Set Title";

#define GRADIENT_MASK_FRAME CGRectMake(0, 0,self.tableView.frame.size.width,self.tableView.frame.size.height)
#define DONE_BUTTON_FRAME CGRectMake(0, 14, 97, 45)
#define SOUND_BUTTON_FRAME CGRectMake(230, 26, 26, 22)
#define GLYPH_BUTTON_FRAME CGRectMake(280, 22, 24, 24)
#define TIMERCONTROL_FRAME CGRectMake(10, 185, 300, 300)
#define CONTAINER_VIEW_FRAME CGRectMake(0, 66, 320, 105)
#define TABLE_VIEW_FRAME CGRectMake(0, 175, 320, 340)
#define COLLECTION_VIEW_FRAME CGRectMake(0, 179, 320, 300)
#define REPEAT_BUTTON_FRAME CGRectMake(0, 538, 68, 26)
#define SMALL_REPEAT_BUTTON_FRAME CGRectMake(136, 24, 30, 24)
#define RESET_BUTTON_FRAME CGRectMake(264, 538, 54, 26)
#define SMALL_RESET_BUTTON_FRAME CGRectMake(186, 24, 25, 25)

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define IS_IPHONE_5 ( [ [ UIScreen mainScreen ] bounds ].size.height == 568 )


typedef NS_ENUM(NSInteger, TMVCollectionViewState)
{
    TMVCollectionViewStateHidden,
    TMVCollectionViewStateHiddenForTableView,
    TMVCollectionViewStateDefault,
};

typedef NS_ENUM(NSInteger, TMVTableViewState)
{
    TMVTableViewStateHidden,
    TMVTableViewStateHiddenForCollectionView,
    TMVTableViewStateDefault,
};

@interface TMVTimerViewController () <TMVCounterLabelDelegate, UIScrollViewDelegate, UITextFieldDelegate, AVAudioPlayerDelegate, TNKColorPickerDotViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *soundButton;
@property (weak, nonatomic) IBOutlet UIButton *glyphButton;
@property (weak, nonatomic) IBOutlet UIButton *repeatButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;

// *--- Small Screen Interface Buttons --- *//
@property (nonatomic) UIButton *smallRepeatButton, *smallResetButton;
// *--- ---*//

@property (weak, nonatomic) IBOutlet UIImageView *glyphImageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet TMVCounterLabel *timerLabel;
@property (nonatomic) IBOutlet SATimerControl *timerControl;
@property (nonatomic) TNKColorPickerDotView *colorPicker;

@property (nonatomic) UIView *backgroundContainerView;
@property (nonatomic) UIPageControl *pageControl;
@property (nonatomic) AVAudioPlayer *audioPlayer;
@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) UIGravityBehavior *gravity;
@property (nonatomic) NSMutableString *valueString;
@property (nonatomic) NSString *secondsString, *minutesString, *hoursString;
@property (nonatomic) NSArray *soundArray, *glyphNameArray; //, *glyphArray
@property (nonatomic) NSIndexPath *selectedItemIndexPath, *selectedRowIndexPath;
@property (nonatomic) CAGradientLayer *maskLayer;
@property (nonatomic) TNKArrayDataSource *soundArrayDataSource;
@property (nonatomic) TNKArrayDataSource *glyphArrayDataSource;

@property (nonatomic, assign, getter = isShowingSoundPicker) BOOL showingSoundPicker;
@property (nonatomic, assign, getter = isShowingGlyphPicker) BOOL showingGlyphPicker;
@property (nonatomic, getter = isResetting) BOOL resetting;

-(IBAction)didPressRepeatButton:(UIButton *)button;

@end

@implementation TMVTimerViewController

#pragma mark - Lifecyle

- (instancetype)initWIthItemView:(TMVItemView *)itemView
{
    self = [super init];
    if (self)
    {
        self.itemView = itemView;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    [self configureUI];
    [self configureTimerControl];
    [self updateViewsForTimerControlValue:self.timerLabel.currentValue];
    [self configureColorPicker];
    
    [AppContainer.atmosphere transitionToColor:self.itemView.apparentColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self configureTableViewMaskLayer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.soundArray enumerateObjectsUsingBlock:^(Sound *obj, NSUInteger idx, BOOL *stop)
     {
         if ([obj.name isEqual:self.itemView.item.sound.name] && self.timerLabel.currentValue !=0)
         {
             [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
         }
         
         if ([obj.name isEqual:self.itemView.item.sound.name] && self.timerLabel.currentValue == 0)
         {
             [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
         }
     }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Configure UI

- (void)configureUI
{
    [self configureDoneButton];
    [self configureSoundButton];
    [self configureGlyphTapGesture];
    [self configureGlyphButton];
    [self configureRepeatButton];
    [self configureTimerLabel];
    [self configureTextField];
    [self configureGlyphImageView];
    [self configureDetailLabel];
    [self configureCollectionView];
    [self configureTableView];
    [self configureResetButton];
    
    
}

- (void)configureDoneButton
{
    self.doneButton.tintColor = self.itemView.apparentColor;
    [self.doneButton setTitle:NSLocalizedString(@"Set Timer", Set Timer) forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(didPressBack:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureSoundButton
{
    self.soundButton.tintColor = self.itemView.apparentColor;
    [self.soundButton setImage:[[UIImage imageNamed:@"music-note-2"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.soundButton setImage:[[UIImage imageNamed:@"music-note-2-selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
    [self.soundButton addTarget:self action:@selector(didPressSound:) forControlEvents:UIControlEventTouchDown];
    
}

- (void)configureGlyphButton
{
    self.glyphButton.tintColor = self.itemView.apparentColor;
    [self.glyphButton setImage:[[UIImage imageNamed:@"picture"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.glyphButton setImage:[[UIImage imageNamed:@"picture-selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
    [self.glyphButton addTarget:self action:@selector(didPressGlyph:) forControlEvents:UIControlEventTouchUpInside];
    self.glyphButton.userInteractionEnabled = YES;
}

- (void)configureRepeatButton
{
    if (IS_IPHONE_5)
    {
        self.repeatButton.tintColor = self.itemView.apparentColor;
        
        if ([self.itemView.item.repeat  isEqual: @(YES)])
        {
            [self repeatButtonOn:self.repeatButton];
        }
    }
    
    else if (!IS_IPHONE_5)
    {
        self.repeatButton.hidden = YES;
        
        self.smallRepeatButton = [[UIButton alloc] initWithFrame:SMALL_REPEAT_BUTTON_FRAME];
        [self.smallRepeatButton setTitle:nil forState:UIControlStateNormal];
        self.smallRepeatButton.tintColor = self.itemView.apparentColor;
        [self.smallRepeatButton setImage:[[UIImage imageNamed:@"repeat"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.smallRepeatButton setImage:[[UIImage imageNamed:@"repeat-selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
        [self.smallRepeatButton addTarget:self action:@selector(didPressRepeatButton:) forControlEvents:UIControlEventTouchDown];
        
        [self.view addSubview:self.smallRepeatButton];
        
        if ([self.itemView.item.repeat isEqual:@(YES)])
        {
            [self repeatButtonOn:self.smallRepeatButton];
        }
        
        if (self.timerLabel.currentValue == 0)
        {
            self.smallRepeatButton.layer.opacity = kLayerOpacityDimmed;
            self.smallRepeatButton.userInteractionEnabled = NO;
        }
    }
    
    else if (self.timerLabel.currentValue == 0)
    {
        self.repeatButton.layer.opacity = kLayerOpacityDimmed;
        self.repeatButton.userInteractionEnabled = NO;
        
    }
    
    [self.repeatButton setTitle:NSLocalizedString(@"Repeat", Repeat) forState:UIControlStateNormal];
    self.repeatButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.repeatButton.titleLabel.minimumScaleFactor = 0.1f;
}

- (void)configureGlyphImageView
{
    self.glyphImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.glyphImageView.userInteractionEnabled = YES;
    
    if (self.itemView.item.glyphURL == nil)
    {
        self.glyphImageView.alpha = 0;
    }
    
    else
    {
        self.glyphImageView.alpha = 1;
        self.glyphImageView.image = [UIImage imageNamed:self.itemView.item.glyphURL];
    }
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithSimpleFormat:@[@"self.glyphImageView.height = 30",
                                                                                @"self.glyphImageView.width = 30",]
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(self.glyphImageView)]];
}

- (void)configureGlyphTapGesture
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapGlyphImageView:)];
    [self.glyphImageView addGestureRecognizer:tap];
}

- (void)configureTimerLabel
{
    
    NSString *fontFamily = @"HelveticaNeue-Light";
    
    self.timerLabel.font = [UIFont fontWithName:fontFamily size:48];
    
    
    self.timerLabel.delegate = self;
    self.timerLabel.countDirection = TMVCounterDirectionDown;
    [self.timerLabel setStartValue:self.itemView.counterLabel.currentValue];
    
}

- (void)configureDetailLabel
{
    /*---Set up the detail label---*/
    if (self.itemView.item.name != nil && ![self.itemView.item.name isEqualToString:@""] && self.itemView.item.name.length <= kMaxStringLength)
    {
        self.detailLabel.text = self.itemView.item.name;
        [self glyphButtonFadeOut];
    }
    
    else if (self.itemView.item.glyphURL != nil)
    {
        self.detailLabel.layer.opacity = 0;
        self.textField.text = NSLocalizedString(@"Tap To Set Title", SetTitle);
        self.textField.hidden = YES;
        self.glyphButton.selected = YES;
        
    }
    
    else
    {
        self.detailLabel.layer.opacity = 0;
        self.textField.text = NSLocalizedString(@"Tap To Set Title", SetTitle);
        self.textField.layer.opacity = kLayerOpacityDimmed;
        self.textField.hidden = NO;
        self.glyphButton.selected = YES;
    }
    
}

- (void)configureTextField
{
    self.textField.keyboardAppearance = UIKeyboardAppearanceLight;
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithSimpleFormat:@[@"self.textField.height = 24",
                                                                                @"self.textField.width = 160",]
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(self.textField)]];
}

- (void)configureCollectionView
{
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.hidden = YES;
    self.collectionView.pagingEnabled = YES;
    self.collectionView.dataSource = self.glyphArrayDataSource;
    [self setCollectionViewState:TMVCollectionViewStateHidden animated:YES];
    
    __weak typeof(self) weakSelf = self;
    
    [self.glyphNameArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop)
     {
         if ([obj isEqualToString:self.itemView.item.glyphURL])
         {
             [weakSelf collectionView:weakSelf.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]];
         }
         
     }];
}

- (void)configureTableView
{
    self.tableView.dataSource = self.soundArrayDataSource;
    self.tableView.hidden = YES;
    [self setTableViewState:TMVTableViewStateHidden animated:YES];
    
    if (!IS_IPHONE_5)
    {
        self.tableView.contentInsetBottom = 30;
    }
}

- (void)configureTableViewMaskLayer
{
    if (!self.tableView.layer.mask)
    {
        self.tableView.layer.mask = self.maskLayer;
    }
    
    [self scrollViewDidScroll:self.tableView];
}

- (void)configureResetButton
{
    if (IS_IPHONE_5)
    {
        self.resetButton.tintColor = self.itemView.apparentColor;
        [self.resetButton addTarget:self action:@selector(didPressResetButton:) forControlEvents:UIControlEventTouchUpInside];
        
        if (self.timerLabel.currentValue == 0)
        {
            self.resetButton.layer.opacity = kLayerOpacityDimmed;
            self.resetButton.userInteractionEnabled = NO;
        }
    }
    else
    {
        self.smallResetButton = [[UIButton alloc] initWithFrame:SMALL_RESET_BUTTON_FRAME];
        [self.smallResetButton setTitle:nil forState:UIControlStateNormal];
        self.smallResetButton.tintColor = self.itemView.apparentColor;
        [self.smallResetButton setImage:[[UIImage imageNamed:@"rewind-time-1"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.smallResetButton setImage:[[UIImage imageNamed:@"rewind-time-1-selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
        [self.smallResetButton addTarget:self action:@selector(didPressResetButton:) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:self.smallResetButton];
        
        if (self.timerLabel.currentValue == 0)
        {
            self.smallResetButton.layer.opacity = kLayerOpacityDimmed;
            self.smallResetButton.userInteractionEnabled = NO;
        }
        
    }
    
    [self.resetButton setTitle:NSLocalizedString(@"Reset", Reset) forState:UIControlStateNormal];
    self.resetButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.resetButton.titleLabel.minimumScaleFactor = 0.1f;
}

#pragma mark - Color Picker -

- (void)configureColorPicker
{
    if (!self.colorPicker)
    {
        self.colorPicker = [[TNKColorPickerDotView alloc] initWithFrame:CGRectWithCenter(CGRectMake(0, 0, self.itemView.width * 0.3f, self.itemView.height * 0.3f), self.timerControl.center)];
        self.colorPicker.delegate = self;
        self.colorPicker.backgroundColor = self.itemView.apparentColor;
        
        [self.view addSubview:self.colorPicker];
        [self.view bringSubviewToFront:self.colorPicker];
    }
}

- (void)didChangeDotView:(TNKColorPickerDotView *)dotView
                 toColor:(UIColor *)color
{
    self.doneButton.tintColor = color;
    self.soundButton.tintColor = color;
    self.glyphButton.tintColor = color;
    self.resetButton.tintColor = color;
    
    self.itemView.apparentColor = color;
    self.itemView.dashView.ringLayer.strokeColor = color.CGColor;
    
    [AppContainer.atmosphere updateColorAnimated:NO];
    
    for (SATimerSector *sector in self.timerControl.sectorsArray)
    {
        sector.color = color;
    }
    
    if (IS_IPHONE_5)
    {
        self.repeatButton.tintColor = color;
        [self.repeatButton setTitleColor:self.itemView.apparentColor forState:UIControlStateNormal];
    }
    else
    {
        self.smallRepeatButton.tintColor = self.itemView.apparentColor;
    }
    
    [self.timerControl setNeedsDisplay];
    
    [self.tableView reloadData];
    [self.collectionView reloadData];
}

#pragma mark - Timer Control

- (void)configureTimerControl
{
    self.timerControl.exclusiveTouch = YES;
    
    [self.timerControl addTarget:self
                          action:@selector(multisectorValueChanged:)
                forControlEvents:UIControlEventValueChanged];
    
    if (IS_IPHONE_5)
    {
        self.timerControl.sectorsRadius = kSectorRadius;
    }
    else
    {
        self.timerControl.sectorsRadius = kSectorRadiusSmall;
    }
    
    SATimerSector *secondsSector = [SATimerSector sectorWithColor:self.itemView.apparentColor maxValue:60];
    SATimerSector *minutesSector = [SATimerSector sectorWithColor:self.itemView.apparentColor maxValue:60];
    SATimerSector *hourSector = [SATimerSector sectorWithColor:self.itemView.apparentColor maxValue:24];
    
    secondsSector.tag = 0;
    minutesSector.tag = 1;
    hourSector.tag = 2;
    
    [self formatValueStringsForTime];
    
    secondsSector.endValue = [self.secondsString integerValue];
    minutesSector.endValue = [self.minutesString integerValue];
    hourSector.endValue = [self.hoursString integerValue];
    
    
    [self.timerControl addSector:hourSector];
    [self.timerControl addSector:minutesSector];
    [self.timerControl addSector:secondsSector];
}

- (void)multisectorValueChanged:(id)sender
{
    [self updateDataView];
    [self updateTimerLabelForSectorsValueChange];
}

- (void)updateTimerLabelForSectorsValueChange
{
    [self.timerLabel setStartValueWithHours:[self.hoursString integerValue]
                                    minutes:[self.minutesString integerValue]
                                    seconds:[self.secondsString integerValue]
                               milliSeconds:0];
    
    [self updateViewsForTimerControlValue:self.timerLabel.currentValue];
    
}

- (void)updateViewsForTimerControlValue:(unsigned long long)value
{
    if (self.timerLabel.currentValue == 0)
    {
        [UIView animateWithDuration:0.2
                         animations:^{
                             
                             self.soundButton.layer.opacity = kLayerOpacityDimmed;
                             self.soundButton.userInteractionEnabled = NO;
                             
                             self.repeatButton.layer.opacity = kLayerOpacityDimmed;
                             self.repeatButton.userInteractionEnabled = NO;
                             
                             self.resetButton.layer.opacity = kLayerOpacityDimmed;
                             self.resetButton.userInteractionEnabled = NO;
                             
                             if (self.repeatButton.selected)
                             {
                                 [self didPressRepeatButton:self.repeatButton];
                             }
                             
                             if (!IS_IPHONE_5)
                             {
                                 self.smallRepeatButton.layer.opacity = kLayerOpacityDimmed;
                                 self.smallRepeatButton.userInteractionEnabled = NO;
                                 
                                 self.smallResetButton.layer.opacity = kLayerOpacityDimmed;
                                 self.smallResetButton.userInteractionEnabled = NO;
                                 
                                 if (self.smallRepeatButton.selected)
                                 {
                                     [self didPressRepeatButton:self.smallRepeatButton];
                                 }
                             }
                         }];
        
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        
    }
    
    else
    {
        [UIView animateWithDuration:0.2
                         animations:^{
                             self.repeatButton.layer.opacity = kLayerOpacityFull;
                             self.repeatButton.userInteractionEnabled = YES;
                             
                             self.soundButton.layer.opacity = kLayerOpacityFull;
                             self.soundButton.userInteractionEnabled = YES;
                             
                             if ([self.textField.text isEqualToString:NSLocalizedString(@"Tap To Set Title", SetTitle)])
                             {
                                 self.glyphButton.layer.opacity = kLayerOpacityFull;
                                 self.glyphButton.userInteractionEnabled = YES;
                             }
                             
                             self.resetButton.layer.opacity = kLayerOpacityFull;
                             self.resetButton.userInteractionEnabled = YES;
                             
                             if (!IS_IPHONE_5)
                             {
                                 self.smallRepeatButton.layer.opacity = kLayerOpacityFull;
                                 self.smallRepeatButton.userInteractionEnabled = YES;
                                 
                                 self.smallResetButton.layer.opacity = kLayerOpacityFull;
                                 self.smallResetButton.userInteractionEnabled = YES;
                             }
                         }];
    }
}

- (void)updateDataView
{
    [self.timerControl.sectorsArray enumerateObjectsUsingBlock:^(SATimerSector *sector, NSUInteger idx, BOOL *stop) {
        
        switch (sector.tag)
        {
            case 0:
                [self setSecondsStringForValue:sector.endValue];
                break;
                
            case 1:
                [self setMinutesStringForValue:sector.endValue];
                break;
                
            case 2:
                [self setHoursStringForValue:sector.endValue];
                break;
                
            default:
                break;
        }
        
    }];
}

- (void)setSecondsStringForValue:(int)value
{
    self.secondsString = [NSString stringWithFormat:@"%d",value];
}

- (void)setMinutesStringForValue:(int)value
{
    self.minutesString = [NSString stringWithFormat:@"%d",value];
    
}

- (void)setHoursStringForValue:(int)value
{
    self.hoursString = [NSString stringWithFormat:@"%d",value];
    
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath == nil)
    {
        indexPath = [NSIndexPath indexPathWithIndex:0];
    }
    NSMutableArray *indexPaths = [NSMutableArray arrayWithObject:indexPath];
    
    if (self.selectedRowIndexPath)
    {
        
        if ([indexPath compare:self.selectedRowIndexPath] == NSOrderedSame)
        {
            if (!tableView.hidden)[self playSound];
        }
        
        else
        {
            [indexPaths addObject:self.selectedRowIndexPath];
            self.selectedRowIndexPath= indexPath;
            [tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
            
            if (!tableView.hidden)[self playSound];
        }
    }
    
    else
    {
        self.selectedRowIndexPath = indexPath;
    }
    
    [tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UICollectionView Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *indexPaths = [NSMutableArray arrayWithObject:indexPath];
    
    if (self.selectedItemIndexPath)
    {
        
        if ([indexPath compare:self.selectedItemIndexPath] == NSOrderedSame)
        {
            self.selectedItemIndexPath = nil;
            self.glyphImageView.image = nil;
            self.itemView.item.glyphURL = nil;
            
            [DataManager saveContext];
            
        }
        
        else
        {
            
            [indexPaths addObject:self.selectedItemIndexPath];
            self.selectedItemIndexPath = indexPath;
        }
    }
    
    else
    {
        self.selectedItemIndexPath = indexPath;
    }
    
    [collectionView reloadItemsAtIndexPaths:indexPaths];
    
}
#pragma mark - Scroll View Delegate

- (void)updateGradientMask:(UIScrollView *)scrollView
{
    CGColorRef outerColor = [UIColor colorWithWhite:1.0 alpha:0.0].CGColor;
    CGColorRef innerColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
    NSArray *colors;
    
    if (scrollView.contentOffset.y + scrollView.contentInset.top <= 0)
    {
        //Top of scrollView
        colors = @[(__bridge id)innerColor, (__bridge id)innerColor,
                   (__bridge id)innerColor, (__bridge id)outerColor];
        
    }
    
    else if (scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height)
    {
        //Bottom of tableView
        colors = @[(__bridge id)outerColor, (__bridge id)innerColor,
                   (__bridge id)innerColor, (__bridge id)innerColor];
    }
    else
    {
        //Middle
        colors = @[(__bridge id)outerColor, (__bridge id)innerColor,
                   (__bridge id)innerColor, (__bridge id)outerColor];
    }
    
    ((CAGradientLayer *)scrollView.layer.mask).colors = colors;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    scrollView.layer.mask.position = CGPointMake(0, scrollView.contentOffset.y);
    [CATransaction commit];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateGradientMask:scrollView];
    
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    self.pageControl.currentPage = page;
    
}

#pragma mark TextField Delegate

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.detailLabel.hidden = YES;
    self.textField.text = @"";
    self.textField.alpha = kLayerOpacityDimmed;
    
    self.timerControl.userInteractionEnabled = NO;
    
    [self glyphButtonFadeOut];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (!self.textField.hidden)
    {
        
        if (self.textField.text.length != 0 && ![self.itemView.item.name isEqualToString:NSLocalizedString(@"Tap To Set Title", SetTitle)])
        {
            self.detailLabel.text = self.textField.text;
            self.detailLabel.hidden = NO;
            self.detailLabel.layer.opacity = kLayerOpacityFull;
            
            self.itemView.item.name = self.textField.text;
            self.textField.text = nil;
            
            [DataManager saveContext];
        }
        
        else
        {
            self.detailLabel.hidden = NO;
            self.detailLabel.text = @"";
            self.detailLabel.layer.opacity = kLayerOpacityDimmed;
            self.textField.text = NSLocalizedString(@"Tap To Set Title", SetTitle);
            self.textField.hidden = NO;
            
            self.itemView.item.name = nil;
            [DataManager saveContext];
            
            if (self.timerLabel.currentValue !=0)
            {
                [self glyphButtonFadeIn];
            }
            else
            {
                [self glyphButtonFadeIn];
            }
        }
    }
    
    self.timerControl.userInteractionEnabled = YES;
    [self.textField resignFirstResponder];
    
    return YES;
}


- (BOOL)textField:(UITextField *) textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;
    NSUInteger newLength = oldLength - rangeLength + replacementLength;
    
    BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
    
    return newLength <= kMaxStringLength || returnKey;
}


#pragma mark - Reset Timer

- (void)didPressResetButton:(UIButton *)button
{
    if (self.isResetting) return;
    
    self.resetting = YES;
    
    self.view.userInteractionEnabled = NO;
    
    [self.timerControl resetAnimated:YES]; // Animates the sectors back to 0 which also will set the ui to where it needs to be
    
    [self resetAllValues];
    
    self.textField.layer.opacity = kLayerOpacityDimmed;
    
    [UIView transitionWithView:self.containerView
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        
                        self.detailLabel.text = @"";
                        
                        self.textField.text = NSLocalizedString(@"Tap To Set Title", SetTitle);
                        
                        self.textField.hidden = NO;
                        
                        self.glyphImageView.hidden = YES;
                        
                    } completion:^(BOOL finished) {
                        
                        self.view.userInteractionEnabled = YES;
                        
                        self.resetting = NO;
                        
                    }];
    
    /*
     //    [self updateDataView]; // Resets the sectors
     //    [self addGravityBehaviors];
     //    [self addAttachmentBeahviors];
     
     [self performSelector:@selector(resetAllValues)
     withObject:nil
     afterDelay:1.0];
     
     [self performSelector:@selector(resetTimer)
     withObject:nil
     afterDelay:1.0];
     
     [self performSelector:@selector(removeAnimatorAndGravityBehaviours)
     withObject:nil
     afterDelay:1.0];
     
     [self performSelector:@selector(cancelRepeatInteraction)
     withObject:nil
     afterDelay:1.1];
     
     if (!IS_IPHONE_5)
     {
     [self performSelector:@selector(cancelSmallResetInteraction)
     withObject:nil
     afterDelay:1.1];
     }
     */
}

- (void)resetAllValues
{
    [self.glyphNameArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop)
     {
         if ([obj isEqualToString:self.itemView.item.glyphURL])
         {
             [self collectionView:self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]];
         }
         
     }];
    
    
    self.itemView.item.glyphURL = nil;
    self.itemView.item.name = nil;
    self.itemView.item.sound = [self.soundArray objectAtIndex:0];
    self.itemView.counterLabel.currentValue = 0;
    self.itemView.item.repeat = @(NO);
    
    
    [self.soundArray enumerateObjectsUsingBlock:^(Sound *obj, NSUInteger idx, BOOL *stop)
     {
         if ([obj.name isEqual:self.itemView.item.sound.name])
         {
             [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
             [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
         }
     }];
    
    
    [DataManager saveContext];
}

/*
 - (void)addAttachmentBeahviors
 {
 //--- Done Button ---/
 CGPoint doneButtonCenterPoint = [self squareCenterPointForX:self.doneButton.frame andY:self.doneButton.frame];
 UIOffset doneButtonAttachmentPoint = [self offsetForAttachmentPoint:self.timerControl.frame andY:self.timerControl.frame];
 UIAttachmentBehavior *doneButtonAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.doneButton
 offsetFromCenter:doneButtonAttachmentPoint
 attachedToAnchor:doneButtonCenterPoint];
 //--- SoundButton ---/
 CGPoint soundButtonCenterPoint = [self squareCenterPointForX:self.soundButton.frame andY:self.soundButton.frame];
 UIOffset soundButtonattachmentPoint = [self offsetForAttachmentPoint:self.timerControl.frame andY:self.timerControl.frame];
 UIAttachmentBehavior *soundAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.soundButton
 offsetFromCenter:soundButtonattachmentPoint
 attachedToAnchor:soundButtonCenterPoint];
 //--- GlyphButton ---/
 CGPoint glyphButtonCenterPoint = [self squareCenterPointForX:self.glyphButton.frame andY:self.glyphButton.frame];
 UIOffset glyphButtonAttachmentPoint = [self offsetForAttachmentPoint:self.timerControl.frame andY:self.timerControl.frame];
 UIAttachmentBehavior *glyphAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.glyphButton
 offsetFromCenter:glyphButtonAttachmentPoint
 attachedToAnchor:glyphButtonCenterPoint];
 
 //-- Container View---/
 CGPoint containerViewCenterPoint = [self squareCenterPointForX:self.containerView.frame andY:self.containerView.frame];
 UIOffset containerViewAttachmentPoint = [self offsetForAttachmentPoint:self.timerControl.frame andY:self.timerControl.frame];
 UIAttachmentBehavior *containerAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.containerView
 offsetFromCenter:containerViewAttachmentPoint
 attachedToAnchor:containerViewCenterPoint];
 
 //--- TimerControl ---/
 CGPoint timerViewCenterPoint = [self squareCenterPointForX:self.timerControl.frame andY:self.timerControl.frame];
 UIOffset timerViewAttachmentPoint = [self offsetForAttachmentPoint:self.timerControl.frame andY:self.timerControl.frame];
 UIAttachmentBehavior *timerViewAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.timerControl
 offsetFromCenter:timerViewAttachmentPoint
 attachedToAnchor:timerViewCenterPoint];
 
 //--- RepeatButton ---/
 CGPoint repeatButtonCenterPoint = [self squareCenterPointForX:self.repeatButton.frame andY:self.repeatButton.frame];
 UIOffset repeatButtonAttachmentPoint = [self offsetForAttachmentPoint:self.repeatButton.frame andY:self.repeatButton.frame];
 UIAttachmentBehavior *repeatButtonAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.repeatButton
 offsetFromCenter:repeatButtonAttachmentPoint
 attachedToAnchor:repeatButtonCenterPoint];
 //--- Reset Button ---/
 CGPoint resetButtonCenterPoint = [self squareCenterPointForX:self.resetButton.frame andY:self.resetButton.frame];
 UIOffset resetButtonAttachmentPoint = [self offsetForAttachmentPoint:self.resetButton.frame andY:self.resetButton.frame];
 UIAttachmentBehavior *resetAttatchentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.resetButton
 offsetFromCenter:resetButtonAttachmentPoint
 attachedToAnchor:resetButtonCenterPoint];
 
 
 [self.animator addBehavior:doneButtonAttachmentBehavior];
 [self.animator addBehavior:soundAttachmentBehavior];
 [self.animator addBehavior:glyphAttachmentBehavior];
 [self.animator addBehavior:containerAttachmentBehavior];
 [self.animator addBehavior:timerViewAttachmentBehavior];
 [self.animator addBehavior:repeatButtonAttachmentBehavior];
 [self.animator addBehavior:resetAttatchentBehavior];
 
 
 if (!IS_IPHONE_5)
 {
 
 CGPoint repeatButtonCenterPoint = [self squareCenterPointForX:self.smallRepeatButton.frame andY:self.self.smallRepeatButton.frame];
 UIOffset repeatButtonAttachmentPoint = [self offsetForAttachmentPoint:self.timerControl.frame andY:self.timerControl.frame];
 UIAttachmentBehavior *smallRepeatButtonAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.smallRepeatButton
 offsetFromCenter:repeatButtonAttachmentPoint
 attachedToAnchor:repeatButtonCenterPoint];
 
 CGPoint killButtonCenterPoint = [self squareCenterPointForX:self.smallResetButton.frame andY:self.smallResetButton.frame];
 UIOffset killButtonAttachmentPoint = [self offsetForAttachmentPoint:self.timerControl.frame andY:self.timerControl.frame];
 UIAttachmentBehavior *smallKillButtonAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.smallResetButton
 offsetFromCenter:killButtonAttachmentPoint
 attachedToAnchor:killButtonCenterPoint];
 
 [self.animator removeBehavior:repeatButtonAttachmentBehavior];
 [self.animator removeBehavior:resetAttatchentBehavior];
 [self.animator addBehavior:smallRepeatButtonAttachmentBehavior];
 [self.animator addBehavior:smallKillButtonAttachmentBehavior];
 
 }
 
 
 }
 //*/

- (void)addGravityBehaviors
{
    [self.animator addBehavior:self.gravity];
}

- (void)resetTimer
{
    [self.animator removeAllBehaviors];
    [self.timerControl setNeedsDisplay];
    
    self.detailLabel.text = @"";
    self.textField.text = NSLocalizedString(@"Tap To Set Title", SetTitle);
    self.glyphImageView.image = nil;
    self.timerLabel.currentValue = 0;
    
    [self.timerLabel setStartValue:0];
    
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self reloadNewTimerView];
                         self.textField.hidden = NO;
                         self.textField.layer.opacity = kLayerOpacityDimmed;
                         
                     }
                     completion:^(BOOL finished){
                         [self.tableView reloadData];
                         [self.collectionView reloadData];
                     }];
}

- (void)reloadNewTimerView
{
    [self.doneButton setTransform:CGAffineTransformIdentity];
    [self.soundButton setTransform:CGAffineTransformIdentity];
    [self.glyphButton setTransform:CGAffineTransformIdentity];
    [self.timerControl setTransform:CGAffineTransformIdentity];
    [self.repeatButton setTransform:CGAffineTransformIdentity];
    [self.containerView setTransform:CGAffineTransformIdentity];
    [self.resetButton setTransform:CGAffineTransformIdentity];
    
    self.doneButton.frame = DONE_BUTTON_FRAME;
    self.soundButton.frame = SOUND_BUTTON_FRAME;
    self.glyphButton.frame = GLYPH_BUTTON_FRAME;
    self.timerControl.frame = TIMERCONTROL_FRAME;
    
    self.containerView.frame = CONTAINER_VIEW_FRAME;
    self.tableView.frame = TABLE_VIEW_FRAME;
    self.collectionView.frame = COLLECTION_VIEW_FRAME;
    
    self.repeatButton.frame = REPEAT_BUTTON_FRAME;
    self.resetButton.frame  = RESET_BUTTON_FRAME;
    
    self.detailLabel.layer.opacity = kLayerOpacityDimmed;
    //    self.soundButton.layer.opacity = kLayerOpacityDimmed;
    self.glyphButton.layer.opacity = kLayerOpacityFull;
    
    self.glyphImageView.layer.opacity = 0;
    
    [self repeatButtonOff:self.repeatButton];
    
    self.repeatButton.layer.opacity = kLayerOpacityDimmed;
    self.resetButton.layer.opacity = kLayerOpacityDimmed;
    
    
    self.soundButton.userInteractionEnabled = NO;
    self.glyphButton.userInteractionEnabled = YES;
    self.repeatButton.userInteractionEnabled = NO;
    self.resetButton.userInteractionEnabled = NO;
    
    if (!IS_IPHONE_5)
    {
        [self.smallRepeatButton setTransform:CGAffineTransformIdentity];
        [self.smallResetButton setTransform:CGAffineTransformIdentity];
        
        self.smallRepeatButton.frame = SMALL_REPEAT_BUTTON_FRAME;
        self.smallResetButton.frame = SMALL_RESET_BUTTON_FRAME;
        
        [self repeatButtonOff:self.smallResetButton];
        
        self.smallRepeatButton.layer.opacity = kLayerOpacityDimmed;
        self.smallRepeatButton.userInteractionEnabled = NO;
        
        self.smallResetButton.layer.opacity = kLayerOpacityDimmed;
        self.smallResetButton.userInteractionEnabled = NO;
    }
    
    
}

- (void)cancelSmallResetInteraction
{
    self.smallResetButton.userInteractionEnabled = NO;
}

- (void)cancelRepeatInteraction
{
    self.repeatButton.userInteractionEnabled = NO;
}

- (void)removeAnimatorAndGravityBehaviours
{
    self.gravity = nil;
    self.animator = nil;
}

#pragma mark - Actions
- (void)didTapGlyphImageView:(UITapGestureRecognizer *)tap
{
    if (self.collectionView.hidden)
    {
        [self didPressGlyph:self.glyphButton];
        
        [self.glyphButton setImage:[[UIImage imageNamed:@"picture-selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        
    }
}

- (void)playSound
{
    [SoundManager lowerSystemSound];
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:self.itemView.item.sound.sourceURL
                                                                        ofType:self.itemView.item.sound.sourceExt]];
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.audioPlayer.delegate = self;
    
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
    
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [SoundManager raiseSystemSound];
}

- (void)didPressBack:(UIButton *)backButton
{
    // Set the time
    self.itemView.item.time = @(self.timerLabel.currentValue);
    self.itemView.counterLabel.currentValue = self.timerLabel.currentValue;
    
    // Set the Repeat
    if (self.repeatButton.selected || self.smallRepeatButton.selected)
    {
        self.itemView.item.repeat = @YES;
        [self.itemView showRepeatImageViewAnimated:YES];
    }
    else
    {
        self.itemView.item.repeat = @NO;
        [self.itemView hideRepeatImageViewAnimated:YES];
    }
    
    // Set the Name Label
    if (self.detailLabel.text.length > 0 && ![self.detailLabel.text isEqualToString:NSLocalizedString(@"Tap To Set Title", SetTitle)])
    {
        self.itemView.item.name = self.detailLabel.text;
    }
    
    [self.itemView setItem:self.itemView.item];
    
    self.itemView.editing = NO;
    
    [DataManager saveContext];
    
    [self dismissTransition];
}

- (void)didPressSound:(UIButton *)soundButton
{
    if (!self.showingSoundPicker && !self.showingGlyphPicker)
    {
        self.showingSoundPicker = YES;
        [self setTableViewState:TMVTableViewStateDefault animated:YES];
    }
    
    else if (!self.showingSoundPicker && self.showingGlyphPicker)
    {
        self.showingGlyphPicker = NO;
        self.showingSoundPicker = YES;
        
        [self setCollectionViewState:TMVCollectionViewStateHiddenForTableView animated:YES];
        [self setTableViewState:TMVTableViewStateDefault animated:YES];
        
        [self glyphButtonAnimationOff];
    }
    
    else
    {
        self.showingSoundPicker = NO;
        
        [self setTableViewState:TMVTableViewStateHidden animated:YES];
    }
    
}



- (void)didPressGlyph:(UIButton *)glyphButton
{
    self.glyphImageView.hidden = NO;
    
    if (!self.showingGlyphPicker && !self.showingSoundPicker)
    {
        self.showingGlyphPicker = YES;
        
        [self setCollectionViewState:TMVCollectionViewStateDefault animated:YES];
        [self scrollToIndexForSelectedGlyph];
        [self glyphButtonAnimationOn];
    }
    
    else if (!self.showingGlyphPicker && self.showingSoundPicker)
    {
        self.showingGlyphPicker = YES;
        self.showingSoundPicker = NO;
        
        [self setTableViewState:TMVTableViewStateHiddenForCollectionView animated:YES];
        [self setCollectionViewState:TMVCollectionViewStateDefault animated:YES];
        [self scrollToIndexForSelectedGlyph];
        [self glyphButtonAnimationOn];
    }
    
    
    else
    {
        self.showingGlyphPicker = NO;
        
        [self setCollectionViewState:TMVCollectionViewStateHidden animated:YES];
        [self glyphButtonAnimationOff];
    }
    
}

- (void)scrollToIndexForSelectedGlyph
{
    
    [self.collectionView scrollToItemAtIndexPath:self.selectedItemIndexPath
                                atScrollPosition:UICollectionViewScrollPositionNone
                                        animated:NO];
    
    NSInteger item = self.selectedItemIndexPath.item;
    
    if (item <= 8)
    {
        [self.collectionView setContentOffsetX:0];
    }
    
    if (item <= 17 && item >= 9)
    {
        [self.collectionView setContentOffsetX:320];
    }
    
    if (item <= 26 && item >= 18)
    {
        [self.collectionView setContentOffsetX:638];
    }
    
}

- (void)didPressRepeatButton:(UIButton *)button
{
    if (!button.selected && self.timerLabel.currentValue != 0) [self repeatButtonOn:button];
    
    else if (!button.selected && self.timerLabel.currentValue == 0)
    {
        button.selected = NO;
    }
    
    else [self repeatButtonOff:button];
}

#pragma mark - Animations
- (void)dismissTransition
{
    [self.view.superview addSubview:self.view];
    
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         // Shrink!
                         self.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
                         self.view.center = AppContainer.view.center;
                     }
                     completion:^(BOOL finished){
                         
                         [self willMoveToParentViewController:nil];
                         [self.view removeFromSuperview];
                         [self removeFromParentViewController];
                         [AppContainer showHUDAnimated:YES];
                         [AppContainer didDismissViewController:self];
                     }];
    
    
}

- (void)repeatButtonOn:(UIButton *)button
{
    button.selected = YES;
    
    if (IS_IPHONE_5)
    {
        [UIView animateWithDuration:0.3 animations:^
         {
             [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
             button.layer.opacity = kLayerOpacityFull;
             button.userInteractionEnabled = NO;
             
         } completion:^(BOOL finished)
         {
             button.userInteractionEnabled = YES;
             
             self.itemView.item.repeat = @(YES);
             [DataManager saveContext];
         }];
    }
    else
    {
        [UIView animateWithDuration:0.3 animations:^
         {
             self.smallRepeatButton.tintColor = [UIColor whiteColor];
             [self.smallRepeatButton setImage:[[UIImage imageNamed:@"repeat-selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
             self.smallRepeatButton.selected = YES;
             
             button.layer.opacity = kLayerOpacityFull;
             button.userInteractionEnabled = NO;
             
         } completion:^(BOOL finished)
         {
             button.userInteractionEnabled = YES;
             
             self.itemView.item.repeat = @(YES);
             [DataManager saveContext];
         }];
    }
}

- (void)repeatButtonOff:(UIButton *)button
{
    button.selected = NO;
    
    if (IS_IPHONE_5)
    {
        
        [UIView animateWithDuration:0.3 animations:^
         {
             button.layer.opacity = kLayerOpacityFull;
             
             [button setTitleColor:self.itemView.apparentColor forState:UIControlStateNormal];
             
             button.userInteractionEnabled = NO;
             
         } completion:^(BOOL finished)
         {
             button.userInteractionEnabled = YES;
             
             self.itemView.item.repeat = @(NO);
             [DataManager saveContext];
         }];
        
    }
    
    else
    {
        [UIView animateWithDuration:0.3 animations:^
         {
             
             self.smallRepeatButton.tintColor = self.itemView.apparentColor;
             [self.smallRepeatButton setImage:[[UIImage imageNamed:@"repeat"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
             button.userInteractionEnabled = NO;
             self.smallRepeatButton.selected = NO;
             
         } completion:^(BOOL finished)
         {
             button.userInteractionEnabled = YES;
             
             self.itemView.item.repeat = @(NO);
             [DataManager saveContext];
         }];
    }
}
- (void)glyphButtonFadeIn
{
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.glyphButton.layer.opacity = kLayerOpacityFull;
                         
                     } completion:^(BOOL finished) {
                         self.glyphButton.userInteractionEnabled = YES;
                         self.glyphButton.selected = YES;
                         
                     }];
}

- (void)glyphButtonFadeOut
{
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.glyphButton.layer.opacity = kLayerOpacityDimmed;
                         
                     } completion:^(BOOL finished) {
                         self.glyphButton.userInteractionEnabled = NO;
                         self.glyphButton.selected = NO;
                         
                     }];}

- (void)glyphButtonAnimationOn
{
    
    if (self.itemView.item.glyphURL == nil)
    {
        [UIView animateWithDuration:0.3
                         animations:^
         {
             self.glyphButton.userInteractionEnabled = NO;
             self.glyphImageView.layer.opacity = kLayerOpacityDimmed;
             self.detailLabel.layer.opacity = 0;
             self.textField.layer.opacity = 0;
             
         }
                         completion:^(BOOL finished)
         {
             self.glyphButton.userInteractionEnabled = YES;
             self.textField.hidden  = YES;
             
         }];
    }
    
    else
    {
        [UIView animateWithDuration:0.3
                         animations:^
         {
             self.glyphButton.userInteractionEnabled = NO;
             self.glyphImageView.layer.opacity = kLayerOpacityDimmed;
             self.detailLabel.layer.opacity = 0;
             self.textField.layer.opacity = 0;
             
         }
                         completion:^(BOOL finished)
         {
             self.glyphButton.userInteractionEnabled = YES;
             self.textField.hidden  = YES;
             
         }];
    }
    
    
}

- (void)glyphButtonAnimationOff
{
    self.detailLabel.alpha = 0;
    
    if (self.itemView.item.glyphURL == nil)
    {
        
        [UIView animateWithDuration:0.3 animations:^
         {
             self.glyphButton.userInteractionEnabled = NO;
             self.glyphImageView.alpha = 0;
             self.detailLabel.layer.opacity = 0;
             self.textField.hidden = NO;
             self.textField.layer.opacity = kLayerOpacityDimmed;
             
         }
                         completion:^(BOOL finished)
         {
             self.glyphButton.userInteractionEnabled = YES;
         }];
    }
    
    else
    {
        [UIView animateWithDuration:0.3 animations:^
         {
             self.glyphButton.userInteractionEnabled = NO;
             self.glyphImageView.layer.opacity = kLayerOpacityFull;
         }
                         completion:^(BOOL finished)
         {
             self.glyphButton.userInteractionEnabled = YES;
         }];
    }
    
}

- (void)setCollectionViewState:(TMVCollectionViewState)state animated:(BOOL)animated
{
    [UIView transitionWithView:self.timerControl
                      duration:0.3
                       options:UIViewAnimationOptionTransitionNone
                    animations:^{
                        
                        switch (state) {
                            case TMVCollectionViewStateHidden:
                            {
                                self.collectionView.alpha = 0;
                                self.collectionView.hidden = YES;
                                
                                self.timerControl.alpha = kLayerOpacityFull;
                                self.timerControl.hidden = NO;
                                
                                self.colorPicker.layer.opacity = kLayerOpacityFull;
                                self.colorPicker.hidden = NO;
                                
                                self.pageControl.layer.opacity = 0;
                                
                                if (self.timerLabel.currentValue != 0)
                                {
                                    self.resetButton.layer.opacity = kLayerOpacityFull;
                                    
                                    if (!IS_IPHONE_5)
                                    {
                                        self.smallResetButton.layer.opacity = kLayerOpacityFull;
                                    }
                                }
                                
                                self.glyphButton.tintColor = self.itemView.apparentColor;
                                [self.glyphButton setImage:[[UIImage imageNamed:@"picture"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                            }
                                break;
                                
                            case TMVCollectionViewStateDefault:
                            {
                                self.collectionView.layer.opacity = kLayerOpacityFull;
                                self.collectionView.hidden = NO;
                                
                                self.timerControl.layer.opacity = 0;
                                self.timerControl.hidden = YES;
                                
                                self.colorPicker.layer.opacity = 0;
                                self.colorPicker.hidden = YES;
                                [self.colorPicker cancelGestures];
                                
                                self.pageControl.layer.opacity = 1;
                                
                                self.resetButton.layer.opacity = kLayerOpacityDimmed;
                                self.smallResetButton.layer.opacity = kLayerOpacityDimmed;
                                
                                self.glyphButton.tintColor = [UIColor whiteColor];
                                
                                [self.glyphButton setImage:[[UIImage imageNamed:@"picture-selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                                
                                
                            }
                                break;
                                
                            case TMVCollectionViewStateHiddenForTableView:
                            {
                                self.collectionView.layer.opacity = 0;
                                self.collectionView.hidden = YES;
                                
                                self.pageControl.layer.opacity = 0;
                                
                                self.glyphButton.tintColor = self.itemView.apparentColor;
                                [self.glyphButton setImage:[[UIImage imageNamed:@"picture"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                                
                            }
                                break;
                                
                            default:
                                break;
                        }
                    }
                    completion:^(BOOL finished) {
                        
                        if (self.collectionView.hidden == NO)
                        {
                            self.resetButton.userInteractionEnabled = NO;
                            self.smallResetButton.userInteractionEnabled = NO;
                        }
                        
                        else if (self.collectionView.hidden == YES && self.timerLabel.currentValue != 0)
                        {
                            self.smallResetButton.userInteractionEnabled = YES;
                            self.resetButton.userInteractionEnabled = YES;
                            
                        }
                        
                    }];
}

- (void)setTableViewState:(TMVTableViewState)state animated:(BOOL)animated
{
    [UIView transitionWithView:self.timerControl
                      duration:0.3
                       options:UIViewAnimationOptionTransitionNone
                    animations:^{
                        
                        switch (state) {
                            case TMVTableViewStateHidden:
                            {
                                self.tableView.layer.opacity = 0;
                                self.tableView.hidden = YES;
                                
                                self.timerControl.layer.opacity = kLayerOpacityFull;
                                self.timerControl.hidden = NO;
                                
                                self.colorPicker.layer.opacity = kLayerOpacityFull;
                                self.colorPicker.hidden = NO;
                                
                                if (self.timerLabel.currentValue != 0)
                                {
                                    self.resetButton.layer.opacity = kLayerOpacityFull;
                                    
                                    if (!IS_IPHONE_5)
                                    {
                                        self.smallResetButton.layer.opacity = kLayerOpacityFull;
                                    }
                                }
                                
                                self.soundButton.tintColor = self.itemView.apparentColor;
                                [self.soundButton setImage:[[UIImage imageNamed:@"music-note-2"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                                
                                
                            }
                                break;
                                
                            case TMVTableViewStateDefault:
                            {
                                self.tableView.layer.opacity = kLayerOpacityFull;
                                self.tableView.hidden = NO;
                                
                                self.timerControl.layer.opacity = 0;
                                self.timerControl.hidden = YES;
                                
                                self.colorPicker.layer.opacity = 0;
                                self.colorPicker.hidden = YES;
                                [self.colorPicker cancelGestures];
                                
                                self.resetButton.layer.opacity = kLayerOpacityDimmed;
                                self.smallResetButton.layer.opacity = kLayerOpacityDimmed;
                                
                                self.soundButton.tintColor = [UIColor whiteColor];
                                [self.soundButton setImage:[[UIImage imageNamed:@"music-note-2-selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                                
                                
                                
                            }
                                break;
                                
                            case TMVTableViewStateHiddenForCollectionView:
                            {
                                self.tableView.layer.opacity = 0;
                                self.tableView.hidden = YES;
                                
                                self.soundButton.tintColor = self.itemView.apparentColor;
                                [self.soundButton setImage:[[UIImage imageNamed:@"music-note-2"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                                
                            }
                                break;
                                
                                
                            default:
                                break;
                        }
                    }
                    completion:^(BOOL finished) {
                        
                        if (self.tableView.hidden == NO)
                        {
                            self.resetButton.userInteractionEnabled = NO;
                            self.smallResetButton.userInteractionEnabled = NO;
                        }
                        
                        else if (self.tableView.hidden == YES && self.timerLabel.currentValue != 0)
                        {
                            
                            self.smallResetButton.userInteractionEnabled = YES;
                            self.resetButton.userInteractionEnabled = YES;
                        }
                        
                    }];
    
    
}

#pragma mark Helpers
-(CGPoint)squareCenterPointForX:(CGRect)x andY:(CGRect)y
{
    return CGPointMake(CGRectGetMaxX(x), CGRectGetMinY(y));
}

-(UIOffset)offsetForAttachmentPoint:(CGRect)x andY:(CGRect)y
{
    
    return UIOffsetMake(CGRectGetMinX(x), CGRectGetMaxY(y));
}

- (void)formatValueStringsForTime
{
    unsigned long long msperhour = 3600000;
    unsigned long long mspermin = 60000;
    
    unsigned long long hrs = self.itemView.counterLabel.currentValue / msperhour;
    unsigned long long mins = (self.itemView.counterLabel.currentValue % msperhour) / mspermin;
    unsigned long long secs = ((self.itemView.counterLabel.currentValue % msperhour) % mspermin) / 1000;
    
    self.secondsString = [NSString stringWithFormat:@"%llu",secs % 60];
    
    self.minutesString = [NSString stringWithFormat:@"%llu",mins];
    
    self.hoursString = [NSString stringWithFormat:@"%llu",hrs];
    
}

#pragma mark - Getters
- (NSArray *)soundArray
{
    if (!_soundArray)
    {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        _soundArray = [[SoundManager allSounds] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
    }
    
    return _soundArray;
}

/*
 - (NSArray *)glyphArray
 {
 if (!_glyphArray)
 {
 _glyphArray = @[[UIImage imageNamed:@"oven"],[UIImage imageNamed:@"chicken-leg-selected"],[UIImage imageNamed:@"pizza-selected"],
 [UIImage imageNamed:@"washingMachine"], [UIImage imageNamed:@"sock-selected"],[UIImage imageNamed:@"neck-tie-selected"],
 [UIImage imageNamed:@"utensils-selected"],[UIImage imageNamed:@"food-selected"],[UIImage imageNamed:@"wine-glass-selected"],
 
 [UIImage imageNamed:@"beer-mug-selected"],[UIImage imageNamed:@"coffee-cup-selected"],[UIImage imageNamed:@"bottle-selected"],
 [UIImage imageNamed:@"game-controller-selected"],[UIImage imageNamed:@"running-man-selected"], [UIImage imageNamed:@"walking-man-selected"],
 [UIImage imageNamed:@"basketball-selected"], [UIImage imageNamed:@"football-selected"], [UIImage imageNamed:@"soccer-ball-selected"],
 
 [UIImage imageNamed:@"weights-selected"], [UIImage imageNamed:@"hammer-selected"], [UIImage imageNamed:@"paint-roller-selected"],
 [UIImage imageNamed:@"pill-selected"],[UIImage imageNamed:@"microphone-selected"],[UIImage imageNamed:@"guitar-selected"],
 [UIImage imageNamed:@"puzzle-piece-selected"], [UIImage imageNamed:@"fish-hook-selected"], [UIImage imageNamed:@"light-bulb-selected"]];
 
 }
 
 return _glyphArray;
 }
 */

- (NSArray *)glyphNameArray
{
    if (!_glyphNameArray)
    {
        _glyphNameArray = @[@"oven", @"chicken-leg-selected",@"pizza-selected",
                            @"washingMachine",@"sock-selected",@"neck-tie-selected",
                            @"utensils-selected",@"food-selected",@"wine-glass-selected",
                            @"beer-mug-selected",@"coffee-cup-selected",@"bottle-selected",
                            @"game-controller-selected",@"running-man-selected",@"walking-man-selected",
                            @"basketball-selected",@"football-selected",@"soccer-ball-selected",
                            @"weights-selected",@"hammer-selected",@"paint-roller-selected",
                            @"pill-selected",@"microphone-selected",@"guitar-selected",
                            @"puzzle-piece-selected",@"fish-hook-selected", @"light-bulb-selected"];
        
    }
    
    return _glyphNameArray;
}
- (UIDynamicAnimator *)animator
{
    if (!_animator)
    {
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    }
    
    return _animator;
}

- (UIGravityBehavior *)gravity
{
    NSArray *gravityBehaviorArray;
    
    if (!_gravity)
    {
        if (IS_IPHONE_5)
        {
            gravityBehaviorArray = @[self.doneButton,self.soundButton, self.glyphButton, self.timerControl,
                                     self.tableView, self.collectionView, self.repeatButton,self.containerView,
                                     self.resetButton];
            
        }
        else
        {
            gravityBehaviorArray = @[self.doneButton, self.smallRepeatButton,self.smallResetButton
                                     ,self.soundButton, self.glyphButton, self.timerControl,
                                     self.tableView, self.collectionView,self.containerView];
        }
        
        _gravity = [[UIGravityBehavior alloc] initWithItems:gravityBehaviorArray];
        _gravity.magnitude = 4;
        _gravity.angle = DEGREES_TO_RADIANS(100);
        
    }
    
    return _gravity;
}

- (UIPageControl *)pageControl
{
    if (!_pageControl)
    {
        if (IS_IPHONE_5)
        {
            _pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(141, 478, 39, 37)];
        }
        else
        {
            _pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(141, 166, 39, 37)];
        }
        
        _pageControl.currentPage = 1;
        _pageControl.numberOfPages = 3;
        
    }
    
    [self.view addSubview:_pageControl];
    
    return _pageControl;
}

- (CAGradientLayer *)maskLayer
{
    if (!_maskLayer)
    {
        _maskLayer = [CAGradientLayer layer];
        
        _maskLayer.locations =     @[[NSNumber numberWithFloat:0.0],
                                     [NSNumber numberWithFloat:0.2],
                                     [NSNumber numberWithFloat:0.8],
                                     [NSNumber numberWithFloat:1.0]];
        
        _maskLayer.bounds = GRADIENT_MASK_FRAME;
        
        _maskLayer.anchorPoint = CGPointZero;
    }
    
    return _maskLayer;
}

- (TNKArrayDataSource *)soundArrayDataSource
{
    if (!_soundArrayDataSource)
    {
        __weak typeof(self) weakSelf = self;
        
        _soundArrayDataSource = [[TNKArrayDataSource alloc] initWithItems:self.soundArray
                                                           cellIdentifier:@"SoundCell" configureCellBlock:^(TMVSoundCell *cell, Sound *item, NSIndexPath *index) {
                                                               
                                                               cell.soundTitle.text = [[weakSelf.soundArray objectAtIndex:index.row]name];
                                                               
                                                               
                                                               if (weakSelf.selectedRowIndexPath != nil && [index compare:weakSelf.selectedRowIndexPath] == NSOrderedSame)
                                                               {
                                                                   cell.soundTitle.textColor = [UIColor whiteColor];
                                                                   self.itemView.item.sound = [weakSelf.soundArray objectAtIndex:index.row];
                                                                   
                                                                   [DataManager saveContext];
                                                               }
                                                               
                                                               else
                                                               {
                                                                   cell.soundTitle.textColor = self.itemView.apparentColor;
                                                               }
                                                               
                                                           }];
    }
    
    return _soundArrayDataSource;
}

- (TNKArrayDataSource *)glyphArrayDataSource
{
    if (!_glyphArrayDataSource)
    {
        __weak typeof(self) weakSelf = self;
        
        _glyphArrayDataSource = [[TNKArrayDataSource alloc] initWithItems:self.glyphNameArray
                                                           cellIdentifier:@"GlyphCell"
                                                       configureCellBlock:^(TMVGlyphCell *cell, id item, NSIndexPath *indexPath) {
                                                           
                                                           UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%@", weakSelf.glyphNameArray[indexPath.item]]];
                                                           
                                                           cell.glyphImageView.image = image;
                                                           cell.glyphImageView.image = [cell.glyphImageView.image imageWithColor:self.itemView.apparentColor];
                                                           cell.glyphImageView.contentMode = UIViewContentModeScaleAspectFit;
                                                           
                                                           if (weakSelf.selectedItemIndexPath != nil && [indexPath compare:weakSelf.selectedItemIndexPath] == NSOrderedSame)
                                                           {
                                                               cell.glyphImageView.image = [cell.glyphImageView.image imageWithColor:[UIColor whiteColor]];
                                                               [weakSelf.glyphImageView setImage:cell.glyphImageView.image];
                                                               
                                                               weakSelf.itemView.item.glyphURL = [weakSelf.glyphNameArray objectAtIndex:indexPath.item];
                                                               [DataManager saveContext];
                                                           }
                                                           
                                                           
                                                       }];
    }
    
    return _glyphArrayDataSource;
}


@end

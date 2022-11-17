//
//  TMVAlarmViewController.m
//  Timerverse
//
//  Created by Justin Cabral on 2/7/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVAlarmViewController.h"

#define Max_String_Length 19

typedef NS_ENUM(NSInteger, MonringNightLabelState)
{
    MorningNightLabelStateAM = 0,
    MorningNightLabelStatePM,
};


@interface TMVAlarmViewController () <UITextFieldDelegate>

@property (nonatomic) IBOutlet UIButton *soundsButton;

@property (nonatomic) IBOutlet UITextField *textField;
@property (nonatomic) IBOutlet UILabel *descriptionLabel;

@property (nonatomic) IBOutlet UILabel *timeLabel;
@property (nonatomic) IBOutlet UILabel *morningNightLabel;
@property (nonatomic) IBOutlet UILabel *repeatLabel;

@property (nonatomic) IBOutletCollection(UIButton) NSArray *repeatAlarmButtons;

@property (nonatomic) IBOutlet UIButton *setAlarmButton;

@property (nonatomic) UIView *lineView;
@property (nonatomic) NSMutableArray *buttonsOnArray;

@property (nonatomic) NSDateFormatter *timeFormatter;

@property (nonatomic) TMVItemView *itemView;

@property (nonatomic, assign, getter = isMilitaryTime) BOOL militaryTime;


-(IBAction)didPressSetAlarm:(UIButton *)button;
-(IBAction)didPressRepeatAlarmButton:(UIButton *)button;

@end

@implementation TMVAlarmViewController

#pragma mark - Getters
- (NSDateFormatter *)timeFormatter
{
    if (!_timeFormatter)
    {
        _timeFormatter = [[NSDateFormatter alloc] init];
        [_timeFormatter setLocale:[NSLocale currentLocale]];
        [_timeFormatter setDateStyle:NSDateFormatterNoStyle];
        [_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        NSString *dateString = [_timeFormatter stringFromDate:[NSDate date]];
        NSRange amRange = [dateString rangeOfString:[_timeFormatter AMSymbol]];
        NSRange pmRange = [dateString rangeOfString:[_timeFormatter PMSymbol]];
        
        BOOL is24h = (amRange.location == NSNotFound && pmRange.location == NSNotFound);
        
        if (is24h)
        {
            self.morningNightLabel.hidden = YES;
            self.militaryTime = YES;
        }
        else
        {
            self.morningNightLabel.hidden = NO;
            self.militaryTime = NO;
        }
    }
    
    return _timeFormatter;
}

- (UIView *)lineView
{
    if (!_lineView)
    {
       UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 1)];
        
        CGFloat lineWidth = 250;
        
        _lineView = [[UIView alloc] initWithFrame:CGRectMake((320 - lineWidth) / 2, 20, lineWidth, 1)];
        _lineView.backgroundColor = AppContainer.atmosphere.currentColor;
        _lineView.layer.opacity = 1;
        
        [view addSubview:_lineView];
        
        [self.view addSubview:view];
    }
    
    return _lineView;
}

#pragma mark - Lifecyle

- (instancetype)initWithItemView:(TMVItemView *)itemView
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
	// Do any additional setup after loading the view.
    [self configureView];
    [self configureMultiselectorControl];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureView
{
    self.view.backgroundColor = [UIColor clearColor];
    
    self.setAlarmButton.tintColor = AppContainer.atmosphere.currentColor;
    
    /*--Set up the sound button---*/
    self.soundsButton.tintColor = AppContainer.atmosphere.currentColor;
    [self.soundsButton setImage:[[UIImage imageNamed:@"sounds"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.soundsButton setImage:[[UIImage imageNamed:@"sounds"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
    [self.soundsButton addTarget:self action:@selector(didPressSound:) forControlEvents:UIControlEventTouchUpInside];
    
    //Clean this up
    self.textField.hidden = NO;
    self.descriptionLabel.layer.opacity = 0.4f;

    [self.timeFormatter stringFromDate:[NSDate date]];
    
    [self.lineView setCenterY:534];
    
    self.buttonsOnArray = [NSMutableArray new];

}

-(void)configureMultiselectorControl
{
    [self.alarmSelector addTarget:self
                           action:@selector(multisectorValueChanged:)
                 forControlEvents:UIControlEventValueChanged];
    
    self.alarmSelector.sectorsRadius = 124;
   
    
    SAAlarmSector *clockSector = [SAAlarmSector sectorWithColor:AppContainer.atmosphere.currentColor maxValue:97];
    
    
    [self.alarmSelector addSector:clockSector];
    
    [self updateDataView];
}

- (void)multisectorValueChanged:(id)sender{
    [self updateDataView];
}

- (void)updateDataView {
   
    for(SAAlarmSector *sector in self.alarmSelector.sectors)
    {
//        NSString *startValue = [NSString stringWithFormat:@"%.0f", sector.startValue];
//        NSString *endValue = [NSString stringWithFormat:@"%.0f", sector.endValue];
        
        if(sector.tag == 0)
        {
            [self adjustTimeForValue:sector.endValue];
            
            if (sector.endValue >= 48)
            {
                [self setMorningNightLabelState:MorningNightLabelStatePM animated:YES];
            }
            else
            {
                [self setMorningNightLabelState:MorningNightLabelStateAM animated:YES];
            }
        }
    }
}

#pragma mark TextField Delegate
- (BOOL)canBecomeFirstResponder
{
    return YES;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.descriptionLabel.hidden = YES;
    self.textField.text = @"";
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    NSString *frontQuotation = @"\" ";
    NSString *backQuotation = @" \"";
    
    if (!self.textField.hidden)
    {
    
        if (self.textField.text.length != 0)
        {
            NSString *finalDescriptionString = [NSString stringWithFormat:@"%@%@%@",frontQuotation,self.textField.text,backQuotation];
        
            self.descriptionLabel.text = finalDescriptionString;
            self.descriptionLabel.hidden = NO;
            self.descriptionLabel.layer.opacity = 1;
        
            self.itemView.item.name = self.textField.text;
        
            [DataManager saveContext];
        }
        
        else
        {
            self.descriptionLabel.hidden = NO;
            self.descriptionLabel.layer.opacity = 0.4f;
            self.descriptionLabel.text = NSLocalizedString(@"Tap To Set Title", SetTitle);
            self.textField.hidden = NO;
        }
    }
    
    [self.textField resignFirstResponder];
    
    return YES;
}


- (BOOL)textField:(UITextField *) textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;
    
    NSUInteger newLength = oldLength - rangeLength + replacementLength;
    
    BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
    
    return newLength <= Max_String_Length || returnKey;
}

#pragma mark - Button Actions

- (void)didPressSetAlarm:(UIButton *)button
{
    [self.view.superview addSubview:self.view];
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         // Shrink!
                         self.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
                         self.view.center = self.itemCenter;
                     }
                     completion:^(BOOL finished){
                         [self willMoveToParentViewController:nil];
                         [self.view removeFromSuperview];
                         [self removeFromParentViewController];
                     }];
}

- (void)didPressSound:(UIButton *)button
{
    
}


- (void)didPressMore:(UIButton *)button
{
    // 3.5 inch screen only
}

- (void)didPressRepeatAlarmButton:(UIButton *)button
{
   if (!button.selected) [self repeatButtonOn:button];
    
   else [self repeatButtonOff:button];
    
}

#pragma mark - Animations

- (void)repeatButtonOn:(UIButton *)button
{
    [UIView animateWithDuration:0.5 animations:^
    {
        
        [self.buttonsOnArray addObject:button];
        
        self.repeatLabel.alpha = 0;
        button.centerY = button.centerY - 30;
        button.alpha = 1.0;
        button.userInteractionEnabled = NO;
        
    } completion:^(BOOL finished)
    {
        button.userInteractionEnabled = YES;
        button.selected = YES;
        
    }];
}

- (void)repeatButtonOff:(UIButton *)button
{
    [UIView animateWithDuration:0.5 animations:^
    {
        
        [self.buttonsOnArray removeObject:button];
        
        if (self.buttonsOnArray.count == 0)
        {
            self.repeatLabel.alpha = 1;
        }
        
        button.centerY = button.centerY + 30;
        button.alpha = 0.4;
        button.userInteractionEnabled = NO;
        
    } completion:^(BOOL finished)
     {
        button.userInteractionEnabled = YES;
        button.selected = NO;
    }];
}

-(void)adjustTimeForValue:(int)value
{
    if (!self.isMilitaryTime)
    {
        switch (value)
        {
            case 0:
                self.timeLabel.text = @"12:00";
                break;
                
            case 1:
                self.timeLabel.text = @"12:15";
                break;
                
            case 2:
                self.timeLabel.text = @"12:30";
                break;
                
            case 3:
                self.timeLabel.text = @"12:45";
                break;
                
            case 4:
                self.timeLabel.text = @"01:00";
                break;
                
            case 5:
                self.timeLabel.text = @"01:15";
                break;
                
            case 6:
                self.timeLabel.text = @"01:30";
                break;
                
            case 7:
                self.timeLabel.text = @"01:45";
                break;
                
            case 8:
                self.timeLabel.text = @"02:00";
                break;
                
            case 9:
                self.timeLabel.text = @"02:15";
                break;
                
            case 10:
                self.timeLabel.text = @"02:30";
                break;
                
            case 11:
                self.timeLabel.text = @"02:45";
                break;
                
            case 12:
                self.timeLabel.text = @"03:00";
                break;
                
            case 13:
                self.timeLabel.text = @"03:15";
                break;
                
            case 14:
                self.timeLabel.text = @"03:30";
                break;
                
            case 15:
                self.timeLabel.text = @"03:45";
                break;
                
            case 16:
                self.timeLabel.text = @"04:00";
                break;
                
            case 17:
                self.timeLabel.text = @"04:15";
                break;
                
            case 18:
                self.timeLabel.text = @"04:30";
                break;
                
            case 19:
                self.timeLabel.text = @"04:45";
                break;
                
            case 20:
                self.timeLabel.text = @"05:00";
                break;
                
            case 21:
                self.timeLabel.text = @"05:15";
                break;
                
            case 22:
                self.timeLabel.text = @"05:30";
                break;
                
            case 23:
                self.timeLabel.text = @"05:45";
                break;
                
            case 24:
                self.timeLabel.text = @"06:00";
                break;
                
            case 25:
                self.timeLabel.text = @"06:15";
                break;
                
            case 26:
                self.timeLabel.text = @"06:30";
                break;
                
            case 27:
                self.timeLabel.text = @"06:45";
                break;
                
            case 28:
                self.timeLabel.text = @"07:00";
                break;
                
            case 29:
                self.timeLabel.text = @"07:15";
                break;
                
            case 30:
                self.timeLabel.text = @"07:30";
                break;
                
            case 31:
                self.timeLabel.text = @"07:45";
                break;
                
            case 32:
                self.timeLabel.text = @"08:00";
                break;
                
            case 33:
                self.timeLabel.text = @"08:15";
                break;
                
            case 34:
                self.timeLabel.text = @"08:30";
                break;
                
            case 35:
                self.timeLabel.text = @"08:45";
                break;
                
            case 36:
                self.timeLabel.text = @"09:00";
                break;
                
            case 37:
                self.timeLabel.text = @"09:15";
                break;
                
            case 38:
                self.timeLabel.text = @"09:30";
                break;
                
            case 39:
                self.timeLabel.text = @"09:45";
                break;
                
            case 40:
                self.timeLabel.text = @"10:00";
                break;
                
            case 41:
                self.timeLabel.text = @"10:15";
                break;
                
            case 42:
                self.timeLabel.text = @"10:30";
                break;
                
            case 43:
                self.timeLabel.text = @"10:45";
                break;
                
            case 44:
                self.timeLabel.text = @"11:00";
                break;
                
            case 45:
                self.timeLabel.text = @"11:15";
                break;
                
            case 46:
                self.timeLabel.text = @"11:30";
                break;
                
            case 47:
                self.timeLabel.text = @"11:45";
                break;
                
            case 48:
                self.timeLabel.text = @"12:00";
                break;
                
            case 49:
                self.timeLabel.text = @"12:15";
                break;
                
            case 50:
                self.timeLabel.text = @"12:30";
                break;
                
            case 51:
                self.timeLabel.text = @"12:45";
                break;
                
            case 52:
                self.timeLabel.text = @"01:00";
                break;
                
            case 53:
                self.timeLabel.text = @"01:15";
                break;
                
            case 54:
                self.timeLabel.text = @"01:30";
                break;
                
            case 55:
                self.timeLabel.text = @"01:45";
                break;
                
            case 56:
                self.timeLabel.text = @"02:00";
                break;
                
            case 57:
                self.timeLabel.text = @"02:15";
                break;
                
            case 58:
                self.timeLabel.text = @"02:30";
                break;
                
            case 59:
                self.timeLabel.text = @"02:45";
                break;
                
            case 60:
                self.timeLabel.text = @"03:00";
                break;
                
            case 61:
                self.timeLabel.text = @"03:15";
                break;
                
            case 62:
                self.timeLabel.text = @"03:30";
                break;
                
            case 63:
                self.timeLabel.text = @"03:45";
                break;
                
            case 64:
                self.timeLabel.text = @"04:00";
                break;
                
            case 65:
                self.timeLabel.text = @"04:15";
                break;
                
            case 66:
                self.timeLabel.text = @"04:30";
                break;
                
            case 67:
                self.timeLabel.text = @"04:45";
                break;
                
            case 68:
                self.timeLabel.text = @"05:00";
                break;
                
            case 69:
                self.timeLabel.text = @"05:15";
                break;
                
            case 70:
                self.timeLabel.text = @"05:30";
                break;
                
            case 71:
                self.timeLabel.text = @"05:45";
                break;
                
            case 72:
                self.timeLabel.text = @"06:00";
                break;
                
            case 73:
                self.timeLabel.text = @"06:15";
                break;
                
            case 74:
                self.timeLabel.text = @"06:30";
                break;
                
            case 75:
                self.timeLabel.text = @"06:45";
                break;
                
            case 76:
                self.timeLabel.text = @"07:00";
                break;
                
            case 77:
                self.timeLabel.text = @"07:15";
                break;
                
            case 78:
                self.timeLabel.text = @"07:30";
                break;
                
            case 79:
                self.timeLabel.text = @"07:45";
                break;
                
            case 80:
                self.timeLabel.text = @"08:00";
                break;
                
            case 81:
                self.timeLabel.text = @"08:15";
                break;
                
            case 82:
                self.timeLabel.text = @"08:30";
                break;
                
            case 83:
                self.timeLabel.text = @"08:45";
                break;
                
            case 84:
                self.timeLabel.text = @"09:00";
                break;
                
            case 85:
                self.timeLabel.text = @"09:15";
                break;
                
            case 86:
                self.timeLabel.text = @"09:30";
                break;
                
            case 87:
                self.timeLabel.text = @"09:45";
                break;
                
            case 88:
                self.timeLabel.text = @"10:00";
                break;
                
            case 89:
                self.timeLabel.text = @"10:15";
                break;
                
            case 90:
                self.timeLabel.text = @"10:30";
                break;
                
            case 91:
                self.timeLabel.text = @"10:45";
                break;
                
            case 92:
                self.timeLabel.text = @"11:00";
                break;
                
            case 93:
                self.timeLabel.text = @"11:15";
                break;
                
            case 94:
                self.timeLabel.text = @"11:30";
                break;
                
            case 95:
                self.timeLabel.text = @"11:45";
                break;

            case 96:
                self.timeLabel.text = @"11:55";
                break;
                
                
            default:
                break;
        }
    }
    
    else
    {
        switch (value)
        {
            case 0:
                self.timeLabel.text = @"00:00";
                break;
                
            case 1:
                self.timeLabel.text = @"00:15";
                break;
                
            case 2:
                self.timeLabel.text = @"00:30";
                break;
                
            case 3:
                self.timeLabel.text = @"00:45";
                break;
                
            case 4:
                self.timeLabel.text = @"01:00";
                break;
                
            case 5:
                self.timeLabel.text = @"01:15";
                break;
                
            case 6:
                self.timeLabel.text = @"01:30";
                break;
                
            case 7:
                self.timeLabel.text = @"01:45";
                break;
                
            case 8:
                self.timeLabel.text = @"02:00";
                break;
                
            case 9:
                self.timeLabel.text = @"02:15";
                break;
                
            case 10:
                self.timeLabel.text = @"02:30";
                break;
                
            case 11:
                self.timeLabel.text = @"02:45";
                break;
                
            case 12:
                self.timeLabel.text = @"03:00";
                break;
                
            case 13:
                self.timeLabel.text = @"03:15";
                break;
                
            case 14:
                self.timeLabel.text = @"03:30";
                break;
                
            case 15:
                self.timeLabel.text = @"03:45";
                break;
                
            case 16:
                self.timeLabel.text = @"04:00";
                break;
                
            case 17:
                self.timeLabel.text = @"04:15";
                break;
                
            case 18:
                self.timeLabel.text = @"04:30";
                break;
                
            case 19:
                self.timeLabel.text = @"04:45";
                break;
                
            case 20:
                self.timeLabel.text = @"05:00";
                break;
                
            case 21:
                self.timeLabel.text = @"05:15";
                break;
                
            case 22:
                self.timeLabel.text = @"05:30";
                break;
                
            case 23:
                self.timeLabel.text = @"05:45";
                break;
                
            case 24:
                self.timeLabel.text = @"06:00";
                break;
                
            case 25:
                self.timeLabel.text = @"06:15";
                break;
                
            case 26:
                self.timeLabel.text = @"06:30";
                break;
                
            case 27:
                self.timeLabel.text = @"06:45";
                break;
                
            case 28:
                self.timeLabel.text = @"07:00";
                break;
                
            case 29:
                self.timeLabel.text = @"07:15";
                break;
                
            case 30:
                self.timeLabel.text = @"07:30";
                break;
                
            case 31:
                self.timeLabel.text = @"07:45";
                break;
                
            case 32:
                self.timeLabel.text = @"08:00";
                break;
                
            case 33:
                self.timeLabel.text = @"08:15";
                break;
                
            case 34:
                self.timeLabel.text = @"08:30";
                break;
                
            case 35:
                self.timeLabel.text = @"08:45";
                break;
                
            case 36:
                self.timeLabel.text = @"09:00";
                break;
                
            case 37:
                self.timeLabel.text = @"09:15";
                break;
                
            case 38:
                self.timeLabel.text = @"09:30";
                break;
                
            case 39:
                self.timeLabel.text = @"09:45";
                break;
                
            case 40:
                self.timeLabel.text = @"10:00";
                break;
                
            case 41:
                self.timeLabel.text = @"10:15";
                break;
                
            case 42:
                self.timeLabel.text = @"10:30";
                break;
                
            case 43:
                self.timeLabel.text = @"10:45";
                break;
                
            case 44:
                self.timeLabel.text = @"11:00";
                break;
                
            case 45:
                self.timeLabel.text = @"11:15";
                break;
                
            case 46:
                self.timeLabel.text = @"11:30";
                break;
                
            case 47:
                self.timeLabel.text = @"11:45";
                break;
                
            case 48:
                self.timeLabel.text = @"12:00";
                break;
                
            case 49:
                self.timeLabel.text = @"12:15";
                break;
                
            case 50:
                self.timeLabel.text = @"12:30";
                break;
                
            case 51:
                self.timeLabel.text = @"12:45";
                break;
                
            case 52:
                self.timeLabel.text = @"13:00";
                break;
                
            case 53:
                self.timeLabel.text = @"13:15";
                break;
                
            case 54:
                self.timeLabel.text = @"13:30";
                break;
                
            case 55:
                self.timeLabel.text = @"13:45";
                break;
                
            case 56:
                self.timeLabel.text = @"14:00";
                break;
                
            case 57:
                self.timeLabel.text = @"14:15";
                break;
                
            case 58:
                self.timeLabel.text = @"14:30";
                break;
                
            case 59:
                self.timeLabel.text = @"14:45";
                break;
                
            case 60:
                self.timeLabel.text = @"15:00";
                break;
                
            case 61:
                self.timeLabel.text = @"15:15";
                break;
                
            case 62:
                self.timeLabel.text = @"15:30";
                break;
                
            case 63:
                self.timeLabel.text = @"15:45";
                break;
                
            case 64:
                self.timeLabel.text = @"16:00";
                break;
                
            case 65:
                self.timeLabel.text = @"16:15";
                break;
                
            case 66:
                self.timeLabel.text = @"16:30";
                break;
                
            case 67:
                self.timeLabel.text = @"16:45";
                break;
                
            case 68:
                self.timeLabel.text = @"17:00";
                break;
                
            case 69:
                self.timeLabel.text = @"17:15";
                break;
                
            case 70:
                self.timeLabel.text = @"17:30";
                break;
                
            case 71:
                self.timeLabel.text = @"17:45";
                break;
                
            case 72:
                self.timeLabel.text = @"18:00";
                break;
                
            case 73:
                self.timeLabel.text = @"18:15";
                break;
                
            case 74:
                self.timeLabel.text = @"18:30";
                break;
                
            case 75:
                self.timeLabel.text = @"18:45";
                break;
                
            case 76:
                self.timeLabel.text = @"19:00";
                break;
                
            case 77:
                self.timeLabel.text = @"19:15";
                break;
                
            case 78:
                self.timeLabel.text = @"19:30";
                break;
                
            case 79:
                self.timeLabel.text = @"19:45";
                break;
                
            case 80:
                self.timeLabel.text = @"20:00";
                break;
                
            case 81:
                self.timeLabel.text = @"20:15";
                break;
                
            case 82:
                self.timeLabel.text = @"20:30";
                break;
                
            case 83:
                self.timeLabel.text = @"20:45";
                break;
                
            case 84:
                self.timeLabel.text = @"21:00";
                break;
                
            case 85:
                self.timeLabel.text = @"21:15";
                break;
                
            case 86:
                self.timeLabel.text = @"21:30";
                break;
                
            case 87:
                self.timeLabel.text = @"21:45";
                break;
                
            case 88:
                self.timeLabel.text = @"22:00";
                break;
                
            case 89:
                self.timeLabel.text = @"22:15";
                break;
                
            case 90:
                self.timeLabel.text = @"22:30";
                break;
                
            case 91:
                self.timeLabel.text = @"22:45";
                break;
                
            case 92:
                self.timeLabel.text = @"23:00";
                break;
                
            case 93:
                self.timeLabel.text = @"23:15";
                break;
                
            case 94:
                self.timeLabel.text = @"23:30";
                break;
                
            case 95:
                self.timeLabel.text = @"23:45";
                break;
                
            case 96:
                self.timeLabel.text = @"23:55";
                break;

                
                
            default:
                break;
        }
    }
}

- (void)setMorningNightLabelState:(MonringNightLabelState)state animated:(BOOL)animated
{
    
    [UIView transitionWithView:self.morningNightLabel
                      duration:1.0
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        switch (state)
                        {
                            case MorningNightLabelStateAM:
                            {
                                self.morningNightLabel.text = @"AM";
                                
                            }
                                break;
                            case MorningNightLabelStatePM:
                            {
                                self.morningNightLabel.text = @"PM";
                            }
                                break;
                        }
                    }
                    completion:^(BOOL finished) {}];
    
}

@end

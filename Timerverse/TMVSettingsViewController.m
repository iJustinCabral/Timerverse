//
//  TMVSettingsViewController.m
//  Timerverse
//
//  Created by Larry Ryan on 2/1/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVSettingsViewController.h"
#import "TMVSwitchCell.h"

@import MessageUI;

#define IS_IPHONE_5 ([[UIScreen mainScreen] bounds].size.height >= 568)
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

static BOOL const kUseItemColors = YES;
static NSInteger const kAppStoreID = 836717526;

typedef NS_ENUM (NSUInteger, CellSection)
{
    CellSectionGeneral,
    CellSectionMisc
};

typedef NS_ENUM (NSUInteger, SectionGeneral)
{
    SectionGeneralVibration,
    SectionGeneralGridLock
};

typedef NS_ENUM (NSUInteger, SectionMisc)
{
    SectionMiscRateApp,
    SectionMiscShareApp,
    SectionMiscFeatureRequest,
    SectionMiscRemoveAds,
    SectionMiscRestorePurchases
};

typedef NS_ENUM (NSUInteger, PanDirection)
{
    PanDirectionUp,
    PanDirectionRight,
    PanDirectionDown,
    PanDirectionLeft
};

@interface TMVSettingsViewController () <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UIGestureRecognizerDelegate, UICollisionBehaviorDelegate, MFMailComposeViewControllerDelegate>



@property (nonatomic) UILabel *settingsLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation TMVSettingsViewController


#pragma mark - Lifecycle -

+ (instancetype)sharedSettings
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UILabel *)settingsLabel
{
    if (!_settingsLabel)
    {
        _settingsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 300, 30)];
        _settingsLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:40.0f];
        _settingsLabel.adjustsFontSizeToFitWidth = YES;
        _settingsLabel.minimumScaleFactor = 0.1f;
        
        _settingsLabel.textColor = [UIColor timerversePurple];
        _settingsLabel.text = NSLocalizedString(@"Settings", Settings);
        
        [_settingsLabel sizeToFit];
    }
    
    return _settingsLabel;
}

- (void)displayNoEmailAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Email", NoEmail)
                                                    message:NSLocalizedString(@"Looks like your device hasn't been setup for sending email. You may contact us at support@thinkr.us", NoEmailMessage)
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    
    [alert show];
}


#pragma mark - Helpers -

- (UIColor *)colorForSection:(NSUInteger)section
{
    if (AppContainer.atmosphere.state == TMVAtmosphereStateDay) return AppContainer.atmosphere.currentColor;
    
    if (AppContainer.itemManager.itemViewArray.count > section && kUseItemColors)
    {
        return [AppContainer.itemManager.itemViewArray[section] apparentColor];
    }
    else
    {
        switch (section)
        {
            case 0:
            {
                return [UIColor timerversePurple];
            }
                break;
            case 1:
            {
                return [UIColor timerverseLightBlue];
            }
                break;
            case 2:
            {
                return [UIColor timerverseGreen];
            }
                break;
            case 3:
            {
                return [UIColor timerverseOrange];
            }
                break;
            default:
                return [UIColor whiteColor];
                break;
        }
    }
}

- (NSNumber *)shouldEnableSettingForSwitch:(UISwitch *)cellSwitch
{
    return [NSNumber numberWithBool:cellSwitch.isOn ? YES : NO];
}

- (NSUInteger)tagForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section = (indexPath.section + 1) * 10;
    NSUInteger row = indexPath.row * 1;
    
    return section + row;
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


#pragma mark - Settings Accessors -

// Alerts
- (BOOL)alertVibrationEnabled
{
    return DataManager.settings.alertVibrationEnabled.boolValue;
}

// Effects
- (BOOL)effectGridLockEnabled
{
    return DataManager.settings.effectGridLockEnabled.boolValue;
}

// Clock
- (BOOL)clockSecondsEnabled
{
    return DataManager.settings.clockSecondsEnabled.boolValue;
}


#pragma mark - Mail Composer Delegate -

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES
                                   completion:^{
                                       
                                   }];
}


#pragma mark - UITableView -

- (void)configureTableView
{
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.sectionFooterHeight = 0.0f;
    
    [self.tableView registerClass:[TMVSwitchCell class] forCellReuseIdentifier:@"SwitchCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DisclosureCell"];
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;
    
    switch (indexPath.section)
    {
        case CellSectionMisc:
        {
            switch (indexPath.row)
            {
                case SectionMiscRateApp:
                {
                    // Send to App Store
                    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%ld?mt=8", (long)kAppStoreID];
                    NSURL *url = [NSURL URLWithString:urlString];
                    
                    [[UIApplication sharedApplication] openURL:url];
                }
                    break;
                case SectionMiscShareApp:
                {
                    // Share Sheet
                    NSString *shareString = NSLocalizedString(@"Check out timerverse! It's a timer app that's out of this world.", ShareApp);
                    
                    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%ld?mt=8", (long)kAppStoreID];
                    NSURL *shareURL = [NSURL URLWithString:urlString];
                    
                    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[shareString, shareURL] applicationActivities:nil];
                    vc.excludedActivityTypes = @[UIActivityTypeAddToReadingList, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll];
                    
                    [AppContainer presentViewController:vc animated:YES completion:nil];
                }
                    break;
                case SectionMiscFeatureRequest:
                {
                    // Bring up Mail Composer
                    if ([MFMailComposeViewController canSendMail])
                    {
                        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
                        mailer.mailComposeDelegate = self;
                        [mailer setSubject:NSLocalizedString(@"I have a ", FeatureRequestSubject)];
                        NSArray *toRecipients = [NSArray arrayWithObjects:@"support@thinkr.us",nil];
                        [mailer setToRecipients:toRecipients];
                        NSString *emailBody = NSLocalizedString(@"I have a ", FeatureRequestBody);
                        [mailer setMessageBody:emailBody isHTML:NO];
                        
                        [AppContainer presentViewController:mailer
                                           animated:YES
                                         completion:^{}];
                    }
                    else
                    {
                        [self displayNoEmailAlert];
                    }
                }
                    break;
                case SectionMiscRemoveAds:
                {
                    [IAPManager buyProduct:IAPManager.productArray.firstObject];
                }
                    break;
                case SectionMiscRestorePurchases:
                {
                    [IAPManager restoreCompletedTransactions];
                    
                    for (TMVItemView *itemView in AppContainer.itemManager.itemViewArray)
                    {
                        if (itemView.state == TMVItemViewStateLocked)
                        {
                            [itemView showActivityIndicatorAnimated:YES];
                        }
                    }
                    
                    [SettingsContainerController hideSettingsAnimated];
                }
                    break;
            }
        }
            break;
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case CellSectionGeneral:
        {
            return 2;
        }
            break;
        case CellSectionMisc:
        {
            return IAPManager.isPurchased ? 3 : 5;
        }
            break;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    switch (indexPath.section)
    {
        case CellSectionGeneral:
        {
            switch (indexPath.row)
            {
                case SectionGeneralVibration:
                case SectionGeneralGridLock:
                {
                    TMVSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell" forIndexPath:indexPath];
                    [self configureSwitchCell:(TMVSwitchCell *)cell forRowAtIndexPath:indexPath];
                    
                    return cell;
                }
                    break;
            }
        }
        case CellSectionMisc:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DisclosureCell" forIndexPath:indexPath];
            [self configureDisclosureCell:cell forRowAtIndexPath:indexPath];
            
            return cell;
        }
            break;
    }
    
    return cell;
}

- (void)configureDisclosureCell:(UITableViewCell *)cell
              forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    cell.textLabel.highlightedTextColor = [UIColor timerversePurple];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumScaleFactor = 0.1f;
    cell.backgroundColor = [UIColor clearColor];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    UIView *view = [[UIView alloc] initWithFrame:cell.frame];
    view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.1f];
    
    cell.selectedBackgroundView = view;
    
    UIImageView *disclousreImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"disclosureArrow"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    disclousreImageView.frame = CGRectMake(0, 0, 8, 15.5);
    disclousreImageView.contentMode = UIViewContentModeScaleAspectFit;
    disclousreImageView.tintColor = [UIColor whiteColor];
    cell.accessoryView = disclousreImageView;
    
    switch (indexPath.section)
    {
        case CellSectionMisc:
            switch (indexPath.row)
        {
            case SectionMiscRateApp:
            {
                cell.textLabel.text = NSLocalizedString(@"Rate", Rate);
            }
                break;
            case SectionMiscShareApp:
            {
                cell.textLabel.text = NSLocalizedString(@"Share", Share);
            }
                break;
            case SectionMiscFeatureRequest:
            {
                cell.textLabel.text = NSLocalizedString(@"Report / Request", FeatureRequest);
            }
                break;
            case SectionMiscRemoveAds:
            {
                //!!! update localization
                cell.textLabel.text = NSLocalizedString(@"Remove Ads", RemoveAds);
            }
                break;
            case SectionMiscRestorePurchases:
            {
                cell.textLabel.text = NSLocalizedString(@"Restore Purchases", RestorePurchases);
            }
                break;
        }
            break;
    }
}

- (void)configureSwitchCell:(TMVSwitchCell *)cell
          forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.textColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumScaleFactor = 0.1f;
    cell.cellSwitch.onTintColor = [UIColor timerversePurple];
    cell.cellSwitch.tag = [self tagForIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    [cell.cellSwitch addTarget:self
                        action:@selector(cellSwitchAction:)
              forControlEvents:UIControlEventValueChanged];
    
    switch (indexPath.section)
    {
        case CellSectionGeneral:
        {
            switch (indexPath.row)
            {
                case SectionGeneralVibration:
                {
                    cell.textLabel.text = NSLocalizedString(@"Vibration", Vibration);
                    cell.cellSwitch.on = DataManager.settings.alertVibrationEnabled.boolValue;
                }
                    break;
                case SectionGeneralGridLock:
                {
                    cell.textLabel.text = NSLocalizedString(@"Grid Lock", GridLock);
                    cell.cellSwitch.on = DataManager.settings.effectGridLockEnabled.boolValue;
                }
                    break;
            }
        }
            break;
            
        default:
            break;
    }
    
    [cell.textLabel sizeToFit];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return IS_IPHONE_5 ? 62.0f : 52.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section != 0) return 1.0f;
    
    return IS_IPHONE_5 ? 100.0f : 80.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
        {
            CGFloat height = IS_IPHONE_5 ? 100.0f : 80.0f;
            
            UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, height)];
            
            self.settingsLabel.center = containerView.center;
            [containerView addSubview:self.settingsLabel];
            
            UIView *lineView = [self lineViewForSection:0];
            lineView.y = containerView.bottom - lineView.height;
            
            [containerView addSubview:lineView];
            
            return containerView;
        }
            break;
        case 1:
        default:
        {
            UIView *lineView = [self lineViewForSection:0];
            
            return lineView;
        }
            break;
    }
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(6_0)
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    cell.accessoryView.tintColor = [UIColor timerversePurple];
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(6_0)
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    cell.accessoryView.tintColor = [UIColor whiteColor];
}


#pragma mark - Actions -

- (void)showPurchaseCells:(BOOL)show
                 animated:(BOOL)animated
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:CellSectionMisc]
                  withRowAnimation:UITableViewRowAnimationFade];
}

- (void)cellSwitchAction:(UISwitch *)cellSwitch
{
    switch (cellSwitch.tag)
    {
        case 10: // Vibration
        {
            DataManager.settings.alertVibrationEnabled = [self shouldEnableSettingForSwitch:cellSwitch];
        }
            break;
        case 11: // Dynamics
        {
            DataManager.settings.effectGridLockEnabled = [self shouldEnableSettingForSwitch:cellSwitch];
            
            AppContainer.itemManager.layout = DataManager.settings.effectGridLockEnabled.boolValue ? TMVItemManagerLayoutGridLock : TMVItemManagerLayoutDynamics;
        }
            break;
    }
    
    [DataManager saveContext];
}

@end

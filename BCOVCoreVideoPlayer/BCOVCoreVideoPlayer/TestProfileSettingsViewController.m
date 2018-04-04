//
//  TestProfileSettingsViewController.m
//  BCOVCoreVideoPlayer
//
//  Created by Bill Sahlas on 9/21/17.
//  Copyright © 2017 Brightcove. All rights reserved.
//

@import AVFoundation;

#import "TestProfileSettingsViewController.h"
#import "VideoViewController.h"
#import "PlayListViewController.h"

TestProfileSettingsViewController *gTestProfileSettingsViewController;

@interface TestProfileSettingsViewController ()
{

}

// IBOutlets for UI elements
@property (weak, nonatomic) IBOutlet UISegmentedControl *environmentSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *securityLevelSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *deliveryTypeSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *adTypeSegmentedControl;
@property (weak, nonatomic) IBOutlet UISwitch *useAdsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *seekWithoutAdsSwitch;
@property (weak, nonatomic) IBOutlet UITextField *seekTimeTextField;
@property (weak, nonatomic) IBOutlet UIPickerView *adsDataPicker;
@property (weak, nonatomic) IBOutlet UIPickerView *playlistPicker;
@property (weak, nonatomic) IBOutlet UILabel *accountNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *pickerValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *pickerKeyNameLabel;

@end

@implementation TestProfileSettingsViewController

// Returns the environment to run in
- (NSString *)environmentOptionSelection
{
    NSInteger selectedSegment = self.environmentSegmentedControl.selectedSegmentIndex;
    // Set the default to 'Production'
    if (self.environmentSegmentedControl == nil)
    {
        self.currentEnvironmentSelection = kEnvironmentProduction;
    }
    if(selectedSegment==0)
    {
        self.currentEnvironmentSelection = kEnvironmentProduction;
    }
    else if(selectedSegment==1)
    {
        self.currentEnvironmentSelection = kEnvironmentStaging;
    }
    else
    {
        self.currentEnvironmentSelection = kEnvironmentQa;
    }
    return self.currentEnvironmentSelection;
}

// Returns the security level to use
- (NSString *)securityLevelOptionSelection
{
    NSInteger selectedSegment = self.securityLevelSegmentedControl.selectedSegmentIndex;
    // Set the default to 'Clear'
    if (self.securityLevelSegmentedControl == nil)
    {
        self.currentSecurityLevelSelection = kSecurityLevelClear;
    }
    if(selectedSegment==0)
    {
        self.currentSecurityLevelSelection = kSecurityLevelClear;
    }
    else if(selectedSegment==1)
    {
        self.currentSecurityLevelSelection = kSecurityLevelDrm;
    }
    else
    {
        self.currentSecurityLevelSelection = kSecurityLevelHlse;
    }
    return self.currentSecurityLevelSelection;
}

// Returns the delivery type to use
- (NSString *)deliveryTypeOptionSelection
{
    NSInteger selectedSegment = self.deliveryTypeSegmentedControl.selectedSegmentIndex;
    if(selectedSegment==0)
    {
        self.currentDeliveryTypeSelection = kDeliveryTypeDynamicDelivery;
    }
    else if(selectedSegment==1)
    {
        self.currentDeliveryTypeSelection = kDeliveryTypeVideoCloud;
    }
    else if(selectedSegment==2)
    {
        self.currentDeliveryTypeSelection = kDeliveryTypeCAE;
    }
    else
    {
        // Set the default to 'Dynamic Delivery'
        self.currentDeliveryTypeSelection =  kDeliveryTypeDynamicDelivery;
    }
    NSLog(@"currentDeliveryTypeSelection: %@", self.currentDeliveryTypeSelection);
    return self.currentDeliveryTypeSelection;
}

NSArray * playlistArray;
NSArray * pickerDataKVPairsArray;
NSString * dataKey;
NSString * dataValue;

// Returns the ad type to use
- (NSString *)selectedAdType
{
    if (self.adTypeSegmentedControl == nil)
    {
        // methods that interact with this don't like nil so set to empty string by default
        self.currentAdTypeSelection = @"";
    }
    if(self.adTypeSegmentedControl.isEnabled && self.adTypeSegmentedControl.selectedSegmentIndex == 0)
    {
        self.currentAdTypeSelection = kAdTypeSsai;
        dataKey = @"adConfigName";
        dataValue = @"adConfigId";
    }
    else if(self.adTypeSegmentedControl.isEnabled && self.adTypeSegmentedControl.selectedSegmentIndex == 1)
    {
        self.currentAdTypeSelection = kAdTypeOux;
        dataKey = @"ouxAssetName";
        dataValue = @"ouxAssetUrl";
    }
    else
    {
        self.currentAdTypeSelection = @"";
        dataKey = @"";
        dataValue = @"";
    }
    return self.currentAdTypeSelection;
}

#pragma mark picker data and other datasources
-(void) createAdConfigData
{
    // Connect testProfile data
    self.adsDataPicker.dataSource = self;
    self.adsDataPicker.delegate = self;
    [self.adsDataPicker reloadAllComponents];
    // Manually calls didSelectRow:inComponent: when first created
    [self pickerView: self.adsDataPicker didSelectRow:0 inComponent:0];
}

-(void) createPlaylistData
{
    self.playlistPicker.dataSource = self;
    self.playlistPicker.delegate = self;
    [self.playlistPicker reloadAllComponents];
    // Manually calls didSelectRow:inComponent: when first created
    [self pickerView: self.adsDataPicker didSelectRow:0 inComponent:0];
}

-(void) destroyAdConfigData
{
    // Disconnect testProfile data
    self.adsDataPicker.dataSource = nil;
    self.adsDataPicker.delegate = nil;
    self.selectedPickerDataValue = @"";
    self.selectedPickerDataName = @"";
    self.pickerKeyNameLabel.text = @"";
    self.pickerValueLabel.text = @"";
    [self.adsDataPicker reloadAllComponents];
}

-(void) resetDataSources
{
    self.initialTestProfile = nil;
    self.accountNameLabel.text = @"";
    [self createTestProfile];
    [self createPlaylistData];

    if(self.adTypeSegmentedControl.enabled == YES)
    {
        [self createAdConfigData];
    }
    else
    {
        [self destroyAdConfigData];
    }
}

-(TestProfileManager *) createTestProfile
{
    NSDictionary *profileRequirements = @{
                                          @"kEnvironment" : [self environmentOptionSelection],
                                          @"kSecurityLevel" : [self securityLevelOptionSelection],
                                          @"kDeliveryType" : [self deliveryTypeOptionSelection],
                                          @"kAdType" : [self selectedAdType]
                                          };
    self.initialTestProfile = [[[TestProfileManager alloc]init]createTestProfile: profileRequirements];
    self.accountNameLabel.text = self.initialTestProfile.accountDescription;
    playlistArray = self.initialTestProfile.playlistPickerDataArray;
    // Reset the datasource of the Ads picker
    if([profileRequirements[@"kAdType"] isEqualToString:kAdTypeOux])
    {
        pickerDataKVPairsArray = self.initialTestProfile.ouxPickerDataArray;
    }
    else if([profileRequirements[@"kAdType"] isEqualToString:kAdTypeSsai])
    {
        pickerDataKVPairsArray = self.initialTestProfile.ssaiPickerDataArray;
    }
    else
    {
        pickerDataKVPairsArray = self.initialTestProfile.ssaiPickerDataArray;
    }
    return self.initialTestProfile;
}

-(TestProfileManager *) getCurrentTestProfile
{
    // get the currently selected info
    if(!self.selectedPlaylistDescription)
    {
        // Be sure that a row is selected when for the account profile
        [self pickerView:self.playlistPicker didSelectRow:0 inComponent:0];
    }
    return self.initialTestProfile;
}

- (IBAction)doEnvironmentTypeSwitch:(id)switchControl
{
    [self resetDataSources];
}
- (IBAction)doSecurityTypeSwitch:(id)switchControl
{
    [self resetDataSources];
}
- (IBAction)doDeliveryTypeSwitch:(id)switchControl
{
    [self resetDataSources];
}
- (IBAction)doAdTypeSwitch:(id)switchControl
{
    [self resetDataSources];
}

- (IBAction)doEnableAdsSwitch:(UISwitch *)switchControl
{
    if(switchControl.on)
    {
        self.adTypeSegmentedControl.enabled = YES;
        self.seekWithoutAdsSwitch.enabled = YES;
        [self resetDataSources];
    }
    else
    {
        self.adTypeSegmentedControl.enabled = NO;
        self.seekWithoutAdsSwitch.enabled = NO;
        self.seekWithoutAdsSwitch.on = NO;
        self.seekTimeTextField.enabled = NO;
        self.seekTimeTextField.text = @"0";
        [self destroyAdConfigData];
    }
}

- (IBAction)doSeekWithoutAdsSwitch:(UISwitch *)switchControl
{
    if(switchControl.on)
    {
        self.seekTimeTextField.enabled = YES;
    }
    else
    {
        self.seekTimeTextField.enabled = NO;
        self.seekTimeTextField.text = @"0";
    }
}

- (long long int)seekTime
{
    if (self.seekTimeTextField == nil)
    {
        return 0;
    }
    
    long long int seekTime = self.seekTimeTextField.text.longLongValue;
    
    return seekTime;
}

#pragma initialization methods
-(void) setup
{
    // Create and initialize the Test Profile
    [self createTestProfile];
    [self createPlaylistData];
    // tag the different pickers
    self.adsDataPicker.tag = 0;
    self.playlistPicker.tag = 1;
    
    [self.useAdsSwitch addTarget:self
                          action:@selector(doEnableAdsSwitch:)
                forControlEvents:UIControlEventValueChanged];
    
    [self.environmentSegmentedControl addTarget:self
                                          action:@selector(doEnvironmentTypeSwitch:)
                                forControlEvents:UIControlEventValueChanged];
    
    [self.securityLevelSegmentedControl addTarget:self
                          action:@selector(doSecurityTypeSwitch:)
                forControlEvents:UIControlEventValueChanged];
    
    [self.deliveryTypeSegmentedControl addTarget:self
                        action:@selector(doDeliveryTypeSwitch:)
                forControlEvents:UIControlEventValueChanged];
    
    [self.adTypeSegmentedControl addTarget:self
                        action:@selector(doAdTypeSwitch:)
                                forControlEvents:UIControlEventValueChanged];
    
    [self.seekWithoutAdsSwitch addTarget:self
                                  action:@selector(doSeekWithoutAdsSwitch:)
                forControlEvents:UIControlEventValueChanged];

}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder;
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        gTestProfileSettingsViewController = self;
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tabBarController.delegate = self;
    
}

- (UIInterfaceOrientationMask)tabBarControllerSupportedInterfaceOrientations:(UITabBarController *)tabBarController
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    gTestProfileSettingsViewController = self;
    self.tabBarController = (UITabBarController*)self.parentViewController;
    [self setup];
    // Keyboard control and gestures
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"gTestProfileSettingsViewController.tabBarController.selectedIndex %d",(int) gTestProfileSettingsViewController.tabBarController.selectedIndex);

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

#pragma mark UIPickerView delegate methods

- (long)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    // adType data
    if(pickerView.tag == 0)
    {
        return pickerDataKVPairsArray.count;
    }
    else
    {
        return playlistArray.count;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    // adType data
    if(pickerView.tag == 0)
    {
        return pickerDataKVPairsArray[row][dataKey];
    }
    else
    {
        return playlistArray[row][@"playlistRefId"];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // adType data
    if(pickerView.tag == 0)
    {
        self.selectedPickerDataValue = pickerDataKVPairsArray[row][dataValue];
        self.selectedPickerDataName = pickerDataKVPairsArray[row][dataKey];
        self.pickerValueLabel.text = self.selectedPickerDataValue;
        self.pickerKeyNameLabel.text = self.selectedPickerDataName;
    }
    // playlist data
    else
    {
        self.selectedPlaylistRefId = playlistArray[row][@"playlistRefId"];
        self.selectedPlaylistDescription = playlistArray[row][@"playlistDescription"];
        NSLog(@"plist_refId %@, plist_description %@", self.selectedPlaylistRefId, self.selectedPlaylistDescription);
    }
}

-(void)dismissKeyboard
{
    [self.seekTimeTextField resignFirstResponder];
}

#pragma mark navigation methods

- (BOOL)tabBarController:(UITabBarController *)tabBarController
shouldSelectViewController:(UIViewController *)viewController
{
    // Do not allow going from the TestProfileSettingsViewController to VideoViewController
    if ([viewController isKindOfClass:[VideoViewController class]])
    {
        NSLog(@"Prevent going directly to VideoViewController from TestProfileSettingsViewController.");
        return NO;
    }
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController
{
    // Need a flag or something that let's the PlayListViewController know to reset the playlist
    NSLog(@"didSelectViewController PlayListViewController from TestProfileSettingsViewController.");
    if ([viewController isKindOfClass:[PlayListViewController class]])
    {
        gPlayListViewController.resetTestProfileAndPlaylist = (BOOL *) YES;
    }
    else
    {
        gPlayListViewController.resetTestProfileAndPlaylist = nil;
    }
}
@end


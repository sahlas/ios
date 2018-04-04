//
//  PlayerSettingsViewController.m
//  BCOVCoreVideoPlayer
//
//  Created by Bill Sahlas on 9/21/17.
//  Copyright © 2017 Brightcove. All rights reserved.
//

@import AVFoundation;

#import "PlayListViewController.h"
#import "TestProfileManager.h"
#import "TestProfileSettingsViewController.h"

PlayListViewController *gPlayListViewController;

@interface PlayListViewController()

// IBOutlets for our UI elements
@property (weak, nonatomic) IBOutlet UIView *pickerBoxView;
@property (weak, nonatomic) IBOutlet UILabel *playlistTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *playlistRefIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *accountIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *environmentLabel;
@property (weak, nonatomic) IBOutlet UILabel *securityLevelLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoRefIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *accountNameLabel;

// Keep track of info from the playlist for easy display in the table
@property (nonatomic, strong) NSString *currentPlaylistTitle;
@property (nonatomic, strong) NSString *currentPlaylistReferenceId;
@property (nonatomic, strong) NSMutableArray *videoIdArray;
@property (weak, nonatomic) IBOutlet UISwitch *autoPlaySwitch;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *playlistRequestActivityIndicatorView;

@end

@implementation PlayListViewController 
@synthesize videoPlaylistPickerView;
@synthesize simpleView;
@synthesize videoPlayListData;
@synthesize selectedTitleVideoId;

// Hold on to the profile settings from the TestProfileSettingsViewController
NSDictionary *currentTestProfileConfiguration;
// Create an instance of the TestProfileManager
TestProfileManager *currentTestProfileManager;

#pragma mark Initialization method

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder;
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        gPlayListViewController = self;
    }
    return self;
}

- (UIInterfaceOrientationMask)tabBarControllerSupportedInterfaceOrientations:(UITabBarController *)tabBarController
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)setup
{
    // hide control by default
    self.playlistRequestActivityIndicatorView.hidden = YES;
}

-(NSDictionary *)getProfileRequirements
{
    // Reads the values currently selected from the TestProfileSettingsViewController
    NSDictionary *profileRequirements = @{
                                          @"kEnvironment" : [gTestProfileSettingsViewController environmentOptionSelection],
                                          @"kSecurityLevel" : [gTestProfileSettingsViewController securityLevelOptionSelection],
                                          @"kDeliveryType" : [gTestProfileSettingsViewController deliveryTypeOptionSelection],
                                          @"kAdType" : [gTestProfileSettingsViewController selectedAdType]
                                          };
    return profileRequirements;
}


/*!
 @brief This method creates an instance of TestProfileManager. The return from getProfileRequirements is an NSDictionary that contains the default
 Environment, SecurityLevel, DeliveryType & AdType
 */
-(void)createTestProfileConfiguration
{
    // Pull the default requirements from the TestProfileSettingsViewControl controls
    currentTestProfileConfiguration = self.getProfileRequirements;
    
    // initialize and call the createTestProfile method using the default requirements
    currentTestProfileManager = [[[TestProfileManager alloc]init]createTestProfile: currentTestProfileConfiguration];
    self.accountIdLabel.text = currentTestProfileManager.accountId;
    self.accountNameLabel.text = currentTestProfileManager.accountDescription;
    self.environmentLabel.text = currentTestProfileManager.environment;
    self.securityLevelLabel.text = currentTestProfileManager.securityLevel;
    return;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //    self.view.backgroundColor = [UIColor yellowColor];
    // Become delegate so we can control orientation
    gPlayListViewController.tabBarController.delegate = self;
    // Create a dictionary to hold video metadata
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    gPlayListViewController = self;
    self.tabBarController = (UITabBarController*)self.parentViewController;
    [self setup];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(gPlayListViewController.resetTestProfileAndPlaylist)
    {
        [self doCreateTestProfileWithPlaylist:self];
        // reset flag
        gPlayListViewController.resetTestProfileAndPlaylist = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

// Creates a Test Profile based on current (or default) settings
// and retrieves a playlist.  The playlist
- (IBAction)doCreateTestProfileWithPlaylist:(id)sender
{
    [self resetLabels];
    [self.videoPlaylistPickerView removeFromSuperview];
    self.videoPlayListData = nil;
    self.videoPlayListData = [[NSMutableDictionary alloc] init];
    [self createTestProfileConfiguration];
    [self retrievePlaylist];
    self.isPresentedFromPlayListViewController = YES;
    [self.videoPlaylistPickerView reloadAllComponents];
}

-(void) resetLabels
{
    self.accountNameLabel.text = nil;
    self.accountIdLabel.text = nil;
    self.environmentLabel.text = nil;
    self.securityLevelLabel.text = nil;
    self.videoNameLabel.text = nil;
    self.videoRefIdLabel.text = nil;
    self.videoIdLabel.text = nil;
}

- (IBAction)doAutoPlaySwitch:(UISwitch *)switchControl
{
    self.autoPlay = (BOOL *)switchControl.on;
}

- (IBAction)doAutoAdvanceSwitch:(UISwitch *)switchControl
{
    self.autoAdvance = (BOOL *)switchControl.on;
}

- (IBAction)doExternalPlaybackSwitch:(UISwitch *)switchControl
{
    self.enableExternalPlayback = (BOOL *)switchControl.on;
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}
-(void)retrievePlaylist
{
    self.playlistRequestActivityIndicatorView.hidden = NO;
    self.playlistRequestActivityIndicatorView.hidesWhenStopped = YES;
    [self.playlistRequestActivityIndicatorView startAnimating];
    
    NSDictionary *queryParameters = @{
                                      @"limit" : @(100), // make sure we get a lot of videos
                                      @"offset" :@(0)
                                      };
    NSString * playlistRefId;
    
    // Retrieve a playlist through the BCOVPlaybackService
    BCOVPlaybackServiceRequestFactory *playbackServiceRequestFactory = [[BCOVPlaybackServiceRequestFactory alloc] initWithAccountId:currentTestProfileManager.accountId
                                                                                                        policyKey:currentTestProfileManager.policyKey];
    BCOVPlaybackService *playbackService = [[BCOVPlaybackService alloc] initWithRequestFactory:playbackServiceRequestFactory];
    
    
    if(gTestProfileSettingsViewController.selectedPlaylistRefId)
    {
        playlistRefId = gTestProfileSettingsViewController.selectedPlaylistRefId;
    }
    else
    {
        playlistRefId = currentTestProfileManager.defaultPlaylistRefId;
    }
    
    [playbackService findPlaylistWithReferenceID:playlistRefId
                                      parameters:queryParameters
                                      completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error)
     {
         if (playlist)
         {
             
             self.currentPlaylistTitle = playlist.properties[@"name"];
             self.currentPlaylistReferenceId = playlist.properties[@"reference_id"];
             self.playlistTitleLabel.text = self.currentPlaylistTitle;
             self.playlistRefIDLabel.text = self.currentPlaylistReferenceId;
             // Pull information from each video and store it
             for (BCOVVideo *video in playlist)
             {
                 // make the videoId the key and store the entire video object for referencing
                 [self.videoPlayListData  setObject:video.properties forKey:video.properties[@"id"]];
             }
             // Create a UIPickerView for the videoPlayListData (includes all the videos in the playlist)
             [self createVideoPlaylistPickerView];
             NSLog(@"testProfileManagerr.defaultPlaylistRefId %@", currentTestProfileManager.defaultPlaylistRefId);
             [self.playlistRequestActivityIndicatorView stopAnimating];
             self.playlistRequestActivityIndicatorView.hidden = YES;
         }
         else
         {
             NSLog(@"An Error has occured attempting to get the playlist %@", error);
         }

     }];
}

-(TestProfileManager *) getCurrentTestProfile
{
    currentTestProfileManager = [[[TestProfileManager alloc]init]createTestProfile: currentTestProfileConfiguration];
    return currentTestProfileManager;
}

/*!
 @brief Create the UIPickerView instance programmatically. We do this in the PlaybackService call back for findPlaylistWithReferenceID and populate it after we get the playlist data from the response.
 */
-(void) createVideoPlaylistPickerView {
    
    // Init the picker view and match the size of the UIView parent
    float pickerBoxWidth = self.pickerBoxView.frame.size.width;
    float pickerBoxHeight = self.pickerBoxView.frame.size.height;
    
    self.videoPlaylistPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0, 0.0, pickerBoxWidth, pickerBoxHeight)];
    self.videoPlaylistPickerView.showsSelectionIndicator = YES;

    // Set the delegate and datasource.
    [self.videoPlaylistPickerView setDataSource: self];
    [self.videoPlaylistPickerView setDelegate: self];

    // Add the picker in our view.
    self.pickerBoxView.layer.borderWidth = 1.5f; //make border 1px thick
    [self.pickerBoxView addSubview: self.videoPlaylistPickerView];

    // Manually calls didSelectRow:inComponent: when first created
    [self pickerView:videoPlaylistPickerView didSelectRow:0 inComponent:0];
}

#pragma mark UIPickerView delegate methods
- (long)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return self.videoPlayListData.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
                      titleForRow:(NSInteger)row
                     forComponent:(NSInteger)component
{
    // Pull out and use the video's name from the properties for this row's video object
    return [self.videoPlayListData allValues][row][@"name" ];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // the video object's id property is the key
    self.selectedTitleVideoId = [self.videoPlayListData allKeys][row];
    // get anyother values here for the video object under test that you'll need to reference later on
    self.selectedTitleVideoName = [self.videoPlayListData allValues][row][@"name"];
    self.selectedVideoRefId = [self.videoPlayListData allValues][row][@"reference_id"];
    self.videoNameLabel.text = self.selectedTitleVideoName;
    self.videoRefIdLabel.text = self.selectedVideoRefId;
    self.videoIdLabel.text = self.selectedTitleVideoId;
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController
shouldSelectViewController:(UIViewController *)viewController
{
    return YES;
}

@end



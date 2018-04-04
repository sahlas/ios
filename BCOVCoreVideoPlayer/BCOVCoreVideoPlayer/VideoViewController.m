//
//  VideoViewController.m
//
//  Created by Bill Sahlas on 9/18/17.
//  Copyright © 2017 Brightcove. All rights reserved.
//

#import "VideoViewController.h"
#import "PlayListViewController.h"
#import "TestProfileSettingsViewController.h"

VideoViewController *gVideoViewController;

// Create an instance of the TestProfileManager
TestProfileManager *testProfileManager;

@interface VideoViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) BCOVPUIPlayerView *playerView;
@property (nonatomic, assign) BOOL playbackControllerConfigured;
@property (nonatomic, strong) IBOutlet UIView *videoContainer;
@property (nonatomic, strong) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIButton *moreVideoDetailsButton;
@property (nonatomic) IBOutlet UILabel *accountNameLabel;
@property (nonatomic) IBOutlet UILabel *currentVideoNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *playlistLabel;

@end

@implementation VideoViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    gVideoViewController.tabBarController.delegate = self;
}

/* The usual parameters to get and play content */
NSString *analyticsSource;
NSString *analyticsDestination;
NSString * adConfigId;


#pragma mark Initialization method

- (void)setup
{
    [self.refreshButton addTarget:self
                           action:@selector(doRefreshButton:)
                 forControlEvents:UIControlEventTouchUpInside];
    [self.moreVideoDetailsButton addTarget:self
                        action:@selector(doMoreButton:)
              forControlEvents:UIControlEventTouchUpInside];
    [self createTestProfile];

}

- (void)configurePlaybackController:(id<BCOVPlaybackController>)playbackController {
    playbackController.delegate = self;
    _playbackController = playbackController;
    _playbackController.analytics.source = @"source://com.brightcove.BCOVCoreVideoPlayer";
    _playbackController.analytics.destination = @"source://com.brightcove.BCOVCoreVideoPlayer";
    _playbackController.analytics.account = testProfileManager.accountId;

    if (!self.playbackControllerConfigured)
    {
        if (self.playerView == nil)
        {
            BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
            options.presentingViewController = self;
            
            BCOVPUIBasicControlView *controlView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
            self.playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil
                                                                            options:options
                                                                       controlsView:controlView ];
            self.playerView.frame = self.videoContainer.bounds;
            self.playerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
            self.playerView.delegate = self;
            [self.videoContainer addSubview:self.playerView];
        }
        self.playerView.playbackController = self.playbackController;
        self.playbackControllerConfigured = YES;
        self.isPresented = YES;
    }
    else
    {
        NSLog(@"The playbackController is already configured, ignoring the call to configure it.");
    }
}

- (void)createPlaybackController
{
    if (!self.playbackController)
    {
        BCOVPlayerSDKManager *sdkManager = [BCOVPlayerSDKManager sharedManager];
        // Create the first link in the session provider chain
        BCOVBasicSessionProviderOptions *options = [[BCOVBasicSessionProviderOptions alloc] init];
        options.sourceSelectionPolicy = [BCOVBasicSourceSelectionPolicy sourceSelectionHLSWithScheme:kBCOVSourceURLSchemeHTTPS];
        id<BCOVPlaybackSessionProvider> bsp = [sdkManager createBasicSessionProviderWithOptions:options];
        id<BCOVPlaybackController> playbackController;
        
        // If OUX testing
        if ([gTestProfileSettingsViewController.selectedAdType isEqualToString: kAdTypeOux])
        {
            id<BCOVPlaybackSessionProvider> osp = [sdkManager createOUXSessionProviderWithUpstreamSessionProvider:bsp];
            // Create the playback controller for OUX and Clear
            playbackController = [sdkManager createPlaybackControllerWithSessionProvider:osp
                                                                            viewStrategy:nil];

        }
        
        // DRM: This section uses FairPlaySessionProvider chained with BasicSessionProviderWithOptions
        else if ([testProfileManager.securityLevel isEqualToString:kSecurityLevelDrm])
        {
            BCOVFPSBrightcoveAuthProxy *proxy = [[BCOVFPSBrightcoveAuthProxy alloc] initWithPublisherId:nil
                                                                                          applicationId:nil];
            id<BCOVPlaybackSessionProvider> fps = [sdkManager createFairPlaySessionProviderWithApplicationCertificate:nil
                                                                                                   authorizationProxy:proxy
                                                                                              upstreamSessionProvider:bsp];
            //SSAI: chain OUX SessionProvider to `fps`
            if(adConfigId)
            {
                id<BCOVPlaybackSessionProvider> osp = [sdkManager createOUXSessionProviderWithUpstreamSessionProvider:fps];
                // Create the playback controller for SSAI and FairPlay
                playbackController = [sdkManager createPlaybackControllerWithSessionProvider:osp
                                                                                viewStrategy:nil];
            }
            // Create the playback controller for FairPlay only
            else
            {
                playbackController = [sdkManager createPlaybackControllerWithSessionProvider:fps
                                                                                viewStrategy:nil];
            }
        }
        // Clear: This section uses the BasicSessionProviderWithOptions
        else
        {
            if(adConfigId)
            {
                id<BCOVPlaybackSessionProvider> osp = [sdkManager createOUXSessionProviderWithUpstreamSessionProvider:bsp];
                // Create the playback controller for SSAI and Clear
                playbackController = [sdkManager createPlaybackControllerWithSessionProvider:osp
                                                                                viewStrategy:nil];
            }
            else
            {
                // Create the playback controller for Basic Session only
                playbackController = [sdkManager createPlaybackControllerWithSessionProvider:bsp
                                                                                viewStrategy:nil];
            }
        }
        // Set the playback controller
        [self configurePlaybackController:playbackController];
    }
    else
    {
        NSLog(@"The playbackController already exists, ignoring the call to create it.");
    }
}

-(void)createTestProfile
{
    testProfileManager = [[TestProfileManager alloc]init];
    testProfileManager = gTestProfileSettingsViewController.getCurrentTestProfile;
    self.accountNameLabel.text = testProfileManager.accountDescription;
    self.playlistLabel.text = gTestProfileSettingsViewController.selectedPlaylistDescription;
    return;
}

static void playbackServiceJsonResponse(NSError *error, NSDictionary *jsonResponse) {
    NSLog(@"JSON Response:\n%@", jsonResponse);
    NSLog(@"error:\n%@", error);
}

- (void)requestContentWithParametersByVideoId:(NSString *)videoIDString
                                    accountID:(NSString *)accountIDString
                                    policyKey:(NSString *)policyKeyString
                        playbackAPIParameters:(NSDictionary *)playbackAPIParameters
{
    BCOVPlaybackServiceRequestFactory *playbackServiceRequestFactory = [[BCOVPlaybackServiceRequestFactory alloc]
                                                                        initWithAccountId:accountIDString policyKey:policyKeyString baseURLStr:testProfileManager.playbackApiUrl];
    BCOVPlaybackService *playbackService = [[BCOVPlaybackService alloc] initWithRequestFactory:playbackServiceRequestFactory];
    self.playbackController.autoPlay = gPlayListViewController.autoPlay;
    self.playbackController.autoAdvance = gPlayListViewController.autoAdvance;
    [self.playbackController setAllowsExternalPlayback:gPlayListViewController.enableExternalPlayback];
    
    // TODO: if no selection then use the default videoId for the account under test
    if(gPlayListViewController.selectedTitleVideoId){
        [playbackService findVideoWithVideoID:videoIDString parameters:playbackAPIParameters completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error)
         {
             playbackServiceJsonResponse(error, jsonResponse);
             [self validateVideoObject:video];
         }];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    gVideoViewController = self;
    self.tabBarController = (UITabBarController*)self.parentViewController;
    [self setup];
    self.currentVideoNameLabel.text = @"";
    self.accountNameLabel.text = @"";
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"%d self.tabBarController.selectedIndex", (int) self.tabBarController.selectedIndex);
    NSLog(@"userDefaults %d",(int) gTestProfileSettingsViewController.tabBarController.selectedIndex);
}

#pragma mark workflow management methods

- (void)validateVideoObject:(BCOVVideo *)video {
    if(video)
    {
        // Add atleast 3 videos for testing
        [self.playbackController setVideos:@[video, video, video]];
        self.moreVideoDetailsButton.enabled = YES;
        if(![gTestProfileSettingsViewController.selectedAdType isEqualToString:kAdTypeOux])
        {
            self.currentVideoNameLabel.text = gPlayListViewController.selectedTitleVideoName;
        }
        else
        {
            self.currentVideoNameLabel.text = gTestProfileSettingsViewController.selectedPickerDataName;
        }
    }
    else
    {
        NSLog(@"No video content for Video ID (\"%@\") was found.", gPlayListViewController.selectedTitleVideoId);
        self.currentVideoNameLabel.text = @"";
        self.moreVideoDetailsButton.enabled = NO;
    }
}

- (IBAction)doRefreshButton:(id)sender
{
    [self destroyPlaybackController];
    [self createTestProfile];

        adConfigId = gTestProfileSettingsViewController.selectedPickerDataValue;
        NSDictionary *queryParameters = nil;
        if(adConfigId)
        {
            NSLog(@"Testing ad config: %@", adConfigId);
            queryParameters = @{
                                @"ad_config_id" : adConfigId
                                };

        }
    [self createPlaybackController];
    if ([gTestProfileSettingsViewController.selectedAdType isEqualToString:kAdTypeOux])
    {
        BCOVVideo *video = [self videoWithURL: [NSURL URLWithString:gTestProfileSettingsViewController.selectedPickerDataValue] deliveryMethod:kBCOVSourceDeliveryHLS properties:nil];
        [self validateVideoObject:video];
    }
    else
    {
        [self requestContentWithParametersByVideoId:gPlayListViewController.selectedTitleVideoId
                                          accountID:testProfileManager.accountId
                                          policyKey:testProfileManager.policyKey
                              playbackAPIParameters:queryParameters];
    }
}

- (IBAction)doMoreButton:(UIButton *)button
{
    NSMutableDictionary * testDetailsDictionary = [[NSMutableDictionary alloc] init];
    
    NSString * destination = self.playbackController.analytics.destination;
    NSString * deliveryType = gTestProfileSettingsViewController.deliveryTypeOptionSelection;
    NSString * videoName = gPlayListViewController.selectedTitleVideoName;
    NSString * videoId = gPlayListViewController.selectedTitleVideoId;
    NSString * playlistDescription = gTestProfileSettingsViewController.selectedPlaylistDescription;
    NSString * accountName = testProfileManager.accountDescription;
    NSString * accountId = testProfileManager.accountId;
    NSString * securityLevel = testProfileManager.securityLevel;
    
    // Set these to empty strings by default since ads are not required for testing, they're not required here either.
    NSString * adType = @"";
    NSString * adDescription = @"";
    if(![gTestProfileSettingsViewController.currentAdTypeSelection  isEqualToString:@""])
    {
        adType =  gTestProfileSettingsViewController.currentAdTypeSelection;
        adDescription = gTestProfileSettingsViewController.selectedPickerDataName;
    }
    
    [testDetailsDictionary setObject:destination forKey:@"destination"];
    [testDetailsDictionary setObject:deliveryType forKey:@"deliveryType"];
    [testDetailsDictionary setObject:videoName forKey:@"videoName"];
    [testDetailsDictionary setObject:videoId forKey:@"videoId"];
    [testDetailsDictionary setObject:playlistDescription forKey:@"playlistDescription"];
    [testDetailsDictionary setObject:accountName forKey:@"accountName"];
    [testDetailsDictionary setObject:accountId forKey:@"accountId"];
    [testDetailsDictionary setObject:securityLevel forKey:@"securityLevel"];
    [testDetailsDictionary setObject:adType forKey:@"adType"];
    [testDetailsDictionary setObject:adDescription forKey:@"adDescription"];
    
    NSString *testInformation = [NSString stringWithFormat:@"Destination: '%@'\n"
                      "Delivery Type:  '%@'\n"
                      "Video Name:  '%@'\n"
                      "Video ID:  %@\n"
                      "Playlist RefId:  %@\n"
                      "Account Name:  '%@'\n"
                      "Account ID:  %@\n"
                      "Security Level:  %@\n"
                      "Ad Type:  %@\n"
                      "Ad Description:  %@\n"
                                 ,destination, deliveryType, videoName, videoId, playlistDescription, accountName, accountId, securityLevel, adType, adDescription];

    // Copy the testDetails
    self.pasteBoard = [UIPasteboard generalPasteboard];
    [self.pasteBoard setString:testInformation];

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Test Details"
                                                                   message:testInformation
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* doSlackItAction =
    [UIAlertAction actionWithTitle:@"Slack It!" style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action) { [self doSlackIt:testDetailsDictionary]; }];
    UIAlertAction* doClipboardAction =
    [UIAlertAction actionWithTitle:@"Copy to Clipboard" style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action) { [self doClipboard]; }];
    UIAlertAction* defaultOKAction =
    [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action) { }];
    [alert addAction:doSlackItAction];
    [alert addAction:doClipboardAction];
    [alert addAction:defaultOKAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)doClipboard
{
    // Paste the contents of the clipboard
    // This could be useful when your devices are signed in to your iCloud account.
    // When that is the case, it allows you to `hand-off` the clipboard contents to your laptop.
    NSString * message = [self.pasteBoard string];
    // do something with the clipbaord
    NSLog(@"\nTest Details: \n%@", message);
}

/* param: testDetailsDictionary contains the list of selected params for the current test  */
-(void) doSlackIt: (NSMutableDictionary * )testDetailsDictionary
{
    NSString * sdkTeamExpressNodeServer = @"http://xiappsci.vidmark.local:3000/";
    
    NSMutableURLRequest *sdkTeamExpressNodeServerUrlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:sdkTeamExpressNodeServer]];
    [sdkTeamExpressNodeServerUrlRequest setHTTPMethod:@"POST"];
   
    NSError * parseJsonError;
    NSData * testDetailsJSONSerializedData = [NSJSONSerialization dataWithJSONObject:testDetailsDictionary
                                                               options:0 // another option is NSJSONWritingPrettyPrinted for readability of the generated data
                                                         error:&parseJsonError];
    if (!parseJsonError) {
        //Convert the String to Data
        NSString * testDetailsJSONSerializedDataAsString = [[NSString alloc] initWithData:testDetailsJSONSerializedData encoding:NSUTF8StringEncoding];
        NSData * encodedTestDetailsData = [testDetailsJSONSerializedDataAsString dataUsingEncoding:NSUTF8StringEncoding];
        //Apply the data to the body
        [sdkTeamExpressNodeServerUrlRequest setHTTPBody:encodedTestDetailsData];

        NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]
                                          dataTaskWithRequest:sdkTeamExpressNodeServerUrlRequest completionHandler:^(NSData *data,
                                                                                             NSURLResponse *response, NSError *error) {
                                              
                                              // Check to make sure the server didn't respond with a "404 Not Found" which could indicate service unavailable
                                              if ([response respondsToSelector:@selector(statusCode)]) {
                                                  if ([(NSHTTPURLResponse *) response statusCode] == 404) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          // Log any access errors
                                                          NSLog(@"Cannot communicate with sdkTeamExpressNodeServer at this time.\nReason: %@", response);
                                                          return;
                                                      });
                                                  }
                                              }
                                              if(data != nil)
                                              {
                                                  NSString *decodedResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                  // Let's you know if the slack was successful or not
                                                  NSLog(@"Response from sdkTeamExpressNodeServer: %@", decodedResponse);
                                              }
                                              else
                                              {
                                                  // Log any data errors
                                                  NSLog(@"Error: %@", error);
                                                  return;
                                              }
                                          }];
        [dataTask resume];
    }
    else
    {
        // In the unforseen event that we cannot parse the testDetailsDictionary as `dataWithJSONObject`
        NSLog(@"parseJsonError = %@", parseJsonError);
    }
}

- (void)destroyPlaybackController
{
    if (self.playbackController)
    {
        self.isPresented = NO;
        self.playerView.playbackController = nil;
        [self.playerView removeFromSuperview];
        self.playerView = nil;
        self.playbackController = nil;
        self.playbackControllerConfigured = NO;
        self.moreVideoDetailsButton.enabled = NO;
    }
    else
    {
        NSLog(@"The playbackController does not exist, ignoring the call to destroy it.");
    }
}

#pragma OUX Methods

- (BCOVVideo *)videoWithURL:(NSURL *)url deliveryMethod:(NSString *) deliveryMethod properties:(NSDictionary *) properties
{
    NSURL *videoUrl;
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    NSMutableArray *queryItems = [[NSMutableArray alloc] initWithCapacity:2];
    
    urlComponents.queryItems = queryItems;
    if (![urlComponents.query isEqualToString:@""])
    {
        videoUrl = urlComponents.URL;
    }
    else
    {
        videoUrl = url;
    }
    
    // set the delivery method for BCOVSources that belong to a video
    BCOVSource *source = [[BCOVSource alloc] initWithURL:videoUrl deliveryMethod:kBCOVSourceDeliveryHLS properties:nil];
    return [[BCOVVideo alloc] initWithSource:source cuePoints:[BCOVCuePointCollection collectionWithArray:@[]] properties:@{}];
}

#pragma mark - BCOVPUIPlayerViewDelegate Methods

- (void)playerView:(BCOVPUIPlayerView *)playerView willTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    self.tabBarController.tabBar.hidden = (screenMode == BCOVPUIScreenModeFull);
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController
shouldSelectViewController:(UIViewController *)viewController
{
    return YES;
}

#pragma playController delagate methods

-(void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    long long int seekTime;
    seekTime = gTestProfileSettingsViewController.seekTime;
    if(seekTime != 0)
    {
        // disable ads.
        self.playbackController.adsDisabled = YES;
        
        // seek somewhere into the video content.
        
        [session.providerExtension oux_seekToTime:CMTimeMake(seekTime, 1) completionHandler:^(BOOL finished) {
            
            // re-enable ads.
            self.playbackController.adsDisabled = NO;
            
            // open the shutter.
            self.playbackController.shutterFadeTime = 0.0;
            self.playbackController.shutter = NO;
        }];
    }
    NSLog(@"Ad Markers: %@", [session.video.cuePoints cuePointsOfType:kBCOVCuePointTypeAdSlot]);
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([kBCOVPlaybackSessionLifecycleEventResumeBegin isEqualToString:lifecycleEvent.eventType])
    {
        NSLog(@"%@ at time %f", kBCOVPlaybackSessionLifecycleEventResumeBegin, CMTimeGetSeconds([session.player currentTime]));
    }

    if ([kBCOVPlaybackSessionLifecycleEventResumeFail isEqualToString:lifecycleEvent.eventType])
    {
        NSLog(@"%@ at time %f", kBCOVPlaybackSessionLifecycleEventResumeFail, CMTimeGetSeconds([session.player currentTime]));
    }

    if ([kBCOVPlaybackSessionLifecycleEventResumeComplete isEqualToString:lifecycleEvent.eventType])
    {
        NSLog(@"%@ at time %f", kBCOVPlaybackSessionLifecycleEventResumeComplete, CMTimeGetSeconds([session.player currentTime]));
    }
}
@end



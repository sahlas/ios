//
//  TestProfileSettingsViewController.h
//  BCOVCoreVideoPlayer
//
//  Created by Bill Sahlas on 9/21/17.
//  Copyright © 2017 Brightcove. All rights reserved.
//

#import <UIKit/UIKit.h>

@import BrightcovePlayerSDK;

#import "TestProfileManager.h"

@interface TestProfileSettingsViewController : UIViewController <UITabBarControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>


// The parent tab bar controller for all three primary view controllers
@property (nonatomic, nonnull) UITabBarController *tabBarController;

// Create an instance of the TestProfileManager
@property (nonatomic, strong, nullable) TestProfileManager *initialTestProfile;

@property (nonatomic, strong, nonnull) NSString *currentEnvironmentSelection;
@property (nonatomic, strong, nonnull) NSString *currentSecurityLevelSelection;
@property (nonatomic, strong, nonnull) NSString *currentDeliveryTypeSelection;
@property (nonatomic, strong, nullable) NSString *currentAdTypeSelection;

@property (nonatomic, strong, nonnull) NSDictionary *searchResultsDict;
@property (nonatomic, strong, nonnull) NSURLSession *defaultSession;

@property (nonatomic, nullable, strong) NSString *selectedPickerDataValue;
@property (nonatomic, nullable, strong) NSString *selectedPickerDataName;

@property (nonatomic, nullable, strong) NSString *selectedPlaylistRefId;
@property (nonatomic, nullable, strong) NSString *selectedPlaylistDescription;


// Get a test profile based on current settings
- (TestProfileManager * _Nonnull) createTestProfile;
- (TestProfileManager * _Nonnull) getCurrentTestProfile;

// define methods for profile tweaking
- (NSString * _Nonnull) environmentOptionSelection;
- (NSString * _Nonnull) securityLevelOptionSelection;
- (NSString * _Nonnull) deliveryTypeOptionSelection;
- (NSString * _Nonnull) selectedAdType;
- (long long int) seekTime;

@end



extern TestProfileSettingsViewController * _Nonnull gTestProfileSettingsViewController;


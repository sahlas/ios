    //
//  TestProfileManager.m
//  BCOVCoreVideoPlayer
//
//  Created by Bill Sahlas on 10/4/17.
//  Copyright © 2017 Brightcove. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TestProfileManager.h"

#pragma mark extern variables
TestProfileManager *gTestProfileManager;

// Containers for account and profile data
NSDictionary * testOptions;
NSDictionary * videoCloudAccountDetails;


// Environment Types
NSString * const _Nonnull kEnvironmentProduction = @"production";
NSString * const _Nonnull kEnvironmentStaging = @"staging";
NSString * const _Nonnull kEnvironmentQa = @"qa";

// Security Level Types
NSString * const _Nonnull kSecurityLevelClear = @"clear";
NSString * const _Nonnull kSecurityLevelHlse = @"hlse";
NSString * const _Nonnull kSecurityLevelDrm = @"drm";

// Delivery Types
NSString * const _Nonnull kDeliveryTypeDynamicDelivery = @"dynamic_delivery";
NSString * const _Nonnull kDeliveryTypeVideoCloud = @"legacy_vc";
NSString * const _Nonnull kDeliveryTypeCAE = @"cae";

// Ad Types
NSString * const _Nonnull kAdTypeSsai = @"ssai";
NSString * const _Nonnull kAdTypeOux = @"oux";
NSString * const _Nonnull kAdTypeIma = @"ima";
NSString * const _Nonnull kAdTypeFw = @"fw";

@implementation TestProfileManager

NSString *environmentOptionSelection;
NSString *securityLevelOptionSelection;
NSString *deliveryTypeOptionSelection;
NSString *selectedAdType;

/* Create an instance of the TestProfileManager */
TestProfileManager *testProfile;

-(void) getTestProfileAccountInformationFromBundleLocation
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"NativeSDKMasterTestProfileData" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    // Once we get the response and it is clean, handle the next steps
    [self processResponseUsingData:data];
}

// Process the account details
- (void)processResponseUsingData:(NSData*)data {
    NSError * parseJsonError = nil;
    NSDictionary * accountResponseDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                        options:NSJSONReadingAllowFragments error:&parseJsonError];
    if (!parseJsonError) {
        testOptions = accountResponseDictionary[@"testOptions"];
        videoCloudAccountDetails = accountResponseDictionary[@"video_cloud"];
        [testProfile setAnalyticsUrl : testOptions[@"kProductionAnalyticsUrl"]];
        [testProfile setOuxPickerDataArray: testOptions[@"kOuxAssets"]];
        [testProfile setFairplayPublisherId : testOptions[@"kFairPlayPublisherId"]];
        [testProfile setFairplayApplicationId : testOptions[@"kFairPlayApplicationId"]];
        NSLog(@"NativeSDKTestAcccountData = %@", accountResponseDictionary);
    }
    else
    {
        NSLog(@"parseJsonError = %@", parseJsonError);
    }
}

- (TestProfileManager *)createTestProfile:(NSDictionary *) profileParameters
{
    // Get the production accounts
    [self getTestProfileAccountInformationFromBundleLocation];
    
    NSLog(@"%@", profileParameters);
    // First, validate the choices. This will throw an exception if they are not valid.
    if([self validateTestProfileOptions : profileParameters])
    {
        // Once we determine that the parameters are valid it's ok to give back a
        // test profile
        testProfile = [[TestProfileManager alloc]init];
        
        // Initialize global variables with preferred settings
        if(environmentOptionSelection == kEnvironmentProduction)
        {
            [testProfile setEnvironment : kEnvironmentProduction];
        }
        else if(environmentOptionSelection == kEnvironmentStaging)
        {
            [testProfile setEnvironment : kEnvironmentStaging];
        }
        else if(environmentOptionSelection == kEnvironmentQa)
        {
            [testProfile setEnvironment : kEnvironmentQa];
        }
        else
        {
            [testProfile setEnvironment : kEnvironmentProduction];
        }
        
        if(securityLevelOptionSelection == kSecurityLevelDrm)
        {
            [testProfile setSecurityLevel : kSecurityLevelDrm];
        }
        else if(securityLevelOptionSelection == kSecurityLevelClear)
        {
            [testProfile setSecurityLevel : kSecurityLevelClear];
        }
        else if(securityLevelOptionSelection == kSecurityLevelHlse)
        {
            [testProfile setSecurityLevel : kSecurityLevelHlse];
        }
        else
        {
            [testProfile setSecurityLevel : kSecurityLevelClear];
        }
        
        if(deliveryTypeOptionSelection == kDeliveryTypeDynamicDelivery)
        {
            [testProfile setDeliveryType : kDeliveryTypeDynamicDelivery];
        }
        else if(deliveryTypeOptionSelection == kDeliveryTypeVideoCloud)
        {
            [testProfile setDeliveryType : kDeliveryTypeVideoCloud];
        }
        else if(deliveryTypeOptionSelection == kDeliveryTypeCAE)
        {
            [testProfile setDeliveryType : kDeliveryTypeCAE];
        }
        else
        {
            [testProfile setDeliveryType : kDeliveryTypeDynamicDelivery];
        }
        
        /* PRODUCTION Accounts - NativeSDKMasterTestProfileData.json contains all the details */
        if(environmentOptionSelection == kEnvironmentProduction)
        {
            [testProfile setPlaybackApiUrl : testOptions[@"kPlaybackApiBaseUrl"][@"production"]];
            [testProfile setOuxPickerDataArray: testOptions[@"kOuxAssets"]];
            
            // Pull out the production accounts into a dictionary
            NSDictionary * productionAccountDetailsDictionary = videoCloudAccountDetails[kEnvironmentProduction];
            
            // The testProfile.securityLevel under tests
            NSString * securityLevel = testProfile.securityLevel;
            // The testProfile.deliveryType under tests
            NSString * deliveryType = testProfile.deliveryType;
            
            /*
             ** The number or accounts per securityType is typically >= 1. Iterate over the list of all the accounts at this security level (clear/drm/hlse)
             ** and set the properties based on the required testProfile `deliveryType`
             */
            if(securityLevel == kSecurityLevelDrm)
            {
                for (NSDictionary * accountsForDrm in productionAccountDetailsDictionary[kSecurityLevelDrm])
                {
                    [testProfile setAccountId : accountsForDrm[deliveryType][@"accountId"]];
                    [testProfile setPolicyKey : accountsForDrm[deliveryType][@"policyKey"]];
                    [testProfile setAccountDescription : accountsForDrm[deliveryType][@"description"]];
                    [testProfile setDefaultVideoRefId : accountsForDrm[deliveryType][@"defaultVideoRefId"]];
                    [testProfile setDefaultPlaylistRefId : accountsForDrm[deliveryType][@"defaultPlaylistRefId"]];
                    [testProfile setPlaylistPickerDataArray: accountsForDrm[deliveryType][@"kPlaylistArray"]];
                    [testProfile setSsaiPickerDataArray: accountsForDrm[deliveryType][@"kSsaiConfigs"]];
                }
            }
            else if (securityLevel == kSecurityLevelClear)
            {
                for (NSDictionary * accountsForClear in productionAccountDetailsDictionary[kSecurityLevelClear])
                {
                    [testProfile setAccountId : accountsForClear[deliveryType][@"accountId"]];
                    [testProfile setPolicyKey : accountsForClear[deliveryType][@"policyKey"]];
                    [testProfile setAccountDescription : accountsForClear[deliveryType][@"description"]];
                    [testProfile setDefaultVideoRefId : accountsForClear[deliveryType][@"defaultVideoRefId"]];
                    [testProfile setDefaultPlaylistRefId : accountsForClear[deliveryType][@"defaultPlaylistRefId"]];
                    [testProfile setPlaylistPickerDataArray: accountsForClear[deliveryType][@"kPlaylistArray"]];
                    [testProfile setSsaiPickerDataArray: accountsForClear[deliveryType][@"kSsaiConfigs"]];
                }
            }
            else if (securityLevel == kSecurityLevelHlse)
            {
                for (NSDictionary * accountsForHLSe in productionAccountDetailsDictionary[kSecurityLevelHlse])
                {
                    [testProfile setAccountId : accountsForHLSe[deliveryType][@"accountId"]];
                    [testProfile setPolicyKey : accountsForHLSe[deliveryType][@"policyKey"]];
                    [testProfile setAccountDescription : accountsForHLSe[deliveryType][@"description"]];
                    [testProfile setDefaultVideoRefId : accountsForHLSe[deliveryType][@"defaultVideoRefId"]];
                    [testProfile setDefaultPlaylistRefId : accountsForHLSe[deliveryType][@"defaultPlaylistRefId"]];
                    [testProfile setPlaylistPickerDataArray: accountsForHLSe[deliveryType][@"kPlaylistArray"]];
                    [testProfile setSsaiPickerDataArray: accountsForHLSe[deliveryType][@"kSsaiConfigs"]];
                }
            }
            return testProfile;
        }
        /* STAGING */
        // Get the staging accounts

        /* QA */
        // Get the QA accounts

    }
    return testProfile;
}

#pragma  validation methods
-(BOOL) validateTestProfileOptions:(NSDictionary *)profileParameters
{
    BOOL testProfileOptionsAreValid = NO;
    
    // parse the individual arguments
    for (NSString *requirementsKey in profileParameters)
    {
        id requirementsValue = profileParameters[requirementsKey];
        
        if([requirementsKey isEqualToString:(NSString *) @"kEnvironment"])
        {
            environmentOptionSelection = requirementsValue;
        }
        else if([requirementsKey isEqualToString:(NSString *) @"kSecurityLevel"])
        {
            securityLevelOptionSelection = requirementsValue;
        }
        else if([requirementsKey isEqualToString:(NSString *) @"kAdType"])
        {
            selectedAdType = requirementsValue;
        }
        else if([requirementsKey isEqualToString:(NSString *) @"kDeliveryType"])
        {
            deliveryTypeOptionSelection = requirementsValue;
        }
    }
    
    // check out the requirements and determine if default settings should be used, otherwise attempt to build a profile based on the requirements parameters.
    if(environmentOptionSelection == nil && securityLevelOptionSelection == nil && deliveryTypeOptionSelection == nil)
    {
        // use defaults
        self.environment = kEnvironmentProduction;
        self.securityLevel = kSecurityLevelClear;
        self.deliveryType = kDeliveryTypeDynamicDelivery;
        self.adType = kAdTypeSsai;
        testProfileOptionsAreValid = YES;
    }
    else if(environmentOptionSelection != nil && securityLevelOptionSelection != nil && deliveryTypeOptionSelection != nil)
    {
        if(environmentOptionSelection == kEnvironmentProduction || environmentOptionSelection == kEnvironmentStaging || environmentOptionSelection == kEnvironmentQa)
        {
            _environment = environmentOptionSelection;
            testProfileOptionsAreValid = YES;
        }
        else
        {
            [NSException raise:@"Invalid requirements: " format:@"(\"%@\") is an invalid selection for the (\"kEnvironment\") property", environmentOptionSelection];
        }
        if(securityLevelOptionSelection == kSecurityLevelDrm || securityLevelOptionSelection == kSecurityLevelClear || securityLevelOptionSelection == kSecurityLevelHlse)
        {
            _securityLevel = securityLevelOptionSelection;
            testProfileOptionsAreValid = YES;
        }
        else
        {
            [NSException raise:@"Invalid requirements: " format:@"(\"%@\") is an invalid selection for the (\"kSecurityLevel\") property", securityLevelOptionSelection];
        }
        if(deliveryTypeOptionSelection == kDeliveryTypeDynamicDelivery || deliveryTypeOptionSelection == kDeliveryTypeVideoCloud || deliveryTypeOptionSelection == kDeliveryTypeCAE)
        {
            _deliveryType = deliveryTypeOptionSelection;
            testProfileOptionsAreValid = YES;
        }
        else
        {
            [NSException raise:@"Invalid requirements: " format:@"(\"%@\") is an invalid selection for the (\"kDeliveryType\") property",deliveryTypeOptionSelection];
        }
    }
    else
    {
        //bail out if any of the requirements parameters are nil
        [NSException raise:@"Invalid requirements: " format:@"validateTestProfileOptions: The test profile request is invalid."];
    }
    return testProfileOptionsAreValid;
}


@end

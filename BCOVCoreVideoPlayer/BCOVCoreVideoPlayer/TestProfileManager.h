//
//  TestProfileManager.h
//  BCOVCoreVideoPlayer
//
//  Created by Bill Sahlas on 10/4/17.
//  Copyright © 2017 Brightcove. All rights reserved.
//

/**
  A class that represents the account and its capabilities.
  Use the definition to make determinations on what apis to use, whether or not
  to use specific session provider, etc.
 */
@interface TestProfileManager : NSMutableDictionary

@property(nonnull, retain, nonatomic) NSString * accountId;
@property(nonnull, retain, nonatomic) NSString * policyKey;
@property(nonnull, retain, nonatomic) NSString * accountDescription;
@property(nonnull, retain, nonatomic) NSString * environment;
@property(nonnull, retain, nonatomic) NSString * playbackApiUrl;
@property(nonnull, retain, nonatomic) NSString * defaultVideoRefId;
@property(nonnull, retain, nonatomic) NSString * defaultPlaylistRefId;

@property(nonnull, retain, nonatomic) NSString * securityLevel;
@property(nonnull, retain, nonatomic) NSString * deliveryType;
@property(nonnull, retain, nonatomic) NSString * adType;
@property(nonnull, retain, nonatomic) NSString * analyticsUrl;
@property(nonnull, retain, nonatomic) NSString * analyticsSource;
@property(nonnull, retain, nonatomic) NSString * analyticsDestination;
@property(nonnull, retain, nonatomic) NSString * fairplayPublisherId;
@property(nonnull, retain, nonatomic) NSString * fairplayApplicationId;
@property(nonnull, retain, nonatomic) NSString * defaultSsaiAdConfigName;
@property(nonnull, retain, nonatomic) NSString * defaultSsaiAdConfigId;
@property(nonnull, retain, nonatomic) NSArray * playlistPickerDataArray;
@property(nonnull, retain, nonatomic) NSArray * ssaiPickerDataArray;
@property(nonnull, retain, nonatomic) NSArray * ouxPickerDataArray;

/**
 Accepts an NSDictionary as its argument containing kEnvironment, kSecurityLevel and kDeliveryType values. Reads the values selected on the TestProfileSettings Controller and returns a testProfile. The available settings are
 
 @param profileRequirements An NSDictionary containing the requirements for kEnvironment, kSecurityLevel and kDeliveryType
 
 @return The TestProfile Configuration.
 */
- (TestProfileManager * _Nonnull)createTestProfile:(NSDictionary * _Nullable)profileRequirements;

@end

// Other classes use these `category-type` constants
extern NSString * _Nonnull const kDefaultEnvironmentOptionSection;
extern NSString * _Nonnull const kDefaultSecurityLevelOptionSelection;
extern NSString * _Nonnull const kDefaultDeliveryTypeOptionSelection;

extern NSString * _Nonnull const kPlatoUrlBase;

extern NSString * _Nonnull const kEnvironmentProduction;
extern NSString * _Nonnull const kEnvironmentStaging;
extern NSString * _Nonnull const kEnvironmentQa;

extern NSString * _Nonnull const kSecurityLevelClear;
extern NSString * _Nonnull const kSecurityLevelDrm;
extern NSString * _Nonnull const kSecurityLevelHlse;

extern NSString * _Nonnull const kDeliveryTypeDynamicDelivery;
extern NSString * _Nonnull const kDeliveryTypeVideoCloud;
extern NSString * _Nonnull const kDeliveryTypeCAE;

extern NSString * _Nonnull const kAdTypeSsai;
extern NSString * _Nonnull const kAdTypeOux;
extern NSString * _Nonnull const kAdTypeIma;
extern NSString * _Nonnull const kAdTypeFw;

// Hook to the class for other classes
extern TestProfileManager * _Nonnull gTestProfileManager;

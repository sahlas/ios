//
//  VideoViewController.h
//  BCOVSSAIVideoPlayerModified
//
//  Created by Bill Sahlas on 9/18/17.
//  Copyright © 2017 Brightcove. All rights reserved.
//

#import <UIKit/UIKit.h>
@import BrightcoveOUX;
@import BrightcovePlayerSDK;

#import "TestProfileManager.h"

typedef enum
{
    eDidEnterAdSequence,
    eDidExitAdSequence,
    eDidEnterAd,
    eDidExitAd,
    eDidProgressTo,
    eDidPauseAd,
    eDidResumeAd,
    
    eDelegateMethodCount
    
} E_DelegateMethodName;


@interface VideoViewController : UIViewController <BCOVPlaybackControllerDelegate, UITabBarControllerDelegate>


// The parent tab bar controller for all three primary view controllers
@property (nonatomic, nonnull) UITabBarController * tabBarController;

// Return the Account Details for the session
@property (nonatomic, nonnull) TestProfileManager * getTestProfileManager;

// Helpers
@property (nonatomic) BOOL isPresented;
@property (nonatomic, nullable, strong) UIPasteboard * pasteBoard;

@end

extern VideoViewController * _Nonnull gVideoViewController;



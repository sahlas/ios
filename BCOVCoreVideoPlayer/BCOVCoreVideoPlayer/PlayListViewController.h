//
//  PlayerSettingsViewController.h
//  BCOVCoreVideoPlayer
//
//  Created by Bill Sahlas on 9/21/17.
//  Copyright © 2017 Brightcove. All rights reserved.
//

#import <UIKit/UIKit.h>

@import BrightcovePlayerSDK;

#import "VideoViewController.h"

@interface PlayListViewController : UIViewController <UITabBarControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
{
    UIPickerView *videoPlaylistPickerView;
    UIView *simpleView;
    NSMutableDictionary *videoPlayListData;
}

// The parent tab bar controller for all three primary view controllers
@property (nonatomic, nonnull) UITabBarController *tabBarController;

// Video Playlist
@property (nonatomic, retain, nonnull) UIPickerView *videoPlaylistPickerView;
@property (nonatomic, nonnull) UIView *simpleView;
@property (nonatomic, retain, nullable) NSMutableDictionary *videoPlayListData;
@property (nonatomic, nonnull, strong) NSString *selectedTitleVideoId;
@property (nonatomic, nonnull, strong) NSString *selectedTitleVideoName;
@property (nonatomic, nonnull, strong) NSString *selectedVideoRefId;
@property (nonatomic, nullable) BOOL *resetTestProfileAndPlaylist;
@property (nonatomic, nonnull) BOOL *autoPlay;
@property (nonatomic, nonnull) BOOL *autoAdvance;
@property (nonatomic, nonnull) BOOL *enableExternalPlayback;

// Helper to know when coming from PlayListViewControllefr
@property (nonatomic) BOOL isPresentedFromPlayListViewController;

- (TestProfileManager * _Nonnull) getCurrentTestProfile;

@end
extern PlayListViewController * _Nonnull gPlayListViewController;


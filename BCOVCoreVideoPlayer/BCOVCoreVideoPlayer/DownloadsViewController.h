//
//  DownloadsViewController.h
//  BCOVCoreVideoPlayer
//
//  Created by Steve Bushell on 1/27/17.
//  Copyright (c) 2017 Brightcove. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MediaPlayer;

@import BrightcovePlayerSDK;

#import "VideosViewController.h"

@interface DownloadsViewController : UIViewController <UITabBarControllerDelegate>

// The parent tab bar controller for all three primary view controllers
@property (nonatomic, nonnull) UITabBarController *tabBarController;

- (void)refresh;
- (void)updateInfoForSelectedDownload;


@end

@interface DownloadCell : UITableViewCell

@property (nonatomic, nonnull) UIButton *statusButton;
@property (nonatomic, nonnull) UIView *progressBarView;
@property (nonatomic) CGFloat progress;

- (void)setStateImage:(VideoState)state;

@end

extern DownloadsViewController * _Nonnull gDownloadsViewController;

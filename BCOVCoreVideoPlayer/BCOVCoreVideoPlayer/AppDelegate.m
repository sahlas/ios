//
//  AppDelegate.m
//  BCOVSSAIVideoPlayerModified
//
//  Created by Jim Whisenant on 6/24/14.
//  Copyright (c) 2014 Brightcove. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "AppDelegate.h"
#import "VideoViewController.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //    NSError *setCategoryError = nil;
    //    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    //    NSLog(@"AppDelegate Debug - foobar %@", setCategoryError);
    //    if (setCategoryError)
    //    {
    //        NSLog(@"AppDelegate Debug - Error setting AVAudioSession category.  Because of this, there may be no sound. %@", setCategoryError);
    //    }
    // Override point for customization after application launch.
    return YES;
}

// By default enable 
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if ([self.window.rootViewController isKindOfClass:[UITabBarController class]])
    {
        for ( UIViewController *childViewController in ((UITabBarController *)self.window.rootViewController).viewControllers ) {
            if([childViewController isKindOfClass:[VideoViewController class]])
            {
                NSLog(@"AppDelegate Debug - is VideoViewController");
                VideoViewController *videoViewController = (VideoViewController *) childViewController;
                
                if (videoViewController.isPresented)
                {
                    return UIInterfaceOrientationMaskAll;
                }
                else
                {
                    return UIInterfaceOrientationMaskPortrait;
                }
            }
            else
            {
                NSLog(@"AppDelegate Debug - is NOT VideoViewController");
                return UIInterfaceOrientationMaskPortrait;
            }
        }
    }
    return UIInterfaceOrientationMaskPortrait;
}

@end


//
//  AppDelegate.m
//  HomeMonitor
//
//  Created by Taylan Pince on 2014-11-19.
//  Copyright (c) 2014 Hipo. All rights reserved.
//

#import "AppDelegate.h"
#import "HMORootViewController.h"


@interface AppDelegate ()

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    HMORootViewController *rootController = [[HMORootViewController alloc] init];
    
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [_window setRootViewController:rootController];
    [_window makeKeyAndVisible];
    
    return YES;
}

@end

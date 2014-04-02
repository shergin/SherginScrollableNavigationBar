//
//  SherginAppDelegate.m
//  SherginScrollableNavigationBarDemo
//
//  Created by Valentin Shergin on 31/03/14.
//  Copyright (c) 2014 shergin research. All rights reserved.
//

#import "SherginAppDelegate.h"

#import "SherginScrollableNavigationBar.h"
#import "SherginNavigationTableViewController.h"

@implementation SherginAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];

    UINavigationController *navigationController =
        [[UINavigationController alloc] initWithNavigationBarClass:[SherginScrollableNavigationBar class] toolbarClass:nil];

    SherginNavigationTableViewController *tableViewController =
        [[SherginNavigationTableViewController alloc] initWithStyle:UITableViewStylePlain];

    [navigationController setViewControllers:@[tableViewController] animated:NO];

    self.window.rootViewController = navigationController;

    [self.window makeKeyAndVisible];
    return YES;
}

@end

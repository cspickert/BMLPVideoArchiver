//
//  AppDelegate.m
//  BMLPVideoArchiver
//
//  Created by Justine Gartner on 10/26/15.
//  Copyright © 2015 Justine Kay. All rights reserved.
//

#import "AppDelegate.h"
#import "VideoViewController.h"
#import "LogInViewController.h"

@interface AppDelegate ()

@property (nonatomic, strong) IBOutlet UINavigationController *navigationController;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    UINavigationController *navigationController = (UINavigationController *) self.window.rootViewController;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:SignedInKey]) {
        
//        UIStoryboard *storyboard = self.window.rootViewController.storyboard;
//        
//        UIViewController *logInViewController = [storyboard instantiateViewControllerWithIdentifier:@"LogInViewController"];
//        
//        [(UINavigationController *)self.window.rootViewController pushViewController:logInViewController animated:YES];
//        
//        [self.window makeKeyAndVisible];
        
        [navigationController pushViewController:[storyboard instantiateViewControllerWithIdentifier:@"LogInViewController"] animated:NO];
        
    }else {
        
        [navigationController pushViewController:[storyboard instantiateViewControllerWithIdentifier:@"VideoViewController"] animated:NO];
        
//        UIStoryboard *storyboard = self.window.rootViewController.storyboard;
//        
//        UINavigationController *navController = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"MainNavigationController"];
//        
//        VideoViewController *videoVC = [[VideoViewController alloc] init];
//        
////        VideoViewController *videoVC = [storyboard instantiateViewControllerWithIdentifier:@"VideoViewController"];
////        
////        [(UINavigationController *)self.window.rootViewController pushViewController: videoVC animated:YES];
//        
//        [navController pushViewController:videoVC animated:YES];
//        
//        //[self.window makeKeyAndVisible];
        
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

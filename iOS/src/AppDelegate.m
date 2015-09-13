//
//  AppDelegate.m
//  SuperNES
//
//  Created by Joride on 27/12/14.
//  Copyright (c) 2014 KerrelInc. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if DEBUG
    NSLog(@"\t\t==== DEBUG ====\n\n");
#endif

#if TARGET_OS_TV
    NSLog(@"\t\t==== Running on tvOS ====");
#else
    NSLog(@"\t\t==== NOT Running on tvOS ====");
#endif

#if TARGET_IPHONE_SIMULATOR
    NSLog(@"Documents Directory: %@", [[[NSFileManager defaultManager]
                                        URLsForDirectory:NSDocumentDirectory
                                        inDomains:NSUserDomainMask] lastObject]);
#endif



    return YES;
}

@end

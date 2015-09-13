//
//  SNESGamePlayViewController+Subclassing.h
//  SuperNES
//
//  Created by Joride on 13-09-15.
//  Copyright © 2015 KerrelInc. All rights reserved.
//

#import "SNESGamePlayViewController.h"
#import "ConsoleGame.h"
#import "SNES.h"
#import "CGGameControllerForSNESInterpreter.h"

#if TARGET_OS_TV
    #import "SuperNES_TV-Swift.h"
#else
    #import "SuperNES-Swift.h"  
#endif

// implemented int the main implementation file
@interface SNESGamePlayViewController ()
<SNESDelegate>
@property (nonatomic, strong) id<SNESController> controllerOne;
@property (nonatomic, strong) id<SNESController> controllerTwo;
@property (readonly) SNES * console;

- (void) registerForNotifications NS_REQUIRES_SUPER;
- (void) controllerDidDisconnect: (NSNotification *) notification;
- (void) controllerDidConnect: (NSNotification *) notification;
@end

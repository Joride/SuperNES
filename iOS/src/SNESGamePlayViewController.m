//
//  ViewController.m
//  SuperNES
//
//  Created by Joride on 27/12/14.
//  Copyright (c) 2014 KerrelInc. All rights reserved.
//

#import "SNESGamePlayViewController.h"
#import "SNESGamePlayViewController+Subclassing.h"

#if TARGET_OS_TV
    #import "SNESGamePlayViewController_tvos.h"
#else
    #import "SNESGamePlayViewController_iphoneos.h"
#endif

@interface SNESGamePlayViewController ()
@end

@implementation SNESGamePlayViewController
{
    BOOL _paused;
}
@synthesize controllerOne = _controllerOne;
@synthesize controllerTwo = _controllerTwo;

-(SNES *)console
{
    return [SNES sharedSNES];
}
-(BOOL)prefersStatusBarHidden
{
    return YES;
}
- (void) registerForNotifications
{
    NSNotificationCenter * notificationCenter;
    notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver: self
                           selector: @selector(controllerDidConnect:)
                               name: GCControllerDidConnectNotification
                             object: nil];
    [notificationCenter addObserver: self
                           selector: @selector(controllerDidDisconnect:)
                               name: GCControllerDidDisconnectNotification
                             object: nil];
    
}
-(void)setConsoleGame:(id<SNESROMFileManaging>)consoleGame
{
    if (_consoleGame != consoleGame)
    {
        [self.console powerOff];
        dispatch_async(dispatch_get_main_queue(), ^{
#pragma message "the console has to be able to queue up the operations or actuall stop immediately"
            [self.console ejectROMFile];
            _consoleGame = consoleGame;
            [self startConsole];
        });
    }
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear: animated];
    [self.console pause];
}
- (void)viewDidLoad
{
    [super viewDidLoad];

    NSArray * controllers = [GCController controllers];
    if (controllers.count > 0)
    {   
        [self controllerDidConnect: nil];
    }
    else
    {
        [self controllerDidDisconnect: nil];
    }
    
    [self registerForNotifications];

    if (nil != self.consoleGame)
    {
        [self startConsole];
    }
}
- (void) startConsole
{
    [self.console inserROMFileAtPath: self.consoleGame.ROMPath];
    [self.console powerOnWithDelegate: self];
}
-(void)showOptionsMenu
{
    NSAssert(NO, @"Subclasses should implement this.");
}
- (void) showSelectGameStateViewController
{
    NSAssert(NO, @"Subclasses should implement this.");
}

#pragma mark - Controller handling
-(void)controllerDidConnect:(NSNotification *)notification
{
    NSAssert(NO, @"Subclasses should implement this.");
}
-(void)controllerDidDisconnect:(NSNotification *)notification
{
    NSAssert(NO, @"Subclasses should implement this.");
}


#pragma mark - SNESDelegate
-(NSString *)SNESConsole:(SNES *)console SRAMPathForRomWithFilePath:(NSString *)ROMName
{
    return self.consoleGame.SRAMPath;
}



















@end

//
//  SNESGamePlayViewController-tvos.m
//  SuperNES
//
//  Created by Joride on 13-09-15.
//  Copyright © 2015 KerrelInc. All rights reserved.
//

#import "SNESGamePlayViewController_tvos.h"
#import "SNESGamePlayViewController+Subclassing.h"

@implementation SNESGamePlayViewController_tvos
-(void)viewDidLoad
{
    [super viewDidLoad];
    [self.view.layer addSublayer: self.console.videoOutputLayer];


    UITapGestureRecognizer * playPauseRecognizer;
    playPauseRecognizer = [[UITapGestureRecognizer alloc]
                           initWithTarget: self
                           action: @selector(playPauseButtonTapped:)];
    playPauseRecognizer.allowedPressTypes = @[@(UIPressTypePlayPause)];
    [self.view addGestureRecognizer: playPauseRecognizer];

    UITapGestureRecognizer * selectRecognizer = [[UITapGestureRecognizer alloc]
                                                 initWithTarget: self
                                                 action: @selector(selectButtonTapped:)];
    selectRecognizer.allowedPressTypes = @[@(UIPressTypeSelect)];
    [self.view addGestureRecognizer: selectRecognizer];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    CGRect frameForVideoOutputLayer = CGRectZero;
    frameForVideoOutputLayer.size = self.console.nativeVideoSize;
    frameForVideoOutputLayer.origin.x = ((CGRectGetWidth(self.view.bounds) -
                                          frameForVideoOutputLayer.size.width ) / 2.0f);
    frameForVideoOutputLayer.origin.y = ((CGRectGetHeight(self.view.bounds) -
                                          frameForVideoOutputLayer.size.height ) / 2.0f);
    self.console.videoOutputLayer.frame = frameForVideoOutputLayer;
}

- (void) playPauseButtonTapped: (UITapGestureRecognizer *) gestureRecognizer
{
    if (self.console.isPaused)
    {
        [self.console unPause];
    }
    else
    {
        [self.console pause];
    }

}
- (void) showOptionsMenu
{
    [self.console pause];

    UIAlertController * alertController;
    alertController = [UIAlertController
                       alertControllerWithTitle: @"What now?"
                       message: nil
                       preferredStyle: UIAlertControllerStyleActionSheet];

    UIAlertAction * pauseAction;
    pauseAction = [UIAlertAction actionWithTitle: @"Cancel"
                                           style: UIAlertActionStyleCancel
                                         handler:^(UIAlertAction *action)
                   {
                       if (nil != self.completion)
                       {
                           [self.console unPause];
                       }
                   }];
    [alertController addAction: pauseAction];

    if (self.consoleGame.saveStates.count > 0)
    {
        UIAlertAction * loadsaveStateAction;
        loadsaveStateAction = [UIAlertAction actionWithTitle: @"Load saved state"
                                                       style: UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action)
                               {
                                   if (nil != self.completion)
                                   {
                                       [self showSelectGameStateViewController];
                                   }
                               }];
        [alertController addAction: loadsaveStateAction];
    }

    UIAlertAction * dismissAction;
    dismissAction = [UIAlertAction actionWithTitle: @"Games list"
                                             style: UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action)
                     {
                         if (nil != self.completion)
                         {
                             [self.console powerOff];
                             [self.console ejectROMFile];
                             self.completion();
                         }
                     }];
    [alertController addAction: dismissAction];

    UIAlertAction * saveStateAction;
    saveStateAction = [UIAlertAction actionWithTitle: @"Save state"
                                               style: UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * action)
                       {
                           if (nil != self.completion)
                           {
                               id <SNESROMSaveState> saveState = [self.consoleGame pushSaveStatePath];
                               NSString * saveStatePath = saveState.saveStateFilePath;
                               [self.console saveStateAtPath: saveStatePath];

                               dispatch_queue_t backgroundQueue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
                               UIImage * screenCapture = self.console.videoOutputLayer.imageRepresentation;
                               dispatch_async(backgroundQueue, ^
                                              {
                                                  // we also save an image to the indicated a path
                                                  NSString * imagePath = saveState.screenCaptureFilePath;
                                                  NSData * imageData = UIImagePNGRepresentation(screenCapture);
                                                  [imageData writeToFile: imagePath atomically: YES];
                                              });
                           }
                       }];
    [alertController addAction: saveStateAction];

    UIAlertAction * resetAction;
    resetAction = [UIAlertAction actionWithTitle: @"Reset game"
                                           style: UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction *action)
                   {
                       if (nil != self.completion)
                       {
                           [self.console reset];
                           [self.console unPause];
                       }
                   }];
    [alertController addAction: resetAction];

    UIAlertAction * turnOffAction;
    turnOffAction = [UIAlertAction actionWithTitle: @"Power off"
                                             style: UIAlertActionStyleDestructive
                                           handler:^(UIAlertAction * action)
                     {
                         if (nil != self.completion)
                         {
                             [self.console unPause];
                             [self.console powerOff];
                         }
                     }];
    [alertController addAction: turnOffAction];

    alertController.popoverPresentationController.sourceView = self.view;

    [self presentViewController: alertController
                       animated: YES
                     completion: nil];
}
- (void) showSelectGameStateViewController
{
    UIStoryboard * storyBoard = [UIStoryboard storyboardWithName: @"Main"
                                                          bundle: [NSBundle mainBundle]];
    SNESSelectGameStateViewController * selectGameStateViewController;
    selectGameStateViewController = (SNESSelectGameStateViewController *) [storyBoard instantiateViewControllerWithIdentifier: @"SNESSelectGameStateViewController"];
    selectGameStateViewController.ROM = self.consoleGame;
    selectGameStateViewController.completion = ^(NSString * saveStatePath)
    {
        [self dismissViewControllerAnimated: YES completion:^
         {
             [self.console loadStateFromFileAtPath: saveStatePath];
             [self.console unPause];
         }];

    };

    [self presentViewController: selectGameStateViewController
                       animated: YES
                     completion: NULL];
}
- (void) selectButtonTapped: (UITapGestureRecognizer *) gestureRecognizer
{
    [self showOptionsMenu];
}
#pragma mark - Controller handling
-(void)controllerDidConnect:(NSNotification *)notification
{
}
-(void)controllerDidDisconnect:(NSNotification *)notification
{
}

@end

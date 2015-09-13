//
//  SNESGamePlayViewController_iphoneos.m
//  SuperNES
//
//  Created by Joride on 13-09-15.
//  Copyright © 2015 KerrelInc. All rights reserved.
//

#import "SNESGamePlayViewController_iphoneos.h"
#import "SNESGamePlayViewController+Subclassing.h"

#import "SNESView.h"

@interface SNESGamePlayViewController_iphoneos ()
<UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet SNESView * SNESView;
// we need these properties only when there is a secondary screen (Airplay)
@property (nonatomic, strong) UIWindow * gameWindow;
@property (nonatomic, readonly) UIScreen * secondaryScreen;

@end
@implementation SNESGamePlayViewController_iphoneos
@synthesize secondaryScreen = _secondaryScreen;
- (void) registerForNotifications
{
    [super registerForNotifications];

    NSNotificationCenter * notificationCenter;
    notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver: self
                           selector: @selector(screenDidConnect:)
                               name: UIScreenDidConnectNotification
                             object: nil];
    [notificationCenter addObserver: self
                           selector: @selector(screenDidDisconnect:)
                               name: UIScreenDidDisconnectNotification
                             object: nil];
    
}
-(void)viewDidLoad
{
    [super viewDidLoad];

    self.SNESView.videoOutputLayer = self.console.videoOutputLayer;
    [self.console connectControllerOne: self.SNESView];

    UITapGestureRecognizer * doubleTapGestureRecognizer;
    doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                  initWithTarget:self
                                  action: @selector(doupleTapped:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    doubleTapGestureRecognizer.numberOfTouchesRequired = 2;
    doubleTapGestureRecognizer.delegate = self;
    [self.SNESView addGestureRecognizer: doubleTapGestureRecognizer];

    // setup the game-screenview for either the secondaryscreen or mainscreen
    UIScreen * secondaryScreen = [self secondaryScreen];
    if (nil != secondaryScreen)
    {
        [self screenDidConnect: nil];
    }
    else
    {
        [self screenDidDisconnect: nil];
    }
}

- (void) doupleTapped: (UITapGestureRecognizer *) tapGestureRecognize
{
    [self showOptionsMenu];
}
- (void)showOptionsMenu
{
    [self.console pause];
    UIAlertController * alertController;
    alertController = [UIAlertController
                       alertControllerWithTitle: @"What now?"
                       message: nil
                       preferredStyle: UIAlertControllerStyleActionSheet];
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
                               UIImage * screenCapture = self.SNESView.videoOutputLayer.imageRepresentation;
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
#pragma mark - UIGestureRecognizerDelegate
-(BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch
{
    BOOL shouldReceiveTouch = NO;
    CGPoint location = [touch locationInView: self.SNESView];
    if (CGRectContainsPoint(self.SNESView.videoOutputLayer.frame, location))
    {
        shouldReceiveTouch = YES;
    }
    return shouldReceiveTouch;
}
- (UIScreen *) secondaryScreen
{
    // find the first screen that is not the mainscreen.
    // We hold on to it, so that calling self.secondaryScreen does not cause
    if (nil == _secondaryScreen)
    {
        NSArray * screens = [UIScreen screens];
        // no more then one screen means there is no
        // secondary screen
        if ([screens count] > 1)
        {
            for (UIScreen * aScreen in screens)
            {
                if (aScreen != [UIScreen mainScreen])
                {
                    _secondaryScreen = aScreen;
                    break;
                }
            }
        }
    }
    return  _secondaryScreen;
}
- (void) screenDidConnect: (NSNotification *) notification
{
    UIScreen * secondaryScreen = [self secondaryScreen];
    self.gameWindow = [[UIWindow alloc]
                       initWithFrame: secondaryScreen.bounds];
    self.gameWindow.backgroundColor = [UIColor blackColor];

    [self.gameWindow makeKeyAndVisible];
    self.gameWindow.screen = secondaryScreen;

    CADisplayLink * secondaryScreenDisplayLink;
    secondaryScreenDisplayLink = [secondaryScreen displayLinkWithTarget: self.console
                                                               selector: self.console.displayLinkSelector];

    CGSize nativeSize = self.console.nativeVideoSize;

    CGSize screenSize = self.secondaryScreen.bounds.size;
    CGSize videoSize = CGSizeZero;
    if (screenSize.width > screenSize.height)
    {
        // width is larger then heigth
        videoSize.height = screenSize.height;
        videoSize.width = videoSize.height * (nativeSize.height / nativeSize.width);
    }
    else
    {
        videoSize.width = screenSize.width;
        videoSize.height = videoSize.height * (nativeSize.width / nativeSize.height);
    }

    CGRect frameForVideoLayer = CGRectZero;
    frameForVideoLayer.size = videoSize;
    frameForVideoLayer.origin.x = (self.secondaryScreen.bounds.origin.x +
                                   (screenSize.width - videoSize.width) / 2.0f);
    frameForVideoLayer.origin.y = (self.secondaryScreen.bounds.origin.y +
                                   (screenSize.height - videoSize.height) / 2.0f);

    self.console.videoOutputLayer.frame = CGRectIntegral(frameForVideoLayer);

    [self.console setDisplayLink: secondaryScreenDisplayLink];
    self.SNESView.videoOutputLayer = nil;
    self.console.videoOutputLayer.borderWidth = 0.0f;
    [self.gameWindow.layer addSublayer: self.console.videoOutputLayer];
    [self.view setNeedsLayout];
}
- (void) screenDidDisconnect:  (NSNotification *) notification
{
    // we don't need these anymore
    _secondaryScreen = nil;
    _gameWindow = nil;
}
- (void) controllerDidConnect: (NSNotification *) notification
{
    NSArray * controllers = [GCController controllers];
    if (controllers.count > 0)
    {
        GCController * gameController = [controllers firstObject];
        if (gameController.playerIndex == 1) {
            self.controllerTwo = [[CGGameControllerForSNESInterpreter alloc]
                              initWithController: gameController];
        } else if (nil != self.controllerOne) {
            gameController.playerIndex = 1;
            self.controllerTwo = [[CGGameControllerForSNESInterpreter alloc]
                              initWithController: gameController];
        } else {
            gameController.playerIndex = 0;
            self.controllerOne = [[CGGameControllerForSNESInterpreter alloc]
                              initWithController: gameController];
        }
    }
    [self.console connectControllerOne: self.controllerOne];
    if (nil != self.controllerTwo) {
        [self.console connectControllerTwo:self.controllerTwo];
    }
}
- (void) controllerDidDisconnect: (NSNotification *) notification
{
    // possibile states

    // 1. One controller was connected and is now disconnected

    // 2. two controllers were connected and the second controller is disconnecting

    // 3. two controllers were connected and the first controller is disconnecting

    // 4. two controllers were connected and both controllers are disconnecting

    // 5. inconsistent state

    NSArray * controllers = [GCController controllers];
    // 1.
    if (nil == self.controllerTwo && nil != self.controllerOne && controllers.count == 0) {
        self.controllerOne = nil;
        [self.console connectControllerOne: self.SNESView];
    }
    // 2. and 3.
    else if (nil != self.controllerTwo && nil != self.controllerOne && controllers.count > 0)
    {
        self.controllerOne = nil;
        self.controllerTwo = nil;
        [self.console connectControllerTwo:nil];

        GCController * gameController = [controllers firstObject];
        gameController.playerIndex = 0;
        self.controllerOne = [[CGGameControllerForSNESInterpreter alloc]
                          initWithController: gameController];
        [self.console connectControllerOne:self.controllerOne];
    }
    // 4.
    else if (nil != self.controllerTwo && nil != self.controllerOne && controllers.count == 0) {
        self.controllerOne = nil;
        self.controllerTwo = nil;
        [self.console connectControllerOne: self.SNESView];
        [self.console connectControllerTwo:nil];
    }
    // 5.
    else {
        self.controllerOne = nil;
        self.controllerTwo = nil;
        [self.console connectControllerOne: self.SNESView];
        [self.console connectControllerTwo:nil];
    }
}
@end

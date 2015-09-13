//
//  ViewController.h
//  SuperNES
//
//  Created by Joride on 27/12/14.
//  Copyright (c) 2014 KerrelInc. All rights reserved.
//

@import UIKit;
@import GameController;

#if TARGET_OS_TV
    #import "SuperNES_TV-Swift.h"
#else
    #import "SuperNES-Swift.h"
#endif

@class SNES;

typedef void(^CompletionHandler)(void);

/*!
 @class SNESGamePlayViewController : UIViewController
 class cluster for having one interface both tvOS and iphoneOS
 */
@interface SNESGamePlayViewController : UIViewController
@property (nonatomic, strong) id<SNESROMFileManaging> consoleGame;
@property (nonatomic, strong) CompletionHandler completion;
@end


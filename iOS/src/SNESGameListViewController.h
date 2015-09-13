//
//  SNESGameListViewController.h
//  SuperNES
//
//  Created by Joride on 09-02-15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

@import UIKit;
#import <SNES/SNESKit.h>

#if TARGET_OS_TV
    #import "SuperNES_TV-Swift.h"
#else
    #import "SuperNES-Swift.h"
#endif


@interface SNESGameListViewController : UIViewController

@end

//
//  SNESView.h
//  SuperNES
//
//  Created by Joride on 15-02-15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

@import UIKit;
#import <SNES/SNESKit.h>

@interface SNESView : UIView <SNESController>
@property (nonatomic, strong) CALayer * videoOutputLayer;
@end

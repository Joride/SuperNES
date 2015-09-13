//
//  CGGameControllerForSNESInterpreter.h
//  Nestopia
//
//  Created by Joride on 01/01/15.
//
//

@import Foundation;
@import GameController;
#import "SNESConstants.h"
#import "SNES.h"

@interface CGGameControllerForSNESInterpreter : NSObject
<SNESController>
-(instancetype)initWithController: (GCController *) controller;
@end

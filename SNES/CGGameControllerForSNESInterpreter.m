//
//  CGGameControllerForSNESInterpreter.m
//  Nestopia
//
//  Created by Joride on 01/01/15.
//
//

#import "CGGameControllerForSNESInterpreter.h"


@interface CGGameControllerForSNESInterpreter ()
@property (nonatomic, strong) GCController * controller;
@property (nonatomic, getter= isPauseButtonPressed) BOOL pauseButtonPressed;
@end



@implementation CGGameControllerForSNESInterpreter
{
    BOOL _pauseButtonPressed;
}
-(instancetype)initWithController: (GCController *) controller
{
    self = [super init];
    if (self)
    {
        _controller = controller;
        __weak CGGameControllerForSNESInterpreter * weakSelf = self;
        _controller.controllerPausedHandler = ^(GCController * controller)
        {
            // set a flag, clear it when signal is called
            weakSelf.pauseButtonPressed = YES;
        };
    }
    return self;
}

-(SNESControllerOutput) output
{
    SNESControllerOutput signal = kSNESControllerOutputNone;
    
    // Apple spec has flipped A-B and X-Y compared to SNES
    SNESControllerOutput AButton = (self.controller.gamepad.buttonB.isPressed) ? kSNESControllerOutputA : 0;
    SNESControllerOutput BButton = (self.controller.gamepad.buttonA.isPressed) ? kSNESControllerOutputB : 0;
    
    SNESControllerOutput XButton = (self.controller.gamepad.buttonY.isPressed) ? kSNESControllerOutputX : 0;
    SNESControllerOutput YButton = (self.controller.gamepad.buttonX.isPressed) ? kSNESControllerOutputY : 0;
    
    SNESControllerOutput LButton = (self.controller.gamepad.leftShoulder.isPressed) ? kSNESControllerOutputShoulderLeft : 0;
    SNESControllerOutput RButton = (self.controller.gamepad.rightShoulder.isPressed) ? kSNESControllerOutputShoulderRight : 0;
    
    SNESControllerOutput selectButton = (self.controller.extendedGamepad.leftTrigger.isPressed) ? kSNESControllerOutputSelect : 0;
    SNESControllerOutput left = (self.controller.gamepad.dpad.left.isPressed) ? kSNESControllerOutputLeft : 0;
    SNESControllerOutput right = (self.controller.gamepad.dpad.right.isPressed) ? kSNESControllerOutputRight : 0;
    SNESControllerOutput up = (self.controller.gamepad.dpad.up.isPressed) ? kSNESControllerOutputUp : 0;
    SNESControllerOutput down = (self.controller.gamepad.dpad.down.isPressed) ? kSNESControllerOutputDown: 0;
    
    SNESControllerOutput start = (self.isPauseButtonPressed) ? kSNESControllerOutputStart: 0;
    self.pauseButtonPressed = NO;
    
    signal |= AButton;
    signal |= BButton;
    signal |= XButton;
    signal |= YButton;
    signal |= LButton;
    signal |= RButton;
    signal |= selectButton;
    signal |= left;
    signal |= right;
    signal |= up;
    signal |= down;
    signal |= start;
    
    return signal;
}

@end

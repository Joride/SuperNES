//
//  SNESView.m
//  SuperNES
//
//  Created by Joride on 15-02-15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

#import <SNES/SNESKit.h>
#import "SNESView.h"
#import "ConsoleFireButtons.h"


@interface SNESView ()
<ConsoleFireButtonsDelegate>
@property (nonatomic, strong, readwrite) UIView * leftControlView;
@property (nonatomic, strong, readwrite) UIView * rightControlView;
@property (nonatomic, strong, readwrite) UIButton * startButton;
@property (nonatomic, strong, readwrite) UIButton * selectButton;
@property (nonatomic, strong, readwrite) UIButton * leftShoulderButton;
@property (nonatomic, strong, readwrite) UIButton * rightShoulderButton;
@property (atomic) SNESControllerOutput controllerOutput;

@end

@implementation SNESView

#pragma mark - ConsoleFireButtonsDelegate
-(void)consoleFireButtons:(ConsoleFireButtons *) consoleFireButtons
     didPressButtonWithID:(NSString *)buttonID
{
    if (self.rightControlView == consoleFireButtons)
    {
        self.controllerOutput |= [self controllerOutputFromFireButtonID: buttonID];
    }
    else if (self.leftControlView == consoleFireButtons)
    {
        self.controllerOutput |= [self controllerOutputFromDPadID: buttonID];
    }
    else
    {
        NSAssert(NO, @"Callback from an unexpected consoleFireButtonsView");
    }

}
-(void)consoleFireButtons:(ConsoleFireButtons *) consoleFireButtons
didReleaseButtonWithID:(NSString *)buttonID
{
    SNESControllerOutput outputToTurnOff;
    if (self.leftControlView == consoleFireButtons)
    {
        outputToTurnOff = [self controllerOutputFromDPadID: buttonID];
    }
    else if (self.rightControlView == consoleFireButtons)
    {
        outputToTurnOff = [self controllerOutputFromFireButtonID: buttonID];
    }
    else
    {
        NSAssert(NO, @"Callback from unexpected consoleFireButtonsView received");
    }
    /*
     We want to turn off the direction that was unpressed,
     but not any other direction.

     example:
     uint8_t original = 0b00001010;
     uint8_t value = 0b00001000;
     uint8_t invertedValue = ~value;
     uint8_t newOriginal = original & invertedValue;
     */
    SNESControllerOutput invertedOutputToTurnOff = ~outputToTurnOff;
    self.controllerOutput = self.controllerOutput & invertedOutputToTurnOff;
}

#pragma mark -
- (SNESControllerOutput) controllerOutputFromDPadID: (NSString *) buttonID
{
    SNESControllerOutput output = kSNESControllerOutputNone;
    if ([buttonID isEqualToString: kSNESUP])
    {
        output = kSNESControllerOutputUp;
    }
    else if ([buttonID isEqualToString: kSNESDOWN])
    {
        output = kSNESControllerOutputDown;
    }
    else if ([buttonID isEqualToString: kSNESLEFT])
    {
        output = kSNESControllerOutputLeft;
    }
    else if ([buttonID isEqualToString: kSNESRIGHT])
    {
        output = kSNESControllerOutputRight;
    }
    else if ([buttonID isEqualToString: kSNESUPRIGHT])
    {
        output = kSNESControllerOutputUp | kSNESControllerOutputRight;
    }
    else if ([buttonID isEqualToString: kSNESUPLEFT])
    {
        output = kSNESControllerOutputUp | kSNESControllerOutputLeft;
    }
    else if ([buttonID isEqualToString: kSNESDOWNRIGHT])
    {
        output = kSNESControllerOutputDown | kSNESControllerOutputRight;
    }
    else if ([buttonID isEqualToString: kSNESDOWNLEFT])
    {
        output = kSNESControllerOutputDown | kSNESControllerOutputLeft;
    }
    else
    {
        NSAssert(NO, @"Unknown button identifier received");
    }
    return output;
}

- (SNESControllerOutput) controllerOutputFromFireButtonID: (NSString *) buttonID
{
    SNESControllerOutput output = kSNESControllerOutputNone;
    if ([buttonID isEqualToString: kSNESA])
    {
        output = kSNESControllerOutputA;
    }
    else if ([buttonID isEqualToString: kSNESB])
    {
        output = kSNESControllerOutputB;
    }
    else if ([buttonID isEqualToString: kSNESX])
    {
        output = kSNESControllerOutputX;
    }
    else if ([buttonID isEqualToString: kSNESY])
    {
        output = kSNESControllerOutputY;
    }
    else
    {
        NSAssert(NO, @"Unknown button identifier received");
    }
    return output;
}
#pragma mark - SNESController
-(SNESControllerOutput)output
{
    SNESControllerOutput output =
    self.controllerOutput;
    return output;
}
-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder: aDecoder];
    if (self)
    {
        [self commonInit];
    }
    return self;
}
- (void) commonInit
{
    self.backgroundColor = [UIColor blackColor];
    // D-pad
    UIImage * DPadImage = [UIImage imageNamed: @"SNES-DPad"];
    ConsoleFireButtons * DPad;
    DPad = [ConsoleFireButtons fireButtonsWithType: kConsoleTypeSNESDPad];
    DPad.delegate = self;
    [DPad setBackgroundImage: DPadImage];
    DPad.layer.cornerRadius = DPadImage.size.width / 2.0f;
    DPad.clipsToBounds = YES;
    _leftControlView = DPad;

    // firebuttons
    UIImage * fireButtonsImage = [UIImage imageNamed: @"SNESFireButtons"];
    ConsoleFireButtons * fireButtons;
    fireButtons = [ConsoleFireButtons fireButtonsWithType: kConsoleTypeSNES];
    fireButtons.delegate = self;
    [fireButtons setBackgroundImage: fireButtonsImage];
    fireButtons.layer.cornerRadius = fireButtonsImage.size.width / 2.0f;
    fireButtons.clipsToBounds = YES;
    _rightControlView = fireButtons;

    // start
    _startButton = [UIButton buttonWithType: UIButtonTypeCustom];
    UIImage * startImage = [UIImage imageNamed: @"SNESStart"];
    [_startButton setBackgroundImage: startImage
                            forState: UIControlStateNormal];
    [_startButton addTarget: self
                     action: @selector(buttonPressed:)
           forControlEvents: UIControlEventTouchDown];
    [_startButton addTarget: self
                     action: @selector(buttonReleased:)
           forControlEvents: UIControlEventTouchUpInside];
    _startButton.layer.cornerRadius = 6.0f;
    _startButton.clipsToBounds = YES;

    // select
    _selectButton = [UIButton buttonWithType: UIButtonTypeCustom];
    UIImage * selectImage = [UIImage imageNamed: @"SNESSelect"];
    [_selectButton setBackgroundImage: selectImage
                             forState: UIControlStateNormal];
    [_selectButton addTarget: self
                      action: @selector(buttonPressed:)
            forControlEvents: UIControlEventTouchDown];
    [_selectButton addTarget: self
                      action: @selector(buttonReleased:)
            forControlEvents: UIControlEventTouchUpInside];
    _selectButton.layer.cornerRadius = 6.0f;
    _selectButton.clipsToBounds = YES;

    UIImage * shoulderButtonImage = [UIImage imageNamed: @"SNESShoulderButton"];

    // left shoulder
    _leftShoulderButton = [UIButton buttonWithType: UIButtonTypeSystem];
    _leftShoulderButton.tintColor = [UIColor darkGrayColor];
    [_leftShoulderButton setTitle: @"L" forState: UIControlStateNormal];
    [_leftShoulderButton setBackgroundImage: shoulderButtonImage
                                   forState: UIControlStateNormal];
    [_leftShoulderButton addTarget: self
                            action: @selector(buttonPressed:)
                  forControlEvents: UIControlEventTouchDown];
    [_leftShoulderButton addTarget: self
                            action: @selector(buttonReleased:)
                  forControlEvents: UIControlEventTouchUpInside];
    _leftShoulderButton.layer.cornerRadius= 6.0f;
    _leftShoulderButton.clipsToBounds = YES;

    // right shoulder
    _rightShoulderButton = [UIButton buttonWithType: UIButtonTypeSystem];
    _rightShoulderButton.tintColor = [UIColor darkGrayColor];
    [_rightShoulderButton setTitle: @"R" forState: UIControlStateNormal];
    [_rightShoulderButton setBackgroundImage: shoulderButtonImage
                                   forState: UIControlStateNormal];
    [_rightShoulderButton addTarget: self
                            action: @selector(buttonPressed:)
                  forControlEvents: UIControlEventTouchDown];
    [_rightShoulderButton addTarget: self
                            action: @selector(buttonReleased:)
                  forControlEvents: UIControlEventTouchUpInside];
    _rightShoulderButton.layer.cornerRadius= 6.0f;
    _rightShoulderButton.clipsToBounds = YES;


    [self addSubview: _leftControlView];
    [self addSubview: _rightControlView];
    [self addSubview: _startButton];
    [self addSubview: _selectButton];
    [self addSubview: _leftShoulderButton];
    [self addSubview: _rightShoulderButton];
}
- (void) buttonPressed: (UIButton *) button
{
    SNESControllerOutput output = kSNESControllerOutputNone;
    if (self.selectButton == button)
    {
        output = kSNESControllerOutputSelect;
    }
    else if (self.startButton == button)
    {
        output = kSNESControllerOutputStart;
    }
    else if (self.leftShoulderButton == button)
    {
        output = kSNESControllerOutputShoulderLeft;
    }
    else if (self.rightShoulderButton == button)
    {
        output = kSNESControllerOutputShoulderRight;
    }
    else
    {
        NSAssert(NO, @"Unexpected button calling us");
    }
    self.controllerOutput |= output;
}
- (void) buttonReleased: (UIButton *) button
{
    SNESControllerOutput outputToTurnOff = kSNESControllerOutputNone;
    if (self.selectButton == button)
    {
        outputToTurnOff = kSNESControllerOutputSelect;
    }
    else if (self.startButton == button)
    {
        outputToTurnOff = kSNESControllerOutputStart;
    }
    else if (self.leftShoulderButton == button)
    {
        outputToTurnOff = kSNESControllerOutputShoulderLeft;
    }
    else if (self.rightShoulderButton == button)
    {
        outputToTurnOff = kSNESControllerOutputShoulderRight;
    }
    else
    {
        NSAssert(NO, @"Unexpected button calling us");
    }

    SNESControllerOutput invertedOutputToTurnOff = ~outputToTurnOff;
    self.controllerOutput = self.controllerOutput & invertedOutputToTurnOff;
}
-(void)setVideoOutputLayer:(CALayer *)videoOutputLayer
{
    [self.videoOutputLayer removeFromSuperlayer];
    _videoOutputLayer = videoOutputLayer;
    _videoOutputLayer.borderColor = [UIColor darkGrayColor].CGColor;

    CGFloat scale = [UIScreen mainScreen].scale;
    _videoOutputLayer.borderWidth = 1.0f / scale;

    [self.layer addSublayer: _videoOutputLayer];
    [self setNeedsLayout];
}
-(void)layoutSubviews
{
    [super layoutSubviews];

    // leftControlView
    [self.leftControlView sizeToFit];
    CGRect frameForLeftControlView = self.leftControlView.frame;
    frameForLeftControlView.origin.y = (self.bounds.origin.y +
                                        self.bounds.size.height -
                                        frameForLeftControlView.size.height);
    frameForLeftControlView.origin.x = self.bounds.origin.x;
    self.leftControlView.frame = CGRectIntegral(frameForLeftControlView);

    // rightControlView
    [self.rightControlView sizeToFit];
    CGRect frameForRightControlView = self.rightControlView.frame;
    frameForRightControlView.origin.y = (self.bounds.origin.y +
                                        self.bounds.size.height -
                                        frameForRightControlView.size.height);
    frameForRightControlView.origin.x = (self.bounds.origin.x +
                                         self.bounds.size.width -
                                         frameForRightControlView.size.width);
    self.rightControlView.frame = CGRectIntegral(frameForRightControlView);

    /* 
     the videoOutputLayer is going to be between the buttons or above them,
     whichever has the biggest area.
     512 : 480 = 16 : 15
    */

    // between
    CGFloat heightToWidthRatio = 16.00f / 15.00f;
    CGFloat widthToHeightRatio = 1.00f / heightToWidthRatio;

    CGFloat leftXOfRightView = CGRectGetMinX(frameForRightControlView);
    CGFloat rightXOfLeftView = CGRectGetMaxX(frameForLeftControlView);
    CGFloat availableWidth = leftXOfRightView - rightXOfLeftView;
    CGFloat requiredHeight = availableWidth * widthToHeightRatio;

    CGSize sizeBetweenControllers = CGSizeZero;
    if (requiredHeight > self.bounds.size.height)
    {
        // fitting the availableWidth won't fit inside self.bounds
        // we set the heigth to be self.heigth, we already know the width
        // is available
        sizeBetweenControllers.height = self.bounds.size.height;
        sizeBetweenControllers.width = sizeBetweenControllers.height * heightToWidthRatio;
    }
    else
    {
        sizeBetweenControllers.height = requiredHeight;
        sizeBetweenControllers.width = sizeBetweenControllers.height * heightToWidthRatio;
    }

    // above controllers
    CGFloat availableHeight = (CGRectGetMinY(self.leftControlView.frame) -
                               CGRectGetMinY(self.bounds));
    CGFloat requiredWidth = availableHeight * heightToWidthRatio;
    CGSize sizeAboveControllers = CGSizeZero;
    if (requiredWidth > self.bounds.size.width)
    {
        // fitting the availableHeight won't fit inside self.bounds
        // we set the width to be self.width, we already know the height
        // is available
        sizeAboveControllers.width = self.bounds.size.width;
        sizeAboveControllers.height = sizeAboveControllers.width * widthToHeightRatio;
    }
    else
    {
        sizeAboveControllers.width = requiredWidth;
        sizeAboveControllers.height = sizeAboveControllers.width * widthToHeightRatio;
    }

    // check which size yields the largest area and then take that size
    CGFloat areaWhenAboveControllers;
    areaWhenAboveControllers = sizeAboveControllers.width * sizeAboveControllers.height;
    CGFloat areaWhenBetweenControllers;
    areaWhenBetweenControllers = sizeBetweenControllers.width * sizeBetweenControllers.height;

    [self.selectButton sizeToFit];
    [self.startButton sizeToFit];

    CGSize videoOutputLayerSize = CGSizeZero;
    if (areaWhenAboveControllers > areaWhenBetweenControllers)
    {
        // the videoOutlayerSize will be placed above the controllers
        videoOutputLayerSize = sizeAboveControllers;
    }
    else
    {
        // the videoOutlayerSize will be placed between the controllers
        videoOutputLayerSize = sizeBetweenControllers;
    }

    CGRect frameForvideoOutputLayer = CGRectZero;
    frameForvideoOutputLayer.size = videoOutputLayerSize;
    frameForvideoOutputLayer.origin.y = self.bounds.origin.y;

    CGFloat spaceBetweenControls = (CGRectGetMinX(self.rightControlView.frame) -
                                    CGRectGetMaxX(self.leftControlView.frame));
    CGFloat videoXOffset = CGRectGetMidX(self.bounds) - (CGRectGetWidth(self.videoOutputLayer.frame) / 2.0f);
    if (CGRectGetMaxY(frameForvideoOutputLayer) > CGRectGetMinY(self.leftControlView.frame) ||
        CGRectGetMaxY(frameForvideoOutputLayer) > CGRectGetMinY(self.rightControlView.frame))
    {
        CGFloat margin = spaceBetweenControls - videoOutputLayerSize.width;
        videoXOffset = (CGRectGetMaxX(self.leftControlView.frame) +
                        margin / 2.0f);
    }
    frameForvideoOutputLayer.origin.x = videoXOffset;
    self.videoOutputLayer.frame = CGRectIntegral(frameForvideoOutputLayer);

    // left and right shoulder buttons
    [self.leftShoulderButton sizeToFit];
    [self.rightShoulderButton sizeToFit];

    CGRect frameForLeftShoulderButton = self.leftShoulderButton.frame;
    frameForLeftControlView.origin.x = (CGRectGetMidX(self.leftControlView.frame) -
                                        CGRectGetWidth(frameForLeftShoulderButton) / 2.0f);
    frameForLeftShoulderButton.origin.y = (CGRectGetMinY(self.rightControlView.frame) -
                                           CGRectGetHeight(frameForLeftShoulderButton) -
                                           4.0f);
    self.leftShoulderButton.frame = frameForLeftShoulderButton;

    CGRect frameForRightShoulderButton = self.rightShoulderButton.frame;
    frameForRightShoulderButton.origin.x = (CGRectGetMidX(self.rightControlView.frame) -
                                            CGRectGetWidth(frameForRightShoulderButton) / 2.0f);
    frameForRightShoulderButton.origin.y = (CGRectGetMinY(self.rightControlView.frame) -
                                            CGRectGetHeight(frameForRightShoulderButton) -
                                            4.0f);
    self.rightShoulderButton.frame = frameForRightShoulderButton;

    // start and select buttons
    // the start and selet button will be placed above the shoulderbuttons
    CGRect frameForSelectButton = self.selectButton.frame;
    frameForSelectButton.origin.x = (self.leftControlView.center.x -
                                     frameForSelectButton.size.width / 2.0f);
    frameForSelectButton.origin.y = (CGRectGetMinY(self.rightShoulderButton.frame) -
                                     CGRectGetHeight(frameForSelectButton) -
                                     2.0f);
    self.selectButton.frame = frameForSelectButton;

    CGRect frameForStartButton = self.startButton.frame;
    frameForStartButton.origin.x = (self.rightControlView.center.x -
                                    frameForStartButton.size.width / 2.0f);
    frameForStartButton.origin.y = (CGRectGetMinY(self.rightShoulderButton.frame) -
                                    CGRectGetHeight(frameForStartButton) -
                                    2.0f);
    self.startButton.frame = frameForStartButton;
}
-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame: frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}
@end

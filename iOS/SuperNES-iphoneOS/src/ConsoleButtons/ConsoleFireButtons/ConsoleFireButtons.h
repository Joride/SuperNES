//
//  ConsoleFireButtons.h
//  SuperNES
//
//  Created by Joride on 02-03-15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

@import UIKit;
typedef NS_ENUM(NSInteger, ConsoleType)
{
    kConsoleTypeNES = 1,
    kConsoleTypeSNES,
    kConsoleTypeSNESDPad,
    kConsoleTypeN64
};
extern NSString * const kSNESA;
extern NSString * const kSNESB;
extern NSString * const kSNESY;
extern NSString * const kSNESX;
extern NSString * const kSNESUP;
extern NSString * const kSNESDOWN;
extern NSString * const kSNESLEFT;
extern NSString * const kSNESRIGHT;
extern NSString * const kSNESUPLEFT;
extern NSString * const kSNESUPRIGHT;
extern NSString * const kSNESDOWNLEFT;
extern NSString * const kSNESDOWNRIGHT;


@class ConsoleFireButtons;
@protocol ConsoleFireButtonsDelegate <NSObject>
@required
- (void) consoleFireButtons: (ConsoleFireButtons *) ConsoleFireButtons
       didPressButtonWithID: (NSString *) buttonID;
- (void) consoleFireButtons: (ConsoleFireButtons *) ConsoleFireButtons
     didReleaseButtonWithID: (NSString *) buttonID;
@end

@interface ConsoleFireButtons : UIView
@property (nonatomic, getter=isSingleButtonModeEnabled) BOOL singleButtonModeEnabled;
@property (nonatomic, weak) id<ConsoleFireButtonsDelegate> delegate;
+ (ConsoleFireButtons *) fireButtonsWithType: (ConsoleType) consoleType;
- (void) setBackgroundImage: (UIImage *) image;

@end



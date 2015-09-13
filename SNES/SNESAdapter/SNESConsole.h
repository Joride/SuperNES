//
//  SNESConsole.h
//  SuperNES
//
//  Created by Joride on 27/12/14.
//  Copyright (c) 2014 snes9x. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIScreen.h>
#import "SNESControllerConstants.h"


@protocol SNESController <NSObject>
@property (atomic, readonly) SNESControllerButton controllerOutput;
@end

@interface SNESConsole : NSObject
+ (SNESConsole *) sharedConsole;

/*!
 @property CALayer * videoOutputLayer;
 A CALayer that is used by the SNESConsole to draw its contents into.
 */
@property (nonatomic, readonly) CALayer * videoOutputLayer;

/*!
 @property NSURL * currentlyInsertedROM
 The URL of the ROM that is currently inserted. 
 @note This will return nil if no ROM was inserted, of when trying to insert
 one failed.
 */
@property (nonatomic, readonly) NSURL * currentlyInsertedROM;

/*!
 @property BOOL on
 YES if the reveiver was succesfully turned on, NO if it is off.
 */
@property (nonatomic, readonly, getter=isOn) BOOL on;

/*!
 @method -(void)connectToScreen:(UIScreen *) screen
 Call this method when the videoOutputLayer is displayed on any other screen
 then the mainscreen. It will cause the receiver to synchronize with the refresh
 rate of the screen
 @param screen
 The screen on which the videoOutputLayer is diplayed.
 */
- (void) connectToScreen: (UIScreen *) screen;

#pragma mark - Original hardware functions
/*!
 @method -(BOOL)inserROMFileAtURL:(NSURL *) ROMFileURL
 Initialize the SNES with a ROM-file at the given URL.
 @note Just luke the real SNES, you can only insert a cartridge of the device
 is turned off and no other ROm (cartridge) is currently inserted.
 @param ROMFileURL
 The URL of the ROM.
 @return YES if the ROM was succesfully inserted, NO if it was not inserted.
 */
- (BOOL) inserROMFileAtURL: (NSURL *) ROMFileURL;

/*!
 @method
 Removes the loaded ROM from the receiver.
 @note Just like the reals SNES, ejecting is only possible if the console is
 turned off.
 @return YES if after calling this method no ROM is loaded anymore. NO if there
 still is a ROM loaded.
 */
- (BOOL) ejectROMFile;

/*!
 @method -(BOOL)powerOn
 This method turns on the receiver. If no ROM was loaded, this method does
 nothing.
 @return YES if the reveiver was successfully turned on, NO if it was not turned
 on (e.g. the console was already turned on or no ROM was loaded).
 */
- (BOOL) powerOn;

/*! 
 @method -(void) powerOff
 Turns of the console.
 @note Just like the real SNES, this method will leave the currently inserted
 ROM inserted.
 */
- (void) powerOff;

/*!
 @method -(void)reset
 Resets the reveiver. This means that the current ROM will simply start again
 from the beginning, just like with the real SNES.
 */
- (void) reset;

/*!
 @method -(void)connectControllerOne:(id<SNESController>)controller;
 Connects a controller to the SNES controller slot one. If a controller was
 connected already, it will be disconnected. The SNES will hold on to the
 controller strongly.
 @param controller
 An object that conforms to the SNESController protocol.
 @note This argument will be polled many times per second for its output, so
 the implementation has to be performent.
 */
- (void) connectControllerOne: (id<SNESController>) controller;

/*!
 @method -(void)connectControllerOne:(id<SNESController>)controller;
 Connects a controller to the SNES controller slot two. If a controller was
 connected already, it will be disconnected. The SNES will hold on to the
 controller strongly.
 @param controller
 An object that conforms to the SNESController protocol.
 @note This argument will be polled many times per second for its output, so
 the implementation has to be performent.
 */
- (void) connectControllerTwo: (id<SNESController>) controller;

/*!
 @method -(void)disConnectControllerOne
 Removes the controller that was connected to slot one from the reeiver.
 */
- (void) disConnectControllerOne;

/*!
 @method -(void)disConnectControllerOne
 Removes the controller that was connected to slot two from the reeiver.
 */
- (void) disConnectControllerTwo;

#pragma mark - Additional software enabled features
/*!
 @method -(void)pause
 Pauses the emulation. This method is usefull for when the app becomes inactive,
 moves to the background, or a menu is presented over the game.
 */
- (void) pause;

/*!
 @method  -(void)unPause
 Resumed emulation.
 */
- (void) unPause;


- (void) saveState;
- (void) restoreStateFromFileAtURL: (NSURL *) savedStateURL;

@end

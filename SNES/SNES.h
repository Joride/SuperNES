//
//  SNES.h
//  SuperNES
//
//  Created by Joride on 09/01/15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

@import Foundation;
@import QuartzCore;
#import "SNESConstants.h"

@protocol SNESController <NSObject>
@property (atomic, readonly) SNESControllerOutput output;
@end

@class SNES;
@protocol SNESDelegate <NSObject>
- (NSString *) SNESConsole: (SNES*) console
SRAMPathForRomWithFilePath: (NSString *) ROMName;
@end

@interface SNES : NSObject
/*!
 @method + (SNES *) sharedSNES
 Returns the shared instance for a SNES. It is a singleton, as the underlying
 SNES9x emulator code uses global variables.
 */
+ (SNES *) sharedSNES;

@property (nonatomic, weak) id<SNESDelegate> delegate;

/*!
 @property CALayer * videoOutputLayer
 The CALayer in which the SNES draws it's content.
 */
@property (nonatomic, readonly) CALayer * videoOutputLayer;

/*! @property currentlyInsertedROM
 The NSURL to the currently inserted ROM file.
 */
@property (nonatomic, readonly) NSString * currentlyInsertedROM;

/*!
 @property SEL displayLinkSelector
 The selected to be used when creating a new CADisplayLink. Use this selector
 and as target the receiver for obtaining a CADisplayLink that can be used
 to set on the receiver.
 @see -(void)setDisplayLink:(CADisplayLink *)displayLink
 */
@property (nonatomic, readonly) SEL displayLinkSelector;

/*!
 @method -(void)connectControllerOne:(id<SNESController>)controller
 This method will cause the receiver to hold a strong reference to the 
 supplied controller object, and this object will be queried at each turn
 of the game-loop for the output. This output will be interpreted to be
 the output of controller one.
 @param controller
 An object that conforms to the SNESController protocol
 */
- (void) connectControllerOne: (id<SNESController>) controller;

/*!
 @method -(void)connectControllerTwo:(id<SNESController>)controller
 This method will cause the receiver to hold a strong reference to the
 supplied controller object, and this object will be queried at each turn
 of the game-loop for the output. This output will be interpreted to be
 the output of controller two.
 @param controller
 An object that conforms to the SNESController protocol
 */
- (void) connectControllerTwo: (id<SNESController>) controller;

/*!
- (BOOL) inserROMFileAtPath: (NSString *) ROMFilePath
 Insert a ROM file into the SNES. Only possible, just like with the real SNES,
 when the console is OFF, and no other ROM is currenly inserted.
 @param a String that points to valid SNES-rom file
 @return YES if the ROMFile could be set. NO if the SNES was either ON, or 
 had already an inserted ROM.
 @note This method does not check the path, or the file to be a valid SNES ROM.
 */
- (BOOL) inserROMFileAtPath: (NSString *) ROMFilePath;

/*!
 @method -(BOOL)ejectROMFile
 This method will eject the currently loaded ROM file. THe console has to be
 turned off.
 @return YES when the currenly loaded ROM file was ejected, NO if there is
 no file currently loaded, or if the console is not turned of.
 */
- (BOOL) ejectROMFile;

/*!
 @method - (BOOL) powerOnWithDelegate: (id <SNESDelegate>) delegate
 @param delegate
 Required. An object that conforms to SNESDelegate. It is consulted for certain data
 that a SNES needs to have in order to funcion well.
 Cannot be nil.
 @note the delegate is not retained, but weakly hold on to.
 */
- (BOOL) powerOnWithDelegate: (id <SNESDelegate>) delegate;
- (BOOL) powerOff;

- (BOOL) reset;

- (BOOL) pause;
- (BOOL) unPause;

@property (atomic, readonly, getter=isPaused) BOOL paused;

#pragma mark -
- (void) saveStateAtPath: (NSString *) path;
- (void) loadStateFromFileAtPath: (NSString *) path;

/*!
 @method -(void)setDisplayLink:(CADisplayLink *)displayLink
 By default, the receiver will use a CADisplayLink obtained via 
 [CADisplayLink displayLinkWithTarget: selector:]. When using the 
 videoOutputLayer on a screen that is not the mainscreen, you should get a 
 CADisplayLink from that screen, and call this method with that diplayLink
 as argument.
 The receiver will invalidate any previous displaylink, and add this displaylink
 to a suitable runloop.
 @param displayLink
 This must be a displayLink configured to call the displayLinkSelector obtained
 from the receiver and the receiver has to be the target.
 */
-(void)setDisplayLink:(CADisplayLink *)displayLink;

/*!
 @method - (CGSize) nativeVideoSize
 @return CGSize
 Returns the number of pixels in both directions. The dimensions should be
 devided by the screenScale to achieve a one-to-one pixel mapping of the SNES
 to the device. This is probably not something you want, as the size on modern
 devices (like iPhone 6 Plus) would be very small.
 */
- (CGSize) nativeVideoSize;

@end

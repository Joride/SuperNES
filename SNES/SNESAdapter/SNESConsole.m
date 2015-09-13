//
//  SNESConsole.m
//  SuperNES
//
//  Created by Joride on 27/12/14.
//  Copyright (c) 2014 snes9x. All rights reserved.
//

#include "SNESConsole.h"
#import "SNESVideoOutputLayer.h"
#import "SNES9xAdapter.h"

CGFloat const kMicrosecondsPerSecond = 1000000.00000000f;

CFTimeInterval const kTimeIntervalInvalid = -1.00f;

typedef enum SNESConsoleStates
{
    kSNESConsoleStateRunning = 1,
    kSNESConsoleStateReset,
    kSNESConsoleStatePaused,
    kSNESConsoleStateStopped,
    kSNESConsoleStatePowerOff
}SNESConsoleState;

@interface SNESConsole ()
<SNES9xAdapterDelegate>

@property (atomic, copy) NSString * loadedROMFilePath;
@property (nonatomic, strong) dispatch_queue_t SNES9xQueue;

@property (atomic) SNESConsoleState consoleState;
@property (nonatomic, readwrite, getter=isOn) BOOL on;
@property (atomic, getter = isPaused) BOOL paused;

@property (atomic, strong) id<SNESController> controllerOne;
@property (atomic, strong) id<SNESController> controllerTwo;

@property (nonatomic, strong) CADisplayLink * displayLink;
@end

@implementation SNESConsole
{
    SNESVideoOutputLayer * _videoOutputLayer;
    unsigned char* _imageBufferAlt;
    unsigned char* _imageBuffer;
    
    // synching related
    NSUInteger _framerate;
    CFTimeInterval _startTimeStamp;
    CFTimeInterval _frameDurationInUs;
    NSUInteger _currentlyRenderedFrame;
}

-(void)dealloc
{
    SNES9xAdapterDelegateClear();
    
    // self is the target of this displaylink and a CADisplayLink
    // retains its target. Invalidating it will break the retain cycle.
    [_displayLink invalidate];
}
-(instancetype)init
{
    self = [super init];
    if (self)
    {
        _startTimeStamp = kTimeIntervalInvalid;
        _videoOutputLayer = [[SNESVideoOutputLayer alloc] init];
        _SNES9xQueue = dispatch_queue_create("com.SNESConsole.SNES9xQueue",
                                             DISPATCH_QUEUE_SERIAL);
        SNES9xAdapterDelegateSet(self);
        
        // kick off the display-synchronzed callbacks
        _displayLink = [CADisplayLink displayLinkWithTarget: self
                                                   selector: @selector(displayLinkFired:)];
        [_displayLink addToRunLoop: [NSRunLoop mainRunLoop]
                           forMode: NSRunLoopCommonModes];
    }
    return self;
}
- (void) connectToScreen: (UIScreen *) screen
{
    if (screen != nil)
    {   
        [_displayLink invalidate];
        _displayLink = [screen displayLinkWithTarget: self
                                            selector: @selector(displayLinkFired:)];
    }
}
- (NSUInteger) frameNumberAtTimestamp: (CFTimeInterval) timestamp
{
    // overflows after ~2.26 years in 32 bit environment (at 60 Hz)
    // overflows after ~9.6 billion years in 64 bit environment (at 60 Hz)
    NSUInteger frameDeltaSinceFirstFrame;
    
    if (kTimeIntervalInvalid == _startTimeStamp)
    {
        // first time this method is called
        _frameDurationInUs   = SNES9xAdapterGetFrameTimeInMicroSeconds();
        NSLog(@"framerate: %2.0f",
               1.000f / (_frameDurationInUs / 1000000.00000));
        _startTimeStamp = timestamp;
    }
    
    // compute absolute framenumber
    CFTimeInterval timeDeltaInµs;
    timeDeltaInµs = (timestamp - _startTimeStamp) * kMicrosecondsPerSecond;
    
    frameDeltaSinceFirstFrame = (NSUInteger) floor(timeDeltaInµs / _frameDurationInUs);
    
    return frameDeltaSinceFirstFrame;
}
- (void) displayLinkFired: (CADisplayLink *) displayLink
{
    dispatch_async(self.SNES9xQueue,^
    {
        if (kSNESConsoleStateRunning != self.consoleState)
        {
            if (kSNESConsoleStatePowerOff == self.consoleState)
            {
                SNES9XAdapterTurnOff();
            }
            return;
        }

        NSUInteger frameToRenderNow = [self frameNumberAtTimestamp: self.displayLink.timestamp];
        if (frameToRenderNow != _currentlyRenderedFrame)
        {
            // skip frames if we are behind, do nothing if we are ahead
            NSUInteger frameDifference = frameToRenderNow - _currentlyRenderedFrame;
            
            NSInteger framesToSkip = (frameDifference - 1);
            
            if (framesToSkip > 0)
            {
                // we need to skip some frames to catch up again
                // tell the adapter to skip (frameDifference - 1)
                NSInteger framesToSkip = frameDifference -1;
                NSLog(@"skipping %ld frames", (unsigned long)framesToSkip);
                SNES9xAdapterSkipFrames(framesToSkip);
            }
            
            SNES9xAdapterSkipFrames(0);
            // render this frame
            SNES9xAdapterRunMainLoop();
            
            _currentlyRenderedFrame = frameToRenderNow;
        }
        else
        {
            // we are running fast, so we don't display this frame (as it is the same
            // one as last run
            ;
        }
    });
}

#pragma mark - SNES9xAdapterStateSupplying
-(void)SNES9xAdapterDidReset
{
    // the console has reset, we can resume the
    // clean up any state we still have and resume
    
    [self clearSynchronizationState];
    
    // resume running (the displaylink kep on firing)
    self.consoleState = kSNESConsoleStateRunning;
}

#pragma mark -SNES9XAdapterDelegate
-(void)flipFrontbuffer:(NSArray *)dimensions
{
    [_videoOutputLayer updateBufferCropWidth:[dimensions[0] intValue]
                                      height:[dimensions[1] intValue]];
    
    if(_videoOutputLayer.displayMainBuffer == YES)
    {
        SNES9xAdapterSetScreenBuffer(_imageBufferAlt);
        [_videoOutputLayer setNeedsDisplay];
        _videoOutputLayer.displayMainBuffer = NO;
    }
    else
    {
        SNES9xAdapterSetScreenBuffer(_imageBuffer);
        [_videoOutputLayer setNeedsDisplay];
        _videoOutputLayer.displayMainBuffer = YES;
    }
}
-(SNESControllerButton)buttonOuputControllerOne
{
    return self.controllerOne.controllerOutput;
}
-(SNESControllerButton)buttonOuputControllerTwo
{
    return self.controllerTwo.controllerOutput;
}

#pragma mark - 
- (void) clearSynchronizationState
{
#warning (JvA) these need to be atomic properties
    _framerate = 0;
    _startTimeStamp = kTimeIntervalInvalid;
    _frameDurationInUs = 0;
    _currentlyRenderedFrame = 0;
}

#pragma mark - Original hardware functions
- (BOOL) inserROMFileAtURL: (NSURL *) ROMFileURL
{
    BOOL ROMFileLoaded = NO;
    dispatch_async(self.SNES9xQueue,^
    {
        self.loadedROMFilePath = ROMFileURL.path;
    });
    return ROMFileLoaded;
}
- (void) powerOff
{
    self.on = NO;
    self.consoleState = kSNESConsoleStatePowerOff;
}
- (BOOL) powerOn
{
    BOOL powerOn = NO;
    if (self.loadedROMFilePath.length > 0)
    {
        powerOn = YES;
        dispatch_async(self.SNES9xQueue,^
        {
            if([self loadROM])
            {
                self.consoleState = kSNESConsoleStateRunning;
            }
        });
    }
    return powerOn;
}
- (void) reset // √
{
    self.consoleState = kSNESConsoleStateReset;
    
    // reset the console on it's own queue
    dispatch_async(self.SNES9xQueue, ^
    {
        // the console will call it's delegate (self) when it has finished
        // resetting itself
        SNES9xAdapterReset();
    });
    
    
}
- (BOOL) ejectROMFile
{
    BOOL ROMFileEjected = NO;
    if (!self.isOn)
    {
        ROMFileEjected = YES;
        dispatch_async(self.SNES9xQueue,^
                       {
                           self.loadedROMFilePath = nil;
                       });
    }
    return ROMFileEjected;
}
- (void) connectControllerOne: (id<SNESController>) controller
{
    self.controllerOne = controller;    
}
- (void) connectControllerTwo: (id<SNESController>) controller
{
    self.controllerTwo = controller;
}
- (void) disConnectControllerOne
{
    self.controllerOne = nil;
}
- (void) disConnectControllerTwo
{
    self.controllerTwo = nil;
}

#pragma mark - Additional software enabled features
- (void) pause
{
    if (!self.isPaused)
    {
        if (self.consoleState == kSNESConsoleStateRunning)
        {
            self.paused = YES;
            self.consoleState = kSNESConsoleStatePaused;
        }
    }
}
- (void) unPause
{
    if (self.isPaused)
    {
        self.paused = NO;
        self.consoleState = kSNESConsoleStateRunning;
        dispatch_async(self.SNES9xQueue,^
        {
            SNES9xAdapterUnPause();
        });
    }
}
- (void) saveState
{}
- (void) restoreStateFromFileAtURL: (NSURL *) savedStateURL
{}

#pragma mark -
- (BOOL) loadROM
{
    if (0 == self.loadedROMFilePath.length)
    {
        NSLog(@"No ROMFilePath, cannot load ROM");
        return NO;
    }
    // creating our buffers
    unsigned int _bufferWidth = 512;
    unsigned int _bufferHeight = 480;
    
    // RGBA888 format
    unsigned short defaultComponentCount = 4;
    unsigned short bufferBitsPerComponent = 8;
    unsigned int pixelSizeBytes = (_bufferWidth*bufferBitsPerComponent * defaultComponentCount) / 8 / _bufferWidth;
    if(pixelSizeBytes == 0)
        pixelSizeBytes = defaultComponentCount;
    unsigned int bufferBytesPerRow = _bufferWidth*pixelSizeBytes;
    
    // BGR 555 format
    defaultComponentCount = 3;
    bufferBitsPerComponent = 5;
    pixelSizeBytes = 2;
    bufferBytesPerRow = _bufferWidth*pixelSizeBytes;
    CGBitmapInfo bufferBitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder16Little;
    
    _imageBuffer =  (unsigned char*)calloc(_bufferWidth*_bufferHeight,
                                           pixelSizeBytes);
    
    SNES9xAdapterSetScreenBuffer(_imageBuffer);
    
    _imageBufferAlt = (unsigned char*)calloc(_bufferWidth * _bufferHeight,
                                             pixelSizeBytes);
    dispatch_sync(dispatch_get_main_queue(),^{
        SNESVideoOutputLayer * videoOutputLayer = (SNESVideoOutputLayer *) self.videoOutputLayer;
        [videoOutputLayer setImageBuffer:_imageBuffer
                                   width:_bufferWidth
                                  height:_bufferHeight
                        bitsPerComponent:bufferBitsPerComponent
                             bytesPerRow:bufferBytesPerRow
                              bitmapInfo:bufferBitmapInfo];
        [videoOutputLayer addAltImageBuffer:_imageBufferAlt];
    });
    
    char * ROMFileName = (char *)[self.loadedROMFilePath UTF8String];
    return SNES9xAdapterLoadROM(ROMFileName);
}

#pragma mark - Singleton
+ (instancetype)sharedConsole
{
    static dispatch_once_t onceToken = 0L;
    static SNESConsole * sharedConsole = nil;
    dispatch_once(&onceToken, ^{
        sharedConsole = [[super allocWithZone: NULL] init];
    });
    
    return sharedConsole;
}
+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedConsole];
}
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
@end








//
//  SNES.m
//  SuperNES
//
//  Created by Joride on 09/01/15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

#import "SNES.h"
#import "SNESConstants.h"
#import "SNES9xAdapter.h"
#import "SNESVideoOutputLayer.h"

NSString * const SRAMSaveFileExtension = @"srm";

char * const kSNESQueue = "com.SuperNES.SNESQueue";
CFTimeInterval const kSNESTimeIntervalInvalid = -1.00f;
CGFloat const kSNESMicrosecondsPerSecond = 1000000.00000000f;

@interface SNES ()
<SNES9xAdapterDelegate>

@property (atomic) SNESState state; // accessed by calling and internal thread
@property (nonatomic, copy) NSString * loadedROMFilePath;

@property (nonatomic, strong) CADisplayLink * displayLink;
@property (nonatomic, strong) dispatch_queue_t queue;

@property (atomic) uint8_t * secondaryImageBuffer;
@property (atomic) uint8_t * primaryImageBuffer;

@property (nonatomic, strong) id<SNESController> controllerOne;
@property (nonatomic, strong) id<SNESController> controllerTwo;

@end

@implementation SNES
{
    // graphics
    uint32_t _bufferWidth;
    uint32_t _bufferHeight;
    uint32_t _pixelSizeBytes;

    // synching
    NSUInteger      _framerate;
    CFTimeInterval  _startTimeStamp;
    CFTimeInterval  _frameDurationInUs;
    NSUInteger      _currentlyRenderedFrame;
}
#pragma mark - Controllers
- (void) connectControllerOne:(id<SNESController>)controller
{
    self.controllerOne = controller;
}
- (void) connectControllerTwo:(id<SNESController>)controller
{
    self.controllerTwo = controller;
}

#pragma mark - Console Hardware buttons
-(NSString *)currentlyInsertedROM
{
    return self.loadedROMFilePath;
}
- (BOOL) inserROMFileAtPath: (NSString *) ROMFilePath
{
    BOOL ROMFileLoaded = NO;
    if (nil == self.loadedROMFilePath)
    {
        // load the ROM
        self.loadedROMFilePath = ROMFilePath;
        ROMFileLoaded = YES;
    }
    return ROMFileLoaded;
}
- (BOOL) ejectROMFile
{
    BOOL ROMFileEjected = NO;
    if ((self.state & kSNESStateOn) != kSNESStateOn &&
        self.loadedROMFilePath != nil)
    {
        // only able to eject file when SNES not running
        self.loadedROMFilePath = nil;
        ROMFileEjected = YES;
    }
    
    return ROMFileEjected;
}
- (BOOL) powerOnWithDelegate:(id<SNESDelegate>)delegate
{
    NSParameterAssert(delegate);
    self.delegate = delegate;
    
    BOOL powerOn = NO;
    if ((self.state & kSNESStateOn) != kSNESStateOn &&
        self.loadedROMFilePath != nil)
    {
        // not yet turned on and a loaded ROM is present
        [self resetTimerBookkeeping];

        powerOn = YES;
        self.state = kSNESStateOn;
        
        dispatch_async(self.queue, ^
        {
            // on SNES queue?
            if([self loadROM])
            {
                self.state = kSNESStateOn;
            }
        });
    }
    return powerOn;
}
- (BOOL) powerOff
{
    BOOL powerOff = NO;
    if ((self.state & kSNESStateOn) == kSNESStateOn)
    {
        powerOff = YES;
        // turn the On-bit to zero, leave all others the same
        self.state = self.state & (~kSNESStateOn);

        // set the off-bit
        self.state |= kSNESStateOff;
    }
    return powerOff;
}
- (BOOL) reset
{
    BOOL reset = NO;
    // only do something if the machine is turned on
    
    if ((self.state & kSNESStateOn) == kSNESStateOn)
    {
        reset = YES;
        dispatch_async(self.queue, ^
        {
            SNES9xAdapterReset();
        });
    }
    return reset;
}
- (BOOL) pause
{
    BOOL pause = NO;
    if ((self.state & kSNESStateOn) == kSNESStateOn &&
        (self.state & kSNESStatePaused) != kSNESStatePaused)
    {
        self.state |= kSNESStatePaused;
        pause = YES;

        // .. pause the emulator (or displaylink?)
    }
    return pause;
}
- (BOOL) unPause
{
    // only pause if the machine is turned on and not running
    BOOL unPaused = NO;
    if ((self.state & kSNESStatePaused) == kSNESStatePaused)
    {
        self.state &= ~kSNESStatePaused;
        unPaused = YES;
        
        // .. unpause the emulator (or displaylink?)
    }
    return unPaused;
}

-(BOOL)isPaused
{
    BOOL isPaused = ((self.state & kSNESStatePaused) == kSNESStatePaused);
    return isPaused;
}

#pragma mark - SNES9x
- (void) saveStateAtPath: (NSString *) path
{
    char * saveStatePath = (char *)path.UTF8String;
    SNES9xAdapterSaveGameState(saveStatePath);
}
- (void) loadStateFromFileAtPath: (NSString *) path
{
    char * UTF8Path = (char *) path.UTF8String;
    SNES9xAdapterLoadGameState(UTF8Path);
}


- (BOOL) loadROM
{
    if (0 == self.loadedROMFilePath.length)
    {
        NSLog(@"No ROMFilePath, cannot load ROM");
        return NO;
    }
    
    const char * ROMFileName = [self.loadedROMFilePath UTF8String];
    BOOL SRAMFileExists = [self doesSRAMSaveFileExist];
    const char * SRAMSavePath = (SRAMFileExists) ? [self SRAMSavePath] : NULL;

    return  SNES9xAdapterLoadROM(ROMFileName,
                                 SRAMSavePath);
}
- (BOOL) doesSRAMSaveFileExist
{
    NSString * SRAMSavePath = [self SRAMSavePathAsString];
    NSFileManager * fileManager = [NSFileManager defaultManager];


    BOOL SRAMFileExists = [fileManager fileExistsAtPath: SRAMSavePath
                                            isDirectory: NULL];
    return SRAMFileExists;
}
-(NSString *)SRAMSavePathAsString
{
    NSString * SRAMSavePathString;
    if (nil != self.loadedROMFilePath)
    {
        SRAMSavePathString = [self.loadedROMFilePath stringByDeletingPathExtension];
        SRAMSavePathString = [SRAMSavePathString stringByAppendingPathExtension: SRAMSaveFileExtension];
    }
    else
    {
        NSLog(@"NO SRAMSaveFile path, because there seems to be no ROM loaded");
    }
    return SRAMSavePathString;
}

#pragma mark - SNES9xAdapterDelegate
-(const char *)SRAMSavePath
{
    NSAssert(nil != self.delegate, @"A delegate is required");
    NSString * SRAMPathString = [self.delegate SNESConsole: self
                               SRAMPathForRomWithFilePath: self.currentlyInsertedROM];
    NSAssert(nil != SRAMPathString, @"A path is required to store the SRAM data");
    
    const char * SRAMSavePath = [SRAMPathString UTF8String];
    return SRAMSavePath;
}
-(void)updateGraphicsBufferWithPixelWidth: (int)width
                              pixelHeight: (int)height
{
    dispatch_async(dispatch_get_main_queue(), ^{
        SNESVideoOutputLayer * videoOutputLayer;
        videoOutputLayer = (SNESVideoOutputLayer *) self.videoOutputLayer;

        [videoOutputLayer updateGraphicsBufferCropWidth: width
                                                 height: height];

        if(videoOutputLayer.shouldDisplayPrimaryBuffer == YES)
        {
            SNES9xAdapterSetScreenBuffer(_secondaryImageBuffer);
            [videoOutputLayer setNeedsDisplay];
            videoOutputLayer.displayPrimaryBuffer = NO;
        }
        else
        {
            SNES9xAdapterSetScreenBuffer(_primaryImageBuffer);
            [videoOutputLayer setNeedsDisplay];
            videoOutputLayer.displayPrimaryBuffer = YES;
        }
    });
}

#pragma mark - Running the SNES runloop
- (void) displayLinkFired: (CADisplayLink *) displayLink
{
    void (^runMainLoopIfRequired)() = ^
    {
        // only render a frame if the SNES is both ON and NOT paused
        BOOL isSNESOnAndNotPaused;
        isSNESOnAndNotPaused = (self.state & kSNESStateOn) == kSNESStateOn &&
                               (self.state & kSNESStatePaused) != kSNESStatePaused;
        
        if (isSNESOnAndNotPaused)
        {
            SNES9xAdapterReportButtonOutputForController(self.controllerOne.output,
                                                         0);
            if (nil != self.controllerTwo) {
                SNES9xAdapterReportButtonOutputForController(self.controllerTwo.output,
                                                             1);
            }
            // find out what frame should be rendered at this moment in time
            NSUInteger frameToRenderNow;
            frameToRenderNow = [self frameNumberAtTimestamp:
                                self.displayLink.timestamp];
            
            // skip frames if we are behind, do nothing if we are ahead
            if (frameToRenderNow != _currentlyRenderedFrame)
            {
                // we are not ahead
                NSUInteger frameDifference;
                frameDifference = frameToRenderNow - _currentlyRenderedFrame;
                NSInteger framesToSkip = (frameDifference - 1);
                
                // we are lagging behind, log a message
                if (framesToSkip > 0)
                {
                    // we need to skip some frames to catch up again
//                    NSLog(@"skipping %ld frames",
//                          (unsigned long)framesToSkip);
                    SNES9xAdapterSkipFrames(framesToSkip);
                }

                SNES9xAdapterSkipFrames(0);

                // render this frame
                SNES9xAdapterRunMainLoop();

                _currentlyRenderedFrame = frameToRenderNow;
            }
            else
            {
                // we are running fast, so we don't display this frame (as it
                // is the same one as last run
                ;
            }
        }
        else if ((self.state & kSNESStateOff) == kSNESStateOff)
        {
            SNES9xAdapterTurnOff();
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [self generateNoiseGraphics];
            });

            // we call this method ourselves, as there is no callback
            // from the SNES9xAdapter, since we are do not run the mainloop
            // if we are here.
            [self updateGraphicsBufferWithPixelWidth: _bufferWidth
                                         pixelHeight: _bufferHeight];
        }
    };
    
    dispatch_async(self.queue, runMainLoopIfRequired);
}
- (void) generateNoiseGraphics
{
    /*
     2 bytes per pixel, 5 bits per color, only first 3 of the five bytes
     are used, most significant bit of byte is ignored:
     b0RRR00GG G00BBB00
     */
    uint16_t white = 0b0111001110011100; // white
    uint16_t black = 0b0000000000000000; // black

    uint16_t patterns[2] = {white, black};

    // size of the uint8_t buffer
    size_t bufferSize = _bufferWidth * _bufferHeight * _pixelSizeBytes;

    // we cast the arrays to uint16_t
    uint16_t * castPrimaryBuffer    = (uint16_t *) _primaryImageBuffer;
    uint16_t * castSecondaryBuffer  = (uint16_t *) _secondaryImageBuffer;

    // get the correct sizes, as the original arrays are of type uint8_t
    NSInteger factor = sizeof(uint16_t) / sizeof(uint8_t);
    NSInteger castBufferSize = bufferSize /  factor;

    for (NSInteger index = 0; index < castBufferSize; index++ )
    {
        NSUInteger randomNumber = rand() % 2;
        uint16_t patternPrimary = patterns[randomNumber];
        uint16_t patternSecondary = patterns[randomNumber];

        if (NULL != _primaryImageBuffer)
        {
            castPrimaryBuffer[index] = patternPrimary;
        }
        if (NULL != _secondaryImageBuffer)
        {
            castSecondaryBuffer[index] = patternSecondary;
        }
    }
}
- (NSUInteger) frameNumberAtTimestamp: (CFTimeInterval) timestamp
{
    // overflows after ~2.26 years in 32 bit environment (at 60 Hz)
    // overflows after ~9.6 billion years in 64 bit environment (at 60 Hz)
    NSUInteger frameDeltaSinceFirstFrame;
    
    if (kSNESTimeIntervalInvalid == _startTimeStamp)
    {
        // first time this method is called
        _frameDurationInUs = SNES9xAdapterGetFrameTimeInMicroSeconds();
        NSLog(@"framerate: %2.0f",
              1.000f / (_frameDurationInUs / 1000000.00000));
        _startTimeStamp = timestamp;
    }
    
    // compute absolute framenumber
    CFTimeInterval timeDeltaInµs;
    timeDeltaInµs = (timestamp - _startTimeStamp) * kSNESMicrosecondsPerSecond;
    
    frameDeltaSinceFirstFrame = (NSUInteger) floor(timeDeltaInµs /
                                                   _frameDurationInUs);
    
    return frameDeltaSinceFirstFrame;
}
- (void) resetTimerBookkeeping
{
    _startTimeStamp = kSNESTimeIntervalInvalid;
    _currentlyRenderedFrame = 0;
}
- (void) setDisplayLink: (CADisplayLink *) displayLink
{
    // invalidate whatever displaylink we have now
    [_displayLink invalidate];
    _displayLink = displayLink;
    [_displayLink addToRunLoop: [NSRunLoop mainRunLoop]
                       forMode: NSRunLoopCommonModes];
}
- (SEL)displayLinkSelector
{
    return @selector(displayLinkFired:);
}
#pragma mark -
- (void) setupPixelBuffers
{
    _bufferWidth = 512;
    _bufferHeight = 480;
    _pixelSizeBytes = 2;

    // BGR 555 format
    uint16_t bufferBitsPerComponent = 5;
    uint32_t bufferBytesPerRow = _bufferWidth * _pixelSizeBytes;
    CGBitmapInfo bufferBitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder16Little;

    _primaryImageBuffer =  (uint8_t*)calloc(_bufferWidth * _bufferHeight,
                                            _pixelSizeBytes);

    _secondaryImageBuffer = (uint8_t*)calloc(_bufferWidth * _bufferHeight,
                                             _pixelSizeBytes);

    SNESVideoOutputLayer * videoOutputLayer;
    videoOutputLayer = [[SNESVideoOutputLayer alloc] init];
    [videoOutputLayer setImageBuffer:_primaryImageBuffer
                               width:_bufferWidth
                              height:_bufferHeight
                    bitsPerComponent:bufferBitsPerComponent
                         bytesPerRow:bufferBytesPerRow
                          bitmapInfo:bufferBitmapInfo];
    [videoOutputLayer addSecondaryImageBuffer:_secondaryImageBuffer];
    
    _videoOutputLayer = videoOutputLayer;
    
    SNES9xAdapterSetScreenBuffer(_primaryImageBuffer);
}

#pragma mark - Singleton
+ (instancetype)sharedSNES
{
    static dispatch_once_t onceToken = 0L;
    static SNES * SNES = nil;
    dispatch_once(&onceToken, ^
    {
        SNES = [[super allocWithZone: NULL] init];
    });
    
    return SNES;
}
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // Intialize random number generator
        time_t t;
        srand((unsigned) time(&t));

        // initialize some variables and the internal queue
        _startTimeStamp = kSNESTimeIntervalInvalid;
        _queue = dispatch_queue_create(kSNESQueue, DISPATCH_QUEUE_SERIAL);
        
        [self setupPixelBuffers];
        
        SNES9xAdapterDelegateSet(self);

        // kick off the game loop
        CADisplayLink * displayLink = [CADisplayLink
                                       displayLinkWithTarget: self
                                       selector: [self displayLinkSelector]];
        [self setDisplayLink: displayLink];
    }
    return self;
}

#pragma mark -
- (CGSize) nativeVideoSize
{
    // This should be coming from SNES9xAdapter (who gets it from S9x)
    return CGSizeMake(512.00f,
                      480.00f);
}
@end

//
//  SNES9xAdapter.cpp
//  SuperNES
//
//  Created by Joride on 28/12/14.
//  Copyright (c) 2014 KerrelInc. All rights reserved.
//

#include "SNES9xAdapter.h"

#include "snes9x.h"
#include "apu.h"
#include "controls.h"
#include "display.h"
#include "memmap.h"
#include "snapshot.h"


#pragma mark - declarations
static void AQBufferCallback(void* userdata,
                             AudioQueueRef outQ,
                             AudioQueueBufferRef outQB);
void InitializeSNESAudio();
void DeinitializeSNESAudio();
void SNES9xAdapterReset();

#pragma mark -
extern "C" void SNES9xAdapterSetScreenBuffer(unsigned char* screen)
{
    GFX.Screen = (uint16 *) screen;
}

static NSObject <SNES9xAdapterDelegate> * __SNES9xAdapterDelegate = nil;
extern "C" void SNES9xAdapterDelegateSet(id<SNES9xAdapterDelegate> delegate)
{
    __SNES9xAdapterDelegate = delegate;
}
extern "C" id<SNES9xAdapterDelegate> SNES9xAdapterDelegateGet()
{
    return __SNES9xAdapterDelegate;
}
extern "C" void SNES9xAdapterDelegateClear()
{
    __SNES9xAdapterDelegate = nil;
}

void SNES9xAdapterSkipFrames(NSUInteger numberOfFramesToSkip)
{
    if (numberOfFramesToSkip == 0)
    {
        IPPU.RenderThisFrame = true;
    }
    else
    {
        IPPU.RenderThisFrame = false;
    }

    IPPU.SkippedFrames = (uint32) numberOfFramesToSkip;
}
NSInteger SNES9xAdapterGetFrameTimeInMicroSeconds()
{
    return (NSInteger) Settings.FrameTime;
}
void SNES9xAdapterRunMainLoop()
{
    S9xMainLoop();
    S9xSetSoundMute(FALSE);
}
void SNES9xAdapterSetupControllers()
{
    S9xUnmapAllControls();
    S9xSetController(0, CTL_JOYPAD, 0, 0, 0, 0); // controller one
    S9xSetController(1, CTL_JOYPAD, 1, 0, 0, 0); // controller two

    BOOL shouldPoll = NO;
    
    if (!S9xMapButton(kSNESControllerOutputUp,
                      S9xGetCommandT("Joypad1 Up"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputDown,
                      S9xGetCommandT("Joypad1 Down"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputLeft,
                      S9xGetCommandT("Joypad1 Left"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputRight,
                      S9xGetCommandT("Joypad1 Right"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputShoulderLeft,
                       S9xGetCommandT("Joypad1 L"),
                       shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputShoulderRight,
                      S9xGetCommandT("Joypad1 R"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputStart,
                       S9xGetCommandT("Joypad1 Start"),
                       shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputSelect,
                      S9xGetCommandT("Joypad1 Select"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }if (!S9xMapButton(kSNESControllerOutputA,
                       S9xGetCommandT("Joypad1 A"),
                       shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputDown,
                      S9xGetCommandT("Joypad1 Down"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }if (!S9xMapButton(kSNESControllerOutputB,
                       S9xGetCommandT("Joypad1 B"),
                       shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputX,
                      S9xGetCommandT("Joypad1 X"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputY,
                      S9xGetCommandT("Joypad1 Y"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    ///////////////////////
    //  CONTROLLER 2     //
    ///////////////////////
    if (!S9xMapButton(kSNESControllerOutputUp | kSNESControllerIdentifierTwo,
                      S9xGetCommandT("Joypad2 Up"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputDown | kSNESControllerIdentifierTwo,
                      S9xGetCommandT("Joypad2 Down"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputLeft | kSNESControllerIdentifierTwo,
                      S9xGetCommandT("Joypad2 Left"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputRight | kSNESControllerIdentifierTwo,
                      S9xGetCommandT("Joypad2 Right"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputShoulderLeft | kSNESControllerIdentifierTwo,
                      S9xGetCommandT("Joypad2 L"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputShoulderRight | kSNESControllerIdentifierTwo,
                      S9xGetCommandT("Joypad2 R"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputStart | kSNESControllerIdentifierTwo,
                      S9xGetCommandT("Joypad2 Start"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputSelect | kSNESControllerIdentifierTwo,
                      S9xGetCommandT("Joypad2 Select"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }if (!S9xMapButton(kSNESControllerOutputA | kSNESControllerIdentifierTwo,
                       S9xGetCommandT("Joypad2 A"),
                       shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputDown | kSNESControllerIdentifierTwo,
                      S9xGetCommandT("Joypad2 Down"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }if (!S9xMapButton(kSNESControllerOutputB | kSNESControllerIdentifierTwo,
                       S9xGetCommandT("Joypad2 B"),
                       shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputX | kSNESControllerIdentifierTwo,
                      S9xGetCommandT("Joypad2 X"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    if (!S9xMapButton(kSNESControllerOutputY | kSNESControllerIdentifierTwo,
                      S9xGetCommandT("Joypad2 Y"),
                      shouldPoll))
    {
        printf("S9xMapButton(failed)");
    }
    
    S9xReportControllers();
}
void SNES9xAdapterReportButtonOutputForController(SNESControllerOutput controllerOutput,
                                                  uint8_t controllerIndex)
{
    SNESControllerIdentifier controllerID = kSNESControllerIdentifierOne;
    if (controllerIndex == 0)
    {
        // controller one
        controllerID = kSNESControllerIdentifierOne;
    }
    else if (controllerIndex == 1)
    {
        // controller two
        controllerID = kSNESControllerIdentifierTwo;
    }
    else
    {
#if DEBUG
#else
        NSAssert(NO, @"SNES9xAdapter only supports two controllers (argument 'controllerIndex' must be 0 or 1.");
#endif
    }

    const NSInteger numberOfButtons = 12;
    static SNESControllerOutput buttons[numberOfButtons] =
    {
        kSNESControllerOutputUp,
        kSNESControllerOutputLeft,
        kSNESControllerOutputDown,
        kSNESControllerOutputRight,
        kSNESControllerOutputStart,
        kSNESControllerOutputSelect,
        kSNESControllerOutputShoulderLeft,
        kSNESControllerOutputShoulderRight,
        kSNESControllerOutputA,
        kSNESControllerOutputB,
        kSNESControllerOutputX,
        kSNESControllerOutputY
    };

    uint32_t button = (uint32_t) controllerOutput;
    for (NSInteger buttonIndex = 0; buttonIndex < numberOfButtons; buttonIndex++)
    {
        SNESControllerOutput output = buttons[buttonIndex];
        S9xReportButton(output | controllerID,
                        (button & output) == output);
    }

//    if (num > 100)
//    {
//        NSLog(@"reporting buttons");
//        S9xReportButton(kSNESControllerOutputStart, YES);
//        num = 0;
//    }
//    else
//    {
//        S9xReportButton(kSNESControllerOutputStart, NO);
//    }
//    num ++;

}

bool __controllerOneButtonStartPressed = false;
bool __controllerTwoButtonStartPressed = false;
bool S9xPollButton (uint32 button, bool* pressed)
{
/*    id<SNES9xAdapterDelegate> delegate = SNES9xAdapterDelegateGet();
    
    SNESControllerOutput buttonOuput = kSNESControllerNone;
    uint8_t controllerIndex = 0;
    
    if (((button >> 12) & 1) == 1)
    {
        // controller two
        controllerIndex = 1;
        buttonOuput = delegate.buttonOuputControllerTwo;
        if (
            ((buttonOuput >> 4) & 1) == 1// the output contains start
            )
        {
            __controllerTwoButtonStartPressed = true;
        }
    }
    else
    {
        // controller one
        buttonOuput =  delegate.buttonOuputControllerOne;
        if (
            ((buttonOuput >> 4) & 1) == 1 // the output contains start
            )
        {
            __controllerOneButtonStartPressed = true;
        }
        
    }
    
    BOOL buttonPressed = 0;
    switch (button)
    {
        case kSNESControllerOneButtonUp:
            buttonPressed = ((buttonOuput >> 0) & 1) == 1;
            break;
        case kSNESControllerOneButtonLeft:
            buttonPressed = ((buttonOuput >> 1) & 1) == 1;
            break;
        case kSNESControllerOneButtonDown:
            buttonPressed = ((buttonOuput >> 2) & 1) == 1;
            break;
        case kSNESControllerOneButtonRight:
            buttonPressed = ((buttonOuput >> 3) & 1) == 1;
            break;
        case kSNESControllerOneButtonStart:
            if (0 == controllerIndex)
            {
                buttonPressed = __controllerOneButtonStartPressed;
                __controllerOneButtonStartPressed = false;
            }
            else
            {
                buttonPressed = __controllerTwoButtonStartPressed;
                __controllerTwoButtonStartPressed = false;
            }
            
            break;
        case kSNESControllerOneButtonSelect:
            buttonPressed = ((buttonOuput >> 5) & 1) == 1;
            break;
        case kSNESControllerOneButtonL:
            buttonPressed = ((buttonOuput >> 6) & 1) == 1;
            break;
        case kSNESControllerOneButtonR:
            buttonPressed = ((buttonOuput >> 7) & 1) == 1;
            break;
        case kSNESControllerOneButtonA:
            buttonPressed = ((buttonOuput >> 8) & 1) == 1;
            break;
        case kSNESControllerOneButtonB:
            buttonPressed = ((buttonOuput >> 9) & 1) == 1;
            break;
        case kSNESControllerOneButtonX:
            buttonPressed = ((buttonOuput >> 10) & 1) == 1;
            break;
        case kSNESControllerOneButtonY:
            buttonPressed = ((buttonOuput >> 11) & 1) == 1;
            break;
        default:
            break;
    }
    *pressed = buttonPressed;
    return true;


 */
    return 0;
}
void SNES9xAdapterReset()
{
    S9xReset();
}
extern "C" void SNES9xAdapterSetSettings()
{
    // recommended defaults from SNES9x documentation
    memset(&Settings, 0, sizeof(Settings));
    Settings.MouseMaster = true;
    Settings.SuperScopeMaster = true;
    Settings.MultiPlayer5Master = true;
    Settings.JustifierMaster = true;
    Settings.SoundPlaybackRate = 32000;
    Settings.Stereo = true;
    Settings.SixteenBitSound = true;
    Settings.Transparency = true;
    Settings.SupportHiRes = true;

    // smallest possible value, if zero SNES9x will not call the S9xAutoSaveSRAM() function
    Settings.AutoSaveDelay = 1;
    
    // additional
    Settings.FrameTimePAL = 20000;  // microseconds (1/50)
    Settings.FrameTimeNTSC = 16667; // microseconds (1/60)
    Settings.SoundInputRate = 32000;
    
    // don't now why, but this seems to help syncing video and audio
    Settings.SoundSync = FALSE;
    Settings.SkipFrames = 200;
}

extern "C" void SNES9xAdapterTurnOff()
{
    DeinitializeSNESAudio();
    Memory.Deinit();
    S9xDeinitAPU();
    S9xGraphicsDeinit();
}
extern "C" void SNES9xAdapterS9xDidRenderScreenBuffer(int width, int height)
{
    id<SNES9xAdapterDelegate> delegate = SNES9xAdapterDelegateGet();

    if ([delegate respondsToSelector: @selector(updateGraphicsBufferWithPixelWidth:pixelHeight:)])
    {
        [delegate updateGraphicsBufferWithPixelWidth: width
                                         pixelHeight: height];
    }
    else
    {
        NSLog(@"WARNING: Delegate does not implement method, probably no video visible");
    }

}

extern "C" BOOL SNES9xAdapterLoadROM(const char * ROMFilePath,
                                     const char * SRAMSaveFilePath)
{
    BOOL ROMLoaded = YES;
    if (NULL == ROMFilePath ||
        strlen(ROMFilePath) == 0)
    {
        fprintf(stderr, "%s failed: no ROMFilePath.\n",
                __PRETTY_FUNCTION__);
        
        return ROMLoaded;
    }
    
    SNES9xAdapterSetSettings();
    
    CPU.Flags = 0;
    
    BOOL isMemoryInitialized = Memory.Init();
    BOOL isAPUInitialized = S9xInitAPU();
    
    if (!isMemoryInitialized || !isAPUInitialized)
    {
        fprintf(stderr, "%s failed: SNES9x memory or APU could not be initialized.\n",
                __PRETTY_FUNCTION__);
        SNES9xAdapterTurnOff();
        ROMLoaded = NO;
    }
    else
    {
        int samplecount = Settings.SoundPlaybackRate/(Settings.PAL ? 50 : 60);
        int soundBufferSize = samplecount<<(1+(Settings.Stereo?1:0));
        S9xInitSound(soundBufferSize, 0);
        S9xSetSoundMute(TRUE);
        
        S9xReset();
        
        SNES9xAdapterSetupControllers();
        
        uint32	saved_flags = CPU.Flags;
        bool8	loaded = FALSE;
        
        if (NULL != ROMFilePath)
        {
            loaded = Memory.LoadROM(ROMFilePath);
        }
        if (NULL != SRAMSaveFilePath)
        {
            if (!Memory.LoadSRAM(SRAMSaveFilePath))
            {
                NSLog(@"Failed loading SRAM from %s",
                      SRAMSaveFilePath);
            }
        }

        if (!loaded)
        {
            SNES9xAdapterTurnOff();
            ROMLoaded = NO;
            fprintf(stderr, "%s failed: error opening the ROM file at path %s.\n",
                    __PRETTY_FUNCTION__,
                    ROMFilePath);
            
        }
        else
        {
            CPU.Flags = saved_flags;
            Settings.StopEmulation = FALSE;
            GFX.Pitch = 512*2;
            S9xGraphicsInit();
            InitializeSNESAudio();
            S9xSetSoundMute(FALSE);
        }
    }
    return ROMLoaded;
}
void SNES9xAdapterSaveGameState(char * savePath)
{
    if (S9xFreezeGame(savePath))
    {
        NSLog(@"Saved to %s", savePath);
    }
    else
    {
        NSLog(@"Failed to save to %s", savePath);
    }
}
void SNES9xAdapterLoadGameState(char * savePath)
{
    if(S9xUnfreezeGame(savePath))
    {
        NSLog(@"Loaded from %s", savePath);
    }
    else
    {
        NSLog(@"Failed to load from %s", savePath);
    }
}
void SNES9xAdapterS9xRequestedSaveSRAM(void)
{
    
    if (nil != __SNES9xAdapterDelegate)
    {
        const char * savePath = [__SNES9xAdapterDelegate SRAMSavePath];
        if (NULL == savePath)
        {
            NSLog(@"Could not save SRAM: no path (NULL)");
        }
        else
        {
            if (!Memory.SaveSRAM(savePath))
            {
                NSLog(@"Could not save SRAM to path %s",
                      savePath);
            }
        }
    }
    else
    {
        NSLog(@"Could not save SRAM, no delegate to ge the save path from");
    }
}



#pragma mark - Audio
static AudioQueueRef _audioQueue = NULL;
static AudioQueueBufferRef _audioBuffers[6];
static AudioStreamBasicDescription _audioStreamDescription;

void DeinitializeSNESAudio()
{
    if(_audioQueue != nil)
    {
        AudioQueueStop(_audioQueue, YES);
    }
}
void InitializeSNESAudio()
{
    if(_audioQueue != nil)
    {
        AudioQueueDispose(_audioQueue, true);
    }
    
    Float64 sampleRate = 32000.00f;
    
    _audioStreamDescription.mSampleRate = sampleRate;
    _audioStreamDescription.mFormatID = kAudioFormatLinearPCM;
    _audioStreamDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    _audioStreamDescription.mBytesPerPacket    = 4;
    _audioStreamDescription.mFramesPerPacket   = 1;
    _audioStreamDescription.mBytesPerFrame     = 4;
    _audioStreamDescription.mChannelsPerFrame  = 2;
    _audioStreamDescription.mBitsPerChannel    = 16;
    
    
    /* Pre-buffer before we turn on audio */
    OSStatus err;
    err = AudioQueueNewOutput(&_audioStreamDescription,
                              AQBufferCallback,
                              NULL,
                              NULL,
                              kCFRunLoopCommonModes,
                              0,
                              &_audioQueue);
    
    for(int i = 0; i < 6; i++)
    {
        err = AudioQueueAllocateBuffer(_audioQueue, 2132, &_audioBuffers[i]);
        
        memset(_audioBuffers[i]->mAudioData, 0, 2132);
        
        _audioBuffers[i]->mAudioDataByteSize = 2132;
        AudioQueueEnqueueBuffer(_audioQueue, _audioBuffers[i], 0, NULL);
    }
    
    err = AudioQueueStart(_audioQueue, NULL);
}
static void AQBufferCallback(void* userdata,
                             AudioQueueRef outQ,
                             AudioQueueBufferRef outQB)
{
    outQB->mAudioDataByteSize = 2132;
    AudioQueueSetParameter(outQ, kAudioQueueParam_Volume, 1.0f);
    
    int totalSamples = -2;
    int totalBytes = totalSamples;
    int samplesToUse = totalSamples;
    int bytesToUse = totalBytes;
    bytesToUse *= 2;
    totalBytes *= 2;
    
    bytesToUse = 2132;
    samplesToUse = 2132/2;
    
    
    // calculating the audio offset
    int samplesShouldBe = 2132/2;
    
    int audioOffset = 0;
    audioOffset -= (totalSamples-samplesShouldBe)*(1.0/32000)*1000-50;
    if(audioOffset > 8000)
        audioOffset = 4000;
    else if(audioOffset < -8000)
        audioOffset = -4000;
    
    if(samplesToUse > 0)
        S9xMixSamples((unsigned char*)outQB->mAudioData, samplesToUse);
    
    if(bytesToUse < 2132)
    {
        if(bytesToUse == 0)
        {
            // do nothing here... we didn't copy anything... scared that if i write something to the output buffer, we'll get chirps and stuff
            //printf("0 sampes available\n");
        }
        else
        {
            //printf("Fixing %i of %i\n", bytesToUse, SI_SoundBufferSizeBytes);
            // sounds wiggly
            memset(((unsigned char*)outQB->mAudioData)+bytesToUse, ((unsigned char*)outQB->mAudioData)[bytesToUse-1], 2132-bytesToUse);
        }
    }
    
    
    AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
}
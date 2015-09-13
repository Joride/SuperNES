//
//  SNES9xAdapter.h
//  SuperNES
//
//  Created by Joride on 28/12/14.
//  Copyright (c) 2014 KerrelInc. All rights reserved.
//

#ifndef __SuperNES__SNES9xAdapter__
#define __SuperNES__SNES9xAdapter__

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SNESConstants.h"
#include <sys/stat.h>
#include <sys/time.h>
#include "port.h"

@protocol SNES9xAdapterDelegate <NSObject>
@required;
- (void)updateGraphicsBufferWithPixelWidth: (int) width
                               pixelHeight: (int) height;
- (const char *) SRAMSavePath;

@end


#ifdef __cplusplus
extern "C"
{
#endif

#pragma mark - Called from updstream code, to command S9x.

    void SNES9xAdapterReset();

    void SNES9xAdapterRunMainLoop();
    
    NSInteger SNES9xAdapterGetFrameTimeInMicroSeconds();
    
    void SNES9xAdapterSkipFrames(NSUInteger numberOfFramesToSkip);

    void SNES9xAdapterDelegateSet(id<SNES9xAdapterDelegate> delegate);
    
    void SNES9xAdapterDelegateClear();
    
    void SNES9xAdapterSetScreenBuffer(unsigned char * screen);
    
    BOOL SNES9xAdapterLoadROM(const char * ROMFilePath,
                              const char * SRAMSaveFilePath);
    
    void SNES9xAdapterTurnOff();

    void SNES9xAdapterReportButtonOutputForController(
                                                      SNESControllerOutput controllerOutput,
                                                      uint8_t controllerIndex);

    void SNES9xAdapterSaveGameState(char * savePath);

    void SNES9xAdapterLoadGameState(char * savePath);

#pragma mark - Called from S9x, to inform upstream code

    void SNES9xAdapterS9xDidRenderScreenBuffer(int width, int height);

    void SNES9xAdapterS9xRequestedSaveSRAM(void);
    
#ifdef __cplusplus
}
#endif

#endif /* defined(__SuperNES__SNES9xAdapter__) */

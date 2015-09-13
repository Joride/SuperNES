//
//  Snes9xCallbacks.cpp
//  SuperNES
//
//  Created by Joride on 07/02/15.
//  Copyright (c) 2012 Joride. All rights reserved.
//

#include "SNES9xAdapter.h"

#include "conffile.h"
#include "controls.h"
#include "display.h"

#include "memmap.h" // needed for S9xGetFilename()

void S9xExit ()
{
    NSCAssert(NO, @"not implemented");
}
void S9xParsePortConfig(ConfigFile &a, int pass)
{
    NSCAssert(NO, @"not implemented");
}
void S9xExtraUsage (void)
{
    NSCAssert(NO, @"not implemented");
}
void S9xParseArg (char** a, int &b, int c)
{
    NSCAssert(NO, @"not implemented");
}

const char* S9xGetDirectory (enum s9x_getdirtype dirtype)
{
    NSCAssert(NO, @"not implemented");
    return 0;
}

bool8 S9xDoScreenshot (int width, int height)
{
    NSCAssert(NO, @"not implemented");
    return 0;
}

const char* S9xStringInput (const char* s)
{
    NSCAssert(NO, @"not implemented");
    return 0;
}

void S9xHandlePortCommand (s9xcommand_t cmd, int16 data1, int16 data2)
{
    NSCAssert(NO, @"not implemented");
    return;
}

bool S9xPollAxis (uint32 id, int16* value)
{
    NSCAssert(NO, @"not implemented");
    return 0;
}

void S9xToggleSoundChannel (int c)
{
    NSCAssert(NO, @"not implemented");
}

bool8 S9xContinueUpdate (int width, int height)
{
    NSCAssert(NO, @"not implemented");
    return 0;
}

bool S9xPollPointer (uint32 id, int16* x, int16* y)
{
    NSCAssert(NO, @"not implemented");
    return 0;
}

const char* S9xChooseFilename (bool8 read_only)
{
    NSCAssert(NO, @"not implemented");
    return 0;
}

const char* S9xChooseMovieFilename (bool8 read_only)
{
    NSCAssert(NO, @"not implemented");
    return 0;
}

void S9xSetPalette ()
{
    ; // not called in optimized build
}

bool8 S9xOpenSnapshotFile (const char * fileName,
                           bool8 readOnly,
                           STREAM * file)
{
    bool8 succesfullyOpenedSnapshotFile = false;
    if (readOnly)
    {
        * file = OPEN_STREAM(fileName, "rb");
        if (NULL != * file)
        {
            succesfullyOpenedSnapshotFile = true;
        }
    }
    else
    {
        *file = gzopen(fileName, "wb");
        if (NULL != * file)
        {
            succesfullyOpenedSnapshotFile = true;
        }
    }
    
    return succesfullyOpenedSnapshotFile;
}

void S9xCloseSnapshotFile (STREAM file)
{
    CLOSE_STREAM(file);
}

void S9xMessage (int /* type */, int /* number */, const char* message)
{
    printf ("%s\n", message);
}

bool8 S9xInitUpdate ()
{
    return TRUE;
}

/*!
 @function bool8 S9xDeinitUpdate (int width, int height)
 Called once a complete SNES screen has been rendered into the GFX.Screen memory
 buffer, now is your chance to copy the SNES rendered screen to the host 
 computer's screen memory. The problem is that you have to cope with different
 sized SNES rendered screens: 256*224, 256*239, 512*224, 512*239, 512*448 and 
 512*478.
 */
bool8 S9xDeinitUpdate (int width, int height)
{
    SNES9xAdapterS9xDidRenderScreenBuffer(width,
                                         height);

    return TRUE;
}

const char* S9xGetFilename (const char* ex, enum s9x_getdirtype dirtype)
{
    static char filename [PATH_MAX + 1];
    char drive [_MAX_DRIVE + 1];
    char dir [_MAX_DIR + 1];
    char fname [_MAX_FNAME + 1];
    char ext [_MAX_EXT + 1];

    _splitpath (Memory.ROMFilename, drive, dir, fname, ext);
    //strcpy (filename, SIGetSnapshotDirectory());
    strcpy (filename, "");
    strcat (filename, SLASH_STR);
    strcat (filename, fname);
    strcat (filename, ex);
    return (filename);
}

const char* S9xGetFilenameInc (const char* inExt, enum s9x_getdirtype dirtype)
{
    NSCAssert(NO, @"not implemented");
    return 0;
}

void S9xSyncSpeed(void)
{
    // this gets called by SNES9x. It can be used to delay a SNES cycle, or skip
    // one or more cycles.
    // When calling S9xMainLoop() manually and timing it also manually,
    // this method does not need to do anything.
}

const char* S9xBasename (const char* in)
{
    NSString * baseName = @"baseName";
    return [baseName UTF8String];
}

bool8 S9xOpenSoundDevice (void)
{
    return TRUE;
}

void S9xAutoSaveSRAM (void)
{
    SNES9xAdapterS9xRequestedSaveSRAM();
}

void _makepath (char* path,
                const char*,
                const char* dir,
                const char* fname,
                const char* ext)
{
    if (dir && *dir)
    {
        strcpy (path, dir);
        strcat (path, "/");
    }
    else
        *path = 0;
    strcat (path, fname);
    if (ext && *ext)
    {
        strcat (path, ".");
        strcat (path, ext);
    }
}

void _splitpath (const char* path,
                 char* drive,
                 char* dir,
                 char* fname,
                 char* ext)
{
    *drive = 0;

    char* slash = strrchr (path, '/');
    if (!slash)
        slash = strrchr (path, '\\');

    char* dot = strrchr (path, '.');

    if (dot && slash && dot < slash)
        dot = NULL;

    if (!slash)
    {
        strcpy (dir, "");
        strcpy (fname, path);
        if (dot)
        {
            *(fname + (dot - path)) = 0;
            strcpy (ext, dot + 1);
        }
        else
            strcpy (ext, "");
    }
    else
    {
        strcpy (dir, path);
        *(dir + (slash - path)) = 0;
        strcpy (fname, slash + 1);
        if (dot)
        {
            *(fname + (dot - slash) - 1) = 0;
            strcpy (ext, dot + 1);
        }
        else
            strcpy (ext, "");
    }
}

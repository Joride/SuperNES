//
//  SuperNESTests.m
//  SuperNESTests
//
//  Created by Joride on 27/12/14.
//  Copyright (c) 2014 KerrelInc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <SNES/SNESKit.h>

@interface SNES ()
@property (nonatomic) SNESState state;
@property (nonatomic, copy) NSString * loadedROMFilePath;
@end

@interface SuperNESTests : XCTestCase
@end

@implementation SuperNESTests
{
    SNES * _console;
}

#pragma mark - Housekeeping
- (void)setUp
{
    [super setUp];
    _console = [[SNES alloc] init];
}

- (void)tearDown
{
    _console = nil;
    [super tearDown];
}

#pragma mark - Utils
- (void) loadRom
{
    NSURL * userDocumentsDirectory;
#if TARGET_IPHONE_SIMULATOR
    
    NSString * filePath = @"/Users/jvanasselt/Entertainment/Console/Nintendo/SNES/";
    userDocumentsDirectory = [NSURL fileURLWithPath: filePath
                                        isDirectory: YES];
#else
    userDocumentsDirectory = [[[NSFileManager defaultManager]
                               URLsForDirectory:NSDocumentDirectory
                               inDomains:NSUserDomainMask] lastObject];
#endif
    NSString * ROMName = @"Super Mario All Stars (U).SMC";
    NSURL * fileURL = [userDocumentsDirectory URLByAppendingPathComponent: ROMName];
    [_console inserROMFileAtPath: fileURL.path];
}

#pragma mark - SNES states
- (void) testSNESInitialState
{
    XCTAssert((_console.state & kSNESStateOn) != kSNESStateOn,
              @"SNES state should start with being off");
}
- (void) testSNESOnAndOffState
{
    [self loadRom];
    [_console powerOnWithDelegate: nil];
    XCTAssert((_console.state & kSNESStateOn) == kSNESStateOn,
              @"SNES state should be kSNESStateOn when turned on.");

    [_console powerOff];
    XCTAssert((_console.state & kSNESStateOn) != kSNESStateOn,
              @"SNES state should be kSNESStateOff when turned off.");
}
- (void) testOnWithoutLoadedROM
{
    BOOL turnedOn = [_console powerOnWithDelegate: nil];
    XCTAssert(!turnedOn,
              @"SNES should not be turned in without a loaded ROM");
}
- (void) testInsertAndEjectROMFileURL
{
    [self loadRom];
    
    XCTAssert(nil != _console.loadedROMFilePath,
              @"loadedRomFilePath should be non nil when loading a ROM");
    
    BOOL ejected = [_console ejectROMFile];
    XCTAssert(ejected,
              @"A ROM should be ejected after ejectROMFile is called and the SNES is off");
    
    XCTAssert(nil == _console.loadedROMFilePath,
              @"loadedRomFilePath should be nil after ROM is ejected");
}
- (void) testEjectWithoutLoad
{
    BOOL ROMEjected = [_console ejectROMFile];
    XCTAssert(!ROMEjected,
              @"No room to eject, returned BOOL should be NO");
}
- (void) testEjectWhileOn
{
    [self loadRom];
    [_console powerOnWithDelegate: nil];
    
    BOOL ejected = [_console ejectROMFile];
    XCTAssert(!ejected,
              @"The ROM should not be ejected, as the SNES is still on");
}
- (void) testEjectWhileOff
{
    [self loadRom];
    [_console powerOnWithDelegate: nil];
    [_console powerOff];
    
    BOOL ejected = [_console ejectROMFile];
    XCTAssert(ejected,
              @"The ROM should not be ejected, as the SNES is still on");
}
- (void) testPauseAndUnPause
{
    [self loadRom];
    BOOL wasPaused = [_console pause];
    XCTAssert(!wasPaused,
              @"When the console is not turned on, it cannot be paused.");
    
    SNESState state = _console.state;
    XCTAssert(state == kSNESStateOff,
              @"SNES should be off: pausing when off should have no effect");
    
    [_console powerOnWithDelegate: nil];
    state = _console.state;
    XCTAssert(state == kSNESStateOn,
              @"SNES should be on");
    
    wasPaused = [_console pause];
    state = _console.state;
    XCTAssert(state == (kSNESStateOn | kSNESStatePaused),
              @"SNES should be on and paused");
    
    XCTAssert(wasPaused,
              @"When the console is turned on, it should be paused.");
    
    BOOL unPaused = [_console unPause];
    state = _console.state;
    XCTAssert(state == (kSNESStateOn),
              @"SNES should be on (and not paused");
    
    XCTAssert(unPaused,
              @"Console should be unpaused");
}


#pragma mark -
//- (void)testPerformanceExample
//{
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end

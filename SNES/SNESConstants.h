//
//  SNESConstants.h
//  SuperNES
//
//  Created by Joride on 10/01/15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

#ifndef SuperNES_SNESConstants_h
#define SuperNES_SNESConstants_h

typedef NS_ENUM(NSUInteger, SNESState)
{
    kSNESStateOff       = 1<<1,
    kSNESStateOn        = 1<<2,
    kSNESStatePaused    = 1<<3,
    
};
typedef NS_ENUM(uint16_t, SNESControllerOutput)
{
    kSNESControllerOutputNone           = 0,
    kSNESControllerOutputUp             = 1 << 0,
    kSNESControllerOutputLeft           = 1 << 1,
    kSNESControllerOutputDown           = 1 << 2,
    kSNESControllerOutputRight          = 1 << 3,
    kSNESControllerOutputStart          = 1 << 4,
    kSNESControllerOutputSelect         = 1 << 5,
    kSNESControllerOutputShoulderLeft   = 1 << 6,
    kSNESControllerOutputShoulderRight  = 1 << 7,
    kSNESControllerOutputA              = 1 << 8,
    kSNESControllerOutputB              = 1 << 9,
    kSNESControllerOutputX              = 1 << 10,
    kSNESControllerOutputY              = 1 << 11,
};

typedef NS_ENUM(uint16_t, SNESControllerIdentifier)
{
    kSNESControllerIdentifierOne      = 0,               // 0000 0000 0000 0000
    kSNESControllerIdentifierTwo      = 1<<12,           // 0001 0000 0000 0000
};

#endif

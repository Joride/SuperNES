//
//  SNESDPad.m
//  SuperNES
//
//  Created by Joride on 07-03-15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

#import "SNESDPad.h"

NSString * const kSNESUP =  @"UP";
NSString * const kSNESDOWN =  @"DOWN";
NSString * const kSNESLEFT =  @"LEFT";
NSString * const kSNESRIGHT =  @"RIGHT";
NSString * const kSNESUPLEFT =  @"UPLEFT";
NSString * const kSNESUPRIGHT =  @"UPRIGHT";
NSString * const kSNESDOWNLEFT =  @"DOWNLEFT";
NSString * const kSNESDOWNRIGHT =  @"DOWNRIGHT";

@interface SNESDPad ()
@property (nonatomic, readonly) NSMutableDictionary * pathsByID;
@end

@implementation SNESDPad
@synthesize pathsByID = _pathsByID;
-(NSMutableDictionary *)pathsByID
{
    if (nil == _pathsByID)
    {
        _pathsByID = [[NSMutableDictionary alloc] init];
    }
    return _pathsByID;
}
- (NSArray *) buttonIdentifiers
{
    return @[kSNESUP,
             kSNESDOWN,
             kSNESLEFT,
             kSNESRIGHT,
             kSNESUPLEFT,
             kSNESUPRIGHT,
             kSNESDOWNLEFT,
             kSNESDOWNRIGHT];
}
- (CGPathRef) pathForIdentifier: (id) identifier
{
    CGPathRef path = NULL;
    id cachedPath = self.pathsByID[identifier];
    if (nil == cachedPath)
    {
        // pythagoras, from center to topright is the radius
        CGFloat width = CGRectGetWidth(self.bounds) / 2.0f;
        CGFloat height = CGRectGetHeight(self.bounds) / 2.0f;
        CGFloat radius = sqrtf(width * width + height * height);
        NSString * identifierString = (NSString *) identifier;
        path = CGPathCreateMutable();

        CGFloat fullCircle = 2 * M_PI;
        CGFloat oneEigth = 1.00 / 8.00;
        CGPoint center = CGPointMake(self.bounds.size.width / 2.0,
                                     self.bounds.size.height / 2.0f);

        CGFloat startAngle = 0.0f;
        CGFloat endAngle = 0.0f;
        CGFloat offset = 0;
        if ([identifierString isEqualToString: kSNESUP])
        {
            offset = 5.5f;
        }
        else if ([identifierString isEqualToString: kSNESDOWN])
        {
            offset = 1.5f;
        }
        else if ([identifierString isEqualToString: kSNESLEFT])
        {
            offset = 3.5f;
        }
        else if ([identifierString isEqualToString: kSNESRIGHT])
        {
            offset = -0.5f;
        }
        else if ([identifierString isEqualToString: kSNESUPLEFT])
        {
            offset = 4.5f;
        }
        else if ([identifierString isEqualToString: kSNESUPRIGHT])
        {
            offset = 6.5f;
        }
        else if ([identifierString isEqualToString: kSNESDOWNRIGHT])
        {
            offset = 0.5f;
        }
        else if ([identifierString isEqualToString: kSNESDOWNLEFT])
        {
            offset = 2.5f;
        }
        else
        {
            NSAssert(NO, @"Unexpected identifier received.");
        }

        startAngle  = offset * oneEigth * fullCircle;
        endAngle    = (offset + 1) * oneEigth * fullCircle;
        UIBezierPath * bezierPath;
        bezierPath = [UIBezierPath bezierPathWithArcCenter: center
                                                    radius: radius
                                                startAngle: startAngle
                                                  endAngle: endAngle
                                                 clockwise: YES];
        [bezierPath addLineToPoint: center];
        [bezierPath closePath];
        path = bezierPath.CGPath;
        CGPathRetain(path);

        cachedPath = (__bridge id) path;
        self.pathsByID[identifier] = cachedPath;
        CGPathRelease(path);
    }
    else
    {
        path = (__bridge CGMutablePathRef) cachedPath;
    }
    return path;
}
- (BOOL) areMultipleButtonsEnabled
{
    return NO;
}
@end

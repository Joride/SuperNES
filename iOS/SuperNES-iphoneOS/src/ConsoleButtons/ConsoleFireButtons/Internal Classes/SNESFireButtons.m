//
//  SNESFireButtons.m
//  SuperNES
//
//  Created by Joride on 07-03-15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

#import "SNESFireButtons.h"

NSString * const kSNESA =  @"A";
NSString * const kSNESB =  @"B";
NSString * const kSNESY =  @"Y";
NSString * const kSNESX =  @"X";


@interface SNESFireButtons ()
@property (nonatomic, readonly) NSMutableDictionary * pathsByID;
@end

@implementation SNESFireButtons
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
    return @[kSNESA,
             kSNESB,
             kSNESX,
             kSNESY];
}
- (CGPathRef) pathForIdentifier: (id) identifier
{
    CGMutablePathRef path = NULL;
    id cachedPath = self.pathsByID[identifier];
    if (nil == cachedPath)
    {
        NSString * identifierString = (NSString *) identifier;
        path = CGPathCreateMutable();
        if ([identifierString isEqualToString: kSNESX])
        {
            CGPathMoveToPoint(path,
                              NULL,
                              CGRectGetMidX(self.bounds),
                              CGRectGetMidY(self.bounds));
            CGPathAddLineToPoint(path,
                                 NULL,
                                 CGRectGetMinX(self.bounds),
                                 CGRectGetMinY(self.bounds));
            CGPathAddLineToPoint(path,
                                 NULL,
                                 CGRectGetMaxX(self.bounds),
                                 CGRectGetMinY(self.bounds));
            CGPathAddLineToPoint(path,
                                 NULL,
                                 CGRectGetMidX(self.bounds),
                                 CGRectGetMidY(self.bounds));
            CGPathCloseSubpath(path);
        }
        if ([identifierString isEqualToString: kSNESA])
        {
            CGPathMoveToPoint(path,
                              NULL,
                              CGRectGetMidX(self.bounds),
                              CGRectGetMidY(self.bounds));
            CGPathAddLineToPoint(path,
                                 NULL,
                                 CGRectGetMaxX(self.bounds),
                                 CGRectGetMinY(self.bounds));
            CGPathAddLineToPoint(path,
                                 NULL,
                                 CGRectGetMaxX(self.bounds),
                                 CGRectGetMaxY(self.bounds));
            CGPathAddLineToPoint(path,
                                 NULL,
                                 CGRectGetMidX(self.bounds),
                                 CGRectGetMidY(self.bounds));
            CGPathCloseSubpath(path);
        }
        if ([identifierString isEqualToString: kSNESB])
        {
            CGPathMoveToPoint(path,
                              NULL,
                              CGRectGetMidX(self.bounds),
                              CGRectGetMidY(self.bounds));
            CGPathAddLineToPoint(path,
                                 NULL,
                                 CGRectGetMaxX(self.bounds),
                                 CGRectGetMaxY(self.bounds));
            CGPathAddLineToPoint(path,
                                 NULL,
                                 CGRectGetMinX(self.bounds),
                                 CGRectGetMaxY(self.bounds));
            CGPathAddLineToPoint(path,
                                 NULL,
                                 CGRectGetMidX(self.bounds),
                                 CGRectGetMidY(self.bounds));
            CGPathCloseSubpath(path);
        }
        if ([identifierString isEqualToString: kSNESY])
        {
            CGPathMoveToPoint(path,
                              NULL,
                              CGRectGetMidX(self.bounds),
                              CGRectGetMidY(self.bounds));
            CGPathAddLineToPoint(path,
                                 NULL,
                                 CGRectGetMinX(self.bounds),
                                 CGRectGetMaxY(self.bounds));
            CGPathAddLineToPoint(path,
                                 NULL,
                                 CGRectGetMinX(self.bounds),
                                 CGRectGetMinY(self.bounds));
            CGPathAddLineToPoint(path,
                                 NULL,
                                 CGRectGetMidX(self.bounds),
                                 CGRectGetMidY(self.bounds));
            CGPathCloseSubpath(path);
        }
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
    return YES;
}
@end

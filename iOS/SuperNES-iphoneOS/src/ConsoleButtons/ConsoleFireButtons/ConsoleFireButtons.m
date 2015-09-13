//
//  ConsoleFireButtons.m
//  SuperNES
//
//  Created by Joride on 02-03-15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

#import "ConsoleFireButtons.h"
#import "ConsoleFireButtons+Internal.h"
#import "SNESFireButtons.h"
#import "SNESDPad.h"

@interface ConsoleFireButtons ()
@property (nonatomic, strong) UIImage * backgroundImage;
@property (nonatomic, readonly) NSMutableSet * pressedButtonIdentifiers;
@property (nonatomic, strong) id firstPressedButton;
@end

@implementation ConsoleFireButtons
@synthesize pressedButtonIdentifiers = _pressedButtonIdentifiers;

+ (ConsoleFireButtons *) fireButtonsWithType: (ConsoleType) consoleType
{
    ConsoleFireButtons * buttons = nil;
    switch (consoleType)
    {
        case  kConsoleTypeNES:
            NSAssert(NO, @"Not yet implemented");
            break;
        case  kConsoleTypeSNES:
            buttons = [[SNESFireButtons alloc]
                       initWithFrame: CGRectZero];
            break;
        case  kConsoleTypeSNESDPad:
            buttons = [[SNESDPad alloc]
                       initWithFrame: CGRectZero];
            break;
        case  kConsoleTypeN64:
            NSAssert(NO, @"Not yet implemented");
            break;
        default:
            NSAssert(NO, @"Unexpected type received.");
            break;
    }
    return buttons;
}
-(NSMutableSet *)pressedButtonIdentifiers
{
    if (nil == _pressedButtonIdentifiers)
    {
        _pressedButtonIdentifiers = [[NSMutableSet alloc] init];
    }
    return _pressedButtonIdentifiers;
}

#pragma mark - layout
-(CGSize)sizeThatFits:(CGSize)size
{
    CGSize sizeThatFits = [super sizeThatFits: size];
    if (nil != self.backgroundImage)
    {
        sizeThatFits = self.backgroundImage.size;
    }
    return sizeThatFits;
}
-(CGSize)intrinsicContentSize
{
    CGSize intrinsicContentSize = [super intrinsicContentSize];

    if (nil != self.backgroundImage)
    {
        intrinsicContentSize = self.backgroundImage.size;
    }
    return intrinsicContentSize;
}

#pragma mark - drawing
-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    // draw image, if one is present
    if (nil != self.backgroundImage)
    {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, 0, self.backgroundImage.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextDrawImage(context, self.bounds, self.backgroundImage.CGImage);
        CGContextRestoreGState(context);
    }

    // combine the paths that are active
    CGMutablePathRef path = NULL;
    if (self.areMultipleButtonsEnabled)
    {
        for (NSString * pathID in self.pressedButtonIdentifiers)
        {
            if (NULL == path)
            {
                path = CGPathCreateMutable();
            }
            CGPathRef pathForID = [self pathForIdentifier: pathID];
            CGPathAddPath(path, NULL, pathForID);
        }
    }
    else if (nil != self.firstPressedButton)
    {
        CGPathRef pathForID = [self pathForIdentifier: self.firstPressedButton];
        if (NULL != pathForID)
        {
            path = CGPathCreateMutable();
            CGPathAddPath(path, NULL, pathForID);
        }
    }

    if (NULL != path)
    {
        CGContextAddPath(context, path);
        CGContextClip(context);
        CGFloat colors [] =
        {
            0.00, 0.5, // light gray    (half opaque)
            1.00, 0.5  // dark gray     (half opaque)
        };
        // gray colors want gray color space
        CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceGray();
        CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace,
                                                                     colors,
                                                                     NULL,
                                                                     2);
        CGColorSpaceRelease(baseSpace), baseSpace = NULL;

        CGContextDrawRadialGradient(context,
                                    gradient,
                                    CGPointMake(CGRectGetMidX(self.bounds),
                                                CGRectGetMidY(self.bounds)),
                                    0.0f,
                                    CGPointMake(CGRectGetMidX(self.bounds),
                                                CGRectGetMidY(self.bounds)),
                                    self.bounds.size.width / 2.0f,
                                    0);
        CGGradientRelease(gradient);
        CGPathRelease(path);
    }
}

#pragma mark - Touch handling
- (void) setMultipleTouchEnabled:(BOOL)multipleTouchEnabled
{
    [super setMultipleTouchEnabled: NO];
}
-(void)touchesBegan:(NSSet *)touches
          withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView: self];
    for (id identifier in [self buttonIdentifiers])
    {
        CGPathRef path = [self pathForIdentifier: identifier];
        if (CGPathContainsPoint(path, NULL, location, NO))
        {
            if (self.areMultipleButtonsEnabled)
            {
                [self.pressedButtonIdentifiers addObject: identifier];
                self.firstPressedButton = identifier;
            }
            else
            {
                self.firstPressedButton = identifier;
            }
            [self.delegate consoleFireButtons: self
                         didPressButtonWithID: identifier];
        }
    }
    [self setNeedsDisplay];
}
-(void)touchesMoved:(NSSet *)touches
          withEvent:(UIEvent *)event
{
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView: self];
    for (id identifier in [self buttonIdentifiers])
    {
        CGPathRef path = [self pathForIdentifier: identifier];
        if (CGPathContainsPoint(path, NULL, location, NO))
        {
            if (self.areMultipleButtonsEnabled)
            {
                if (![self.pressedButtonIdentifiers containsObject: identifier])
                {
                    // the touch is inside this path, and not already in the set,

                    // add this new button to the set and then tell the
                    // delegate it was pressed.
                    [self.pressedButtonIdentifiers addObject: identifier];
                    [self.delegate consoleFireButtons: self
                                 didPressButtonWithID: identifier];
                    [self setNeedsDisplay];
                }
            }
            else
            {
                if (self.firstPressedButton != identifier)
                {
                    [self.delegate consoleFireButtons: self
                               didReleaseButtonWithID: self.firstPressedButton];
                    [self.delegate consoleFireButtons: self
                                 didPressButtonWithID: identifier];
                    self.firstPressedButton = identifier;
                    [self setNeedsDisplay];
                }
            }

        }
        else
        {
            if (self.areMultipleButtonsEnabled)
            {
                if (identifier != self.firstPressedButton &&
                    [self.pressedButtonIdentifiers containsObject: identifier]) // to prevent calling setNeedsDisplay when it is not necessary
                {
                    [self.pressedButtonIdentifiers removeObject: identifier];
                    [self.delegate consoleFireButtons: self
                               didReleaseButtonWithID: identifier];
                    [self setNeedsDisplay];
                }
            }
            else
            {
            }
        }
    }
}
-(void)touchesEnded:(NSSet *)touches
          withEvent:(UIEvent *)event
{
    if (self.areMultipleButtonsEnabled)
        for (id anIdentifier in self.pressedButtonIdentifiers)
        {
            [self.delegate consoleFireButtons: self
                       didReleaseButtonWithID: anIdentifier];
        }
    else
    {
        [self.delegate consoleFireButtons: self
                   didReleaseButtonWithID: self.firstPressedButton];
    }

    self.firstPressedButton = nil;
    [self.pressedButtonIdentifiers removeAllObjects];

    [self setNeedsDisplay];
}
-(void)touchesCancelled:(NSSet *)touches
              withEvent:(UIEvent *)event
{
    if (self.areMultipleButtonsEnabled)
        for (id anIdentifier in self.pressedButtonIdentifiers)
        {
            [self.delegate consoleFireButtons: self
                       didReleaseButtonWithID: anIdentifier];
        }
    else
    {
        [self.delegate consoleFireButtons: self
                   didReleaseButtonWithID: self.firstPressedButton];
    }
    [self.pressedButtonIdentifiers removeAllObjects];
    self.firstPressedButton = nil;
    [self setNeedsDisplay];
}
- (NSArray *) buttonIdentifiers
{
    NSAssert(NO, @"This class is abstract, subclasses have to override this method.");
    return nil;
}
- (CGPathRef) pathForIdentifier: (id) identifier
{
    NSAssert(NO, @"This class is abstract, subclasses have to override this method.");
    return NULL;
}
- (BOOL) areMultipleButtonsEnabled
{
    NSAssert(NO, @"This class is abstract, subclasses have to override this method.");
    return YES;
}
@end

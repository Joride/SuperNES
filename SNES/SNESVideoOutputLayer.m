//
//  SNESVideoOutputLayer.m
//  SuperNES
//
//  Created by Joride on 28/12/14.
//  Copyright (c) 2014 KerrelInc. All rights reserved.
//

#import "SNESVideoOutputLayer.h"

@implementation SNESVideoOutputLayer
{
    unsigned char* _imageBufferPrimary;
    unsigned char* _imageBufferSecondary;
    unsigned int _bufferWidth;
    unsigned int _bufferHeight;
    unsigned short _bufferBitsPerComponent;
    unsigned int _bufferBytesPerRow;
    CGBitmapInfo _bufferBitmapInfo;
    
    CGContextRef _bitmapContextPrimary;
    CGContextRef _bitmapContextSecondary;
}

- (void)recreateBitmapContext
{
    // release
    if(_bitmapContextPrimary != nil)
    {
        CGContextRelease(_bitmapContextPrimary);
    }
    _bitmapContextPrimary = nil;
    
    // create our context
    if(_imageBufferPrimary != nil)
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        _bitmapContextPrimary = CGBitmapContextCreate(
                                               _imageBufferPrimary,
                                               _bufferWidth,
                                               _bufferHeight,
                                               _bufferBitsPerComponent,
                                               _bufferBytesPerRow,
                                               colorSpace,
                                               _bufferBitmapInfo
                                               );
        
        CGColorSpaceRelease(colorSpace);
    }
}

- (void)recreateBitmapContextAlt
{
    // release
    if(_bitmapContextSecondary != nil)
        CGContextRelease(_bitmapContextSecondary);
    _bitmapContextSecondary = nil;

    // create our context
    if(_imageBufferSecondary != nil)
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

        _bitmapContextSecondary = CGBitmapContextCreate(
                                                        _imageBufferSecondary,
                                                        _bufferWidth,
                                                        _bufferHeight,
                                                        _bufferBitsPerComponent,
                                                        _bufferBytesPerRow,
                                                        colorSpace,
                                                        _bufferBitmapInfo
                                                        );

        CGColorSpaceRelease(colorSpace);
    }
}
- (void)setImageBuffer:(uint8_t*)imageBuffer
                 width:(uint32_t)width
                height:(uint32_t)height
      bitsPerComponent:(uint16_t)bitsPerComponent
           bytesPerRow:(uint32_t)bytesPerRow
            bitmapInfo:(CGBitmapInfo)bitmapInfo
{
    // release
    if(_bitmapContextPrimary != nil)
        CGContextRelease(_bitmapContextPrimary);
    _bitmapContextPrimary = nil;
    
    // set new values
    _imageBufferPrimary = imageBuffer;
    _bufferWidth = width;
    _bufferHeight = height;
    _bufferBitsPerComponent = bitsPerComponent;
    _bufferBytesPerRow = bytesPerRow;
    _bufferBitmapInfo = bitmapInfo;
    
    [self recreateBitmapContext];
}

- (void)addSecondaryImageBuffer:(uint8_t*)imageBuffer;
{
    if(_bitmapContextSecondary != nil)
        CGContextRelease(_bitmapContextSecondary);
    _bitmapContextSecondary = nil;
    
    // set new values
    _imageBufferSecondary = imageBuffer;
    
    [self recreateBitmapContextAlt];
    
    // set scaling parameters
    self.magnificationFilter = kCAFilterNearest;
    self.minificationFilter = kCAFilterNearest;
}

- (void)updateGraphicsBufferCropWidth:(uint32_t)width
                               height:(uint32_t)height
{
    if(_bufferWidth != width || _bufferHeight != height)
    {
        _bufferWidth = width;
        _bufferHeight = height;
        
        [self recreateBitmapContext];
        [self recreateBitmapContextAlt];
    }
}

- (void)display
{
    if(_bitmapContextPrimary == nil)
        return;
    
    CGImageRef cgImage = nil;
    if(self.shouldDisplayPrimaryBuffer)
        cgImage = CGBitmapContextCreateImage(_bitmapContextPrimary);
    else
        cgImage = CGBitmapContextCreateImage(_bitmapContextSecondary);
    self.contents = (__bridge id)cgImage;
    CGImageRelease(cgImage);
}
- (id)init
{
    self = [super init];
    if(self)
    {
        _displayPrimaryBuffer = YES;
    }
    return self;
}

- (void)dealloc
{
    if(_bitmapContextPrimary != nil)
        CGContextRelease(_bitmapContextPrimary);
    _bitmapContextPrimary = nil;
    
    if(_bitmapContextSecondary != nil)
        CGContextRelease(_bitmapContextSecondary);
    _bitmapContextSecondary = nil;
}

@end

//
//  SNESVideoOutputLayer.h
//  SuperNES
//
//  Created by Joride on 28/12/14.
//  Copyright (c) 2014 KerrelInc. All rights reserved.
//

@import QuartzCore;

@interface SNESVideoOutputLayer : CALayer

@property (atomic, getter=shouldDisplayPrimaryBuffer) BOOL displayPrimaryBuffer;

- (void)setImageBuffer:(uint8_t*)imageBuffer
                 width:(uint32_t)width
                height:(uint32_t)height
      bitsPerComponent:(uint16_t)bitsPerComponent
           bytesPerRow:(uint32_t)bytesPerRow
            bitmapInfo:(CGBitmapInfo)bitmapInfo;

- (void)addSecondaryImageBuffer:(uint8_t*)imageBuffer;
- (void)updateGraphicsBufferCropWidth:(uint32_t)width
                               height:(uint32_t)height;

@end

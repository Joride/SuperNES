//
//  ConsoleGame.h
//  SuperNES
//
//  Created by Joride on 08-02-15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface ConsoleGame : NSObject

- (instancetype)initWithRelativePath: (NSString *) relatetivePath;

@property (nonatomic, readonly) NSString * title;
@property (nonatomic, readonly) UIImage * image;
@property (nonatomic, readonly) NSURL * fullURL;

@property (nonatomic, readonly) BOOL isImagePlaceholderImage;

@end

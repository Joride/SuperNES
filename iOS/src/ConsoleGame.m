//
//  ConsoleGame.m
//  SuperNES
//
//  Created by Joride on 08-02-15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

#import "ConsoleGame.h"

@interface ConsoleGame ()
@property (nonatomic, strong) NSString * relativePath;
@end

@implementation ConsoleGame
{
    UIImage * _image;
}
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}
- (void) applicationDidReceiveMemoryWarning: (NSNotification *) notification
{
    _image = nil;
}
- (instancetype)initWithRelativePath: (NSString *) relatetivePath
{
    self = [super init];
    if (self)
    {
        _relativePath = relatetivePath;
        NSNotificationCenter * notificationCenter;
        notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver: self
                               selector: @selector(applicationDidReceiveMemoryWarning:)
                                   name: UIApplicationDidReceiveMemoryWarningNotification
                                 object: nil];
    }
    return self;
}
-(NSString *)title
{
    NSString * title = [self.relativePath lastPathComponent];
    NSString * extension = [title pathExtension];

    NSRange extensionRange = [title rangeOfString: extension];
    NSString * titleWithoutExtension;
    titleWithoutExtension = [title substringToIndex: (extensionRange.location - 1)];

    return titleWithoutExtension;
}
-(BOOL)isImagePlaceholderImage
{
    BOOL isImagePlaceholderImage = YES;
    if (nil != self.image)
    {
        isImagePlaceholderImage = NO;
    }
    return isImagePlaceholderImage;
}
- (UIImage *) image
{
    if (nil == _image)
    {
        NSString    * gameNameWithExtension = [self.relativePath lastPathComponent];
        NSArray     * nameAndExtension = [gameNameWithExtension componentsSeparatedByString: @"."];
        NSString    * extensionLessGameName = [nameAndExtension firstObject];

        NSString * imageNameWithExtension = [NSString stringWithFormat: @"%@.png",
                                             extensionLessGameName];
        NSURL * imageURL;
        imageURL = [self.userDocumentsDirectory URLByAppendingPathComponent: imageNameWithExtension
                                                                isDirectory: NO];
        _image = [UIImage imageWithContentsOfFile: imageURL.path];
    }
    return _image;
}
-(NSURL *)fullURL
{
    NSURL * userDocumentsDirectory = [self userDocumentsDirectory];
    NSURL * fullURL;
    fullURL = [userDocumentsDirectory URLByAppendingPathComponent: self.relativePath
                                                      isDirectory: NO];
    return fullURL;
}
- (NSURL *) userDocumentsDirectory
{
    NSURL * userDocumentsDirectory = [[[NSFileManager defaultManager]
                                       URLsForDirectory: NSDocumentDirectory
                                       inDomains: NSUserDomainMask]
                                      lastObject];
    return userDocumentsDirectory;
}
@end

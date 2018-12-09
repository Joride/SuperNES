//
//  SNESGameCollectionViewCell.m
//  SuperNES
//
//  Created by Joride on 09-02-15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

#import "SNESGameCollectionViewCell.h"

@interface SNESGameCollectionViewCell ()
@end


@implementation SNESGameCollectionViewCell
-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame: frame];
    if (self)
    {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.numberOfLines = 1;
        [self.contentView addSubview: _titleLabel];
        
        _imageView = [[UIImageView alloc] init];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview: _imageView];
        
        [self.contentView addConstraints:
         @[[_imageView.topAnchor constraintEqualToAnchor: self.contentView.topAnchor constant: 8],
           [_imageView.leadingAnchor constraintEqualToAnchor: self.contentView.leadingAnchor],
           [_imageView.trailingAnchor constraintEqualToAnchor: self.contentView.trailingAnchor],
           
           [_titleLabel.topAnchor constraintEqualToAnchor:_imageView.bottomAnchor constant:8],
           [_titleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant: -8],
           [_titleLabel.leadingAnchor constraintEqualToAnchor: self.contentView.leadingAnchor],
           [_titleLabel.trailingAnchor constraintEqualToAnchor: self.contentView.trailingAnchor]]];
    }
    return self;
}

@end

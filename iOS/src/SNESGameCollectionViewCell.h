//
//  SNESGameCollectionViewCell.h
//  SuperNES
//
//  Created by Joride on 09-02-15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

@import UIKit;

@interface SNESGameCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic, readonly) IBOutlet UILabel * titleLabel;
@property (weak, nonatomic, readonly) IBOutlet UIImageView * imageView;
@end

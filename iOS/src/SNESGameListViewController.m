//
//  SNESGameListViewController.m
//  SuperNES
//
//  Created by Joride on 09-02-15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

#import "SNESGameListViewController.h"
#import "SNESGameCollectionViewCell.h"
#import "ConsoleGame.h"
#import "SNESGamePlayViewController.h"

NSString * const cellID = @"cellID";

@interface SNESGameListViewController ()
<UICollectionViewDataSource,
UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, readonly) NSArray * games;
@property (nonatomic, strong) UICollectionViewFlowLayout * flowLayout;
@property (nonatomic, strong) ROM * selectedGame;
@property (nonatomic, readonly) SNESROMFileManager * ROMFileManager;
@end


@implementation SNESGameListViewController
@synthesize games = _games;
@synthesize ROMFileManager = _ROMFileManager;
-(SNESROMFileManager *)ROMFileManager
{
    if (nil == _ROMFileManager)
    {
        _ROMFileManager = [[SNESROMFileManager alloc] init];
    }
    return _ROMFileManager;
}
-(void)viewDidLoad
{
    [super viewDidLoad];

    _flowLayout = [[UICollectionViewFlowLayout alloc] init];
    _flowLayout.itemSize = CGSizeMake(self.view.bounds.size.width,
                                     self.view.bounds.size.width / 1.3659 + 50);
    _flowLayout.minimumInteritemSpacing = 10.0f;

    self.collectionView.collectionViewLayout = _flowLayout;

    NSString * nibName = @"SNESGameCollectionViewCell";


    UINib * cellNib = [UINib nibWithNibName: nibName
                                     bundle: [NSBundle mainBundle]];
    [self.collectionView registerNib: cellNib
          forCellWithReuseIdentifier: cellID];

}

-(void)viewWillTransitionToSize:(CGSize)size
      withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    if (size.width > size.height)
    {
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        [_flowLayout invalidateLayout];
    }
    else
    {
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        [_flowLayout invalidateLayout];
    }
}
#pragma mark - UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    return self.ROMFileManager.ROMs.count;
}
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SNESGameCollectionViewCell * cell;
    cell = (SNESGameCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellID
                                                                                   forIndexPath:indexPath];

    id<SNESROMFileManaging> aRom = self.ROMFileManager.ROMs[indexPath.item];

    cell.titleLabel.text = aRom.ROMName;
    UIImage * image = [UIImage imageWithContentsOfFile: aRom.imagePath];
    cell.imageView.image = image;

    return cell;
}
#pragma mark - UICOllectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedGame = self.ROMFileManager.ROMs[indexPath.item];
    [self performSegueWithIdentifier: @"ShowGamePlayViewController"
                              sender: self];
}
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    SNESGamePlayViewController * gamePlayViewController;
    gamePlayViewController = (SNESGamePlayViewController *) segue.destinationViewController;
    gamePlayViewController.completion = ^
    {
        [self dismissViewControllerAnimated: YES
                                 completion: nil];
    };
    gamePlayViewController.consoleGame = self.selectedGame;
}

@end

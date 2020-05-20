//
//  ViewController.m
//  AVFoundationDemo
//
//  Created by Rimson on 2020/4/23.
//  Copyright © 2020 rimson. All rights reserved.
//

#import "ViewController.h"
#import "FileUtil.h"
#import "MediaUtil.h"
#import "CAAnimationUtil.h"

#import <AVFoundation/AVFoundation.h>

#import <Masonry.h>
#import <RITLPhotos.h>

@interface ViewController ()  <RITLPhotosViewControllerDelegate>

@property (nonatomic, assign) CGSize assetSize;
@property (nonatomic, strong) NSString *mVideoPath;
@property (nonatomic, strong) NSMutableArray <UIImage *> *imageArray;
@property (nonatomic, strong) NSMutableArray <NSString *> *savedAssetIds;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initView];
    self.assetSize = CGSizeMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
}

- (void)initView {
    UIButton *choosePhotoButton = [[UIButton alloc] init];
    [choosePhotoButton setTitle:@"选择图片" forState:UIControlStateNormal];
    [choosePhotoButton setBackgroundColor:[UIColor blackColor]];
    UITapGestureRecognizer *tapChoosePhotoButton = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(choosePhoto)];
    [choosePhotoButton addGestureRecognizer:tapChoosePhotoButton];
    [self.view addSubview:choosePhotoButton];
    [choosePhotoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
    }];
    
    UIButton *mergeButton = [[UIButton alloc] init];
    [mergeButton setTitle:@"开始合成" forState:UIControlStateNormal];
    [mergeButton setBackgroundColor:[UIColor brownColor]];
    UITapGestureRecognizer *tapMergeButton = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(beginMerge)];
    [mergeButton addGestureRecognizer:tapMergeButton];
    [self.view addSubview:mergeButton];
    [mergeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(choosePhotoButton.mas_bottom).offset(20);
    }];
    
}

#pragma mark - Action

- (void)choosePhoto {
    RITLPhotosViewController *photosViewController = RITLPhotosViewController.photosViewController;
    photosViewController.configuration.maxCount = 9;
    photosViewController.configuration.containVideo = NO;
    
    photosViewController.photo_delegate = self;
    photosViewController.thumbnailSize = self.assetSize;
    photosViewController.defaultIdentifers = self.savedAssetIds;
    [self presentViewController:photosViewController animated:YES completion:nil];
}

- (void)beginMerge {
    [MediaUtil createVideoFromImages:self.imageArray size:self.assetSize completion:^{
        
    }];
}

#pragma mark - RITLPhotosViewControllerDelegate

- (void)photosViewController:(UIViewController *)viewController assets:(NSArray<PHAsset *> *)assets {
    if (assets[0]) {
        self.assetSize = [MediaUtil sizeFromPHAsset:assets[0]];
    }
    if (!self.imageArray) {
        self.imageArray = [[NSMutableArray alloc] init];
    }
    [self.imageArray removeAllObjects];
    for (int i = 0; i < assets.count; i++) {
        UIImage *image = [MediaUtil imageFromPHAsset:assets[i] inSize:self.assetSize];
        image = [MediaUtil imageResizedFrom:image toSize:self.assetSize];
        [self.imageArray addObject:image];
    }
}

@end

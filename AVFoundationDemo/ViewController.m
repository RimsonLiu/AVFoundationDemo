//
//  ViewController.m
//  AVFoundationDemo
//
//  Created by Rimson on 2020/4/23.
//  Copyright © 2020 rimson. All rights reserved.
//

#import "ViewController.h"

#import <Masonry.h>
#import <RITLPhotos.h>

@interface ViewController ()  <RITLPhotosViewControllerDelegate>

@property (nonatomic, assign) CGSize assetSize;
@property (nonatomic, strong) NSMutableArray <UIImage *> *assets;
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
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
    }];
    
    self.navigationController.navigationBar.hidden = NO;
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

- (void)refresh {
}

#pragma mark - RITLPhotosViewControllerDelegate

- (void)photosViewController:(UIViewController *)viewController assets:(NSArray<PHAsset *> *)assets {
    NSLog(@"");
}

@end

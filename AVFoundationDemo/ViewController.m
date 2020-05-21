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
@property (nonatomic, strong) NSMutableArray <UIImage *> *chosenImages;
@property (nonatomic, strong) NSMutableArray <NSString *> *savedAssetIds;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) UIView *loadingView;

@end

@implementation ViewController

# pragma mark - lifecycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.player.currentItem];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initView];
    self.assetSize = CGSizeMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
}

- (void)initView {
    self.view.backgroundColor = [UIColor blackColor];
    
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
}

- (void)showLoadingView {
    if (!self.loadingView) {
        UIView *loadingView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2 - 75, self.view.bounds.size.height / 2 - 25, 150, 50)];
        loadingView.backgroundColor = [UIColor whiteColor];
        loadingView.alpha = 0.8;
        loadingView.layer.cornerRadius = 10;
        
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicator.frame = CGRectMake(0, 0, 50, 50);
        [indicator startAnimating];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 150, 50)];
        label.textColor = [UIColor grayColor];
        label.text = @"正在合成";
        
        [loadingView addSubview:indicator];
        [loadingView addSubview:label];
        
        self.loadingView = loadingView;
    }
    [self.view addSubview:self.loadingView];
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
    [self showLoadingView];
    __weak typeof(self) weakSelf = self;
    [MediaUtil createVideoFromImages:self.chosenImages size:self.assetSize completion:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.loadingView removeFromSuperview];
        [strongSelf initAVPlayer];
    }];
}

#pragma mark - AVPlayer

- (void)initAVPlayer {
    // 创建播放器
    NSURL *videoURL = [NSURL fileURLWithPath:[MediaUtil getVideoPath]];
    self.player = [AVPlayer playerWithURL:videoURL];
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.player.currentItem];
    // 创建播放器 Layer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.playerLayer.backgroundColor = (__bridge CGColorRef _Nullable)(self.view.backgroundColor);
    self.playerLayer.frame = CGRectMake(0, 100, self.view.bounds.size.width, 600);
    [self.view.layer addSublayer:self.playerLayer];
    // 播放
    [self.player play];
}

- (void)playerDidEnd:(NSNotification *)notification {
    AVPlayerItem *playerItem = [notification object];
    [playerItem seekToTime:kCMTimeZero completionHandler:nil];
}

#pragma mark - RITLPhotosViewControllerDelegate

- (void)photosViewController:(UIViewController *)viewController assets:(NSArray<PHAsset *> *)assets {
    if (assets[0]) {
        self.assetSize = [MediaUtil sizeFromPHAsset:assets[0]];
    }
    if (!self.chosenImages) {
        self.chosenImages = [[NSMutableArray alloc] init];
    }
    [self.chosenImages removeAllObjects];
    for (int i = 0; i < assets.count; i++) {
        UIImage *image = [MediaUtil imageFromPHAsset:assets[i] inSize:self.assetSize];
        image = [MediaUtil imageResizedFrom:image toSize:self.assetSize];
        [self.chosenImages addObject:image];
    }
    [self beginMerge];
}

@end

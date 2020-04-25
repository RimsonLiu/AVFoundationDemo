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
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
    }];
    
    UIButton *mergeButton = [[UIButton alloc] init];
    [mergeButton setTitle:@"开始合成" forState:UIControlStateNormal];
    [mergeButton setBackgroundColor:[UIColor brownColor]];
    UITapGestureRecognizer *tapMergeButton = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(beginMerge)];
    [mergeButton addGestureRecognizer:tapMergeButton];
    [self.view addSubview:mergeButton];
    [mergeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(choosePhotoButton.mas_bottom).offset(10);
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
    [self createVideoFromImages:self.imageArray];
}

- (void)refresh {
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

#pragma mark - AVFoundation

- (void)createVideoFromImages:(NSArray *)images {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *videoPath = [[paths objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mov", @"test"]];
    self.mVideoPath = videoPath;
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    
    [FileUtil deleteFileIfExistsAt:videoPath];
    
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:videoURL fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    
    CGSize size = self.assetSize;
    
    NSMutableDictionary *outputSettings = [[NSMutableDictionary alloc] init];
    [outputSettings setObject:AVVideoCodecTypeH264 forKey:AVVideoCodecKey];
    [outputSettings setObject:@(size.width) forKey:AVVideoWidthKey];
    [outputSettings setObject:@(size.height) forKey:AVVideoHeightKey]
    ;
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject:@(kCVPixelFormatType_32RGBA) forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    [attributes setObject:@(size.width) forKey:(NSString*)kCVPixelBufferWidthKey];
    [attributes setObject:@(size.height) forKey:(NSString*)kCVPixelBufferHeightKey];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:attributes];
    
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    writerInput.expectsMediaDataInRealTime = YES;
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    // 首帧缓存
    UIImage *firstImage = self.imageArray[0];
    CVPixelBufferRef buffer = [MediaUtil pixelBufferRefFromCGImage:[firstImage CGImage] inSize:size];
    [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
    
    if (buffer) {
        CFRelease(buffer);
    }
    
    // 单图逻辑
    if (self.imageArray.count == 1) {
        // timescale = 2 ?
        CMTime presentTime = CMTimeMake(1, 2);
        [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
    }
    
    // 多图逻辑
    int timescale = 1;
    for (int i = 1; i < self.imageArray.count; i++) {
        if (adaptor.assetWriterInput.readyForMoreMediaData) {
            UIImage *imgFrame = self.imageArray[i];
            buffer = [MediaUtil pixelBufferRefFromCGImage:[imgFrame CGImage] inSize:size];
            
            CMTime presentTime = CMTimeMake(i, timescale);

            BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
            
            if (result == NO) {
                NSLog(@"failed to append buffer");
                NSLog(@"The error is %@", [videoWriter error]);
            }
            if(buffer) {
                CVBufferRelease(buffer);
            }
        }
    }
    
    [writerInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"已完成");
    }];
    
    CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
}

@end

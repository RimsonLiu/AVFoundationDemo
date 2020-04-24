//
//  ViewController.m
//  AVFoundationDemo
//
//  Created by Rimson on 2020/4/23.
//  Copyright © 2020 rimson. All rights reserved.
//

#import "ViewController.h"

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
    NSLog(@"");
    [self videoFromImages:self.imageArray];
}

- (void)refresh {
}

#pragma mark - RITLPhotosViewControllerDelegate

- (void)photosViewController:(UIViewController *)viewController assets:(NSArray<PHAsset *> *)assets {
    if (assets[0]) {
        self.assetSize = [self sizeFromPHAsset:assets[0]];
    }
    if (!self.imageArray) {
        self.imageArray = [[NSMutableArray alloc] init];
    }
    [self.imageArray removeAllObjects];
    for (int i = 0; i < assets.count; i++) {
        UIImage *image = [self imageFromPHAsset:assets[i]];
        image = [self newImageWithImage:image toSize:self.assetSize];
        [self.imageArray addObject:image];
    }
}

#pragma mark - AVFoundation

- (void)videoFromImages:(NSArray *)images {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *videoPath = [[paths objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mov", @"test"]];
    self.mVideoPath = videoPath;
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:videoPath]) {
        NSError *error = nil;
        [fileManager removeItemAtURL:videoURL error:&error];
    }
    
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
    
    UIImage *firstImage = self.imageArray[0];
    CVPixelBufferRef buffer = [self pixelBufferRefFromCGImage:[firstImage CGImage] size:size];
    [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
    
    if (buffer) {
        CFRelease(buffer);
    }
    
    if (self.imageArray.count == 1) {
        CMTime presentTime = CMTimeMake(1, 1);
        [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
    }
    
    
    int timescale = 1;
    for (int i = 1; i < self.imageArray.count; i++) {
        if (adaptor.assetWriterInput.readyForMoreMediaData) {
            UIImage *imgFrame = self.imageArray[i];
            buffer = [self pixelBufferRefFromCGImage:[imgFrame CGImage] size:size];
            
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

#pragma mark - ImageProcess

- (UIImage *)newImageWithImage:(UIImage *)image toSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (CGSize)sizeFromPHAsset:(PHAsset *)asset {
    CGSize size = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
    return size;
}

- (UIImage *)imageFromPHAsset:(PHAsset *)asset {
    PHImageManager *manager = [PHImageManager defaultManager];
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = YES;
    __block UIImage *image;
    [manager requestImageForAsset:asset targetSize:self.assetSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        image = result;
    }];
    return image;
}

- (CVPixelBufferRef)pixelBufferRefFromCGImage:(CGImageRef)image size:(CGSize)size {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
        [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
        nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
        size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
        &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);

    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);

    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
        size.height, 8, 4*size.width, rgbColorSpace,
        kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
        CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);

    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);

    return pxbuffer;
}

@end

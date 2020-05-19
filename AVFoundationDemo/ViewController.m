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
//    [self createVideoByBufferFromImages:self.imageArray];
    [self createVideoByLayerFromImages:self.imageArray];
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

- (void)createVideoByLayerFromImages:(NSArray<UIImage *> *)images {
    NSString *videoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.mov"];
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.mov"];
    
    dispatch_queue_t composeQueue = dispatch_queue_create("com.rimson.video.compose", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(composeQueue, ^{
        [FileUtil createEmptyVideoInSize:self.assetSize at:tempPath withCompletion:^{
            [self exportPhotoVideoWithImages:images url:[NSURL fileURLWithPath:videoPath]];
        }];
    });
}

- (void)exportPhotoVideoWithImages:(NSArray<UIImage *> *)images url:(NSURL *)url {
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.mov"];
    
    // 获取视频资源
    NSURL *tempURL = [NSURL fileURLWithPath:tempPath];
    AVAsset *tempAsset = [AVAsset assetWithURL:tempURL];
    CMTime durationTime = [tempAsset duration];
    // 创建自定义合成对象：可变组件
    AVMutableComposition *composition = [AVMutableComposition composition];

    // 创建资源数据，即轨道
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *assetTrack = [[tempAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CGSize naturalSize = assetTrack.naturalSize;

    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, durationTime)
                        ofTrack:assetTrack
                         atTime:kCMTimeZero
                          error:nil];

    // 创建视频应用层的指令，用于管理 layer
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack: assetTrack];

    // 创建视频组件的指令，用于管理应用层
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, durationTime);
    instruction.layerInstructions = @[layerInstruction];

    // 创建视频组件，设置视频属性，并管理视频组件的指令
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = naturalSize;
    videoComposition.instructions = @[instruction];
    videoComposition.frameDuration = CMTimeMake(1, 30);

    // 插入图片，注意 Layer 关系
    CALayer *videoLayer = [CALayer layer];
    videoLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);

    CALayer *animationLayer = [self createAnimationLayerWithPhotos:self.imageArray
                                                              size:naturalSize
                                                        videoLayer:videoLayer];
    
    CALayer *parentLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:animationLayer];

    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool
                                      videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
                                      inLayer:parentLayer];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetPassthrough];
    exporter.videoComposition = videoComposition;
    exporter.outputURL = url;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    
    dispatch_queue_t exportQueue = dispatch_queue_create("com.rimson.video.export", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(exportQueue, ^{
        [FileUtil deleteFileIfExistsAtPath:url.path];
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            if (exporter.error) {
                NSLog(@"AVAssetExportSession Error %@", exporter.error);
            }
            UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }];
    });

}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"保存视频失败%@", error);
    } else {
        NSLog(@"保存视频成功");
    }
}

- (CALayer *)createAnimationLayerWithPhotos:(NSArray<UIImage *> *)images
                                       size:(CGSize)size
                                 videoLayer:(CALayer *)videoLayer {
    CALayer *animationLayer = [CALayer layer];
    animationLayer.frame = CGRectMake(0, 0, size.width, size.height);
//    [animationLayer addSublayer:videoLayer];
    [self addSinglePhotoAnimation:[images firstObject] toLayer:animationLayer inSize:size];
    return animationLayer;
}

- (void)addSinglePhotoAnimation:(UIImage *)image
                        toLayer:(CALayer *)animationLayer
                         inSize:(CGSize)size {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.frame = CGRectMake(0, 0, size.width, size.height);
    
    CALayer *imageLayer = imageView.layer;
    imageLayer.beginTime = AVCoreAnimationBeginTimeAtZero;
    imageLayer.contentsScale = [UIScreen mainScreen].scale;
    imageLayer.magnificationFilter = kCAFilterNearest;
    imageLayer.allowsEdgeAntialiasing = YES;
    
    CAAnimationGroup *animationGroup = [self createSinglePhotoAnimationGroup];
    [imageLayer addAnimation:animationGroup forKey:nil];
    [animationLayer addSublayer:imageLayer];
}

- (CAAnimationGroup *)createSinglePhotoAnimationGroup {
    NSTimeInterval duration = 15;
    CABasicAnimation *photoAnimation = [self createPhotoAnimation:duration
                                                        beginTime:AVCoreAnimationBeginTimeAtZero];
    CAAnimationGroup *animationGroup = [self createPhotoAnimationGroupWithAnimations:@[photoAnimation] dutation:duration];
    return animationGroup;
}

- (CAAnimationGroup *)createPhotoAnimationGroupWithAnimations:(NSArray<CABasicAnimation *> *)animations
                                                     dutation:(NSTimeInterval)duration {
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.fillMode = kCAFillModeForwards;
    animationGroup.removedOnCompletion = NO;
    animationGroup.beginTime = AVCoreAnimationBeginTimeAtZero;
    animationGroup.duration = duration;
    animationGroup.animations = animations;
    return animationGroup;
}

- (CABasicAnimation *)createPhotoAnimation:(NSTimeInterval)duration beginTime:(NSTimeInterval)beginTime {
    CABasicAnimation *photoAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    photoAnimation.fromValue = @(1);
    photoAnimation.toValue = @(1.5);
    photoAnimation.beginTime = beginTime;
    photoAnimation.duration = duration;
    photoAnimation.removedOnCompletion = NO;
    photoAnimation.fillMode = kCAFillModeForwards;
    return photoAnimation;
}

#pragma mark - Deprecated

- (void)createVideoByBufferFromImages:(NSArray *)images {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *videoPath = [[paths objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mov", @"test"]];
    self.mVideoPath = videoPath;
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    
    [FileUtil deleteFileIfExistsAtPath:videoPath];
    
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:videoURL fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    
    CGSize size = self.assetSize;
    
    NSMutableDictionary *outputSettings = [[NSMutableDictionary alloc] init];
    [outputSettings setObject:AVVideoCodecTypeH264 forKey:AVVideoCodecKey];
    [outputSettings setObject:@(size.width) forKey:AVVideoWidthKey];
    [outputSettings setObject:@(size.height) forKey:AVVideoHeightKey];
    
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
    
//    if (buffer) {
//        CFRelease(buffer);
//    }
    
    // 单图逻辑
    if (self.imageArray.count == 1) {
        // timescale = 2 ?
        CMTime presentTime = CMTimeMake(3, 2);
        [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
        
        CGRect cropRect = CGRectMake(0, 0, CVPixelBufferGetWidth(buffer) / 2, CVPixelBufferGetHeight(buffer) / 2);
        CVPixelBufferRef newBuffer = [self bufferByCroppingFrom:buffer toRect:cropRect];
        [adaptor appendPixelBuffer:newBuffer withPresentationTime:presentTime];
    }
    
    // 多图逻辑
    if (self.imageArray.count > 1) {
        // 首张 1.38s show
//        CMTime showTime = CMTimeMake(138, 100);
        
    }
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

- (CVPixelBufferRef)bufferByCroppingFrom:(CVPixelBufferRef)buffer toRect:(CGRect)rect {
    CIImage *image = [CIImage imageWithCVPixelBuffer:buffer];
    image = [image imageByCroppingToRect:rect];
    
    CVPixelBufferRef output = NULL;
    CVPixelBufferCreate(nil,
                        CGRectGetWidth(image.extent),
                        CGRectGetHeight(image.extent),
                        CVPixelBufferGetPixelFormatType(buffer),
                        nil,
                        &output);
    
    if (output != NULL) {
        [[CIContext context] render:image toCVPixelBuffer:output];
    }
    
    return output;
}

@end

//
//  MediaUtil.m
//  AVFoundationDemo
//
//  Created by Rimson on 2020/4/25.
//  Copyright © 2020 rimson. All rights reserved.
//

#import "MediaUtil.h"
#import "FileUtil.h"
#import "CAAnimationUtil.h"

@implementation MediaUtil

+ (UIImage *)imageResizedFrom:(UIImage *)image toSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)imageFromPHAsset:(PHAsset *)asset inSize:(CGSize)size {
    PHImageManager *manager = [PHImageManager defaultManager];
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = YES;
    __block UIImage *image;
    [manager requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        image = result;
    }];
    return image;
}

+ (CGSize)sizeFromPHAsset:(PHAsset *)asset {
    CGSize size = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
    return size;
}

+ (CVPixelBufferRef)pixelBufferRefFromCGImage:(CGImageRef)image inSize:(CGSize)imageSize {
    CGFloat width = CGImageGetWidth(image) / [UIScreen mainScreen].scale;
    CGFloat height = CGImageGetHeight(image) / [UIScreen mainScreen].scale;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVPixelBufferCreate(kCFAllocatorDefault, imageSize.width,
                        imageSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                        &pxbuffer);
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, imageSize.width,
                                                 imageSize.height, 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0 + (imageSize.width-width)/2,
                                           (imageSize.height-height)/2,
                                           width,
                                           height), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (void)createVideoFromImages:(NSArray<UIImage *> *)images size:(CGSize)size completion:(void (^)(void))completion {
    NSString *videoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.mov"];
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.mov"];
    
    dispatch_queue_t composeQueue = dispatch_queue_create("com.rimson.video.compose", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(composeQueue, ^{
        [FileUtil createEmptyVideoInSize:size at:tempPath withCompletion:^{
            [self exportPhotoVideoWithImages:images url:[NSURL fileURLWithPath:videoPath] completion:completion];
        }];
    });
}

+ (void)exportPhotoVideoWithImages:(NSArray<UIImage *> *)images url:(NSURL *)url completion:(void (^)(void))completion {
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

    // 创建 Layer，插入图片，注意 Layer 关系
    CALayer *videoLayer = [CALayer layer];
    videoLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);

    CALayer *animationLayer = [CAAnimationUtil createAnimationLayerWithPhotos:images
                                                                         size:naturalSize
                                                                   videoLayer:videoLayer];
    
//    [videoLayer addSublayer:animationLayer];
//    [animationLayer addSublayer:videoLayer];
    
    // 创建视频组件，设置视频属性，并管理视频组件的指令
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = naturalSize;
    videoComposition.instructions = @[instruction];
    videoComposition.frameDuration = CMTimeMake(1, 30);
    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool
                                      videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
                                      inLayer:animationLayer];
    
    // NOTICE: Do not use AVAssetExportPresetPassthrough !!!
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
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
            if (completion) {
                completion();
            }
        }];
    });
}

+ (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"保存视频失败%@", error);
    } else {
        NSLog(@"保存视频成功");
    }
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

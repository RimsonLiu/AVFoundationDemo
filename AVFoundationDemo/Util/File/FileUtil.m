//
//  FileUtil.m
//  AVFoundationDemo
//
//  Created by Rimson on 2020/4/25.
//  Copyright © 2020 rimson. All rights reserved.
//

#import "FileUtil.h"

@implementation FileUtil

+ (void)deleteFileIfExistsAt:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        [fileManager removeItemAtPath:path error:&error];
    }
}

+ (void)createEmptyVideoInSize:(CGSize)frameSize at:(NSString *)tempPath withCompletion:(void (^)(void))completion {
    [FileUtil deleteFileIfExistsAt:tempPath];
    
    NSError *error = nil;
    
    NSDictionary *videoSettings = @{AVVideoCodecKey: AVVideoCodecTypeH264,
                                    AVVideoWidthKey: @(frameSize.width),
                                    AVVideoHeightKey: @(frameSize.height),
                                    };
    AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *videoAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoInput
                                                                                                                          sourcePixelBufferAttributes:nil];
    
    AVAssetWriter *movieWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:tempPath]
                                                           fileType:AVFileTypeMPEG4
                                                              error:&error];
    
    if ([movieWriter canAddInput:videoInput]) {
        [movieWriter addInput:videoInput];
    }
    
    //Start a session:
    [movieWriter startWriting];
    
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0);
    [[UIColor blackColor] setFill];
    UIRectFill(rect);
    UIImage *endEmptyImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CVPixelBufferRef endImageRef = [MediaUtil pixelBufferRefFromCGImage:endEmptyImage.CGImage inSize:frameSize];
    
//    CMTime startTime = CMTimeMake(0,30);
//    CMTime endTime   = CMTimeMake(150, 30);
    CMTime duration = CMTimeMake(10, 1);
    [movieWriter startSessionAtSourceTime:kCMTimeZero];
    
    BOOL success = [videoAdaptor appendPixelBuffer:endImageRef withPresentationTime:duration];
    
    // 生成视频
    if (success) {
        [videoInput markAsFinished];
        [movieWriter finishWritingWithCompletionHandler:^{
            if (movieWriter.status != AVAssetWriterStatusCompleted) {
                if (completion) {
                    completion();
                }
            } else {
                if (completion) {
                    completion();
                }
            }
        }];
        CVPixelBufferPoolRelease(videoAdaptor.pixelBufferPool);
    } else {
        if (completion) {
            completion();
        }
    }
}

@end

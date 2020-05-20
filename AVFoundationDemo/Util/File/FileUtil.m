//
//  FileUtil.m
//  AVFoundationDemo
//
//  Created by Rimson on 2020/4/25.
//  Copyright © 2020 rimson. All rights reserved.
//

#import "FileUtil.h"

@implementation FileUtil

+ (void)deleteFileIfExistsAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        [fileManager removeItemAtPath:path error:&error];
    }
}

+ (void)createEmptyVideoInSize:(CGSize)frameSize at:(NSString *)tempPath withCompletion:(void (^)(void))completion {
//    [FileUtil deleteFileIfExistsAtPath:tempPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:tempPath]) {
        if (completion) {
            completion();
        }
        return;
    }
    
    NSError *error = nil;
    
    NSDictionary *videoSettings = @{AVVideoCodecKey: AVVideoCodecTypeH264,
                                    AVVideoWidthKey: @(frameSize.width),
                                    AVVideoHeightKey: @(frameSize.height),
                                    };
    AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *videoAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoInput
                                                                                                                          sourcePixelBufferAttributes:nil];
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:tempPath]
                                                           fileType:AVFileTypeMPEG4
                                                              error:&error];
    
    if ([videoWriter canAddInput:videoInput]) {
        [videoWriter addInput:videoInput];
    }
    
    // Start a session:
    [videoWriter startWriting];
    
    CGRect rect = CGRectMake(0, 0, frameSize.width, frameSize.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0);
    [[UIColor redColor] setFill];
    UIRectFill(rect);
    UIImage *endEmptyImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CVPixelBufferRef endImageRef = [MediaUtil pixelBufferRefFromCGImage:endEmptyImage.CGImage inSize:frameSize];
    
    CMTime startTime = CMTimeMake(0,30);
    CMTime endTime   = CMTimeMake(450, 30);
    [videoWriter startSessionAtSourceTime:startTime];
    
    BOOL success = [self appendToAdapter:videoAdaptor
                             pixelBuffer:endImageRef
                                  atTime:endTime
                               withInput:videoInput
                         withMovieWriter:videoWriter];
    
    // 生成视频
    if (success) {
        [videoInput markAsFinished];
        [videoWriter finishWritingWithCompletionHandler:^{
            if (videoWriter.status != AVAssetWriterStatusCompleted) {
                NSLog(@"Create temp video finishWritingWithCompletionHandler error: %@", error);
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
        NSLog(@"Create temp video appendPixelBuffer error: %@", error);
    }
}

+ (BOOL)appendToAdapter:(AVAssetWriterInputPixelBufferAdaptor*)adaptor
            pixelBuffer:(CVPixelBufferRef)buffer
                 atTime:(CMTime)presentTime
              withInput:(AVAssetWriterInput*)writerInput
        withMovieWriter:(AVAssetWriter *)movieWriter {
    NSTimer *foreverTimer = [NSTimer timerWithTimeInterval:INT_MAX
                                                    target:self
                                                  selector:@selector(description)
                                                  userInfo:nil
                                                   repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:foreverTimer
                                 forMode:NSDefaultRunLoopMode];
    
    while (!writerInput.readyForMoreMediaData) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    [foreverTimer invalidate];
    
    BOOL isSuccess = [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
    
    return isSuccess;
}

@end

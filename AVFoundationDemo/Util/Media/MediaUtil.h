//
//  MediaUtil.h
//  AVFoundationDemo
//
//  Created by Rimson on 2020/4/25.
//  Copyright © 2020 rimson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface MediaUtil : NSObject

+ (UIImage *)imageResizedFrom:(UIImage *)image toSize:(CGSize)newSize;
+ (UIImage *)imageFromPHAsset:(PHAsset *)asset inSize:(CGSize)size;

+ (CGSize)sizeFromPHAsset:(PHAsset *)asset;

+ (CVPixelBufferRef)pixelBufferRefFromCGImage:(CGImageRef)image inSize:(CGSize)size;

+ (void)createVideoFromImages:(NSArray<UIImage *> *)images size:(CGSize)size completion:(void (^)(void))completion;

+ (NSString *)getTempBlankVideoPath;
+ (NSString *)getVideoPath;

@end

NS_ASSUME_NONNULL_END

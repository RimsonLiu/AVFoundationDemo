//
//  CAAnimationUtil.m
//  AVFoundationDemo
//
//  Created by RimsonLiu on 2020/5/19.
//  Copyright © 2020 rimson. All rights reserved.
//

#import "CAAnimationUtil.h"
#import <AVFoundation/AVFoundation.h>

@implementation CAAnimationUtil


+ (CALayer *)createAnimationLayerWithPhotos:(NSArray<UIImage *> *)images
                                       size:(CGSize)size
                                 videoLayer:(CALayer *)videoLayer {
    CALayer *animationLayer = [CALayer layer];
    animationLayer.frame = CGRectMake(0, 0, size.width, size.height);
    
    if (images.count > 1) {
        [self addMultiPhotoAnimation:images toLayer:animationLayer inSize:size];
    } else {
        [self addSinglePhotoAnimation:[images firstObject] toLayer:animationLayer inSize:size];
    }
    
    return animationLayer;
}

#pragma mark - single photo animation layer

+ (void)addSinglePhotoAnimation:(UIImage *)image
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

+ (CAAnimationGroup *)createSinglePhotoAnimationGroup {
    NSTimeInterval duration = 15;
    CABasicAnimation *photoAnimation = [self createPhotoAnimationWithType:PhotoMovieAnimationTypeZooming
                                                                 duration:duration
                                                                beginTime:AVCoreAnimationBeginTimeAtZero];
    CAAnimationGroup *animationGroup = [self createPhotoAnimationGroupWithAnimations:@[photoAnimation] dutation:duration];
    return animationGroup;
}

#pragma mark - multi photo animation layer

+ (void)addMultiPhotoAnimation:(NSArray<UIImage *> *)images
                       toLayer:(CALayer *)targetLayer
                        inSize:(CGSize)size {
    NSTimeInterval timeBegin = AVCoreAnimationBeginTimeAtZero;
    NSTimeInterval timeOffset = 1.68;
    for (NSInteger i = 0; i < 10; i++) {
        UIImage *image = images[i % images.count];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.frame = CGRectMake(0, 0, size.width, size.height);
        
        CALayer *animationLayer = imageView.layer;
        animationLayer.beginTime = timeBegin;
        
        CAAnimationGroup *animationGroup = [self createMultiPhotoAnimationGroupAtIndex:i];
        [animationLayer addAnimation:animationGroup forKey:nil];
        
        [targetLayer addSublayer:animationLayer];
        
        if (i == 0) {
            timeBegin += 0.15 + 1.38;
        } else {
            timeBegin += timeOffset;
        }
    }
    
}

+ (CAAnimationGroup *)createMultiPhotoAnimationGroupAtIndex:(NSInteger)index {
    NSTimeInterval photoShowingDuration = 0.3;
    NSTimeInterval photoDuration = 1.38;
    NSTimeInterval photoHidingDuration = 0.3;
    NSMutableArray *animations = [NSMutableArray array];
    if (index != 0) {
        CABasicAnimation *beginAnimation = [self createPhotoAnimationWithType:PhotoMovieAnimationTypeFadeShowing
                                                                     duration:photoShowingDuration
                                                                    beginTime:AVCoreAnimationBeginTimeAtZero];
        [animations addObject:beginAnimation];
    } else {
        photoShowingDuration = 0;
        photoDuration += 0.15;
    }
    
    CABasicAnimation *endAnimation  = [self createPhotoAnimationWithType:PhotoMovieAnimationTypeFadeHiding
                                                                duration:photoHidingDuration
                                                               beginTime:photoDuration + photoShowingDuration];
    [animations addObject:endAnimation];
    
    CAAnimationGroup *animationGroup = [self createPhotoAnimationGroupWithAnimations:animations
                                                                            dutation:(photoShowingDuration + photoDuration + photoHidingDuration)];
    return animationGroup;
}

#pragma mark - photo animation

+ (CAAnimationGroup *)createPhotoAnimationGroupWithAnimations:(NSArray<CABasicAnimation *> *)animations
                                                     dutation:(NSTimeInterval)duration {
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.fillMode = kCAFillModeForwards;
    animationGroup.removedOnCompletion = NO;
    animationGroup.beginTime = AVCoreAnimationBeginTimeAtZero;
    animationGroup.duration = duration;
    animationGroup.animations = animations;
    return animationGroup;
}

+ (CABasicAnimation *)createPhotoAnimationWithType:(PhotoMovieAnimationType)type
                                          duration:(NSTimeInterval)duration
                                         beginTime:(NSTimeInterval)beginTime {
    
    CABasicAnimation *photoAnimation = [self createPhotoAnimationWithType:type];
    photoAnimation.beginTime = beginTime;
    photoAnimation.duration = duration;
    photoAnimation.removedOnCompletion = NO;
    photoAnimation.fillMode = kCAFillModeForwards;
    return photoAnimation;
}

+ (CABasicAnimation *)createPhotoAnimationWithType:(PhotoMovieAnimationType)type {
    CABasicAnimation *animation = nil;
    switch (type) {
        case PhotoMovieAnimationTypeFadeShowing: {
            animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.fromValue = @(0);
            animation.toValue = @(1);
            break;
        }
        case PhotoMovieAnimationTypeFadeHiding: {
            animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.fromValue = @(1);
            animation.toValue = @(0);
            break;
        }
        case PhotoMovieAnimationTypeZooming: {
            animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
            animation.fromValue = @(1);
            animation.toValue = @(1.5);
            break;
        }
        default:
            break;
    }
    return animation;
}

@end

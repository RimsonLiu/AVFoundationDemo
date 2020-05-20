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
    [self addSinglePhotoAnimation:[images firstObject] toLayer:animationLayer inSize:size];
    return animationLayer;
}

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
    CABasicAnimation *photoAnimation = [self createPhotoAnimation:duration
                                                        beginTime:AVCoreAnimationBeginTimeAtZero];
    CAAnimationGroup *animationGroup = [self createPhotoAnimationGroupWithAnimations:@[photoAnimation] dutation:duration];
    return animationGroup;
}

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

+ (CABasicAnimation *)createPhotoAnimation:(NSTimeInterval)duration beginTime:(NSTimeInterval)beginTime {
    CABasicAnimation *photoAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    photoAnimation.fromValue = @(1);
    photoAnimation.toValue = @(1.5);
    photoAnimation.beginTime = beginTime;
    photoAnimation.duration = duration;
    photoAnimation.removedOnCompletion = NO;
    photoAnimation.fillMode = kCAFillModeForwards;
    return photoAnimation;
}

@end

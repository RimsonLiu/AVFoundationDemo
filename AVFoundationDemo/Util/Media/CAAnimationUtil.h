//
//  CAAnimationUtil.h
//  AVFoundationDemo
//
//  Created by RimsonLiu on 2020/5/19.
//  Copyright © 2020 rimson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PhotoMovieAnimationType) {
    PhotoMovieAnimationTypeFadeShowing = 0,
    PhotoMovieAnimationTypeFadeHiding = 1,
    PhotoMovieAnimationTypeZooming = 2,
};

@interface CAAnimationUtil : NSObject

+ (CALayer *)createAnimationLayerWithPhotos:(NSArray<UIImage *> *)images
                                       size:(CGSize)size
                                 videoLayer:(CALayer *)videoLayer;

@end

NS_ASSUME_NONNULL_END

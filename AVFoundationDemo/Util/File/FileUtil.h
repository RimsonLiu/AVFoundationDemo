//
//  FileUtil.h
//  AVFoundationDemo
//
//  Created by Rimson on 2020/4/25.
//  Copyright © 2020 rimson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MediaUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface FileUtil : NSObject

+ (void)deleteFileIfExistsAt:(NSString *)fileName;
+ (void)createEmptyVideoInSize:(CGSize)frameSize at:(NSString *)tempPath withCompletion:(void (^)(void))completion;
@end

NS_ASSUME_NONNULL_END

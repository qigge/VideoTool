//
//  ZQAVPlayerTool.h
//  ChildrenEnglish
//
//  Created by wang on 2017/12/21.
//  Copyright © 2017年 Acadsoc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface ZQVideoModel : NSObject

@property (nonatomic, strong) UIImage *image;


@property (nonatomic, assign) NSTimeInterval length;

- (instancetype)initWithImage:(UIImage *)image length:(NSTimeInterval)length;

@end

@interface ZQVideoTool : NSObject
/** 从视频中取出图片
 *@param video 视频
 *@param time 时间
 *@return UIImage 图片
 */
+ (UIImage *)getImageFromVideo:(AVAsset *)video time:(CMTime)time;

/**
 从图片中获取CVPixelBufferRef

 @param image 图片
 @param size 大小
 @return CVPixelBufferRef
 */
+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size;

/** 从若干图片中 制作成指定长度的视频（默认fps为24）
 *@param models 图片,长度模型数组
 *@param size 视频大小
 *@param handler 完成后回调
 */
+ (void)makeVideoWithModels:(NSArray <ZQVideoModel *>*)models size:(CGSize)size completionHandler:(void (^)(NSURL *filePath))handler;

/**
 合成多个视频文件

 @param arr 视频文件数组
 @param handler 完成回调
 */
+ (void)compositeVideoWithVideos:(NSArray <NSString *>*)arr completionHandler:(void (^)(NSURL *filePath))handler;
@end

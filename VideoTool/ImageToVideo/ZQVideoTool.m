//
//  ZQAVPlayerTool.m
//  ChildrenEnglish
//
//  Created by wang on 2017/12/21.
//  Copyright © 2017年 Acadsoc. All rights reserved.
//

#import "ZQVideoTool.h"
#import <UIKit/UIKit.h>

@implementation ZQVideoModel

- (instancetype)initWithImage:(UIImage *)image length:(NSTimeInterval)length {
    if (self = [super init]) {
        _image = image;
        _length = length;
    }
    return self;
}

@end

@implementation ZQVideoTool
/** 从视频中取出图片
 *@param video 视频
 *@param time 时间
 *@return UIImage 图片
 */
+ (UIImage *)getImageFromVideo:(AVAsset *)video time:(CMTime)time{
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:video];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    CGImageRef thumbnailImageRef = NULL;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:time actualTime:NULL error:&thumbnailImageGenerationError];
    if (!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@", thumbnailImageGenerationError);
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
    return thumbnailImage;
}

+ (void)makeVideoWithModels:(NSArray <ZQVideoModel *>*)models size:(CGSize)size completionHandler:(void (^)(NSURL *))handler {
    NSURL *filePath = [NSURL fileURLWithPath:[self createFilePath]];
    
    // 创建AVAssetWriter，这个类可以方便的将图像和音频写成一个完整的视频文件
    NSError *error = nil;;
    AVAssetWriter *videoWrite = [[AVAssetWriter alloc] initWithURL:filePath fileType:AVFileTypeMPEG4 error:&error];
    if (error) {
        NSLog(@"error -- :%@",error);
    }
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264,AVVideoCodecKey,
                                   [NSNumber numberWithFloat:size.width],AVVideoWidthKey,
                                   [NSNumber numberWithFloat:size.height],AVVideoHeightKey,nil];
    AVAssetWriterInput *writerInput =[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSDictionary*sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                          [NSNumber numberWithInt:kCVPixelFormatType_32ARGB],kCVPixelBufferPixelFormatTypeKey,nil];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor =[AVAssetWriterInputPixelBufferAdaptor
                                                    assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWrite canAddInput:writerInput]);
    
    [videoWrite canAddInput:writerInput];
    
    [videoWrite addInput:writerInput];
    
    [videoWrite startWriting];
    [videoWrite startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
    
    int __block frame = 0;
    NSInteger __block idx = 0;
    int32_t fps = 30;
    CMTime __block startTime = CMTimeMake(0, fps);
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        if ([writerInput isReadyForMoreMediaData]) {
            ZQVideoModel *model = models[idx];
            CVPixelBufferRef buffer = [self pixelBufferFromCGImage:model.image.CGImage size:size];
            [adaptor appendPixelBuffer:buffer withPresentationTime:startTime];
            startTime = CMTimeAdd(startTime, CMTimeMake(1, fps));
            CFRelease(buffer);
            if (frame >= model.length * fps) {
                frame = 0;
                idx ++;
                if (idx >= models.count) {
                    [writerInput markAsFinished];
                    [videoWrite finishWritingWithCompletionHandler:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (handler) {
                                handler(filePath);
                            }
                        });
                    }];
                }
            }
        }
    }];
}

+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size {
    NSDictionary *options =[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    CVPixelBufferRef pxbuffer =NULL;
    
    CGFloat frameWidth = size.width;
    CGFloat frameHeight = size.height;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,frameWidth,frameHeight,kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef) options,&pxbuffer);
    
    NSParameterAssert(status ==kCVReturnSuccess && pxbuffer !=NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer,0);
    
    void *pxdata =CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata !=NULL);
    CGColorSpaceRef rgbColorSpace=CGColorSpaceCreateDeviceRGB();

    //    当你调用这个函数的时候，Quartz创建一个位图绘制环境，也就是位图上下文。当你向上下文中绘制信息时，Quartz把你要绘制的信息作为位图数据绘制到指定的内存块。一个新的位图上下文的像素格式由三个参数决定：每个组件的位数，颜色空间，alpha选项
    CGContextRef context = CGBitmapContextCreate(pxdata,frameWidth,frameHeight,
                                                 8,CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,(CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    //使用CGContextDrawImage绘制图片  这里设置不正确的话 会导致视频颠倒
    //    当通过CGContextDrawImage绘制图片到一个context中时，如果传入的是UIImage的CGImageRef，因为UIKit和CG坐标系y轴相反，所以图片绘制将会上下颠倒
    CGContextDrawImage(context,CGRectMake(0,0,frameWidth,frameHeight), image);
    // 释放色彩空间
    CGColorSpaceRelease(rgbColorSpace);
    // 释放context
    CGContextRelease(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(pxbuffer,0);
    
    return pxbuffer;
}

/**
 创建视频文件路径
 Cache目录下，.mp4后缀

 @return 文件路径
 */
+ (NSString *)createFilePath {
    NSDate *nowDate = [NSDate date];
    double timestamp = (double)[nowDate timeIntervalSince1970]*1000;
    long nowTimestamp = [[NSNumber numberWithDouble:timestamp] longValue];
    NSString *timestampStr = [NSString stringWithFormat:@"%ld",nowTimestamp];
    
    // 创建存储路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    NSString *moviePath = [cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%d.mp4",timestampStr, arc4random()%100000]];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:moviePath]) {
        [fm removeItemAtPath:moviePath error:nil];
    }
    return moviePath;
}

+ (void)compositeVideoWithVideos:(NSArray <NSString *>*)arr completionHandler:(void (^)(NSURL *))handler {
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    //视频轨道
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // 音频轨道
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [arr enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            NSError *error;
            AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:obj]];
            // 插入视频
            NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[videoTracks firstObject] atTime:kCMTimeZero error:&error];
            if (error) {
                NSLog(@"----%@",error);
            }
            // 插入音频
            NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
            if (audioTracks.count) {
                [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[audioTracks firstObject] atTime:kCMTimeZero error:&error];
            }else {
                [audioTrack insertEmptyTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)];
            }
        }
    }];
    // 输出
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetPassthrough];
    // 输出类型
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    
    NSURL *filePath = [NSURL fileURLWithPath:[self createFilePath]];
    assetExport.outputURL = filePath;
    // 优化
    assetExport.shouldOptimizeForNetworkUse = YES;
    // 合成完毕
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) {
                handler(filePath);
            }
            NSLog(@"%@",assetExport.error);
        });
    }];
}

@end

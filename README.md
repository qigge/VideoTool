# iOS VideoTool
ZQVideoTool对iOS视频合成和拼接进行了封装

[Demo地址：](https://github.com/qigge/VideoTool)https://github.com/qigge/VideoTool
# 工具方法

### 从视频中取出图片
```
/** 从视频中取出图片
 *@param video 视频
 *@param time 时间
 *@return UIImage 图片
 */
+ (UIImage *)getImageFromVideo:(AVAsset *)video time:(CMTime)time;
```

### 从图片中获取CVPixelBufferRef
```
/**
 从图片中获取CVPixelBufferRef

 @param image 图片
 @param size 大小
 @return CVPixelBufferRef
 */
+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size;
```

### 从若干图片中 制作成指定长度的视频
```
/** 从若干图片中 制作成指定长度的视频(默认fps为24)
 *@param models 图片,长度模型数组
 *@param size 视频大小
 *@param handler 完成后回调
 */
+ (void)makeVideoWithModels:(NSArray <ZQVideoModel *>*)models size:(CGSize)size completionHandler:(void (^)(NSURL *filePath))handler;
```

### 拼接多个视频文件
```
/**
 拼接多个视频文件

 @param arr 视频文件数组
 @param handler 完成回调
 */
+ (void)compositeVideoWithVideos:(NSArray <NSString *>*)arr completionHandler:(void (^)(NSURL *filePath))handler;
```

# 知识点
```[adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];```
上述方法中presentTime的理解可以参考这边文章[视频合成中CMTime的理解，以及利用CMTime实现过渡效果](https://zwo28.wordpress.com/2015/03/06/%E8%A7%86%E9%A2%91%E5%90%88%E6%88%90%E4%B8%ADcmtime%E7%9A%84%E7%90%86%E8%A7%A3%EF%BC%8C%E4%BB%A5%E5%8F%8A%E5%88%A9%E7%94%A8cmtime%E5%AE%9E%E7%8E%B0%E8%BF%87%E6%B8%A1%E6%95%88%E6%9E%9C/)

我的理解是在presentTime 这个时间点添加关键帧

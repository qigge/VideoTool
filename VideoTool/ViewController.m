//
//  ViewController.m
//  VideoTool
//
//  Created by wang on 2018/6/23.
//  Copyright © 2018年 acadsoc. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ZQPlayerMaskView.h"

#import "ZQVideoTool.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet ZQPlayerMaskView *player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

}
- (IBAction)hcVideo1:(id)sender {
    __weak typeof(self) weakself = self;
    UIImage *image = [UIImage imageNamed:@"1.jpeg"];
    ZQVideoModel *model = [[ZQVideoModel alloc] initWithImage:image length:5];
    [ZQVideoTool makeVideoWithModels:@[model] size:CGSizeMake(200, 300) completionHandler:^(NSURL *filePath) {
        [weakself.player playWithVideoUrl:filePath.relativePath];
    }];
}
- (IBAction)hcVideo2:(id)sender {
    __weak typeof(self) weakself = self;
    UIImage *image = [UIImage imageNamed:@"2.jpeg"];
    ZQVideoModel *model = [[ZQVideoModel alloc] initWithImage:image length:5];
    [ZQVideoTool makeVideoWithModels:@[model] size:CGSizeMake(200, 300) completionHandler:^(NSURL *filePath) {
        [weakself.player playWithVideoUrl:filePath.relativePath];
    }];
}
- (IBAction)twoImageToVideo:(id)sender {
    UIImage *image = [UIImage imageNamed:@"1.jpeg"];
    ZQVideoModel *model1 = [[ZQVideoModel alloc] initWithImage:image length:5];
    
    UIImage *image2 = [UIImage imageNamed:@"2.jpeg"];
    ZQVideoModel *model2 = [[ZQVideoModel alloc] initWithImage:image2 length:5];
    
    [ZQVideoTool makeVideoWithModels:@[model1,model2] size:CGSizeMake(200, 300) completionHandler:^(NSURL *filePath) {
        NSLog(@"%@",filePath);
        [self.player playWithVideoUrl:filePath.relativePath];
    }];
}
- (IBAction)hcTwoVideo:(id)sender {
    NSMutableArray *videos = [NSMutableArray array];
    
    dispatch_group_t group = dispatch_group_create();
    // 并行队列
    dispatch_queue_t queue =dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        UIImage *image = [UIImage imageNamed:@"1.jpeg"];
        ZQVideoModel *model = [[ZQVideoModel alloc] initWithImage:image length:5];
        [ZQVideoTool makeVideoWithModels:@[model] size:CGSizeMake(200, 300) completionHandler:^(NSURL *filePath) {
            [videos addObject:filePath.relativePath];
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    });
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        UIImage *image = [UIImage imageNamed:@"2.jpeg"];
        ZQVideoModel *model = [[ZQVideoModel alloc] initWithImage:image length:5];
        [ZQVideoTool makeVideoWithModels:@[model] size:CGSizeMake(200, 300) completionHandler:^(NSURL *filePath) {
            [videos addObject:filePath.relativePath];
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    });
    __weak typeof(self) weakself = self;
    dispatch_group_notify(group, queue, ^{
        [ZQVideoTool compositeVideoWithVideos:videos completionHandler:^(NSURL *filePath) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.player playWithVideoUrl:filePath.relativePath];
            });
        }];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

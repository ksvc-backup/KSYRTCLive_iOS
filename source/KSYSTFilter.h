//
//  KSYSTFilterThree.h
//  KSYLiveDemo
//
//  Created by 孙健 on 2017/1/16.
//  Copyright © 2017年 qyvideo. All rights reserved.
//

#import <GPUImage/GPUImage.h>
#import "senseAr.h"

@interface KSYSTFilter : GPUImageOutput<GPUImageInput>

//初始化appid
-(id)initWithAppid:(NSString *)appID
            appKey:(NSString *)appKey;

//获取资源列表，完成回调下载数量
@property(nonatomic, copy) void(^fetchListFinishCallback)(NSUInteger count);

//选择该资源，通过下载列表的
- (void)changeSticker:(int) index
            onSuccess:(void (^)(SenseArMaterial *))completeSuccess
            onFailure:(void (^)(SenseArMaterial *, int, NSString *))completeFailure
           onProgress:(void (^)(SenseArMaterial *, float, int64_t))processingCallBack;

//打开贴纸
@property(nonatomic, assign) int enableSticker;

//打开美颜
@property(nonatomic, assign) BOOL enableBeauty;

@end

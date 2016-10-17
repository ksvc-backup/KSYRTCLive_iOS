//
//  KSYRTCAudioCapture.h
//  KSYStreamer
//
//  Created by ksyun on 16/8/24.
//  Copyright © 2016年 yiqian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface KSYRTCAecModule : NSObject

/**
 @abstract  启动音频采集，播放
 @return    是否启动采集成功
 */
- (BOOL)start;

/** 
 @abstract  停止音频采集，播放
 */
- (BOOL)stop;

/** 
 @abstract  采样率
  */
@property(nonatomic, assign) Float64 sampleRate;
/**
  @abstract 放入传输的数据
  */
-(void) putVoiceTobuffer:(void* )buffer
                    size:(int)blockBufSize;
/**
 @abstract   采集数据输出回调函数
 @param      sampleBuffer 采集到的音频数据
 */
@property(nonatomic, copy) void(^audioProcessingCallback)(CMSampleBufferRef sampleBuffer);


@end
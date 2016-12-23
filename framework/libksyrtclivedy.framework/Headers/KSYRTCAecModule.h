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
- (BOOL)startCapture;

/** 
 @abstract  停止音频采集，播放
 */
- (BOOL)stopCapture;
/**
 @abstract  开始扬声器
 */
- (void)startSpeaker;
/**
 @abstract  停止扬声器
 */
- (void)stopSpeaker;

/** 
 @abstract  采样率
  */
@property(nonatomic, assign) Float64 sampleRate;

/**
 @abstract  设置mic采集的声音音量
 @discussion 调整范围 0.0~1.0
 */
@property(nonatomic, assign) Float32 micVolume;


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

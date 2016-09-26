#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class KSYGPUStreamerKit;
@class KSYRTCSteamer;

@interface KSYRTCStreamerKit: KSYGPUStreamerKit

/**
 @abstract 初始化方法
 @discussion 创建带有默认参数的 kit
 
 @warning kit只支持单实例推流，构造多个实例会出现异常
 */
- (instancetype) initWithDefaultCfg;
/**
 @abstract rtc接口类
 */
@property (nonatomic, strong) KSYRTCSteamer * rtcSteamer;

/*
 @abstract start call的回调函数
 */
@property (nonatomic, copy)void (^onCallStart)(int status);
/*
 @abstract stop call的回调函数
 */
@property (nonatomic, copy)void (^onCallStop)(int status);

/**
 @abstract 设置小窗口的位置，可以动态调整
 */

@property (nonatomic, readwrite) CGRect winRect;

/**
 @abstract 主窗口和小窗口切换
 */
@property (nonatomic, readwrite) BOOL selfInFront;

/**
 @abstract 停止音视频采集和渲染
  */
-(void)stopRTCView;

/**
 @abstract 设置美颜接口
 */
- (void) setupRtcFilter:(GPUImageOutput<GPUImageInput>*) filter;
@end

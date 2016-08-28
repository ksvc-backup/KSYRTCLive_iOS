#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class KSYGPUStreamerKit;
@class KSYRTCSteamer;
@class KSYRTCAudioCapture;

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

/**
 @abstract 默认的rtc音频回调
 @discuss 默认音频会输出到播放设备和推流steamer
 */

-(void) defaultRtcVoiceCallback:(uint8_t*)buf
                            len:(int)len
                            pts:(uint64_t)ptsvalue;
/**
 @abstract 默认的rtc视频回调
 @discuss  默认的对端视频会根据defaultOnCallStartCallback的设置放入小窗
 */
-(void) defaultRtcVideoCallback:(CVPixelBufferRef)buf;

/**
  @abstract 默认的主播onCallStart调用
  @param  rect 小窗口的初始化矩阵
  @param  selfinfront
 @discuss rect是归一化的矩阵，即总视图为1.0*1，0的矩阵，rect的顶点+宽高不能大于1.0
 (0.6,0.6,0.3,0.3)是合法的，(0.6,0.6,0.5,0.3)不合法。
 */
-(void) defaultOnCallStartCallback:(CGRect)rect
                       selfinfront:(BOOL)selfinfront;
/**
 @abstract 默认的onCallStop调用
 */
-(void) defaultOnCallStopCallback;
/**
 @abstract 调整小窗口的大小
 @discuss rect是归一化的矩阵，即总视图为1.0*1，0的矩阵，rect的顶点+宽高不能大于1.0
          (0.6,0.6,0.3,0.3)是合法的，(0.6,0.6,0.5,0.3)不合法。
 */
/**
 @abstract 设置小窗口的位置，可以动态调整
 */

@property (nonatomic, readwrite) CGRect winRect;


/**
  @abstract 带回音消除的rtc采集模块
 */
@property (nonatomic,strong)KSYRTCAudioCapture* rtcAudioUnitCapture;

@end

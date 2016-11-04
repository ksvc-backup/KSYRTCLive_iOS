//
//  KSYRTCSteamer.h
//  KSYStreamer
//
//  Created by YULIN on 16/6/17.
//  Copyright © 2016年 YULIN. All rights reserved.
//

/* 错误码定义*/
typedef enum KSYRTCResult{
 KSYRTCErrorWarn = 100,
 KSYRTCErrorBusy = 101,
 KSYRTCErrorNone = 0,
 KSYRTCErrorFatal = -1,
 KSYRTCErrorUnknown = -2,
 KSYRTCErrorInvalidParam = -3,
 KSYRTCErrorSDKFail = -4,
 KSYRTCErrorNotSupport = -5,
 KSYRTCErrorInvalidState = -6,
 KSYRTCErrorLackOfResource = -7,
//创建RTC错误码
 KSYRTC_Create_ErrorFatal = 601,
 KSYRTC_Create_ErrorUnknown = 602,
 KSYRTC_Create_ErrorInvalidParam = 603,
 KSYRTC_Create_ErrorSDKFail = 604,
 KSYRTC_Create_ErrorNotSupport = 605,
 KSYRTC_Create_ErrorInvalidState = 606,
 KSYRTC_Create_ErrorLackOfResource = 607,
//鉴权错误码
 KSYRTC_AUTH_HTTPFail = 611,
 KSYRTC_AUTH_SerializationFail = 612,
 KSYRTC_AUTH_Status_NotOK = 613,
//初始化错误码
 KSYRTC_Init_ErrorFatal = 621,
 KSYRTC_Init_ErrorUnknown = 622,
 KSYRTC_Init_ErrorInvalidParam = 623,
 KSYRTC_Init_ErrorSDKFail = 624,
 KSYRTC_Init_ErrorNotSupport = 625,
 KSYRTC_Init_ErrorInvalidState = 626,
 KSYRTC_Init_ErrorLackOfResource = 627,
//注册错误码
 KSYRTC_Register_ErrorFatal = 631,
 KSYRTC_Register_ErrorUnknown = 632,
 KSYRTC_Register_ErrorInvalidParam = 633,
 KSYRTC_Register_ErrorSDKFail = 634,
 KSYRTC_Register_ErrorNotSupport = 635,
 KSYRTC_Register_ErrorInvalidState = 636,
 KSYRTC_Register_ErrorLackOfResource = 637,
 } KSYRTCResult;

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void (^RTCVideoDataBlock)(CVPixelBufferRef pixelBuffer);

typedef void (^RTCVoiceDataBlock)(uint8_t* pData,int blockBufSize,uint64_t pts);

@interface KSYRTCSteamer: NSObject
/*
 @abstract 鉴权需要的token字符串，具体含义参见文档
 */
@property(nonatomic,copy) NSString * authString;

/*
 @abstract 指定唯一标示，鉴权时候当做后缀使用
 */
@property(nonatomic,copy) NSString * uniqName;

/*
 @abstract 注册后会拿到
 */
@property(nonatomic,copy) NSString * domain;
/*
 @abstract 查询domain的鉴权串
 */
@property(nonatomic,copy) NSString * queryDomainString;
/*
 @abstract 本地id
 */
@property(nonatomic,copy) NSString * localId;
/*
 @abstract video的fps值
 */
@property (nonatomic, assign) int videoFPS;
/*
 @abstract 传输平均比特率
 */
@property (nonatomic, assign) int AvgBps;
/*
 @abstract 传输最大比特率
 */
@property (nonatomic, assign) int MaxBps;

/*
 @abstract audio的采样率
 */
@property (nonatomic, assign) int sampleRate;

/*
 @abstract 是否打开RTC的日志
 */
@property (nonatomic, assign) BOOL openRtcLog;
/*
 @abstract 是否强制使用turn协议
 */
@property (nonatomic, assign) BOOL forceTurn;
/*
 @abstract 对端视频数据宽度
 */
@property (nonatomic, assign) int scaledWidth;

/*
 @abstract 对端视频数据高度
 */
@property (nonatomic, assign) int scaledHeight;

/*
 @abstract 辅播可以通过这个接口不发送视频数据
 */
@property (nonatomic, assign) BOOL muteVideo;

/*
 @abstract rtc信令的传输模式,默认为TLS
 TCP = 0,
 TLS = 1,
 UDP = 2
 */
@property (nonatomic, assign) int rtcMode;

/*
 @abstract sip呼叫里面的账户信息
 */
@property(nonatomic,copy) NSString * authUid;

/*
 @abstract 对端的sip账户信息
 */
@property(nonatomic,copy) NSString * remoteUid;
 
#pragma  mark -  callback
/*
 @abstract 接收注册结果的回调函数
 */
@property (nonatomic, copy)void (^onRegister)(int status);

/*
 @abstract 接收反注册结果的回调函数
 */
@property (nonatomic, copy)void (^onUnRegister)(int status);

/*
 @abstract start call的回调函数
 */
@property (nonatomic, copy)void (^onRtcCallStart)(int status);
/*
 @abstract answer的回调函数
 */
@property (nonatomic, copy)void (^onCallAnswer)(int status);
/*
 @abstract reject的回调函数
 */
@property (nonatomic, copy)void (^onCallReject)(int status);

/*
 @abstract stop call的回调函数
 */
@property (nonatomic, copy)void (^onRTCCallStop)(int status);

/*
 @abstract call coming的回调函数，返回远端的remoteURI
 */
@property (nonatomic, copy)void (^onCallInComing)(char* remoteURI);
/*
 @abstract 事件通知
 @param type =1  网络中断
 */
@property (nonatomic, copy)void (^onEvent)(int type, void* detail);

/*
 @abstract 返回视频数据供上游渲染
 */
@property (nonatomic, copy)RTCVideoDataBlock videoDataBlock;

/*
 @abstract 音频数据回调
 */
@property (nonatomic, copy)RTCVoiceDataBlock voiceDataBlock;

#pragma  mark -  rtc function
/*
 @abstract 注册RTC协议栈
 @discuss registerURL，localURL要确保有效
          返回值参见顶部的KSYRTCResult的定义
 @return  -1000 鉴权http错误
          -1001 鉴权串序列化失败
          -1002 鉴权失败
          其他注册失败的返回值参看
 */
-(int)registerRTC;

/*
 @abstract 反注册RTC协议栈
           返回值参见顶部的KSYRTCResult的定义
 */
-(int)unRegisterRTC;

/*
 @param 远端的用户ID
 @abstract 发起呼叫
           返回值参见顶部的KSYRTCResult的定义
 */
-(int) startCall:(NSString*) remoteid;

/*
 @abstract 接收呼叫
           返回值参见顶部KSYRTCResult的定义
 */
-(int)answerCall;

/*
 @abstract 拒绝呼叫
           返回值参见顶部的KSYRTCResult的定义
 */
-(int)rejectCall;

/*
 @abstract 停止呼叫
           返回值参见顶部的KSYRTCResult的定义
 */
-(int)stopCall;


#pragma  mark - audio/video process

/**
 @abstract   对原始采用数据进行scale处理
 @param      pixelBuffer 美颜后的视频数据
 
 @see CMSampleBufferRef
 */
-(int) processVideo:(CVPixelBufferRef)pixelBuffer
           timeInfo:(CMTime)timeInfo;

/**
 @abstract   对原始音频数据进行rtp传输
 @param      sampleBuffer 原始采集到的音频数据
 @param
 
 @see CMSampleBufferRef
 */
-(int) processAudio:(CMSampleBufferRef)sampleBuffer;

@end


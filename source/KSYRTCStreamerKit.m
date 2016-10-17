
#import "KSYGPUPicOutput.h"
#import "../KSYStreamer/KSYUtils.h"
#import "../KSYStreamer/KSYStreamerBase.h"
#import "../KSYStreamer/KSYBgmPlayer.h"
#import "../KSYStreamer/KSYAudioMixer.h"
#import "../KSYStreamer/KSYMicMonitor.h"
#import "KSYGPUCamera.h"
#import "../KSYGPUFilter/KSYGPUPipBlendFilter.h"
#import "../KSYGPUFilter/KSYGPUDnoiseFilter.h"
#import "../KSYGPUFilter/KSYGPULogoFilter.h"
#import "../KSYGPUStreamer/KSYGPUYUVInput.h"
#import "KSYRTCAecModule.h"
#import "KSYGPUPicMixer.h"
#import "KSYAVAudioSession.h"
#import "KSYGPUStreamerKit.h"
#import "KSYRTCStreamer.h"
#import <GPUImage/GPUImage.h>
#import "KSYRTCStreamerKit.h"

#if __arm__  || __arm64__
@interface KSYRTCStreamerKit (){
    
}

@property KSYGPUPicMixer  *     rtcPicMixer;
@property KSYGPUPicOutput *     beautyOutput;
@property KSYRTCAecModule *     rtcAecModule;
@property KSYGPUYUVInput  *     rtcYuvInput;
@property GPUImageOutput<GPUImageInput>* curfilter;

@property BOOL   callstarted;
@property BOOL   firstFrame;

@end

@implementation KSYRTCStreamerKit

/**
 @abstract 初始化方法
 @discussion 初始化，创建带有默认参数的 KSYStreamerBase
 
 @warning KSYStreamer只支持单实例推流，构造多个实例会出现异常
 */
- (instancetype) initWithDefaultCfg {
    self = [super initWithDefaultCfg];
    _rtcSteamer = [[KSYRTCSteamer alloc] init];
    _rtcAecModule = [[KSYRTCAecModule alloc] init];
    _rtcPicMixer = nil;
    _beautyOutput = nil;
    _callstarted = NO;
    _firstFrame = NO;
    _curfilter = self.filter;
    
    __weak KSYRTCStreamerKit * weak_kit = self;
    _rtcSteamer.videoDataBlock=^(CVPixelBufferRef buf){
        [weak_kit defaultRtcVideoCallback:buf];
    };
    _rtcSteamer.voiceDataBlock=^(uint8_t* buf,int len,uint64_t ptsvalue){
        [weak_kit defaultRtcVoiceCallback:buf len:len pts:ptsvalue];
    };
    _rtcSteamer.onCallStart= ^(int status){
        if(status == 200)
        {
            if([UIApplication sharedApplication].applicationState !=UIApplicationStateBackground)
            {
                [weak_kit defaultOnCallStartCallback];
            }
        }
        else if(status == 404){
            [weak_kit defaultOnCallStopCallback];
        }
        if(weak_kit.onCallStart)
        {
            weak_kit.onCallStart(status);
        }
    };
    
    _rtcSteamer.onCallStop= ^(int status){
         if(status == 200)
         {
             [weak_kit defaultOnCallStopCallback];
         }
        
         if(weak_kit.onCallStop)
         {
             weak_kit.onCallStop(status);
         }
    };
    
    _rtcSteamer.onEvent =^(int type,void * detail){
        if(type == 1 || type == 0)
        {
            NSLog(@"network break happen");
            [weak_kit defaultOnCallStopCallback];
            [weak_kit.rtcSteamer stopCall];
        }
    };
    
    _rtcAecModule.audioProcessingCallback =^(CMSampleBufferRef buf){
        [weak_kit.rtcSteamer processAudio:buf];
    };
    
    //注册进入后台的处理
    NSNotificationCenter* dc = [NSNotificationCenter defaultCenter];
    [dc addObserver:self
           selector:@selector(enterbg)
               name:UIApplicationDidEnterBackgroundNotification
             object:nil];
    
    [dc addObserver:self
           selector:@selector(becomeActive)
               name:UIApplicationDidBecomeActiveNotification
             object:nil];
    
    [dc addObserver:self
           selector:@selector(resignActive)
               name:UIApplicationWillResignActiveNotification
             object:nil];
    
    [dc addObserver:self
           selector:@selector(enterFg)
               name:UIApplicationWillEnterForegroundNotification
             object:nil];
    
    [dc addObserver:self
           selector:@selector(interruptHandler:)
               name:AVAudioSessionInterruptionNotification
             object:nil];
    return self;
}

- (void)interruptHandler:(NSNotification *)notification {
    UInt32 interruptionState = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntValue];
    if (interruptionState == kAudioSessionBeginInterruption){
        [self stopRTCView];
    }
    else if (interruptionState == kAudioSessionEndInterruption){
        [self startRtcView];
    }
}

- (instancetype)init {
    return [self initWithDefaultCfg];
}
- (void)dealloc {
    if(_rtcSteamer){
        [_rtcSteamer stopCall];
        _rtcSteamer = nil;
    }
    
    if(_rtcAecModule){
        _rtcAecModule = nil;
    }
    
    if(_beautyOutput){
        _beautyOutput = nil;
    }
    
    if(_rtcPicMixer){
        _rtcPicMixer = nil;
    }
    
    if(_rtcYuvInput){
        _rtcYuvInput = nil;
    }
    
    if(_curfilter){
        _curfilter = nil;
    }
    NSNotificationCenter* dc = [NSNotificationCenter defaultCenter];
    [dc removeObserver:self
                  name:UIApplicationDidEnterBackgroundNotification
                object:nil];
    [dc removeObserver:self
                  name:UIApplicationWillEnterForegroundNotification
                object:nil];
    [dc removeObserver:self
                  name:AVAudioSessionInterruptionNotification
                object:nil];
    [dc removeObserver:self
                  name:UIApplicationDidBecomeActiveNotification
                object:nil];
    [dc removeObserver:self
                  name:UIApplicationWillResignActiveNotification
                object:nil];
}

-(void) setupRtcFilter:(GPUImageOutput<GPUImageInput>*) filter{
    _curfilter = filter;
    [self.vCapDev     removeAllTargets];
    GPUImageOutput* src = self.vCapDev;
    if (self.cropfilter) {
        [self.cropfilter removeAllTargets];
        [self.cropfilter useNextFrameForImageCapture];
        [src addTarget:self.cropfilter];
        src = self.cropfilter;
    }
//    if (self.scalefilter) {
//        [self.scalefilter removeAllTargets];
//        [self.scalefilter useNextFrameForImageCapture];
//        [src addTarget:self.scalefilter];
//        src = self.scalefilter;
//    }
    if (_curfilter) {
        [_curfilter removeAllTargets];
        [src addTarget:_curfilter];
        src = _curfilter;
    }
    if(_beautyOutput)//美颜后的图像，用于rtc发送
    {
        [src addTarget:_beautyOutput atTextureLocation:2];
    }
    if (_rtcPicMixer) {
        [_rtcYuvInput removeAllTargets];
        [_rtcPicMixer removeAllTargets];
        [_rtcPicMixer clearPicOfLayer:0];
        [_rtcPicMixer clearPicOfLayer:1];
        if(_selfInFront)
        {
            [src addTarget:_rtcPicMixer atTextureLocation:1];
            [_rtcYuvInput addTarget:_rtcPicMixer atTextureLocation:0];
            _rtcPicMixer.masterLayer = 1;
        }
        else
        {
            [src addTarget:_rtcPicMixer atTextureLocation:0];
            [_rtcYuvInput addTarget:_rtcPicMixer atTextureLocation:1];
            _rtcPicMixer.masterLayer = 0;
        }
        [_rtcPicMixer setPicRect:CGRectMake(0,0,1.0,1.0) ofLayer:0];
        [_rtcPicMixer setPicRect:_winRect ofLayer:1];
        src = _rtcPicMixer;
    }
    
    [src     addTarget:self.preview];
    [src     addTarget:self.gpuToStr];
}

#pragma mark -rtc
-(void) defaultOnCallStartCallback
{
    [self startRtcView];
    _callstarted = YES;
}

-(void)startRtcView
{
    [self.aMixer setTrack:2 enable:YES];
    [self.aMixer setMixVolume:1 of:2];
    
    _rtcYuvInput =    [[KSYGPUYUVInput alloc] init];
    _rtcPicMixer =    [[KSYGPUPicMixer alloc]init];
    _beautyOutput  =  [[KSYGPUPicOutput alloc] init];
    __weak KSYRTCStreamerKit * wkit = self;
    _beautyOutput.videoProcessingCallback = ^(CVPixelBufferRef pixelBuffer, CMTime timeInfo ){
        [wkit.rtcSteamer processVideo:pixelBuffer timeInfo:timeInfo];
    };
    [self setupRtcFilter:_curfilter];
    [_rtcAecModule start];
}

-(void)stopRTCView
{
    [self.aMixer setTrack:2 enable:NO];
    _rtcYuvInput = nil;
    _rtcPicMixer = nil;
    _beautyOutput = nil;
    [self setupRtcFilter:_curfilter];
    [_rtcAecModule stop];
}

-(void) defaultRtcVideoCallback:(CVPixelBufferRef)buf
{
    /*
     第一帧到来的时候，重置一下filter，防止摄像头打开晚导致的图像问题
     */
    if(!_firstFrame)
    {
        [self setupRtcFilter:_curfilter];
        _firstFrame = YES;
    }
    [self.rtcYuvInput processPixelBuffer:buf time:CMTimeMake(2, 10)];
}
-(void) defaultRtcVoiceCallback:(uint8_t*)buf
                            len:(int)len
                            pts:(uint64_t)ptsvalue
{
    
    KSYAudioFormat outAudiofmt;
    outAudiofmt.sampleRate = 44100;
    outAudiofmt.chCnt      = 1;
    outAudiofmt.chLayout   = av_get_default_channel_layout(outAudiofmt.chCnt);
    outAudiofmt.sampleFmt  = AV_SAMPLE_FMT_S16P;
    outAudiofmt.sampleSize = sizeof(int16_t);
    
    [_rtcAecModule putVoiceTobuffer:(void*)buf size:len];
    CMTime pts;
    pts.value = ptsvalue;
    if([self.streamerBase isStreaming])
        [self.aMixer processAudioData:&buf nbSample:len/2 withFormat:&outAudiofmt timeinfo:pts of:2];
}


-(void) defaultOnCallStopCallback
{
    [self stopRTCView];
    _callstarted = NO;
}

-(void) setWinRect:(CGRect)rect
{
    [_rtcPicMixer setPicRect:rect ofLayer:1];
    _winRect = rect;
}

-(void)setSelfInFront:(BOOL)selfInFront{
    _selfInFront = selfInFront;
    [self setupRtcFilter:_curfilter];
}

- (void)enterbg {
    [self stopRTCView];
}

-(void)enterFg{
    if(_callstarted)
    {
        [self startRtcView];
    }
}

-(void)becomeActive
{
    __weak KSYRTCStreamerKit * weak_kit = self;
    _rtcSteamer.videoDataBlock=^(CVPixelBufferRef buf){
        [weak_kit defaultRtcVideoCallback:buf];
    };

NSNotificationCenter* dc = [NSNotificationCenter defaultCenter];
[dc addObserver:self
       selector:@selector(interruptHandler:)
           name:AVAudioSessionInterruptionNotification
         object:nil];
}

-(void)resignActive
{
    _rtcSteamer.videoDataBlock = nil;
    NSNotificationCenter* dc = [NSNotificationCenter defaultCenter];
    [dc removeObserver:self
                  name:AVAudioSessionInterruptionNotification
                object:nil];
}
@end
#else
@implementation KSYRTCStreamerKit

-(void)stopRTCView{
    
}

/**
 @abstract 设置美颜接口
 */
- (void) setupRtcFilter:(GPUImageOutput<GPUImageInput>*) filter;
{
    
}
@end
#endif

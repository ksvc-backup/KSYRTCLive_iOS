
#import "KSYGPUPicOutput.h"
#import <libksygpulive/libksygpuimage.h>
#import <libksygpulive/KSYGPUStreamerKit.h>
#import <libksyrtclivedy/KSYRTCAecModule.h>
#import <libksyrtclivedy/KSYRTCClient.h>
#import <GPUImage/GPUImage.h>
#import "KSYSChatKit.h"

#if __arm__  || __arm64__
@interface KSYSChatKit (){
    
}

@property KSYGPUPicOutput *     beautyOutput;
@property KSYRTCAecModule *     rtcAecModule;
@property KSYGPUYUVInput  *     rtcYuvInput;
@property GPUImageUIElement *   uiElementInput;

@end

@implementation KSYSChatKit

/**
 @abstract 初始化方法
 @discussion 初始化，创建带有默认参数的 KSYStreamerBase
 
 @warning KSYStreamer只支持单实例推流，构造多个实例会出现异常
 */
- (instancetype) initWithDefaultCfg {
    self = [super initWithDefaultCfg];
    _rtcClient = [[KSYRTCClient alloc] init];
    _rtcAecModule = [[KSYRTCAecModule alloc] init];
    _beautyOutput = nil;
    _callstarted = NO;
    _curfilter = self.filter;
    
    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
    _contentView.backgroundColor = [UIColor clearColor];
    
    __weak KSYSChatKit * weak_kit = self;
    _rtcClient.videoDataBlock=^(CVPixelBufferRef buf){
        [weak_kit defaultRtcVideoCallback:buf];
    };
    _rtcClient.voiceDataBlock=^(uint8_t* buf,int len,uint64_t ptsvalue,uint32_t channels,
                                 uint32_t sampleRate,uint32_t bytesPerSample){
        [weak_kit defaultRtcVoiceCallback:buf len:len pts:ptsvalue channel:channels sampleRate:sampleRate sampleBytes:bytesPerSample];
    };
    _rtcClient.onRtcCallStart= ^(int status){
        if(status == 200)
        {
            if([UIApplication sharedApplication].applicationState !=UIApplicationStateBackground)
            {
                [weak_kit startRtcView];
            }
            _callstarted = YES;
        }
        else if(status == 404){
            [weak_kit onCallStopCallback];
            if(weak_kit.onCallStop)
            {
                weak_kit.onCallStop(status);
            }
        }
        if(weak_kit.onCallStart)
        {
            weak_kit.onCallStart(status);
        }
    };
    
    _rtcClient.onRTCCallStop= ^(int status){
         if(status == 200 || status == 408)
         {
             [weak_kit onCallStopCallback];
             if(weak_kit.onCallStop)
             {
                 weak_kit.onCallStop(status);
             }
         }
    };
    
    _rtcClient.onEvent =^(int type,void * detail){
        if(type == 1 || type == 0)
        {
            NSLog(@"network break happen");
            [weak_kit onCallStopCallback];
            [weak_kit.rtcClient stopCall];
        }
    };
    
    _rtcAecModule.audioProcessingCallback =^(CMSampleBufferRef buf){
        [weak_kit.rtcClient processAudio:buf];
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
        if(_callstarted)
            [self stopRTCView];
    }
    else if (interruptionState == kAudioSessionEndInterruption){
        if(_callstarted)
            [self startRtcView];
    }
}

- (instancetype)init {
    return [self initWithDefaultCfg];
}
- (void)dealloc {
    NSLog(@"kit dealloc ");
    
    if(_rtcClient){
        _rtcClient = nil;
    }
    
    if(_rtcAecModule){
        _rtcAecModule = nil;
    }
    
    if(_beautyOutput){
        _beautyOutput = nil;
    }
    
    if(_rtcYuvInput){
        _rtcYuvInput = nil;
    }
    
    if(_contentView)
    {
        _contentView = nil;
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


- (void) setupRtcFilter:(GPUImageOutput<GPUImageInput> *) filter {
    _curfilter = filter;
    if (self.vCapDev  == nil) {
        return;
    }
    // 采集的图像先经过前处理
    [self.vCapDev     removeAllTargets];
    GPUImageOutput* src = self.vCapDev;
    if (self.cropfilter) {
        [self.cropfilter removeAllTargets];
        [src addTarget:self.cropfilter];
        src = self.cropfilter;
    }
    if (filter) {
        [filter removeAllTargets];
        [src addTarget:filter];
        src = filter;
    }
    
    // 组装图层
    if(_rtcYuvInput)
    {
        if(!_selfInFront)
        {
            self.vPreviewMixer.masterLayer = self.cameraLayer;
            [self addPic:src       ToMixerAt:self.cameraLayer];
            [self addPic:_rtcYuvInput ToMixerAt:_rtcLayer Rect:_winRect];
        }
        else{
            self.vPreviewMixer.masterLayer = self.rtcLayer;
            [self addPic:_rtcYuvInput  ToMixerAt:self.cameraLayer];
            [self addPic:src ToMixerAt:_rtcLayer Rect:_winRect];
        }
    }else{
        [self.vPreviewMixer clearPicOfLayer:_rtcLayer];
        self.vPreviewMixer.masterLayer = self.cameraLayer;
        [self addPic:src       ToMixerAt:self.cameraLayer];
        
    }
    
    //组装自定义view
    if(_uiElementInput)
    {
        __weak GPUImageUIElement *weakUIEle = _uiElementInput;
        [src setFrameProcessingCompletionBlock:^(GPUImageOutput * f, CMTime fT){
            NSArray* subviews = [_contentView subviews];
            for(int i = 0;i<subviews.count;i++)
            {
                UIView* subview = (UIView*)[subviews objectAtIndex:i];
                if(subview)
                    subview.hidden = NO;
            }
            if(subviews.count > 0)
            {
               [weakUIEle update];
            }
        }];
        [self addPic:_uiElementInput ToMixerAt:_customViewLayer Rect:_customViewRect];
    }
    else{
        [self.vPreviewMixer clearPicOfLayer:_customViewLayer];
        [src setFrameProcessingCompletionBlock:nil];
    }
    
    //美颜后的图像，用于rtc发送
    if(_beautyOutput)
    {
        [src addTarget:_beautyOutput atTextureLocation:2];
    }
    
    // 混合后的图像输出到预览和推流
    [self.vPreviewMixer removeAllTargets];
    [self.vPreviewMixer addTarget:self.preview];
}

- (void) addPic:(GPUImageOutput*)pic ToMixerAt: (NSInteger)idx{
    if (pic == nil){
        return;
    }
    [pic removeAllTargets];
    KSYGPUPicMixer * vMixer[1] = {self.vPreviewMixer};
    for (int i = 0; i<1; ++i) {
        [vMixer[i]  clearPicOfLayer:idx];
        [pic addTarget:vMixer[i] atTextureLocation:idx];
    }
}

- (void) addPic:(GPUImageOutput*)pic
      ToMixerAt: (NSInteger)idx
           Rect:(CGRect)rect{
    if (pic == nil){
        return;
    }
    [pic removeAllTargets];
    KSYGPUPicMixer * vMixer[1] = {self.vPreviewMixer};
    for (int i = 0; i<1; ++i) {
        [vMixer[i]  clearPicOfLayer:idx];
        [pic addTarget:vMixer[i] atTextureLocation:idx];
        [vMixer[i] setPicRect:rect ofLayer:idx];
        [vMixer[i] setPicAlpha:1.0f ofLayer:idx];
    }
}

#pragma mark -rtc

-(void)startRtcView
{
    _rtcYuvInput =    [[KSYGPUYUVInput alloc] init];
    _beautyOutput  =  [[KSYGPUPicOutput alloc] init];
    __weak KSYSChatKit * wkit = self;
    _beautyOutput.videoProcessingCallback = ^(CVPixelBufferRef pixelBuffer, CMTime timeInfo ){
        [wkit.rtcClient processVideo:pixelBuffer timeInfo:timeInfo];
    };
    
    //if(_contentView.subviews.count != 0)
    _uiElementInput = [[GPUImageUIElement alloc] initWithView:_contentView];

    [self setupRtcFilter:_curfilter];
    [_rtcAecModule start];
}

-(void)stopRTCView
{
    _rtcYuvInput = nil;
    _beautyOutput = nil;
    _uiElementInput = nil;
    [self setupRtcFilter:_curfilter];
    [_rtcAecModule stop];
}

-(void) defaultRtcVideoCallback:(CVPixelBufferRef)buf
{

    [self.rtcYuvInput processPixelBuffer:buf time:CMTimeMake(2, 10)];
}
-(void) defaultRtcVoiceCallback:(uint8_t*)buf
                            len:(int)len
                            pts:(uint64_t)ptsvalue
                        channel:(uint32_t)channels
                     sampleRate:(uint32_t)sampleRate
                    sampleBytes:(uint32_t)bytesPerSample
{
    
    AudioStreamBasicDescription asbd;
    asbd.mSampleRate       = sampleRate;
    asbd.mFormatID         = kAudioFormatLinearPCM;
    asbd.mFormatFlags      = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    asbd.mBitsPerChannel   = 8 * bytesPerSample;
    asbd.mBytesPerFrame    = bytesPerSample;
    asbd.mBytesPerPacket   = bytesPerSample;
    asbd.mFramesPerPacket  = channels;
    asbd.mChannelsPerFrame = channels;
    
    [_rtcAecModule putVoiceTobuffer:(void*)buf size:len];
}


-(void) onCallStopCallback
{
    [self stopRTCView];
    _callstarted = NO;
}

-(void) setWinRect:(CGRect)rect
{
    _winRect = rect;
    [self setupRtcFilter:_curfilter];
}

-(void)setSelfInFront:(BOOL)selfInFront{
    _selfInFront = selfInFront;
    [self setupRtcFilter:_curfilter];
}

- (void)enterbg {
    if(_callstarted)
        [self stopRTCView];
    [self.vPreviewMixer removeAllTargets];
}

-(void)enterFg{
    if(_callstarted)
    {
        NSLog(@"enterfg happen,we start capture");
        [self startRtcView];
    }
    [self setupRtcFilter:_curfilter];
}

-(void)becomeActive
{
    __weak KSYSChatKit * weak_kit = self;
    _rtcClient.videoDataBlock=^(CVPixelBufferRef buf){
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
    _rtcClient.videoDataBlock = nil;
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
- (void) setupRtcFilter:(GPUImageOutput<GPUImageInput> *) filter;
{
    
}
@end
#endif

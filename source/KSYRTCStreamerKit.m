
#import <libksygpulive/KSYGPUPicOutput.h>
#import <libksygpulive/libksygpuimage.h>
#import <libksyrtclivedy/KSYRTCAecModule.h>
#import <libksyrtclivedy/KSYRTCClient.h>
#import <GPUImage/GPUImage.h>
#import "KSYRTCClientKitBase.h"
#import "KSYRTCStreamerKit.h"

#if __arm__  || __arm64__
@interface KSYRTCStreamerKit (){
}

@property KSYGPUPicOutput *     beautyOutput;
@property KSYGPUYUVInput  *     rtcYuvInput;
@property GPUImageUIElement *   uiElementInput;
@property GPUImageMaskFilter *  maskingFilter;

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
    if(self)
    {
        _rtcClient = [[KSYRTCClient alloc] init];
        _beautyOutput = nil;
        _callstarted = NO;
        _firstFrame = NO;
        _curfilter = self.filter;
        _maskPicture = nil;
        _rtcLayer = 4;
        self.aCapDev.micVolume = 1.0;
        
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
        _contentView.backgroundColor = [UIColor clearColor];
        
        __weak KSYRTCClient * weak_client = _rtcClient;
        __weak KSYRTCStreamerKit * weak_kit = self;
        
        _rtcClient.videoDataBlock=^(void** pData,size_t width,size_t height,size_t* strides){
            [weak_kit defaultRtcVideoCallback:pData width:width height:height stride:strides];
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
                weak_kit.callstarted = YES;
            }
            else if(status == 404){
                //远端无法连接，主动调用stopcallback
                [weak_kit OnCallStopCallback];
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
                //对端stop
                [weak_kit OnCallStopCallback];
                if(weak_kit.onCallStop)
                {
                    weak_kit.onCallStop(status);
                }
            }
        };
        
        _rtcClient.onEvent =^(int type,void * detail){
            if(type == 1 || type == 0 || type == 2)
            {
                //网络问题，主动stop
                NSLog(@"network break happen,we will stop the call");
                [weak_client stopCall];
            }
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
    }
    return self;
}

- (void)interruptHandler:(NSNotification *)notification {
    UInt32 interruptionState = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntValue];
    if (interruptionState == kAudioSessionBeginInterruption){
        if(_callstarted){
            [self stopRTCView];
        }
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
    if(self.cropfilter)
    {
        [self.cropfilter removeAllTargets];
        [src addTarget:self.cropfilter];
        src = self.cropfilter;
    }
    
    if(filter)
    {
        [self.filter removeAllTargets];
        [src addTarget:self.filter];
        src = self.filter;
    }
      // 组装图层
    if(_rtcYuvInput)
    {
        [_rtcYuvInput removeAllTargets];
        if(!_selfInFront)//主播
        {
            [self setMixerMasterLayer:self.cameraLayer];
            [self addInput:src ToMixerAt:self.cameraLayer];
            if(_maskPicture){
                [self Maskwith:_rtcYuvInput];
                [self addInput:_maskingFilter ToMixerAt:_rtcLayer Rect:_winRect];
            }else{
                 [self addInput:_rtcYuvInput ToMixerAt:_rtcLayer Rect:_winRect];
            }
        }
        else{//辅播
            [self setMixerMasterLayer:self.rtcLayer];
            [self addInput:_rtcYuvInput  ToMixerAt:self.cameraLayer];
            if(_maskPicture){
                [self Maskwith:src];
                [self addInput:_maskingFilter ToMixerAt:_rtcLayer Rect:_winRect];
            }else{
                [self addInput:src ToMixerAt:_rtcLayer Rect:_winRect];
            }
        }
    }else{
        [self clearMixerLayer:self.rtcLayer];
        [self clearMixerLayer:self.cameraLayer];
        [self setMixerMasterLayer:self.cameraLayer];
        [self addInput:src       ToMixerAt:self.cameraLayer];
    }
    
    //美颜后的图像，用于rtc发送
    if(_beautyOutput)
    {
        [src addTarget:_beautyOutput];
    }
    
    //组装自定义view
    if(_uiElementInput){
        [self addElementInput:_uiElementInput callbackOutput:src];
    }
    else{
        [self removeElementInput:_uiElementInput callbackOutput:src];
    }
    
    // 混合后的图像输出到预览和推流
    [self.vPreviewMixer removeAllTargets];
    [self.vPreviewMixer addTarget:self.preview];
    
    [self.vStreamMixer  removeAllTargets];
    [self.vStreamMixer  addTarget:self.gpuToStr];
    // 设置镜像
    [self setPreviewMirrored:self.previewMirrored];
    [self setStreamerMirrored:self.streamerMirrored];
}

-(void)Maskwith:(GPUImageOutput *)input
{
    [input removeAllTargets];
    [_maskPicture removeAllTargets];
    [_maskingFilter removeAllTargets];
    
    [input addTarget:_maskingFilter];
    [_maskPicture addTarget:_maskingFilter];
}

-(void) addElementInput:(GPUImageUIElement *)input
         callbackOutput:(GPUImageOutput*)callbackOutput
{
    __weak GPUImageUIElement *weakUIEle = self.uiElementInput;
    [callbackOutput setFrameProcessingCompletionBlock:^(GPUImageOutput * f, CMTime fT){
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
    [self addInput:_uiElementInput ToMixerAt:_customViewLayer Rect:_customViewRect];
}

-(void) removeElementInput:(GPUImageUIElement *)input
            callbackOutput:(GPUImageOutput *)callbackOutput
{
    [self clearMixerLayer:_customViewLayer];
    [callbackOutput setFrameProcessingCompletionBlock:nil];
}

-(void) clearMixerLayer:(NSInteger)idx
{
    KSYGPUPicMixer * vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
    for (int i = 0; i<2; ++i) {
        [vMixer[i]  clearPicOfLayer:idx];
    }
}

-(void) setMixerMasterLayer:(NSInteger)idx
{
    KSYGPUPicMixer * vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
    for (int i = 0; i<2; ++i) {
        [vMixer[i]  setMasterLayer:idx];
    }
}

- (void) addInput:(GPUImageOutput*)pic
        ToMixerAt:(NSInteger)idx{
    if (pic == nil){
        return;
    }
    [pic removeAllTargets];
    KSYGPUPicMixer * vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
    for (int i = 0; i<2; ++i) {
        [vMixer[i]  clearPicOfLayer:idx];
        [pic addTarget:vMixer[i] atTextureLocation:idx];
    }
}

- (void) addInput:(GPUImageOutput*)pic
        ToMixerAt:(NSInteger)idx
             Rect:(CGRect)rect{
    
    [self addInput:pic ToMixerAt:idx];
    KSYGPUPicMixer * vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
    for (int i = 0; i<2; ++i) {
        [vMixer[i] setPicRect:rect ofLayer:idx];
        [vMixer[i] setPicAlpha:1.0f ofLayer:idx];
    }
}



#pragma mark -rtc
-(void) defaultOnCallStartCallback
{

}

-(void)startRtcView
{
    //设置视频通道
    __weak KSYRTCStreamerKit * wkit = self;
    _rtcYuvInput =    [[KSYGPUYUVInput alloc] initWithFmt:kCVPixelFormatType_420YpCbCr8Planar];   //对端视频流
    __weak KSYRTCStreamerKit * weak_kit = self;
    _rtcClient.videoDataBlock=^(void** pData,size_t width,size_t height,size_t* strides){
        [weak_kit defaultRtcVideoCallback:pData width:width height:height stride:strides];
    };
    _beautyOutput  =  [[KSYGPUPicOutput alloc] initWithOutFmt:kCVPixelFormatType_420YpCbCr8Planar]; //本端视频流
    _beautyOutput.videoProcessingCallback = ^(CVPixelBufferRef pixelBuffer, CMTime timeInfo ){
        [wkit.rtcClient processVideo:pixelBuffer timeInfo:timeInfo];
    };
    
    _maskingFilter = [[GPUImageMaskFilter alloc] init];
    
    if(_contentView.subviews.count != 0)  //个性化窗口
        _uiElementInput = [[GPUImageUIElement alloc] initWithView:_contentView];
    
    [self setupRtcFilter:_curfilter];
    
    //设置音频通道
    [self.aMixer setTrack:2 enable:YES];
    [self.aMixer setMixVolume:1 of:2];
    self.aCapDev.audioProcessingCallback =^(CMSampleBufferRef buf){
        [wkit.rtcClient processAudio:buf];
        [wkit.aMixer processAudioSampleBuffer:buf of:wkit.micTrack];
    };
    [self.aCapDev startSpeaker];
}

-(void)stopRTCView
{
    //拆除视频通道
    _rtcYuvInput = nil; //对端视频流
    _rtcClient.videoDataBlock = nil;
    _beautyOutput = nil;//本端视频流
    _beautyOutput.videoProcessingCallback = nil;
    _uiElementInput = nil; //个性化小窗口
    _maskingFilter = nil;
    _firstFrame = NO;
    [self setupRtcFilter:_curfilter];
    
    //拆除音频通道
    [self.aMixer setTrack:2 enable:NO];
    __weak KSYRTCStreamerKit * wkit = self;
    self.aCapDev.audioProcessingCallback =^(CMSampleBufferRef buf){
        [wkit.aMixer processAudioSampleBuffer:buf of:wkit.micTrack];
    };
    [self.aCapDev stopSpeaker];
}


-(void) defaultRtcVideoCallback:(void**)  pData
                          width:(size_t)  width
                         height:(size_t)  height
                         stride:(size_t*) strides
{
    [_rtcYuvInput processPixelData:pData format:kCVPixelFormatType_420YpCbCr8Planar width:width height:height stride:strides time:CMTimeMake(2, 10)];

    if(_firstFrame && _maskPicture)
        [_maskPicture processImage];
    
    if(!_firstFrame)
        _firstFrame = YES;

}
-(void) defaultRtcVoiceCallback:(uint8_t*)buf
                            len:(int)len
                            pts:(uint64_t)ptsvalue
                        channel:(uint32_t)channels
                     sampleRate:(uint32_t)sampleRate
                    sampleBytes:(uint32_t)bytesPerSample
{
    if(!_callstarted)
        return;
    
    AudioStreamBasicDescription asbd;
    asbd.mSampleRate       = sampleRate;
    asbd.mFormatID         = kAudioFormatLinearPCM;
    asbd.mFormatFlags      = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    asbd.mBitsPerChannel   = 8 * bytesPerSample;
    asbd.mBytesPerFrame    = bytesPerSample;
    asbd.mBytesPerPacket   = bytesPerSample;
    asbd.mFramesPerPacket  = channels;
    asbd.mChannelsPerFrame = channels;
    
    [self.aCapDev putVoiceTobuffer:(void*)buf size:len];
    CMTime pts;
    pts.value = ptsvalue;
    if([self.streamerBase isStreaming])
    {
        [self.aMixer processAudioData:&buf nbSample:len/bytesPerSample withFormat:&asbd timeinfo:pts of:2];
    }
}


-(void) OnCallStopCallback
{
    [self stopRTCView];
    _callstarted = NO;
}

-(void) setWinRect:(CGRect)rect
{
    _winRect = rect;
    if(_callstarted)
    {
        KSYGPUPicMixer * vMixer[2] = {self.vPreviewMixer, self.vStreamMixer};
        for (int i = 0; i<2; ++i) {
            [vMixer[i]  removeAllTargets];
            [vMixer[i] setPicRect:rect ofLayer:self.rtcLayer];
        }
        [self.vPreviewMixer addTarget:self.preview];
        [self.vStreamMixer  addTarget:self.gpuToStr];
    }
}

-(void)setSelfInFront:(BOOL)selfInFront{
    if(_callstarted)
    {
        [self stopRTCView];
        _selfInFront = selfInFront;
        _curfilter = self.filter;
        [self startRtcView];
    }
}

- (void)enterbg {
    if(_callstarted)
        [self stopRTCView];
}

-(void)enterFg{
    if(_callstarted)
        [self startRtcView];
}

-(void)becomeActive
{
    __weak KSYRTCStreamerKit * weak_kit = self;
    _rtcClient.videoDataBlock=^(void** pData,size_t width,size_t height,size_t* strides){
        [weak_kit defaultRtcVideoCallback:pData width:width height:height stride:strides];
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

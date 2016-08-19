//
//  KSYRTCKitDemoVC.m
//  KSYGPUStreamerDemo
//
//  Created by yiqian on 6/23/16.
//  Copyright © 2016 ksyun. All rights reserved.
//

#import "KSYRTCKitDemoVC.h"
#import <libksyrtclive/KSYRTCStreamerKit.h>
#import <libksyrtclive/KSYRTCStreamer.h>

@interface KSYRTCKitDemoVC () {
    id _filterBtn;
    UILabel* label;
    NSDateFormatter * _dateFormatter;
    int64_t _seconds;
    bool _ismaster;
}

@end

@implementation KSYRTCKitDemoVC



#pragma mark - UIViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    _kit = [[KSYRTCStreamerKit alloc] initWithDefaultCfg];
    // 获取streamerBase, 方便进行推流相关操作, 也可以直接 _kit.streamerBase.xxx
    self.streamerBase = _kit.streamerBase;
    // 采集相关设置初始化
    [self setCaptureCfg];
    //推流相关设置初始化
    [self setStreamerCfg];
    //设置rtc参数
    [self setRtcSteamerCfg];
    // 获取背景音乐播放器
    self.bgmPlayer = _kit.bgmPlayer;
    
    // 打印版本号信息
    NSLog(@"version: %@", [_kit getKSYVersion]);
    [self setupLogo];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.ctrlView.btnQuit setTitle: @"退出kit"
                           forState: UIControlStateNormal];
    [self.ksyMenuView.rtcBtn setHidden:NO];
    if (_kit) {
        // init with default filter
        self.filter =self.ksyFilterView.curFilter;
        [_kit setupFilter:self.ksyFilterView.curFilter];
        [_kit startPreview:self.view];
    }
}

- (void) setCaptureCfg {
    _kit.videoDimension = [self.presetCfgView capResolution];
    KSYVideoDimension strDim = [self.presetCfgView strResolution];
    if(_kit.videoDimension != strDim){
        _kit.bCustomStreamDimension = YES;
        _kit.streamDimension = [self.presetCfgView strResolutionSize ];
    }
    _kit.videoFPS       = [self.presetCfgView frameRate];
    _kit.cameraPosition = [self.presetCfgView cameraPos];
    _kit.bInterruptOtherAudio = NO;
    _kit.bDefaultToSpeaker    = YES; // 没有耳机的话音乐播放从扬声器播放
    _kit.videoProcessingCallback = ^(CMSampleBufferRef buf){
    };
    _kit.audioProcessingCallback = ^(CMSampleBufferRef buf){
    };
}
- (void) setupLogo{
    NSString *logoFile=[NSHomeDirectory() stringByAppendingString:@"/Documents/ksvc.png"];
    UIImage *logoImg=[[UIImage alloc]initWithContentsOfFile:logoFile];
    CGRect rect = CGRectMake(10, 10, 80, 80);
    [_kit addLogo:logoImg toRect:rect trans:0.5];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0,100, 500, 100)];
    label.textColor = [UIColor whiteColor];
    //label.font = [UIFont systemFontOfSize:17.0]; // 非等宽字体, 可能导致闪烁
    label.font = [UIFont fontWithName:@"Courier-Bold" size:20.0];
    label.backgroundColor = [UIColor clearColor];
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.dateFormat = @"MM-dd HH:mm:ss";
    NSDate *now = [[NSDate alloc] init];
    label.text = [_dateFormatter stringFromDate:now];
    rect.origin.y += (rect.size.height+5);
    [_kit addTextLabel:label toPos:rect.origin];
}

#pragma mark -  state change
- (void)onTimer:(NSTimer *)theTimer{
    [super onTimer:theTimer];
    _seconds++;
    if (_seconds%5){ // update label every 5 second
        NSDate *now = [[NSDate alloc] init];
        label.text = [_dateFormatter stringFromDate:now];
        [_kit updateTextLable:label];
    }
}

- (void) onCaptureStateChange:(NSNotification *)notification{
    NSLog(@"new capStat: %@", _kit.getCurCaptureStateName );
    self.ctrlView.lblStat.text = [_kit getCurCaptureStateName];
    if (_kit.captureState == KSYCaptureStateCapturing){
        self.capDev = _kit.capDev;
    }
    else {
        self.capDev = nil;
    }
}

- (void) onPipPlayerNotify:(NSNotification *)notification{
    if (MPMediaPlaybackIsPreparedToPlayDidChangeNotification == notification.name) {
        [_kit.player play]; // 准备好后开始播放
    }
    if (MPMoviePlayerPlaybackDidFinishNotification == notification.name) {
        [_kit.player stop]; // 播放完成
    }
}

- (void) onFlash {
    [_kit toggleTorch];
}

- (void) onCameraToggle{
    [_kit switchCamera];
    [super onCameraToggle];
}

- (void) onCapture{
    if (!_kit.capDev.isRunning){
        [_kit startPreview:self.view];
    }
    else {
        [_kit stopPreview];
    }
}
- (void) onStream{
    if (_kit.streamerBase.streamState == KSYStreamStateIdle ||
        _kit.streamerBase.streamState == KSYStreamStateError) {
        _kit.streamerBase.bWithVideo = !self.miscView.swiAudio.on;
        [_kit.streamerBase startStream:self.hostURL];
        self.streamerBase = _kit.streamerBase;
        _seconds = 0;
    }
    else {
        [_kit.streamerBase stopStream];
        self.streamerBase = nil;
    }
}


- (void) onQuit{  // quit current demo
    [_kit.streamerBase stopStream];
    self.streamerBase = nil;
    if (_kit.player){
        [self onPipStop];
    }
    [_kit stopPreview];
    if(_kit.rtcSteamer)
    {
        [_kit.rtcSteamer stopCall];
        [_kit.rtcSteamer unRegisterRTC];
        _kit.rtcSteamer = nil;
    }
    _kit = nil;
    [super onQuit];
}

- (void) onFilterChange:(id)sender{
    if (self.ksyFilterView.curFilter != _kit.filter){
        // use a new filter
        self.filter = self.ksyFilterView.curFilter;
        [_kit setupFilter:self.ksyFilterView.curFilter];
    }
}

// volume change
- (void)onAMixerSlider:(KSYNameSlider *)slider {
    float val = 0.0;
    if ([slider isKindOfClass:[KSYNameSlider class]]) {
        val = slider.normalValue;
    }
    else {
        return;
    }
    if ( slider == self.audioMixerView.bgmVol){
        [_kit.audioMixer setMixVolume:val of: _kit.bgmTrack];
    }
    else if ( slider == self.audioMixerView.micVol){
        [_kit.audioMixer setMixVolume:val of: _kit.micTrack];
    }
    else if ( slider == self.audioMixerView.pipVol){
        [_kit.audioMixer setMixVolume:val of: _kit.pipTrack];
    }
}
#pragma mark - pip ctrl
// pip start
- (void)onPipPlay{
    [_kit startPipWithPlayerUrl:self.ksyPipView.pipURL
                          bgPic:self.ksyPipView.bgpURL
                        capRect:CGRectMake(0.6, 0.6, 0.3, 0.3)];
    
}
- (void)onPipStop{
    [_kit stopPip];
}
- (void)onPipNext{
    if (_kit.player){
        [_kit stopPip];
        [self onPipPlay];
    }
}

- (void)onPipPause{
    if (_kit.player && _kit.player.playbackState == MPMoviePlaybackStatePlaying) {
        [_kit.player pause];
    }
    else if (_kit.player && _kit.player.playbackState == MPMoviePlaybackStatePaused){
        [_kit.player play];
    }
}

- (void)onBgpNext{
    if ( _kit.player ){
        [_kit startPipWithPlayerUrl:nil
                              bgPic:self.ksyPipView.bgpURL
                            capRect:CGRectMake(0.6, 0.6, 0.3, 0.3)];
    }
}

- (void)pipVolChange:(id)sender{
    if (_kit.player && sender == self.ksyPipView.volumSl) {
        float vol = self.ksyPipView.volumSl.normalValue;
        [_kit.player setVolume:vol rigthVolume:vol];
    }
}

#pragma mark - micMonitor
// 是否开启耳返
- (void)onMiscSwitch:(UISwitch *)sw{
    if (sw == self.miscView.micmMix){
        if ( [KSYMicMonitor isHeadsetPluggedIn] == NO ){
            return;
        }
        if (sw.isOn){
            [_kit.micMonitor start];
        }
        else{
            [_kit.micMonitor stop];
        }
    }
    [super onMiscSwitch:sw];
}

// 调节耳返音量
- (void)onMiscSlider:(KSYNameSlider *)slider {
    if (slider == self.miscView.micmVol){
        [_kit.micMonitor setVolume:slider.normalValue];
    }
}

#pragma mark - UIViewController
- (void) setRtcSteamerCfg {
    //设置ak/sk鉴权信息,本demo从testAppServer取，客户请从自己的appserver获取。
    _kit.rtcSteamer.authString = nil;
    //设置域名查询domain，内部使用
    _kit.rtcSteamer.queryDomainString = @"http://rtc.vcloud.ks-live.com:6000/querydomain";
    //设定公司后缀
    _kit.rtcSteamer.uniqName = @"apptest";
    //设置音频采样率
    _kit.rtcSteamer.sampleRate = 44100;
    //设置视频帧率
    _kit.rtcSteamer.videoFPS = 15;
    //是否打开rtc的日志
    _kit.rtcSteamer.openRtcLog = YES;
    //设置对端视频的宽高
    _kit.rtcSteamer.scaledWidth = 240;
    _kit.rtcSteamer.scaledHeight = 320;
    //设置rtc传输的码率
    _kit.rtcSteamer.AvgBps = 256000;
    _kit.rtcSteamer.MaxBps = 256000;
    //设置信令传输模式,tls为推荐
    _kit.rtcSteamer.rtcMode = 1;
    
    __weak KSYRTCKitDemoVC *weak_demo = self;
    __weak KSYRTCStreamerKit *weak_kit = _kit;
    _kit.rtcSteamer.onRegister= ^(int status){
        [weak_demo statEvent:@"register callback" result:status];
    };
    _kit.rtcSteamer.onUnRegister= ^(int status){
        [weak_demo statEvent:@"unregister callback" result:status];
        NSLog(@"unregister callback");
    };
    _kit.rtcSteamer.onCallStop =^(int status){
        if(status == 200)
        {
            [weak_kit defaultOnCallStopCallback];
            [weak_demo statEvent:@"onCallStop callback" result:status];
            NSLog(@"onCallStop happen,status:%d",status);
        }
    };
    _kit.rtcSteamer.onCallInComing =^(char* remoteURI){
        NSString *text = [NSString stringWithFormat:@"有呼叫到来,id:%s",remoteURI];
        [weak_demo statEvent:text result:0];
    };
    _ismaster = NO;
}


-(void)statEvent:(NSString *)event
          result:(int)ret
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.ctrlView.lblStat.text.length > 100)
            self.ctrlView.lblStat.text= @"";
        NSString *text = [NSString stringWithFormat:@"\n%@, ret:%d",event,ret];
        self.ctrlView.lblStat.text = [ self.ctrlView.lblStat.text  stringByAppendingString:text  ];
        
    });
}
-(void)statString:(NSString *)event
{
    if(self.ctrlView.lblStat.text.length > 100)
        self.ctrlView.lblStat.text= @"";
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *text = [NSString stringWithFormat:@"\n%@",event];
        self.ctrlView.lblStat.text = [ self.ctrlView.lblStat.text  stringByAppendingString:text  ];
    });
}


-(void)onMasterChoosed:(BOOL)isMaster{
    __weak KSYRTCKitDemoVC *weak_demo = self;
    __weak KSYRTCStreamerKit *weak_kit = _kit;
    
    _ismaster = isMaster;
    if(isMaster)
    {
        [self statEvent:@"主播" result:0];
        
        //主播小窗口看到的是对端
        _kit.rtcSteamer.onCallStart =^(int status){
            if(status == 200)
            {
            [weak_kit defaultOnCallStartCallback:CGRectMake(0.6, 0.6, 0.3, 0.3)
                                     selfinfront:NO];
            [weak_demo statEvent:@"建立连接," result:status];
            }
            else if(status == 408){
              //[weak_kit defaultOnCallStopCallback];
              [weak_demo statEvent:@"对方无应答," result:status];
            }
            else if(status == 404){
            [weak_kit defaultOnCallStopCallback];
            [weak_demo statEvent:@"呼叫未注册号码,主动停止" result:status];
            }
            NSLog(@"onCallStart status:%d",status);
        };
    }
    else{
        [self statEvent:@"辅播" result:0];
        
        //辅播小窗口看到的是自己
        _kit.rtcSteamer.onCallStart =^(int status){
            if(status == 200)
            {
                [weak_kit defaultOnCallStartCallback:CGRectMake(0.6, 0.6, 0.3, 0.3)
                                         selfinfront:YES];
            }
            else if(status == 408){
                //[weak_kit defaultOnCallStopCallback];
                [weak_demo statEvent:@"对方无应答," result:status];
            }
            else if(status == 404){
                [weak_kit defaultOnCallStopCallback];
                [weak_demo statEvent:@"呼叫未注册号码,主动停止" result:status];
            }

            [weak_demo statEvent:@"onCallStart callback" result:status];
            NSLog(@"onCallStart status:%d",status);

        };
    }
}

- (void)onRtcRegister:(NSString *)localid
{
    _kit.rtcSteamer.localId = localid;
    
    if(!_kit.rtcSteamer.authString)
    {
      //获取鉴权串，demo里为testAppServer，请改用自己的appserver
      NSString * TestASString = [NSString stringWithFormat:@"http://120.132.89.26:6001/rtcauth?uid=%@",localid];
      _kit.rtcSteamer.authString=[NSString stringWithFormat:@"http://rtc.vcloud.ks-live.com:6000/auth?%@",
        [self AuthFromTestAS:TestASString]];
    }
    
    [_kit.rtcSteamer registerRTC];
}

- (void)onRtcStartCall:(NSString *)remoteid{
    
    int ret = [_kit.rtcSteamer startCall:remoteid];
    
    NSString * event = [NSString stringWithFormat:@"发起呼叫,remote_id:%@",remoteid];
    [self statEvent:event result:ret];
}
- (void)onRtcAnswerCall{
    int ret = [_kit.rtcSteamer answerCall];
    [self statEvent:@"应答" result:ret];
}
- (void)onRtcUnregister{
    int ret = [_kit.rtcSteamer unRegisterRTC];
    
    [self statEvent:@"unregister" result:ret];
}

- (void)onRtcRejectCall{
    int ret = [_kit.rtcSteamer rejectCall];
    [self statEvent:@"reject" result:ret];
}
- (void)onRtcStopCall{
    int ret = [_kit.rtcSteamer stopCall];
    [self statEvent:@"stopcall" result:ret];
   }
- (void)onRtcAdjustWindow{
    CGRect old_rect = _kit.winRect;
    CGRect new_rect = old_rect;
    if(new_rect.origin.x >0.1)
        new_rect.origin.x -= 0.1;
    else
        new_rect.origin.x += 0.1;
    _kit.winRect = new_rect;
}

-(NSString *)AuthFromTestAS:(NSString *)ServerIp
{
    NSURLResponse *response = nil;
    NSError *error = nil;
    //http请求消息
    NSURL *requestURL = [NSURL URLWithString:ServerIp];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestURL];
    //发送同步请求
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    //处理http响应消息
    if(error)
    {
        NSLog(@"testAppServer fail, error = %@", error);
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

@end

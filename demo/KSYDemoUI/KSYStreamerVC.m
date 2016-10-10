//
//  ViewController.m
//  KSYStreamerVC
//
//  Created by yiqian on 10/15/15.
//  Copyright (c) 2015 ksyun. All rights reserved.
//

//#import <KSYGPUStreamer/KSYGPUStreamerFramework.h>
#import "KSYUIView.h"
#import "KSYUIVC.h"
#import "KSYPresetCfgView.h"
#import "KSYStreamerVC.h"
#import <GPUImage/GPUImage.h>
#import "KSYFilterView.h"
#import "KSYNameSlider.h"

@interface KSYStreamerVC () {
    StreamState _lastStD;
    double      _startTime;
    int         _notGoodCnt;
    int         _raiseCnt;
    int         _dropCnt;
    
    UISwipeGestureRecognizer *_swipeGest;
}

@end
@implementation KSYStreamerVC

- (id) initWithCfg:(KSYPresetCfgView*)presetCfgView{
    self = [super init];
    _presetCfgView = presetCfgView;
    self.view.backgroundColor = [UIColor whiteColor];
    _lastState = &_lastStD;
    [self initStreamStat];
    return self;
}
// 将推流状态信息清0
- (void) initStreamStat{
    memset(_lastState, 0, sizeof(_lastStD));
    _startTime  = [[NSDate date]timeIntervalSince1970];
    _notGoodCnt = 0;
    _raiseCnt   = 0;
    _dropCnt    = 0;
    
}

#pragma mark - UIViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [self addSubViews];
    [self addSwipeGesture];
}

- (void) addSwipeGesture{
    SEL onSwip =@selector(swipeController:);
    _swipeGest = [[UISwipeGestureRecognizer alloc]initWithTarget:self
                                                          action:onSwip];
    _swipeGest.direction |= UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:_swipeGest];
}

- (void)addSubViews{
    [self initCtrView];
    _ksyMenuView    = [[KSYMenuView alloc]initWithParent:_ctrlView];
    _ksyMenuView.hidden = NO; // menu
    _ksyFilterView  = [[KSYFilterView alloc]initWithParent:_ksyMenuView];
    _rtcView        = [[KSYRtcView alloc]initWithParent:_ksyMenuView];
    _rtcSlaveView   = [[KSYRtcSlaveView alloc]initWithParent:_rtcView];
    _rtcMasterView = [[KSYRtcMasterView alloc]initWithParent:_rtcView];
    
    __weak KSYStreamerVC *weakself = self;
    _ksyMenuView.onBtnBlock=^(id sender){
        [weakself onMenuBtnPress:sender];
    };
    // 滤镜相关参数改变
    _ksyFilterView.onSegCtrlBlock=^(id sender) {
        [weakself onFilterChange:sender];
    };
    _rtcMasterView.onBtnBlock = ^(id sender){
        [weakself onRtcMasterBtn:sender];
    };
    _rtcSlaveView.onBtnBlock = ^(id sender){
        [weakself onRtcSlaveBtn:sender];
    };
    _rtcView.onBtnBlock= ^(id sender){
        [weakself onRtcBtnPress:sender];
    };
}

- (void)initCtrView{
    _ctrlView  = [[KSYCtrlView alloc] init];
    [self.view addSubview:_ctrlView];
    _ctrlView.frame = self.view.frame;
    if ([_presetCfgView cameraPos] == AVCaptureDevicePositionFront) {
        [_ctrlView.btnFlash setEnabled:NO];
    }
    // connect UI
    __weak KSYStreamerVC * vc = self;
    _ctrlView.onBtnBlock = ^(id btn){
        [vc onBasicCtrl:btn];
    };
}


- (void) addObservers {
    [super addObservers];
    //KSYStreamer state changes
    NSNotificationCenter* dc = [NSNotificationCenter defaultCenter];
    [dc addObserver:self
           selector:@selector(onStreamStateChange:)
               name:KSYStreamStateDidChangeNotification
             object:nil];
    [dc addObserver:self
           selector:@selector(onNetStateEvent:)
               name:KSYNetStateEventNotification
             object:nil];
}
- (void) rmObservers {
    [super rmObservers];
    NSNotificationCenter* dc = [NSNotificationCenter defaultCenter];
    [dc removeObserver:self
                  name:KSYStreamStateDidChangeNotification
                object:nil];
    [dc removeObserver:self
                  name:KSYNetStateEventNotification
                object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [self layoutUI];
    [UIApplication sharedApplication].idleTimerDisabled=YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [UIApplication sharedApplication].idleTimerDisabled=NO;
}

- (BOOL)shouldAutorotate {
    [self layoutUI];
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - add UIs to view
- (void) initUI {
    [self layoutUI];
}

- (void) layoutUI {
    if(_ctrlView){
        [_ctrlView layoutUI];
        _ctrlView.yPos   = _ksyMenuView.gap*6+_ksyMenuView.btnH;
        _ctrlView.btnH   = _ctrlView.height-_ctrlView.yPos-_ksyMenuView.btnH;
        [_ctrlView putRow1:_ksyMenuView];
        [_ksyMenuView    layoutUI];
    }
}

#pragma mark - Capture & stream setup
- (void) setCaptureCfg { // see blk/kit
    [_presetCfgView capResolution];
    [_presetCfgView cameraPos];
    [_presetCfgView frameRate];
}
- (void) defaultStramCfg{
    // stream default settings
    _streamerBase.videoCodec = KSYVideoCodec_AUTO;
    _streamerBase.videoInitBitrate =  800;
    _streamerBase.videoMaxBitrate  = 1000;
    _streamerBase.videoMinBitrate  =    0;
    _streamerBase.audiokBPS        =   48;
    _streamerBase.enAutoApplyEstimateBW     = YES;
    _streamerBase.shouldEnableKSYStatModule = YES;
    _streamerBase.videoFPS = 15;
    _streamerBase.logBlock = ^(NSString* str){
        NSLog(@"%@", str);
    };
    _hostURL = [NSURL URLWithString:@"rtmp://test.uplive.ksyun.com/live/123"];
}
- (void) setStreamerCfg { // must set after capture
    if (_streamerBase == nil) {
        return;
    }
    if (_presetCfgView){ // cfg from presetcfgview
        _streamerBase.videoCodec       = [_presetCfgView videoCodec];
        _streamerBase.videoInitBitrate = [_presetCfgView videoKbps]*6/10;//60%
        _streamerBase.videoMaxBitrate  = [_presetCfgView videoKbps];
        _streamerBase.videoMinBitrate  = 0; //
        _streamerBase.audiokBPS        = [_presetCfgView audioKbps];
        _streamerBase.videoFPS         = [_presetCfgView frameRate];
        _streamerBase.enAutoApplyEstimateBW = YES;
        _streamerBase.shouldEnableKSYStatModule = YES;
        _streamerBase.logBlock = ^(NSString* str){ };
        _hostURL = [NSURL URLWithString:[_presetCfgView hostUrl]];
    }
    else {
        [self defaultStramCfg];
    }
}

#pragma mark -  state change
- (void) onCaptureStateChange:(NSNotification *)notification{
}
- (void) onNetStateEvent     :(NSNotification *)notification{
    switch (_streamerBase.netStateCode) {
        case KSYNetStateCode_SEND_PACKET_SLOW: {
            NSLog(@"send slow");
            break;
        }
        case KSYNetStateCode_EST_BW_RAISE: {
            NSLog(@"est bw raise");
            break;
        }
        case KSYNetStateCode_EST_BW_DROP: {
            NSLog(@"est bw drop");
            break;
        }
        case KSYNetStateCode_IN_AUDIO_DISCONTINUOUS: {
            NSLog(@"missing audio data");
            break;
        }
        default:break;
    }
}

- (void) onStreamStateChange :(NSNotification *)notification{
    if (_streamerBase){
        NSLog(@"stream State %@", [_streamerBase getCurStreamStateName]);
    }
    _ctrlView.lblStat.text = [_streamerBase getCurStreamStateName];
    if(_streamerBase.streamState == KSYStreamStateError) {
        [self onStreamError:_streamerBase.streamErrorCode];
    }
    else if (_streamerBase.streamState == KSYStreamStateConnecting) {
        [self initStreamStat]; // 尝试开始连接时,重置统计数据
    }
}

- (void) onStreamError:(KSYStreamErrorCode) errCode{
    _ctrlView.lblStat.text  = [_streamerBase getCurKSYStreamErrorCodeName];
    if (errCode == KSYStreamErrorCode_CONNECT_BREAK) {
        // Reconnect
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC));
        dispatch_after(delay, dispatch_get_main_queue(), ^{
            _streamerBase.bWithVideo = YES;
            [_streamerBase startStream:self.hostURL];
        });
    }
}

#pragma mark - UI respond
//ctrView control (for basic ctrl)
- (void) onBasicCtrl: (id) btn {
    if (btn == _ctrlView.btnFlash){
        [self onFlash];
    }
    else if (btn == _ctrlView.btnCameraToggle){
        [self onCameraToggle];
    }
    else if (btn == _ctrlView.btnQuit){
        [self onQuit];
    }
    else if(btn == _ctrlView.btnCapture){
        [self onCapture];
    }
    else if(btn == _ctrlView.btnStream){
        [self onStream];
    }
}

//menuView control
- (void)onMenuBtnPress:(UIButton *)btn{
    KSYUIView * view = nil;
    if (btn == _ksyMenuView.filterBtn ){
        view = _ksyFilterView; // 美颜滤镜相关
    }
    else if (btn == _ksyMenuView.rtcBtn){
        view = _rtcView;
    }
    
    // 将菜单的按钮隐藏, 将触发二级菜单的view显示
    if (view){
        [_ksyMenuView hideAllBtn:YES];
        view.hidden = NO;
        view.frame = _ksyMenuView.frame;
        [view     layoutUI];
    }
}


- (void)swipeController:(UISwipeGestureRecognizer *)swipGestRec{
    if (swipGestRec == _swipeGest){
        CGRect rect = self.view.frame;
        if ( CGRectEqualToRect(rect, _ctrlView.frame)){
            rect.origin.x = rect.size.width; // hide
        }
        [UIView animateWithDuration:0.1 animations:^{
            _ctrlView.frame = rect;
        }];
    }
}
- (void)onRtcBtnPress:(UIButton *)btn{
    KSYUIView * view = nil;
    if (btn == _rtcView.masterBtn)
    {
        view =_rtcMasterView;
        if(_rtcSlaveView)
            _rtcSlaveView.hidden = YES;
        [self onMasterChoosed:YES];
    }
    else if (btn == _rtcView.slaveBtn)
    {
        view = _rtcSlaveView;
        if(_rtcMasterView)
            _rtcMasterView.hidden = YES;
        [self onMasterChoosed:NO];
    }
    
    if (view){
        [_ksyMenuView hideAllBtn:YES];
        view.hidden = NO;
        view.frame = _ksyMenuView.frame;
        [view     layoutUI];
    }
}

#pragma mark - subviews: basic ctrl
- (void) onFlash { //  see kit or block
}
- (void) onCameraToggle{ // see kit or block
//    if (_capDev && _capDev.cameraPosition == AVCaptureDevicePositionBack) {
//        [_ctrlView.btnFlash setEnabled:YES];
//    }
//    else{
//        [_ctrlView.btnFlash setEnabled:NO];
//    }
}
- (void) onCapture{ // see kit or block
}
- (void) onStream{ // see kit or block
}
- (void) onQuit{  // quit current demo
    if (self.streamerBase){
        [self.streamerBase stopStream];
        self.streamerBase = nil;
    }
    [self rmObservers];
    [self dismissViewControllerAnimated:FALSE completion:nil];
}

#pragma mark - UI respond : gpu filters
- (void) onFilterChange:(id)sender{ // see kit or block
}

#pragma mark - rtc
- (void)onRtcMasterBtn:(id)sender{
    if (sender == _rtcMasterView.registerBtn) {
        NSString * localId = _rtcMasterView.localid.text;
        [self onRtcRegister:localId];
    }
    else if (sender == _rtcMasterView.startCallBtn){
        NSString * remoteId = _rtcMasterView.remoteid.text;
        [self onRtcStartCall:remoteId];
    }
    else if (sender == _rtcMasterView.answerCallBtn){
        [self onRtcAnswerCall];
    }
    else if (sender == _rtcMasterView.unregisterBtn){
        [self onRtcUnregister];
    }
    else if (sender == _rtcMasterView.stopCallBtn){
        [self onRtcStopCall];
    }
    else if(sender == _rtcMasterView.rejectCallBtn){
        [self onRtcRejectCall];
    }
    else if (sender == _rtcMasterView.uninitBtn){
        [self onRtcunInitCall];
    }
}

- (void)onRtcSlaveBtn:(id)sender{
    if (sender == _rtcSlaveView.registerBtn) {
        NSString * localId = _rtcSlaveView.localid.text;
        [self onRtcRegister:localId];
    }
    else if (sender == _rtcSlaveView.startCallBtn){
        NSString * remoteId = _rtcSlaveView.remoteid.text;
        [self onRtcStartCall:remoteId];
    }
    else if (sender == _rtcSlaveView.answerCallBtn){
        [self onRtcAnswerCall];
    }
    else if (sender == _rtcSlaveView.unregisterBtn){
        [self onRtcUnregister];
    }
    else if (sender == _rtcSlaveView.stopCallBtn){
        [self onRtcStopCall];
    }
    else if(sender == _rtcSlaveView.rejectCallBtn){
        [self onRtcRejectCall];
    }
    else if (sender == _rtcSlaveView.uninitBtn){
        [self onRtcunInitCall];
    }
}

-(void)onMasterChoosed:(BOOL)isMaster{// see kit & block
}
- (void)onRtcRegister:(NSString *)localid{// see kit & block
}
- (void)onRtcStartCall:(NSString *)remoteid{ // see kit & block
}
- (void)onRtcAnswerCall{ // see kit & block
}
- (void)onRtcUnregister{ // see kit & block
}
- (void)onRtcStopCall{ // see kit & block
}
- (void)onRtcunInitCall{ // see kit & block
}
- (void)onRtcRejectCall{ // see kit & block
}
-(void) onSwitchRtcView:(CGPoint)location{// see kit & block
}

- (void)keyboardWillShow:(NSNotification *)not{
    [_ksyMenuView hideAllBtn:YES];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [_rtcMasterView.localid resignFirstResponder];
    [_rtcMasterView.remoteid resignFirstResponder];
    [_rtcSlaveView.localid resignFirstResponder];
    [_rtcSlaveView.remoteid resignFirstResponder];
    
    CGPoint origin = [[touches anyObject] locationInView:self.view];
    CGPoint location;
    location.x = origin.x/self.view.frame.size.width;
    location.y = origin.y/self.view.frame.size.height;
    [self onSwitchRtcView:location];
}
@end

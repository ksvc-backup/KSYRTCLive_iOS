//
//  KSYRTCKitDemoVC.m
//  KSYGPUStreamerDemo
//
//  Created by yiqian on 6/23/16.
//  Copyright © 2016 ksyun. All rights reserved.
//
#import <libksyrtclivedy/KSYRTCClient.h>
#import <libksygpulive/libksygpuimage.h>
#import "KSYRTCClientKitBase.h"
#import "KSYStreamerVC.h"
#import "KSYSChatDemoVC.h"
#import "KSYRTCStreamerKit.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>

#define BUTTON_WIDTH        40
#define BUTTON_HEIGHT       30

#define LABEL_WIDTH       60

#define LEFT_MARGIN_X         10
#define LEFT_MARGIN_Y         30

@interface KSYSChatDemoVC ()<UITextFieldDelegate>
{
    UIView * _ctrlView;
    UILabel* _localIdLabel;
    UITextField* _localId;
    UIButton * _registerBtn;
    
    UITextField* _remoteId;
    UIButton * _startCallBtn;
    UIButton * _stopCallBtn;
    
    UILabel* _stat;
    
    UIButton * _filterBtn;
    UIButton * _cameraChangeBtn;
    UIButton * _closeBtn;
    UIAlertController * _callComingAlertController;
    
    GPUImageOutput<GPUImageInput>* _curFilter;

    UIPanGestureRecognizer *panGestureRecognizer;
    UIView* _winRtcView;
    
    UISwipeGestureRecognizer *_swipeGest;
}

@property bool beQuit;

@end

@implementation KSYSChatDemoVC

#pragma mark - UIViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    //UI初始化
    [self initUI];
    
    _kit = [[KSYRTCStreamerKit alloc] initWithDefaultCfg];
    // 采集相关设置初始化
    [self setCaptureCfg];
    //设置rtc参数
    [self setRtcSteamerCfg];
    
    [self addSwipeGesture];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_kit startPreview:self.view];
    [UIApplication sharedApplication].idleTimerDisabled=YES;
}
- (void)viewWillDisappear:(BOOL)animated {
    [UIApplication sharedApplication].idleTimerDisabled=NO;
}

- (void) setCaptureCfg {
    _kit.capPreset = AVCaptureSessionPreset1280x720;
    _kit.videoFPS = 15;
    _kit.cameraPosition = AVCaptureDevicePositionFront;
    _kit.previewDimension = CGSizeMake(720, 1280);
    _curFilter = [[KSYGPUBeautifyExtFilter alloc]init];
    [_kit setupFilter:_curFilter];
    _kit.curfilter = _curFilter;
    _kit.videoProcessingCallback = ^(CMSampleBufferRef buf){
    };
}

#pragma mark -  UI
- (void) addSwipeGesture{
    _swipeGest = [[UISwipeGestureRecognizer alloc]initWithTarget:self
                                                          action:@selector(swipeController:)];
    _swipeGest.direction |= UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:_swipeGest];
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

-(void)initUI
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    //ctrlview
    _ctrlView = [[UIView alloc]init];
    _ctrlView.frame = self.view.frame;
    _ctrlView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_ctrlView];
    //localId
    _localIdLabel = [self addLable:@"本地ID:"];
    _localIdLabel.frame = CGRectMake(LEFT_MARGIN_X, LEFT_MARGIN_Y, LABEL_WIDTH, BUTTON_HEIGHT);
    
    _localId = [self addUITextField:@"666"];
    _localId.frame = CGRectMake(_localIdLabel.frame.origin.x+_localIdLabel.frame.size.width+1, LEFT_MARGIN_Y, LABEL_WIDTH, BUTTON_HEIGHT);
    
    _registerBtn = [self addButton:@"注册"];
    _registerBtn.frame = CGRectMake(_localId.frame.origin.x+_localId.frame.size.width+1,LEFT_MARGIN_Y,BUTTON_WIDTH,BUTTON_HEIGHT);
    
    //stat
    _stat = [self addLable:@""];
    _stat.frame = CGRectMake(10, 300, 400, 100);
    _stat.backgroundColor = [UIColor clearColor];
    _stat.textColor = [UIColor redColor];
    _stat.numberOfLines = 12;
    _stat.textAlignment = NSTextAlignmentLeft;
    
    //remoteid
    _remoteId = [self addUITextField:@"888"];
    _remoteId.frame = CGRectMake(LEFT_MARGIN_X, self.view.bounds.size.height- LEFT_MARGIN_Y, LABEL_WIDTH, BUTTON_HEIGHT);
    
    _startCallBtn = [self addButton:@"呼叫"];
    _startCallBtn.frame = CGRectMake(_remoteId.frame.origin.x+_remoteId.frame.size.width+1,self.view.bounds.size.height- LEFT_MARGIN_Y,BUTTON_WIDTH,BUTTON_HEIGHT);
    
    _stopCallBtn =[self addButton:@"停止"];
    _stopCallBtn.frame = CGRectMake(_startCallBtn.frame.origin.x+_startCallBtn.frame.size.width+5,self.view.bounds.size.height- LEFT_MARGIN_Y,BUTTON_WIDTH,BUTTON_HEIGHT);
    
    _filterBtn = [self addButton:@""];
    [_filterBtn setImage:[UIImage imageNamed:@"icon_beautifulface_19x19"] forState:UIControlStateNormal];
    _filterBtn.frame =CGRectMake(self.view.bounds.size.width - 120,self.view.bounds.size.height- 40,40,40);

    _cameraChangeBtn = [self addButton:@""];
    [_cameraChangeBtn setImage:[UIImage imageNamed:@"camera_change_40x40"] forState:UIControlStateNormal];
    _cameraChangeBtn.frame = CGRectMake(self.view.bounds.size.width - 80,self.view.bounds.size.height- 40,40,40);
    
    _closeBtn = [self addButton:@""];
    [_closeBtn setImage:[UIImage imageNamed:@"talk_close_40x40"] forState:UIControlStateNormal];
    _closeBtn.frame = CGRectMake(self.view.bounds.size.width - 40,self.view.bounds.size.height- 40,40,40);

}

- (UIButton *)addButton:(NSString*)title{
    UIButton * button;
    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle: title forState: UIControlStateNormal];
    button.backgroundColor = [UIColor clearColor];
    button.titleLabel.font    = [UIFont systemFontOfSize:18];
    button.alpha = 1.0f;
    button.layer.cornerRadius = 0.5;
    [_ctrlView addSubview:button];
    
    [button addTarget:self
               action:@selector(onBtn:)
     forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UITextField *)addUITextField:(NSString*)title{
    UITextField * textField;
    textField = [[UITextField alloc] init];
    textField.text = title;
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.backgroundColor = [UIColor clearColor];
    textField.delegate = self;
    [_ctrlView addSubview:textField];
    return textField;
}

- (UILabel *)addLable:(NSString*)title{
    UILabel *  lbl = [[UILabel alloc] init];
    lbl.text = title;
    lbl.textColor = [UIColor grayColor];
    [_ctrlView addSubview:lbl];
    return lbl;
}

- (IBAction)onBtn:(id)sender {
    if(sender == _registerBtn){
        [self onRtcRegister:_localId.text];
    }
    else if(sender == _startCallBtn){
        [self onRtcStartCall:_remoteId.text];
    }
    else if(sender == _stopCallBtn){
        [self onRtcStopCall];
    }
    else if(sender == _filterBtn){
        if(!_curFilter)
            _curFilter = [[KSYGPUBeautifyExtFilter alloc]init];
        else
            _curFilter = nil;
        [_kit setupRtcFilter:_curFilter];
        
    }
    else if(sender == _cameraChangeBtn){
        [_kit switchCamera];
    }
    else if(sender == _closeBtn){
        if(_kit.callstarted)
        {
            [_kit.rtcClient stopCall];
            _beQuit = YES;
        }
        else
        {
            [_kit.rtcClient unRegisterRTC];
            _kit = nil;
            [self dismissViewControllerAnimated:FALSE completion:nil];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    if(textField == _localId)
        [_localId resignFirstResponder];
    else if(textField == _remoteId)
        [_remoteId resignFirstResponder];
    return YES;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [_localId resignFirstResponder];
    [_remoteId resignFirstResponder];
    
    CGPoint origin = [[touches anyObject] locationInView:self.view];
    CGPoint location;
    location.x = origin.x/self.view.frame.size.width;
    location.y = origin.y/self.view.frame.size.height;
    [self onSwitchRtcView:location];
}
#pragma mark - rtc
- (void) setRtcSteamerCfg {
    //设置鉴权信息
    _kit.rtcClient.authString = nil;//设置ak/sk鉴权信息,本demo从testAppServer取，客户请从自己的appserver获取。
    //设置音频属性
    _kit.rtcClient.sampleRate = 44100;//设置音频采样率，暂时不支持调节
    //设置视频属性
    _kit.rtcClient.videoFPS = 24; //设置视频帧率
    _kit.rtcClient.videoWidth = 720;//设置视频的宽高，和当前分辨率相关,注意一定要保持16:9
    _kit.rtcClient.videoHeight = 1280;
    _kit.rtcClient.MaxBps = 0;//设置rtc传输的最大码率,如果推流卡顿，可以设置该参数,0为自适应
    //设置小窗口属性
    _kit.winRect = CGRectMake(0.6, 0.6, 0.3, 0.3);//设置小窗口属性
    _kit.rtcLayer = 4;//设置小窗口图层，因为主版本占用了1~3，建议设置为4
    _kit.selfInFront = NO;
    
    //特性1：悬浮图层，用户可以在小窗口叠加自己的view，注意customViewLayer >rtcLayer,（option）
    _kit.customViewRect = CGRectMake(0.6, 0.6, 0.3, 0.3);
    _kit.customViewLayer = 5;
//    UIView * customView = [self createUIView];
//    [_kit.contentView addSubview:customView];
    //特性2:圆角小窗口
    _kit.maskPicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"mask.png"]];

//    
    //设置回调
    [self setupCallBack];
    
    //设置拖拽手势
    [self setupPanGesture];
    
    //sdk日志接口（option）
    _kit.rtcClient.openRtcLog = YES;//是否打开rtc的日志
    _kit.rtcClient.sdkLogBlock = ^(NSString * message){
        NSLog(@"%@",message);
    };
}

-(void)presentAlertControl:(NSString * )remoteId{
    NSString* message = [NSString stringWithFormat:@"%@请求私聊",remoteId];
    _callComingAlertController = [UIAlertController alertControllerWithTitle:@"呼叫到来" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"应答" style:UIAlertActionStyleDefault handler:^ (UIAlertAction *action){
        int ret = [_kit.rtcClient answerCall];
        [self statEvent:@"应答" result:ret];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
        int ret = [_kit.rtcClient rejectCall];
        [self statEvent:@"reject" result:ret];
    }
    ];
    [_callComingAlertController addAction:cancelAction];
    [_callComingAlertController addAction:okAction];
    
    [self presentViewController:_callComingAlertController animated:YES completion:nil];
}


-(void)setupCallBack
{
    //rtcstreamer的回调，（option）
    __weak KSYSChatDemoVC *weak_demo = self;
    __weak KSYRTCStreamerKit *weak_kit = _kit;
    _kit.rtcClient.onRegister= ^(int status){
        NSString * message = [NSString stringWithFormat:@"local sip account:%@",weak_kit.rtcClient.authUid];
        [weak_demo statString:message];
        NSLog(@"sdkversion:%@",weak_kit.rtcClient.sdkVersion);
        [weak_demo statEvent:@"register callback" result:status];
    };
    _kit.rtcClient.onUnRegister= ^(int status){
        [weak_demo statEvent:@"unregister callback" result:status];
        NSLog(@"unregister callback");
    };
    _kit.rtcClient.onCallInComing =^(char* remoteURI){
        NSString *text = [NSString stringWithFormat:@"有呼叫到来,id:%s",remoteURI];
        NSString *remoteStringUrl = [NSString stringWithFormat:@"%s",remoteURI];
        [weak_demo statEvent:text result:0];
        [weak_demo presentAlertControl:remoteStringUrl];
    };
    
    //kit回调，（option）
    _kit.onCallStart =^(int status){
        if(status == 200)
        {
            if([UIApplication sharedApplication].applicationState !=UIApplicationStateBackground)
            {
                [weak_demo statEvent:@"建立连接," result:status];
            }
        }
        else if(status == 408){
            [weak_demo statEvent:@"对方无应答," result:status];
        }
        else if(status == 404){
            [weak_demo statEvent:@"呼叫未注册号码,主动停止" result:status];
        }
        NSLog(@"oncallstart:%d",status);
    };
    _kit.onCallStop = ^(int status){
        if(status == 200)
        {
            if([UIApplication sharedApplication].applicationState !=UIApplicationStateBackground)
            {
                [weak_demo statEvent:@"断开连接," result:status];
            }
        }
        else if(status == 408)
        {
            [weak_demo statEvent:@"408超时" result:status];
        }
        NSLog(@"oncallstop:%d",status);
        if(weak_demo.beQuit)
        {
            [weak_kit.rtcClient unRegisterRTC];
            weak_demo.kit = nil;
            [weak_demo dismissViewControllerAnimated:FALSE completion:nil];
        }
    };
}

-(void)setupPanGesture
{
    panGestureRecognizer=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
    CGRect rect;
    rect.origin.x = _kit.winRect.origin.x * self.view.frame.size.width;
    rect.origin.y = _kit.winRect.origin.y * self.view.frame.size.height;
    rect.size.height =_kit.winRect.size.height * self.view.frame.size.height;
    rect.size.width =_kit.winRect.size.width * self.view.frame.size.width;
    _winRtcView =  [[UIView alloc] initWithFrame:rect];
    _winRtcView.backgroundColor = [UIColor clearColor];
    [_ctrlView addSubview:_winRtcView];
    [_ctrlView bringSubviewToFront:_winRtcView];
    [_winRtcView addGestureRecognizer:panGestureRecognizer];
}


-(void)statEvent:(NSString *)event
          result:(int)ret
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(_stat.text.length > 100)
            _stat.text= @"";
        NSString *text = [NSString stringWithFormat:@"\n%@, ret:%d",event,ret];
        _stat.text = [ _stat.text  stringByAppendingString:text  ];
        
    });
}
-(void)statString:(NSString *)event
{
    if(_stat.text.length > 100)
        _stat.text= @"";
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *text = [NSString stringWithFormat:@"\n%@",event];
        _stat.text = [ _stat.text  stringByAppendingString:text  ];
    });
}

- (void)onRtcRegister:(NSString *)localid
{
    _kit.rtcClient.localId = localid;
    
    NSString * TestASString;
    if(![self checkNetworkReachability:AF_INET6])
    {
    //获取鉴权串，demo里为testAppServer，请改用自己的appserver
    TestASString = [NSString stringWithFormat:@"http://120.92.10.164:6002/rtcauth?uid=%@",localid];
    _kit.rtcClient.authString=[NSString stringWithFormat:@"https://rtc.vcloud.ks-live.com:6001/auth?%@",
                                    [self AuthFromTestAS:TestASString]];
    }
    else{
    TestASString = @"accesskey=D8uDWZ88ZKW48/eZHmRm&expire=1474713034&nonce=CnhQKCkGZ5DnSvYwtz2uhjb0j599E1e7&uid=330&uniqname=apptest&signature=tndMoVqr0nq3fsFM2iEUNwBw1h8%3D";
        _kit.rtcClient.authString=[NSString stringWithFormat:@"https://rtc.vcloud.ks-live.com:6001/auth?%@",TestASString];
    }

    [_kit.rtcClient registerRTC];
}

- (void)onRtcStartCall:(NSString *)remoteid{
    
    int ret = [_kit.rtcClient startCall:remoteid];
    
    NSString * event = [NSString stringWithFormat:@"发起呼叫,remote_id:%@",remoteid];
    [self statEvent:event result:ret];
}
- (void)onRtcAnswerCall{
    int ret = [_kit.rtcClient answerCall];
    [self statEvent:@"应答" result:ret];
}
- (void)onRtcUnregister{
    int ret = [_kit.rtcClient unRegisterRTC];
    
    [self statEvent:@"unregister" result:ret];
}

- (void)onRtcRejectCall{
    int ret = [_kit.rtcClient rejectCall];
    [self statEvent:@"reject" result:ret];
}
- (void)onRtcStopCall{
    int ret = [_kit.rtcClient stopCall];
    [self statEvent:@"stopcall" result:ret];
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

-(void) onSwitchRtcView:(CGPoint)location
{
    CGRect winrect = _kit.winRect;
    
    //只有小窗口点击才会切换窗口
    if((location.x > winrect.origin.x && location.x <winrect.origin.x +winrect.size.width) &&
        (location.y > winrect.origin.y && location.y <winrect.origin.y +winrect.size.height))
    {
        _kit.selfInFront = !_kit.selfInFront;
    }
}

-(void)panAction:(UIPanGestureRecognizer *)sender
{
    //获取手势在屏幕上拖动的点
    
    CGPoint translatedPoint = [panGestureRecognizer translationInView:self.view];
    
    panGestureRecognizer.view.center = CGPointMake(panGestureRecognizer.view.center.x + translatedPoint.x, panGestureRecognizer.view.center.y + translatedPoint.y);
    
    CGRect newWinRect;
    newWinRect.origin.x = (panGestureRecognizer.view.center.x - panGestureRecognizer.view.frame.size.width/2)/self.view.frame.size.width;
    newWinRect.origin.y = (panGestureRecognizer.view.center.y - panGestureRecognizer.view.frame.size.height/2)/self.view.frame.size.height;
    newWinRect.size.height = _kit.winRect.size.height;
    newWinRect.size.width = _kit.winRect.size.width;
    _kit.winRect = newWinRect;
    [panGestureRecognizer setTranslation:CGPointMake(0, 0) inView:self.view];
}

- (BOOL)checkNetworkReachability:(sa_family_t)sa_family {
    //www.apple.com - IPv4: 125.252.236.67 - IPv6: 64:ff9b::7dfc:ec43
    static unsigned char ipv4_addr[4] = {125, 252, 236, 67};
    static unsigned char ipv6_addr[16] = {0x00, 0x64, 0xff, 0x9b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7d, 0xfc, 0xec, 0x43};
    
    struct sockaddr *pZeroAddress = nil;
    struct sockaddr_in zeroSockaddrin;
    struct sockaddr_in6 zeroSockaddrin6;
    if (AF_INET == sa_family) {
        bzero(&zeroSockaddrin, sizeof(zeroSockaddrin));
        bcopy(ipv4_addr, &zeroSockaddrin.sin_addr, sizeof(zeroSockaddrin.sin_addr));
        zeroSockaddrin.sin_len = sizeof(zeroSockaddrin);
        zeroSockaddrin.sin_family = AF_INET;
        pZeroAddress = (struct sockaddr *)&zeroSockaddrin;
    } else if (AF_INET6 == sa_family) {
        bzero(&zeroSockaddrin6, sizeof(zeroSockaddrin6));
        bcopy(ipv6_addr, &zeroSockaddrin6.sin6_addr, sizeof(zeroSockaddrin6.sin6_addr));
        zeroSockaddrin6.sin6_len = sizeof(zeroSockaddrin6);
        zeroSockaddrin6.sin6_family = AF_INET6;
        pZeroAddress = (struct sockaddr *)&zeroSockaddrin6;
    }
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, pZeroAddress);
    SCNetworkReachabilityFlags flags;
    if (!defaultRouteReachability) {
        return NO;
    }
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    if (!didRetrieveFlags) {
        return NO;
    }
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL isLocalAddress = flags & kSCNetworkFlagsIsLocalAddress;
    BOOL isDirect = flags & kSCNetworkFlagsIsDirect;
    return (isReachable && !isLocalAddress && !isDirect) ? YES : NO;
}


-(UIView *)createUIView{
    UIView * view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    view.layer.borderWidth = 10;
    view.layer.borderColor = [[UIColor blueColor] CGColor];
    return view;
}

@end

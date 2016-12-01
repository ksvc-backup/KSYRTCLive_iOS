//
//  FirstViewController.m
//  QYLive
//
//  Created by yiqian on 11/3/15.
//  Copyright (c) 2015 kingsoft. All rights reserved.
//

#import "KSYLiveVC.h"
#import "KSYPresetCfgVC.h"
#import "KSYStreamerVC.h"
#import "KSYSChatDemoVC.h"
#import "KSYPresetCfgView.h"

@interface KSYLiveVC (){
    
}
@property UIButton * liveBtn;
@property UIButton * chatBtn;

@end

@implementation KSYLiveVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _liveBtn = [self addButton:@"直播连麦"];
    _liveBtn.frame = CGRectMake(80,240, self.view.frame.size.width - 160,40);
    
    _chatBtn = [self addButton:@"私聊连麦"];
    _chatBtn.frame =CGRectMake(80,300, self.view.frame.size.width - 160,40);
}

- (UIButton *)addButton:(NSString*)title{
    UIButton * button;
    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle: title forState: UIControlStateNormal];
    button.backgroundColor = [UIColor lightGrayColor];
    button.alpha = 1.0f;
    button.layer.cornerRadius = 10;
    button.clipsToBounds = YES;
    [self.view addSubview:button];
    
    [button addTarget:self
               action:@selector(onBtn:)
     forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (IBAction)onBtn:(id)sender {
    UIViewController *vc = nil;
   if(sender == _liveBtn)
   {
       NSString *devCode  = [ [[[UIDevice currentDevice] identifierForVendor] UUIDString] substringToIndex:3];
       NSString *streamSrv  = @"rtmp://test.uplive.ksyun.com/live";
       NSString *streamUrl      = [ NSString stringWithFormat:@"%@/%@", streamSrv, devCode];
       vc = [[KSYPresetCfgVC alloc]initWithURL:streamUrl];
   }
   else if(sender == _chatBtn)
   {
       vc = [[KSYSChatDemoVC alloc]init];
   }
    
   [self presentViewController:vc animated:YES completion:nil];
}


@end

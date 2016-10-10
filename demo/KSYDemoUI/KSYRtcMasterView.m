//
//  KSYRtcView.m
//  KSYGPUStreamerDemo
//
//  Created by 孙健 on 16/7/15.
//  Copyright © 2016年 ksyun. All rights reserved.
//

#import "KSYRtcMasterView.h"

@implementation KSYRtcMasterView
- (id)init{
    self = [super init];
    _registerBtn = [self addButton:@"注册"];
    _startCallBtn = [self addButton:@"呼叫"];
    _answerCallBtn = [self addButton:@"应答"];
    _unregisterBtn = [self addButton:@"反注册"];
    _stopCallBtn = [self addButton:@"停止"];
    _rejectCallBtn = [self addButton:@"拒绝"];
    _localid = [self addTextField:@"330"];
    _remoteid = [self addTextField:@"340"];
    return self;
}
- (void)layoutUI{
    [super layoutUI];
    [self putRow:@[_localid,_remoteid]];
    [self putRow:@[_registerBtn,_unregisterBtn,_stopCallBtn,_rejectCallBtn]];
    [self putRow:@[_startCallBtn,_answerCallBtn]];
}

@end

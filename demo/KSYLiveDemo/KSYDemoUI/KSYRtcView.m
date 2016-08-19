//
//  KSYRtcView.m
//  KSYGPUStreamerDemo
//
//  Created by 孙健 on 16/7/15.
//  Copyright © 2016年 ksyun. All rights reserved.
//

#import "KSYRtcView.h"

@implementation KSYRtcView
- (id)init{
    self = [super init];
    _masterBtn = [self addButton:@"主播"];
    _slaveBtn = [self addButton:@"辅播"];
    return self;
}
- (void)layoutUI{
    [super layoutUI];
    [self putRow:@[_masterBtn,_slaveBtn]];
}

@end

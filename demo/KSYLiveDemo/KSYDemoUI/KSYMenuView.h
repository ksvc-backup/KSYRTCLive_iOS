//
//  KSYMenuView.h
//  KSYGPUStreamerDemo
//
//  Created by 孙健 on 16/6/24.
//  Copyright © 2016年 ksyun. All rights reserved.
//

#import "KSYUIView.h"

@interface KSYMenuView : KSYUIView
//美颜
@property UIButton *filterBtn;
//返回
@property UIButton *backBtn;
//连麦
@property UIButton *rtcBtn;

- (void)hideAllBtn: (BOOL) bHide;

@end

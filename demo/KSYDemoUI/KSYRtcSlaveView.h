//
//  KSYRtcView.h
//  KSYGPUStreamerDemo
//
//  Created by 孙健 on 16/7/15.
//  Copyright © 2016年 ksyun. All rights reserved.
//

#import "KSYUIView.h"

@interface KSYRtcSlaveView : KSYUIView
@property UIButton * registerBtn;
@property UIButton * startCallBtn;
@property UIButton * answerCallBtn;
@property UIButton * unregisterBtn;
@property UIButton * stopCallBtn;
@property UIButton * rejectCallBtn;
@property UIButton * uninitBtn;
@property UITextField * localid;
@property UITextField * remoteid;
@end

//
//  SenseArMaterialPart.h
//  SenseAr
//
//  Created by sluin on 16/12/29.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import <Foundation/Foundation.h>


FOUNDATION_EXTERN const uint32_t SENSEAR_FACE_DETECT;       ///<  人脸检测

FOUNDATION_EXTERN const uint32_t SENSEAR_EYE_BLINK;         ///<  眨眼
FOUNDATION_EXTERN const uint32_t SENSEAR_MOUTH_AH;          ///<  嘴巴大张
FOUNDATION_EXTERN const uint32_t SENSEAR_HEAD_YAW;          ///<  摇头
FOUNDATION_EXTERN const uint32_t SENSEAR_HEAD_PITCH;        ///<  点头
FOUNDATION_EXTERN const uint32_t SENSEAR_BROW_JUMP;         ///<  眉毛挑动

FOUNDATION_EXTERN const uint32_t SENSEAR_HAND_GOOD;         ///<  大拇哥
FOUNDATION_EXTERN const uint32_t SENSEAR_HAND_PALM;         ///<  手掌
FOUNDATION_EXTERN const uint32_t SENSEAR_HAND_LOVE;         ///<  爱心
FOUNDATION_EXTERN const uint32_t SENSEAR_HAND_HOLDUP;       ///<  托手
FOUNDATION_EXTERN const uint32_t SENSEAR_HAND_CONGRATULATE; ///<  恭贺(抱拳)


@interface SenseArMaterialPart : NSObject

@property (nonatomic , assign) int iPartID;

@property (nonatomic , copy) NSString *strPartName;

@property (nonatomic , assign) uint32_t iTriggerType;

@property (nonatomic , assign) BOOL isEnable;

@end

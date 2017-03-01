//
//  SenseArMaterial.h
//  SenseArMaterial
//
//  Created by sluin on 16/10/8.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 素材类型
 */
typedef enum : NSUInteger {
    
    // 平台广告
    PlatformAD = 1,
    
    // 直投广告
    SelfAD,
    
    // 趣味特效
    SpecialEffect
    
} SenseArMaterialType;

/**
 计费方式
 */
typedef enum : NSUInteger {
    
    // 按展示时长计费
    SENSEAR_CPM = 1,
    
    // 按点击次数计费
    SENSEAR_CPC
    
} SenseArPricingType;

/**
 触发动作
 */
typedef enum : NSUInteger {
    
    // 张嘴
    MOUTH_AH = 1,
    
    // 眨眼
    EYE_BLINK,
    
    // 点头
    HEAD_PITCH,
    
    // 摇头
    HEAD_YAW,
    
    // 挑眉
    BROW_JUMP,
    
    // 手掌
    HAND_PALM,
    
    // 大拇哥
    HAND_GOOD,
    
    // 托手
    HAND_HOLDUP,
    
    // 爱心手
    HAND_LOVE,
    
    // 恭贺(抱拳)
    HAND_CONGRATULATE
    
} SenseArTriggerAction;

@interface SenseArMaterial : NSObject

/**
 *  MaterialID
 */
@property (nonatomic , copy) NSString *strID;

/**
 *  Material所属的组ID
 */
@property (nonatomic , copy) NSString *groupID;

/**
 *  素材类型
 */
@property (nonatomic , assign) SenseArMaterialType iEffectType;


/**
 *  触发条件,使用时长,秒
 */
@property (nonatomic , assign) int iUsingTime;

/**
 *  触发条件,粉丝个数
 */
@property (nonatomic , assign) int iFansCount;

/**
 *  两次使用间隔,秒
 */
@property (nonatomic , assign) int iIntervalTime;

/**
 *  触发动作
 */
@property (nonatomic , assign) SenseArTriggerAction iTriggerAction;

/**
 *  触发动作描述
 */
@property (nonatomic , copy) NSString *strTriggerActionTip;

/**
 *  缩略图地址
 */
@property (nonatomic , copy) NSString *strThumbnailURL;

/**
 *  素材地址
 */
@property (nonatomic , copy) NSString *strMeterialURL;

/**
 *  素材名称
 */
@property (nonatomic , copy) NSString *strName;

/**
 *  素材描述
 */
@property (nonatomic , copy) NSString *strInstructions;

/**
 *  计费类型
 */
@property (nonatomic , assign) SenseArPricingType iPricingType;

/**
 *  价格
 */
@property (nonatomic , copy) NSString *strPrice;




@end

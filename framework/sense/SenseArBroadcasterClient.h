//
//  SenseArBroadcasterClient.h
//  SenseArMaterial
//
//  Created by sluin on 16/10/8.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import "SenseArClient.h"


/**
 主播类型客户
 */
@interface SenseArBroadcasterClient : SenseArClient

/**
 *  主播在平台上的唯一标识
 */
@property (nonatomic , copy) NSString *strID;

/**
 *  主播昵称
 */
@property (nonatomic , copy) NSString *strName;

/**
 *  主播生日
 */
@property (nonatomic , copy) NSString *strBirthday;

/**
 *  主播性别, 男 , 女
 */
@property (nonatomic , copy) NSString *strGender;

/**
 *  地区
 */
@property (nonatomic , copy) NSString *strArea;

/**
 *  邮编
 */
@property (nonatomic , copy) NSString *strPostcode;

/**
 *  经度
 */
@property (nonatomic , assign) double longitude;

/**
 *  纬度
 */
@property (nonatomic , assign) double latitude;

/**
 *  主播类型
 */
@property (nonatomic , copy) NSString *strType;

/**
 *  关注人数
 */
@property (nonatomic , assign) int iFollowCount;

/**
 *  粉丝人数
 */
@property (nonatomic , assign) int iFansCount;

/**
 *  观众数
 */
@property (nonatomic , assign) int iAudienceCount;

/**
 *  主播电话/手机号
 */
@property (nonatomic , copy) NSString *strTelephone;

/**
 *  主播邮箱地址
 */
@property (nonatomic , copy) NSString *strEmail;

/**
 *  是否在直播中
 */
@property (nonatomic , assign , readonly) BOOL isBroadcasting;

/**
 直播开始
 */
- (void)broadcastStart;


/**
 直播停止
 */
- (void)broadcastEnd;






@end

//
//  SenseArAudienceClient.h
//  SenseArMaterial
//
//  Created by sluin on 16/10/8.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import "SenseArClient.h"
#import <GLKit/GLKit.h>

/**
 粉丝类型客户
 */
@interface SenseArAudienceClient : SenseArClient

/**
 *  粉丝在平台上的唯一标识
 */
@property (nonatomic , copy) NSString *strID;

/**
 *  粉丝昵称
 */
@property (nonatomic , copy) NSString *strName;

/**
 *  粉丝生日
 */
@property (nonatomic , copy) NSString *strBirthday;

/**
 *  粉丝性别, 男, 女
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
 *  粉丝电话/手机号
 */
@property (nonatomic , copy) NSString *strTelephone;

/**
 *  邮箱地址
 */
@property (nonatomic , copy) NSString *strEmail;

/**
 *  是否正在观看直播
 */
@property (nonatomic , assign , readonly) BOOL isWatching;


/**
 开始观看直播

 @param strBroadcasterID 平台上的主播唯一标识
 */
- (void)watchBroadcastStart:(NSString *)strBroadcasterID;

/**
 停止观看直播
 */
- (void)watchBroadcastEnd;


@end

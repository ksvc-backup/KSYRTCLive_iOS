//
//  SenseArMaterialService.h
//  SenseArMaterial
//
//  Created by sluin on 16/10/9.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SenseArClient.h"
#import "SenseArMaterial.h"
#import "SenseArMaterialGroup.h"

/**
 客户端类型配置状态
 */
typedef enum : NSUInteger {
    
    /**
     配置成功
     */
    CONFIG_OK = 0,
    
    /**
     配置的类型不容许
     */
    CONFIG_CLIENT_NOT_ALLOWED,
    
    
    /**
     不可知状态
     */
    CONFIG_CLIENT_UNKNOWN,
    
} SenseArConfigStatus;

/**
 鉴权错误码
 */
typedef enum : NSUInteger {
    
    /**
     无效 AppID/SDKKey
     */
    AUTHORIZE_ERROR_KEY_NOT_MATCHED = 1,
    
    /**
     网络不可用
     */
    AUTHORIZE_ERROR_NETWORK_NOT_AVAILABLE,
    
    /**
     未知错误
     */
    AUTHORIZE_ERROR_UNKNOWN,
    
} SenseArAuthorizeError;



/**
 下载状态码
 */
typedef enum : NSUInteger {
    
    /**
     下载成功
     */
    Success = 0,
    
    /**
     网络未连接
     */
    NetworkUnavailable,
    
    /**
     Group 未发现
     */
    GroupNotFound,
    
    /**
     下载未许可
     */
    NotAuthorized,
    
    /**
     未知错误
     */
    UnknownError
    
} SenseArDownloadStatus;

/*
 最大缓存值 , 不启用 LRU 淘汰规则 .
 */
FOUNDATION_EXTERN const int SENSEAR_CACHE_SIZE_MAX;

@interface SenseArMaterialService : NSObject


/**
 获取 Material 服务
 
 @return 合作商对应的 Material 服务
 */
+ (SenseArMaterialService *)shareInstnce;


/**
 释放资源
 */
+ (void)releaseResources;


/**
 *  SenseAr SDK 使用 license 文件路径生成激活码.生成的激活码需要自行保存,以待下次验证.如果 license 更新需要重新生成激活码.
 *
 *  @param strLicensePath license 文件路径
 *  @param error          生成激活码时产生的错误
 *
 *  @return 生成的激活码
 */
+ (NSString *)generateActiveCodeWithLicensePath:(NSString *)strLicensePath
                                          error:(NSError **)error;

/**
 *  SenseAr SDK 使用 license 文件内容生成激活码.生成的激活码需要自行保存,以待下次验证.如果 license 更新需要重新生成激活码.
 *
 *  @param dataLicense license 文件二进制内容
 *  @param error       生成激活码时产生的错误
 *
 *  @return 生成的激活码
 */
+ (NSString *)generateActiveCodeWithLicenseData:(NSData *)dataLicense
                                          error:(NSError **)error;

/**
 *  SenseAr SDK 使用 license 文件路径验证激活码
 *
 *  @param strActiveCode  激活码
 *  @param strLicensePath license 文件路径
 *  @param error          验证激活码时产生的错误
 *
 *  @return 是否通过 , YES为通过检查.
 */
+ (BOOL)checkActiveCode:(NSString *)strActiveCode
            licensePath:(NSString *)strLicensePath
                  error:(NSError **)error;

/**
 *  SenseAr SDK 使用 license 文件内容验证激活码
 *
 *  @param strActiveCode 激活码
 *  @param dataLicense   license 文件二进制内容
 *  @param error         验证激活码时产生的错误
 *
 *  @return 是否通过 , YES为通过检查.
 */
+ (BOOL)checkActiveCode:(NSString *)strActiveCode licenseData:(NSData *)dataLicense
                  error:(NSError **)error;


/**
 远程授权,未授权的 service 不可用
 
 @param strAppID        注册的合作商 ID
 @param strAppKey       注册的合作商 key
 @param completeSuccess 注册成功后的回调
 @param completeFailure 注册失败后的回调 , iErrorCode : 错误码
 */
- (void)authorizeWithAppID:(NSString *)strAppID
                    appKey:(NSString *)strAppKey
                 onSuccess:(void (^)(void))completeSuccess
                 onFailure:(void (^)(SenseArAuthorizeError iErrorCode))completeFailure;


/**
 服务是否授权
 
 @return YES : 已授权 , NO : 未授权
 */
+ (BOOL)isAuthorized;


/**
 配置使用服务的客户端 , 未经配置的 SenseArMaterialService 不可使用
 
 @param iClientType 配置的客户端类型
 @param client      配置的客户端
 
 @return 配置客户状态
 */
- (SenseArConfigStatus)configureClientWithType:(SenseArClientType)iClientType
                                        client:(SenseArClient *)client;


/**
 获取分组列表

 @param completeSuccess 获取分组列表成功 , arrMaterialGroups 分组列表 .
 @param completeFailure 获取分组列表失败 , iErrorCode 错误码 , strMessage 错误描述 .
 */
- (void)fetchAllGroupsOnSuccess:(void (^)(NSArray <SenseArMaterialGroup *>* arrMaterialGroups))completeSuccess
                      onFailure:(void (^)(int iErrorCode , NSString *strMessage))completeFailure;


/**
 获取 Material 列表
 
 @param strGroupID      素材所在组的 groupID
 @param completeSuccess 获取素材列表成功 , arrMaterias 素材列表 .
 @param completeFailure 获取素材列表失败 , iErrorCode 错误码 , strMessage 错误描述 .
 */
- (void)fetchMaterialsWithGroupID:(NSString *)strGroupID
                        onSuccess:(void (^)(NSArray <SenseArMaterial *>* arrMaterials))completeSuccess
                        onFailure:(void (^)(int iErrorCode , NSString *strMessage))completeFailure;

/**
 能否合法绘制
 
 @return YES : 可以绘制 , NO : 不可以绘制
 */
+ (BOOL)isAuthorizedForRender;


/**
 素材是否已下载
 
 @param strMaterialID 需要判断是否已下载的素材的ID
 
 @return YES 已下载 , NO 未下载或下载中 .
 */
- (BOOL)isMaterialDownloaded:(NSString *)strMaterialID;


/**
 设置素材缓存大小 , 默认 100M 超过限制会遵循LRU淘汰规则删除已有素材包 . 如果不需要设置最大缓存可以设置为 SENSEAR_CACHE_SIZE_MAX 来禁用 LRU 淘汰规则 .
 
 @param iSize 缓存大小 (Byte)
 */
- (void)setMaxCacheSize:(int64_t)iSize;

/**
 下载素材
 
 @param material        下载的素材
 @param completeSuccess 下载成功 , material 下载的素材
 @param completeFailure 下载失败 , material 下载的素材 , iErrorCode 错误码 , strMessage 错误描述
 @param processingCallBack 下载中 , material 下载的素材 , fProgress 下载进度 , iSize 已下载大小
 */
- (void)downloadMaterial:(SenseArMaterial *)material
               onSuccess:(void (^)(SenseArMaterial *material))completeSuccess
               onFailure:(void (^)(SenseArMaterial *material , int iErrorCode , NSString *strMessage))completeFailure
              onProgress:(void (^)(SenseArMaterial *material , float fProgress , int64_t iSize))processingCallBack;












@end

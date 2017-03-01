//
//  SenseArClient.h
//  SenseArMaterial
//
//  Created by sluin on 16/10/8.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 客户类型
 */
typedef enum : NSUInteger {
    
    /**
     * 主播类型客户
     */
    Broadcaster = 0,
    
    /**
     * 粉丝类型客户
     */
    Audience,
    
    /**
     * 短视频类型客户
     */
    SmallVideo
    
} SenseArClientType;



@interface SenseArClient : NSObject

@property (nonatomic , assign) SenseArClientType iClientType;


@end

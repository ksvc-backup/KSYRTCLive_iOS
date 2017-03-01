//
//  SenseArFrameActionInfo.h
//  SenseAr
//
//  Created by sluin on 16/12/30.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SenseArHand : NSObject

@property (nonatomic , assign) int32_t iAction;

@end



@interface SenseArFace : NSObject

@property (nonatomic , assign) int iFaceID;
@property (nonatomic , assign) int32_t iAction;

@end



@interface SenseArFrameActionInfo : NSObject

@property (nonatomic , strong) NSArray <SenseArFace *>*arrFaces;
@property (nonatomic , strong) NSArray <SenseArHand *>*arrHands;

@end

//
//  SenseArMaterialRender.h
//  SenseArMaterial
//
//  Created by sluin on 16/10/8.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "SenseArMaterial.h"
#import "SenseArMaterialPart.h"
#import "SenseArFrameActionInfo.h"



FOUNDATION_EXTERN const uint32_t SENSEAR_ENABLE_HUMAN_ACTION;   ///<开启动作检测功能
FOUNDATION_EXTERN const uint32_t SENSEAR_ENABLE_BEAUTIFY;       ///<开启美颜功能


/**
 美颜参数类型
 */
typedef enum : NSUInteger {
    
    /**
     对比度强度 [0 , 1.0]
     */
    BEAUTIFY_CONTRAST_STRENGTH = 0,
    
    /**
     平滑强度 [0 , 1.0]
     */
    BEAUTIFY_SMOOTH_STRENGTH,
    
    /**
     美白强度 [0 , 1.0]
     */
    BEAUTIFY_WHITEN_STRENGTH,
    
    /**
     大眼比例 [0 , 1.0]
     */
    BEAUTIFY_ENLARGE_EYE_RATIO,
    
    /**
     瘦脸比例 [0 , 1.0]
     */
    BEAUTIFY_SHRINK_FACE_RATIO,
    
    /*
     缩下巴比例 [0 , 1.0]
    */
    BEAUTIFY_SHRINK_JAW_RATIO
    
} BeautifyType;


/**
 客户端类型配置状态
 */
typedef enum : NSUInteger {
    
    /**
     未授权
     */
    RENDER_NOT_AUTHORIZED = 0,
    
    /**
     不可知状态
     */
    RENDER_UNKNOWN,
    
    /**
     成功
     */
    RENDER_SUCCESS
    
} SenseArRenderStatus;

/**
 图像格式
 */
typedef enum : NSUInteger {
    
    /**
     Y    1        8bpp ( 单通道8bit灰度像素 )
     */
    PIX_FMT_GRAY8 = 0,
    
    /**
     YUV  4:2:0   12bpp ( 3通道, 一个亮度通道, 另两个为U分量和V分量通道, 所有通道都是连续的 )
     */
    PIX_FMT_YUV420P,
    
    /**
     YUV  4:2:0   12bpp ( 2通道, 一个通道是连续的亮度通道, 另一通道为UV分量交错 )
     */
    PIX_FMT_NV12,
    
    /**
     YUV  4:2:0   12bpp ( 2通道, 一个通道是连续的亮度通道, 另一通道为VU分量交错 )
     */
    PIX_FMT_NV21,
    
    /**
     BGRA 8:8:8:8 32bpp ( 4通道32bit BGRA 像素 )
     */
    PIX_FMT_BGRA8888,
    
    /**
     BGR  8:8:8   24bpp ( 3通道24bit BGR 像素 )
     */
    PIX_FMT_BGR888,
    
    /**
     BGRA 8:8:8:8 32bpp ( 4通道32bit RGBA 像素 )
     */
    PIX_FMT_RGBA8888
    
} SenseArPixelFormat;


/**
 图像旋转角度
 */
typedef enum : NSUInteger {
    
    /**
     图像不需要转向
     */
    CLOCKWISE_ROTATE_0 = 0,
    
    /**
     图像需要顺时针旋转90度
     */
    CLOCKWISE_ROTATE_90,
    
    /**
     图像需要顺时针旋转180度
     */
    CLOCKWISE_ROTATE_180,
    
    /**
     图像需要顺时针旋转270度
     */
    CLOCKWISE_ROTATE_270
    
} SenseArRotateType;


/**
 素材渲染模块
 */
@interface SenseArMaterialRender : NSObject


/**
 创建渲染模块

 @param strModelPath 模型路径
 @param iConfig      开启功能的配置
 @param context      渲染使用的 OpenGL 环境

 @return 渲染模块实例
 */
+ (SenseArMaterialRender *)instanceWithModelPath:(NSString *)strModelPath
                                          config:(int)iConfig
                                       context:(EAGLContext *)context;



/**
 初始化 OpenGL 资源
 */
- (void)initGLResource;



/**
 释放 OpenGL 资源
 */
- (void)releaseGLResource;


/**
 获取点击热链接区域触发的 URL

 @param clickPosition           点击视图的点
 @param imageSize               图像的尺寸
 @param previewSize             视图的尺寸
 @param previewOriginPosition   视图左上角相对于屏幕左上角的坐标

 @return 热链接的 URL
 */
- (NSURL *)getURLWithClickedPosition:(CGPoint)clickPosition
                           imageSize:(CGSize)imageSize
                         previewSize:(CGSize)previewSize
                 previewOriginPosition:(CGPoint)previewOriginPosition;





/**
 设置图像大小

 @param iWidth  图像宽度
 @param iHeight 图像高度
 @param iStride 图像跨度
 */
- (void)setFrameWidth:(int)iWidth height:(int)iHeight stride:(int)iStride;


/**
 设置美颜参数

 @param fValue        参数大小
 @param iBeautifyType 参数类型

 @return 是否设置成功
 */
- (BOOL)setBeautifyValue:(float)fValue forBeautifyType:(BeautifyType)iBeautifyType;


/**
 对图像进行美颜 , 获取图像绘制信息

 @param pFrameInfo      返回的图像绘制信息 , 需要用户分配内存 , 建议分配 10KB .
 @param pLength         返回的信息长度
 @param iPixelFormatIn  输入图像格式
 @param pImageIn        输入图像
 @param iTextureIn      输入 textureID
 @param iRotateType     图像需要旋转的角度
 @param bNeedsMirroring 图像是否需要镜像
 @param iPixelFormatOut 图像输出的格式
 @param pImageOut       输出图像
 @param iTextureOut     输出 textureID
 
 @return 渲染模块的状态
 */
- (SenseArRenderStatus)beautifyAndGenerateFrameInfo:(Byte *)pFrameInfo
                     frameInfoLength:(int *)pLength
                   withPixelFormatIn:(SenseArPixelFormat)iPixelFormatIn
                             imageIn:(Byte *)pImageIn
                           textureIn:(GLuint)iTextureIn
                          rotateType:(SenseArRotateType)iRotateType
                      needsMirroring:(BOOL)bNeedsMirroring
                      pixelFormatOut:(SenseArPixelFormat)iPixelFormatOut
                            imageOut:(Byte *)pImageOut
                          textureOut:(GLuint)iTextureOut;


/**
 渲染 Material 效果并根据需求可以输出渲染后的图像

 @param strMaterialID 需要渲染的素材 ID
 @param pFrameInfo    渲染素材需要的绘制信息 (beautifyAndGenerateFrameInfo 结果)
 @param iTextureIdIn  输入 textureID
 @param iTextureIdOut 输出 textureID
 @param iPixelFormat  输出的图像格式
 @param pImageOut     输出的图像 , 传 NULL 表示不输出图像 , 性能会更好一些 .

 @return 渲染的状态
 */
- (SenseArRenderStatus)renderMaterial:(NSString *)strMaterialID
                     withFrameInfo:(Byte *)pFrameInfo
                   frameInfoLength:(int)iLength
                         textureIn:(GLuint)iTextureIdIn
                        textureOut:(GLuint)iTextureIdOut
                       pixelFormat:(SenseArPixelFormat)iPixelFormat
                          imageOut:(Byte *)pImageOut;



/**
 获取当前素材所有 part 信息 , 必须在 renderMaterial: 之后调用

 @return 当前素材所有 part 信息 , 按照 zposition 排序
 */
- (NSArray <SenseArMaterialPart *>*)getMaterialParts;


/**
 设置每个 part 是否被渲染 , 顺序需要与 getMaterialParts: 获得的 parts 顺序一致 .

 @param arrMaterialParts part 序列
 */
- (void)enableMaterialParts:(NSArray <SenseArMaterialPart *>*)arrMaterialParts;


/**
 获取当前帧中的人脸、手势、背景的动作行为信息 , 需要在 beautifyAndGenerateFrameInfo: 之后调用,否则可能返回上一帧数据.

 @return 当前帧中的人脸、手势、背景的动作行为信息
 */
- (SenseArFrameActionInfo *)getCurrentFrameActionInfo;




@end

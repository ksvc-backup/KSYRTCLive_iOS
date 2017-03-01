//
//  KSYSTFilterThree.m
//  KSYLiveDemo
//
//  Created by 孙健 on 2017/1/16.
//  Copyright © 2017年 qyvideo. All rights reserved.
//

#import "KSYSTFilter.h"
#import <libksygpulive/libksygpulive.h>
#import <libksygpulive/libksystreamerengine.h>
#import <CommonCrypto/CommonDigest.h>

@interface KSYSTFilter(){
    GLuint               textureStickerOut;
    dispatch_semaphore_t dataUpdateSemaphore;
    GPUImageTextureInput *_textureInput;
    Byte *pFrameInfo;
}
@property (nonatomic, strong) KSYGPUPicOutput *textureOutput;
@property (nonatomic , strong) EAGLContext *glRenderContext;
@property (nonatomic , strong) SenseArMaterialRender *render;
@property (nonatomic , strong) SenseArMaterialService *service;
@property (nonatomic , strong) SenseArBroadcasterClient *broadcaster;
@property (nonatomic , readwrite) SenseArMaterial *currentMaterial;
@property (nonatomic , readwrite) NSMutableArray  *arrStickers;

@end

@implementation KSYSTFilter

-(id)initWithAppid:(NSString *)appID
            appKey:(NSString *)appKey
{
    if (self = [super init]) {

        [self checkActiveCode];
        [self setupMaterialRender];
        [self setupSenseArServiceAndBroadcasterWithAppID:appID appKey:appKey];

        _textureOutput = [[KSYGPUPicOutput alloc] initWithOutFmt:kCVPixelFormatType_32BGRA];
        
        __weak typeof(self) weakSelf = self;
        _textureOutput.videoProcessingCallback = ^(CVPixelBufferRef pixelBuffer, CMTime timeInfo){
            [weakSelf uploadRGBPixel:pixelBuffer time:timeInfo];
        };
        ksy_activeAndBindTexture(GL_TEXTURE3, &textureStickerOut, NULL, GL_RGBA, 360, 640);
        _textureInput = [[GPUImageTextureInput alloc] initWithTexture:textureStickerOut size:CGSizeMake(360, 640)];
        
        pFrameInfo = (Byte *)malloc(sizeof(Byte) * 10000);
        memset(pFrameInfo, 0, 10000 * sizeof(Byte));
        _enableSticker = YES;
        _enableBeauty = YES;
    }
    return self;

}
- (void)downLoadMetarials{
    // 获取素材分组列表
    [self.service fetchAllGroupsOnSuccess:^(NSArray<SenseArMaterialGroup *> *arrMaterialGroups) {
        
        NSLog(@"fetchAllGroupsOnSuccess");
    } onFailure:^(int iErrorCode, NSString *strMessage) {
        
        NSLog(@"fetchAllGroups failed %d , %@" , iErrorCode , strMessage);
    }];
    
    // 获取素材列表
    [self.service fetchMaterialsWithGroupID:@"AD_LIST" onSuccess:^(NSArray<SenseArMaterial *> *arrMaterials) {
        
        NSMutableArray *arrAds = [NSMutableArray array];
        
        for (int i = 0; i < arrMaterials.count; i ++) {
            
            SenseArMaterial *material = [arrMaterials objectAtIndex:i];
            
            [arrAds addObject:material];
        }
        NSLog(@"fetch AD_LIST Success");
    } onFailure:^(int iErrorCode, NSString *strMessage) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
        
        [alert setMessage:[NSString stringWithFormat:@"获取素材列表失败 , %@" , strMessage]];
        
        [alert show];
    }];
    
    [self.service fetchMaterialsWithGroupID:@"SE_LIST" onSuccess:^(NSArray<SenseArMaterial *> *arrMaterials) {
        
        NSMutableArray *arrStickers = [NSMutableArray array];
        
        for (int i = 0; i < arrMaterials.count; i ++) {
            
            SenseArMaterial *material = [arrMaterials objectAtIndex:i];
            
            // 趣味特效
            [arrStickers addObject:material];
        }
        
        self.arrStickers = arrStickers;
        
        if(_fetchListFinishCallback)
        {
            _fetchListFinishCallback(self.arrStickers.count);
        }
         NSLog(@"fetch SE_LIST Success");
    } onFailure:^(int iErrorCode, NSString *strMessage) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
        
        [alert setMessage:[NSString stringWithFormat:@"获取贴纸列表失败 , %@" , strMessage]];
        
        [alert show];
    }];
}
- (void)addTarget:(id<GPUImageInput>)newTarget{
    [_textureInput addTarget:newTarget];
}
- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation{
    [_textureInput addTarget:newTarget atTextureLocation:textureLocation];
}

-(void)removeAllTargets{
    [_textureInput removeAllTargets];
}

- (NSString *)getSHA1StringWithData:(NSData *)data
{
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (unsigned int)data.length, digest);
    
    NSMutableString *strSHA1 = [NSMutableString string];
    
    for (int i = 0 ; i < CC_SHA1_DIGEST_LENGTH ; i ++) {
        
        [strSHA1 appendFormat:@"%02x" , digest[i]];
    }
    
    return strSHA1;
}

- (BOOL)checkActiveCode
{
    NSString *strLicensePath = [[NSBundle mainBundle] pathForResource:@"SENSEME" ofType:@"lic"];
    NSData *dataLicense = [NSData dataWithContentsOfFile:strLicensePath];
    
    NSString *strKeySHA1 = @"SENSEME";
    NSString *strKeyActiveCode = @"ACTIVE_CODE";
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *strStoredSHA1 = [userDefaults objectForKey:strKeySHA1];
    NSString *strLicenseSHA1 = [self getSHA1StringWithData:dataLicense];
    
    NSString *strActiveCode = nil;
    
    NSError *error = nil;
    BOOL bSuccess = NO;
    
    if (strStoredSHA1.length > 0 && [strLicenseSHA1 isEqualToString:strStoredSHA1]) {
        
        // Get current active code
        // In this app active code was stored in NSUserDefaults
        // It also can be stored in other places
        strActiveCode = [userDefaults objectForKey:strKeyActiveCode];
        
        // Check if current active code is available
#if CHECK_LICENSE_WITH_PATH
        
        // use file
        bSuccess = [SenseArMaterialService checkActiveCode:strActiveCode licensePath:strLicensePath error:&error];
#else
        
        // use buffer
        NSData *licenseData = [NSData dataWithContentsOfFile:strLicensePath];
        
        bSuccess = [SenseArMaterialService checkActiveCode:strActiveCode
                                               licenseData:licenseData
                                                     error:&error];
        
#endif
        
        if (bSuccess && !error) {
            
            // check success
            return YES;
        }
    }
    
    /*
     1. check fail
     2. new one
     3. update
     */
    
    
    // generate one
#if CHECK_LICENSE_WITH_PATH
    
    // use file
    strActiveCode = [SenseArMaterialService generateActiveCodeWithLicensePath:strLicensePath
                                                                        error:&error];
    
#else
    
    // use buffer
    strActiveCode = [SenseArMaterialService generateActiveCodeWithLicenseData:dataLicense
                                                                        error:&error];
#endif
    
    if (!strActiveCode.length && error) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"使用 license 文件生成激活码时失败，可能是授权文件过期。" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
        
        return NO;
        
    } else {
        
        // Store active code
        
        [userDefaults setObject:strActiveCode forKey:strKeyActiveCode];
        [userDefaults setObject:strLicenseSHA1 forKey:strKeySHA1];
        
        [userDefaults synchronize];
    }
    
    return YES;
}

- (EAGLContext *)getPreContext
{
    return [EAGLContext currentContext];
}

- (void)setCurrentContext:(EAGLContext *)context
{
    if ([EAGLContext currentContext] != context) {
        
        [EAGLContext setCurrentContext:context];
    }
}

- (void)changeSticker:(int) index
            onSuccess:(void (^)(SenseArMaterial *))completeSuccess
            onFailure:(void (^)(SenseArMaterial *, int, NSString *))completeFailure
           onProgress:(void (^)(SenseArMaterial *, float, int64_t))processingCallBack
{
    if ( index <_arrStickers.count) {
            _currentMaterial = _arrStickers[index];
    }
    
    if(![self.service isMaterialDownloaded:((SenseArMaterial *)_arrStickers[index]).strID])
    {
        [self.service downloadMaterial:_arrStickers[index] onSuccess:completeSuccess onFailure:completeFailure onProgress:processingCallBack];
    }
}

- (void)setupSenseArServiceAndBroadcasterWithAppID:(NSString*)appid
                                            appKey:(NSString *)appKey
{
    // 初始化服务
    self.service = [SenseArMaterialService shareInstnce];
    // 使用AppID , AppKey 进行授权 , 如果不授权将无法使用 SenseArMaterialService 相关接口 .
    __weak typeof(self) weakSelf = self;
    [self.service authorizeWithAppID:appid
                              appKey:appKey
                           onSuccess:^{
                               
                               weakSelf.broadcaster = [[SenseArBroadcasterClient alloc] init];
                               
                               // 根据实际情况设置主播的属性
                               weakSelf.broadcaster.strID = @"testASD01234";
                               weakSelf.broadcaster.strName = @"name_testASD01234";
                               weakSelf.broadcaster.strBirthday = @"19901023";
                               weakSelf.broadcaster.strGender = @"男";
                               weakSelf.broadcaster.strArea = @"北京市/海淀区";
                               weakSelf.broadcaster.strPostcode = @"067306";
                               weakSelf.broadcaster.latitude = 39.977813;
                               weakSelf.broadcaster.longitude = 116.317188;
                               weakSelf.broadcaster.iFollowCount = 2000;
                               weakSelf.broadcaster.iFansCount = 2000;
                               weakSelf.broadcaster.iAudienceCount = 6000;
                               weakSelf.broadcaster.strType = @"游戏";
                               weakSelf.broadcaster.strTelephone = @"13600000000";
                               weakSelf.broadcaster.strEmail = @"broadcasteriOS@126.com";
                               
                               SenseArConfigStatus iStatus = [weakSelf.service configureClientWithType:Broadcaster client:weakSelf.broadcaster];
                               
                               if (CONFIG_OK == iStatus) {
                                   
                                   // 设置缓存大小 , 默认为 100M
                                   [weakSelf.service setMaxCacheSize:120000000];
                                   
                                   // 开始直播
                                   [weakSelf.broadcaster broadcastStart];
                                   
                               }else{
                                   
                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"服务配置失败" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
                                   
                                   [alert show];
                               }
                               
                                [weakSelf downLoadMetarials];
                           } onFailure:^(SenseArAuthorizeError iErrorCode) {
                               
                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"服务初始化失败" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
                               
                               [alert show];
                           }];
}


- (void)setupMaterialRender
{
    // 记录调用 SDK 之前的渲染环境以便在调用 SDK 之后设置回来.
    EAGLContext *preContext = [self getPreContext];
    
    // 创建 OpenGL 上下文 , 根据实际情况与预览使用同一个 context 或 shareGroup .
    self.glRenderContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2
                                                 sharegroup:[GPUImageContext sharedImageProcessingContext].context.sharegroup];;
    
    // 调用 SDK 之前需要切换到 SDK 的渲染环境
    [self setCurrentContext:self.glRenderContext];
    
    // 获取模型路径
    NSString *strModelPath = [[NSBundle mainBundle] pathForResource:@"action3.1.0"
                                                             ofType:@"model"];
    // 根据实际需求决定是否开启美颜和动作检测
    
    self.render = [SenseArMaterialRender instanceWithModelPath:strModelPath
                                                        config:SENSEAR_ENABLE_HUMAN_ACTION |SENSEAR_ENABLE_BEAUTIFY
                                                       context:self.glRenderContext];
    if (self.render) {
        
        // 初始化渲染模块使用的 OpenGL 资源
        [self.render initGLResource];
        [self setBeauty];
        
    }else{
        NSLog(@"setupMaterialRender failed.");
    }
    // 需要设为之前的渲染环境防止与其他需要 GPU 资源的模块冲突.
    [self setCurrentContext:preContext];
}

-(void)setEnableBeauty:(BOOL)enableBeauty
{
    _enableBeauty = enableBeauty;
    [self setBeauty];
}

-(void)setBeauty
{
    if (![self.render setBeautifyValue:_enableBeauty?0.71:0.0 forBeautifyType:BEAUTIFY_CONTRAST_STRENGTH]) {
        
        NSLog(@"set BEAUTIFY_CONTRAST_STRENGTH failed");
    }
    if (![self.render setBeautifyValue:_enableBeauty?0.71:0.0 forBeautifyType:BEAUTIFY_SMOOTH_STRENGTH]) {
        
        NSLog(@"set BEAUTIFY_SMOOTH_STRENGTH failed");
    }
    if (![self.render setBeautifyValue:0.0 forBeautifyType:BEAUTIFY_WHITEN_STRENGTH]) {
        
        NSLog(@"set BEAUTIFY_WHITEN_STRENGTH failed");
    }
    if (![self.render setBeautifyValue:_enableBeauty?0.11:0.0 forBeautifyType:BEAUTIFY_SHRINK_FACE_RATIO]) {
        
        NSLog(@"set BEAUTIFY_SHRINK_FACE_RATIO failed");
    }
    if (![self.render setBeautifyValue:_enableBeauty?0.17:0.0 forBeautifyType:BEAUTIFY_ENLARGE_EYE_RATIO]) {
        
        NSLog(@"set BEAUTIFY_ENLARGE_EYE_RATIO failed");
    }
    if (![self.render setBeautifyValue:_enableBeauty?0.2:0.0 forBeautifyType:BEAUTIFY_SHRINK_JAW_RATIO]) {
        
        NSLog(@"set BEAUTIFY_SHRINK_JAW_RATIO failed");
    }
}

- (void)sovlePaddingImage:(Byte *)pImage width:(int)iWidth height:(int)iHeight bytesPerRow:(int *)pBytesPerRow
{
    int iBytesPerPixel = *pBytesPerRow / iWidth;
    int iBytesPerRowCopied = iWidth * iBytesPerPixel;
    int iCopiedImageSize = sizeof(Byte) * iWidth * iBytesPerPixel * iHeight;
    
    Byte *pCopiedImage = (Byte *)malloc(iCopiedImageSize);
    memset(pCopiedImage, 0, iCopiedImageSize);
    
    for (int i = 0; i < iHeight; i ++) {
        
        memcpy(pCopiedImage + i * iBytesPerRowCopied,
               pImage + i * *pBytesPerRow,
               iBytesPerRowCopied);
    }
    
    memcpy(pImage, pCopiedImage, iCopiedImageSize);
    free(pCopiedImage);
    
    *pBytesPerRow = iBytesPerRowCopied;
}

void ksy_activeAndBindTexture(GLenum textureActive,
                             GLuint *textureBind,
                             Byte *sourceImage,
                             GLenum sourceFormat,
                             GLsizei iWidth,
                             GLsizei iHeight)
{
    glGenTextures(1, textureBind);
    glActiveTexture(textureActive);
    glBindTexture(GL_TEXTURE_2D, *textureBind);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, iWidth, iHeight, 0, sourceFormat, GL_UNSIGNED_BYTE, sourceImage);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glFlush();
}
- (void)uploadRGBPixel:(CVPixelBufferRef)pixelBuffer
                  time:(CMTime)timeInfo {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    unsigned char * pBGRAImageInput = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    int iBytesPerRow = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    int iWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int iHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    size_t iTop , iLeft , iBottom , iRight = 0;
    CVPixelBufferGetExtendedPixels(pixelBuffer, &iLeft, &iRight, &iTop, &iBottom);
    
    iWidth += ((int)iLeft + (int)iRight);
    iHeight += ((int)iTop + (int)iBottom);
    
    iBytesPerRow += (iLeft + iRight);
    
    // 当图像因为字节对齐问题导致填充时 , 需要处理为不带填充的图像再输入 , iBytesPerRow 的值可能被改变 .
    if (iBytesPerRow % iWidth != 0) {
        
        [self sovlePaddingImage:pBGRAImageInput
                          width:iWidth
                         height:iHeight
                    bytesPerRow:&iBytesPerRow];
    }
    
    // 记录之前的渲染环境
    EAGLContext *preContext = [self getPreContext];
    // 设置 SDK 的渲染环境
    [self setCurrentContext:self.glRenderContext];
    
    // 原图纹理
    GLuint textureBeautifyIn;
    ksy_activeAndBindTexture(GL_TEXTURE0, &textureBeautifyIn, pBGRAImageInput, GL_BGRA, iWidth, iHeight);
    
    // 分配渲染信息的内存空间
    memset(pFrameInfo, 0, 10000 * sizeof(Byte));
    int iInfoLength = 10000;
    
    SenseArRenderStatus iRenderStatus = RENDER_UNKNOWN;
    
    [self.render setFrameWidth:iWidth height:iHeight stride:iBytesPerRow];
    
    SenseArRotateType iRotate = [self getRotateTypeWithDeviceOrientation];
    
    GLuint textureBeautifyOut;
    ksy_activeAndBindTexture(GL_TEXTURE1, &textureBeautifyOut, NULL, GL_RGBA, iWidth, iHeight);
    
    iRenderStatus = [self.render beautifyAndGenerateFrameInfo:pFrameInfo
                                              frameInfoLength:&iInfoLength
                                            withPixelFormatIn:PIX_FMT_BGRA8888
                                                      imageIn:pBGRAImageInput
                                                    textureIn:textureBeautifyIn
                                                   rotateType:iRotate
                                               needsMirroring:NO
                                               pixelFormatOut:PIX_FMT_BGRA8888
                                                     imageOut:NULL
                                                   textureOut:(_enableSticker)?textureBeautifyOut:textureStickerOut ];
    
    if(_enableSticker){
        // 如果需要直接推流贴纸后的效果 , imageOut 需要传入有效的内存 .
        iRenderStatus = [self.render renderMaterial:self.currentMaterial.strID
                                      withFrameInfo:pFrameInfo
                                    frameInfoLength:iInfoLength
                                          textureIn:textureBeautifyOut
                                         textureOut:textureStickerOut
                                        pixelFormat:PIX_FMT_BGRA8888
                                           imageOut:pBGRAImageInput];
    }
    
    [_textureInput processTextureWithFrameTime:timeInfo];
    //[_kit processTexture:textureStickerOut size: time:pts];
    
    //    glDeleteTextures(1, &textureStickerOut);
    
    //        glFinish();
    glDeleteTextures(1, &textureBeautifyIn);
    glDeleteTextures(1, &textureBeautifyOut);

    [self setCurrentContext:preContext];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (SenseArRotateType)getRotateTypeWithDeviceOrientation
{
    UIDeviceOrientation iDeviceOrientation = [[UIDevice currentDevice] orientation];
    
    SenseArRotateType iRotate;
    
    switch (iDeviceOrientation) {
            
        case UIDeviceOrientationPortrait:
            
            iRotate = CLOCKWISE_ROTATE_0;
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            
            iRotate = CLOCKWISE_ROTATE_180;
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            
            iRotate = CLOCKWISE_ROTATE_270;
            
            break;
            
        case UIDeviceOrientationLandscapeRight:
            
            iRotate = CLOCKWISE_ROTATE_90;
            
            break;
            
        default:
            
            iRotate = CLOCKWISE_ROTATE_90;
            break;
    }
    
    return iRotate;
}


#pragma GPUImageInput
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    [_textureOutput newFrameReadyAtTime:frameTime atIndex:textureIndex];
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    [_textureOutput setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
}

- (NSInteger)nextAvailableTextureIndex {
    return 0;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {
    [_textureOutput setInputSize:newSize atIndex:textureIndex];
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation
                 atIndex:(NSInteger)textureIndex {
    [_textureOutput setInputRotation:newInputRotation atIndex:textureIndex];
}

- (GPUImageRotationMode)  getInputRotation {
    return [_textureOutput getInputRotation];
}

- (CGSize)maximumOutputSize {
    return [_textureOutput maximumOutputSize];
}

- (void)endProcessing {
    
}
- (BOOL)shouldIgnoreUpdatesToThisTarget {
    return NO;
}

- (BOOL)wantsMonochromeInput {
    return NO;
}
- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue {
    
}

-(void)dealloc{
    NSLog(@"KSYSTFilter dealloc");
    [_arrStickers removeAllObjects];
}
@end

#import <Foundation/Foundation.h>
#import <GPUImage/GPUImage.h>
#import <libksygpulive/libksygpuimage.h>

@interface KSYFaceunityFilter : KSYGPUPicInput <GPUImageInput>
/**
 @abstract   构造函数
 @param      需要导入的bundle包,需要一些时间，请耐心等待
 **/
-(id) initWithArray:(NSArray *) items;


/**
 @abstract      选择的bundle包，可以动态选择
 **/
@property (nonatomic,assign) int choosedIndex;

@end

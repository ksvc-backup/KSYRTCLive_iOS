#import "KSYFaceunityFilter.h"
#include <sys/mman.h>
#include <sys/stat.h>
#import "FURenderer.h"

static int g_frame_id = 0;

static size_t osal_GetFileSize(int fd){
    struct stat sb;
    sb.st_size = 0;
    fstat(fd, &sb);
    return (size_t)sb.st_size;
}
static void* mmap_bundle(NSString* fn_bundle,intptr_t* psize){
    // Load item from predefined item bundle
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fn_bundle];
    //    path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:fn_bundle];
    const char *fn = [path UTF8String];
    int fd = open(fn,O_RDONLY);
    void* g_res_zip = NULL;
    size_t g_res_size = 0;
    if(fd == -1){
        NSLog(@"faceunity: failed to open bundle");
        g_res_size = 0;
    }else{
        g_res_size = osal_GetFileSize(fd);
        g_res_zip = mmap(NULL, g_res_size, PROT_READ, MAP_SHARED, fd, 0);
        NSLog(@"faceunity: %@ mapped %08x %ld\n", path, (unsigned int)g_res_zip, g_res_size);
    }
    *psize = g_res_size;
    return g_res_zip;
    return nil;
}


@interface KSYFaceunityFilter()
{
    int _items[100];
}

@property KSYGPUPicOutput* pipOut;
@property EAGLContext* gl_context;

@end

@implementation KSYFaceunityFilter


-(id) initWithArray:(NSArray *) items
{
    self = [super initWithFmt:kCVPixelFormatType_32BGRA];
    
    if(self)
    {
        [self initFaceUnity];
        
        [self loadItems:items];
        
        _pipOut = [[KSYGPUPicOutput alloc]initWithOutFmt:kCVPixelFormatType_32BGRA];
        __weak KSYFaceunityFilter *weak_filter = self;
        _pipOut.videoProcessingCallback = ^(CVPixelBufferRef pixelBuffer, CMTime timeInfo ){
            [weak_filter renderFaceUnity:pixelBuffer timeInfo:timeInfo];
        };
    }
    return self;

}
- (id) init {
    return [self initWithArray:nil];
}

-(void)dealloc{
    _pipOut = nil;
}

-(void)loadItems:(NSArray *) items
{
    for (int i = 0;i<items.count;i ++){
        [self loadItem:items[i] index:i];
    }
    _choosedIndex = 0;
}

-(void)loadItem:(NSString *)itemName
          index:(int)index
{
    if(![EAGLContext setCurrentContext:_gl_context]){
        NSLog(@"faceunity: failed to create / set a GLES2 context");
    }
    
    intptr_t size;
    void* data = mmap_bundle(itemName, &size);
    _items[index] = fuCreateItemFromPackage(data, (int)size);
}

-(void)renderFaceUnity:(CVPixelBufferRef)pixelBuffer
              timeInfo:(CMTime)timeInfo
{
   if(![EAGLContext setCurrentContext:_gl_context]){
        NSLog(@"faceunity: failed to create / set a GLES2 context");
   }
    
   CVPixelBufferRef output_pixelBuffer = [[FURenderer shareRenderer] renderPixelBuffer:pixelBuffer withFrameId:g_frame_id items:&_items[_choosedIndex] itemCount:1];
   [self processPixelBuffer:output_pixelBuffer time:timeInfo];
}

-(void)initFaceUnity
{
    _gl_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if(![EAGLContext setCurrentContext:_gl_context]){
        NSLog(@"faceunity: failed to create / set a GLES2 context");
    }
    
    intptr_t size = 0;
    void* v2data = mmap_bundle(@"v2.bundle", &size);
    void* ardata = mmap_bundle(@"ar.bundle", &size);
    [[FURenderer shareRenderer] setupWithData:v2data ardata:ardata authPackage:NULL authSize:0];
}

#pragma GPUImageInput
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    [_pipOut newFrameReadyAtTime:frameTime atIndex:textureIndex];
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    [_pipOut setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
}

- (NSInteger)nextAvailableTextureIndex {
    return 0;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {
    [_pipOut setInputSize:newSize atIndex:textureIndex];
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation
                 atIndex:(NSInteger)textureIndex {
    [_pipOut setInputRotation:newInputRotation atIndex:textureIndex];
}

- (GPUImageRotationMode)  getInputRotation {
   return [_pipOut getInputRotation];
}

- (CGSize)maximumOutputSize {
    return [_pipOut maximumOutputSize];
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

@end

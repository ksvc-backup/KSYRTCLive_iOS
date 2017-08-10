具有自主知识产权的连麦内核，欢迎大家试用，并提建议,如果喜欢请star~

## 重要声明

从2017年6月起，不再开放给普通用户使用。请使用其他连麦方案。

给您造成的不便，深表歉意！


## 连麦效果
* 效果如下：

![screenshot](https://github.com/ksvc/KSYRTCLive_iOS/wiki/images/Screenshot.png)

* 连麦效果视频请见：

[![ScreenShot](https://raw.githubusercontent.com/wiki/ksvc/KSYRTCLive_iOS/images/rtc_bi.jpg)](http://www.bilibili.com/video/av7410838/)

## 1. 功能特性

> 超清连麦，不错过每一个细节!

金山云提供高效H.265编解码内核，提供低码率下高质量连麦体验。欢迎试用！

### 1.1 连麦功能
* 基于 [KSYLiveSDK](https://github.com/ksvc/KSYLive_iOS/)的 连麦功能。

### 1.2 文档
[手把手教你学会如何连麦](https://github.com/ksvc/KSYRTCLive_iOS/wiki)

### 1.3 集成方式
- 需要导入的动态库（pod方式）：

  ⚠️：请加上use_frameworks，因为需要使用动态库。
```
use_frameworks!
pod 'KSYRTCLive’,:path => '../'
pod 'libksygpulive/KSYGPUResource'
pod 'libksygpulive/libksygpulive'
```
- 需要导入的动态库（手动方式):

  
  [KSYLive_iOS](https://github.com/ksvc/KSYLive_iOS/releases)下载最新动态库包framework_dy_xxx.zip。

  Embedded Binary的方式嵌入2个动态库GPUImage.framework和libksygpulive.framework。
  
  Embedded Binary的方式嵌入framework目录下的libksyrtclivedy.framework。
  
- 需要导入的文件：
```
source目录下 KSYRTCStreamerKit.h/m
```


## 2. 连麦大事记
### 2.1 发布大事记
- 2016.08.04 初始版本;
- 2016.08.10 支持纯语音连麦;
- 2016.08.15 支持美颜连麦;
- 2016.08.26 支持AEC(回音消除);
- 2016.09.26 音视频质量极致优化,超稳定版本v1.8.5发布。
- 2016.11.22 和rtc主版本分离，更加易于集成。开源[KSYRTCStreamerKit.m]
- 2016.12.01 发布私聊版本。
- 2016.12.22 发布圆角版本+音频极致优化版本。
- 2016.1.20 发布faceunity贴纸版本。[使用指南](https://github.com/ksvc/KSYRTCLive_iOS/wiki/feature)
- 2016.3.1  集成商汤贴纸版本。[使用指南](https://github.com/ksvc/KSYRTCLive_iOS/wiki/feature)

### 2.2 近期工作
- 2016.2.xx 多人连麦；

## 3. 商务合作
demo中有测试评估账号，可以直接实现一对一连麦。  
正式上线需要申请金山云账号，请联系金山云商务。

## 4. 反馈与建议
- 主页：[金山云](http://v.ksyun.com)
- 邮箱：<zengfanping@kingsoft.com>
- QQ讨论群：574179720
- Issues: <https://github.com/ksvc/KSYRTCLive_iOS/issues>

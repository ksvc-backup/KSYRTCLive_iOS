具有自主知识产权的连麦内核，欢迎大家试用，并提建议,如果喜欢请star~
## 1. 功能特性
### 1.1 连麦功能
* 基于 [KSYLiveSDK](https://github.com/ksvc/KSYLive_iOS/)的 连麦功能。

### 1.2 文档
[详情请见wiki](https://github.com/ksvc/KSYRTCLive_iOS/wiki)

### 1.3 pod集成
```
// 私有库 (需要包含rtc库以及主版本库)
pod 'KSYRTCLive’,:path => '../'
pod 'libksygpulive/KSYGPUResource', :git => 'https://github.com/ksvc/KSYLive_iOS.git', :tag => 'v1.8.7’
pod 'libksygpulive/libksygpulive', :git => 'https://github.com/ksvc/KSYLive_iOS.git', :tag => 'v1.8.7’
```

[oschina镜像](https://git.oschina.net/ksvc/KSYRTCLive_iOS)地址：

```
pod 'KSYRTCLive_iOS', :git => 'https://git.oschina.net/ksvc/KSYRTCLive_iOS.git', :tag => 'v1.9.0'

```

## 2. 连麦大事记
### 2.1 发布大事记
- 2016.08.04 初始版本;
- 2016.08.10 支持纯语音连麦;
- 2016.08.15 支持美颜连麦;
- 2016.08.26 支持AEC(回音消除);
- 2016.09.26 音视频质量极致优化,超稳定版本v1.8.5发布。
- 2016.11.22 和rtc主版本分离，更加易于集成。开源[KSYRTCStreamerKit.m](https://github.com/ksvc/KSYRTCLive_iOS/blob/master/source/KSYRTCStreamerKit.m)

### 2.2 近期工作
- 2016.12.xx 多人连麦；

## 3. 商务合作
demo中有测试评估账号，可以直接实现一对一连麦。  
正式上线需要申请金山云账号，请联系金山云商务。

## 4. 反馈与建议
- 主页：[金山云](http://v.ksyun.com)
- 邮箱：<zengfanping@kingsoft.com>
- QQ讨论群：574179720
- Issues: <https://github.com/ksvc/KSYRTCLive_iOS/issues>

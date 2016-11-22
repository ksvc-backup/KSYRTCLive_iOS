Pod::Spec.new do |spec|
  spec.name         = 'KSYRTCLive'
  spec.version      = '1.9.0'
  spec.license      = {
:type => 'Proprietary',
:text => <<-LICENSE
      Copyright 2015 kingsoft Ltd. All rights reserved.
      LICENSE
  }
  spec.homepage     = 'http://v.ksyun.com/doc.html'
  spec.authors      = { 'ksyun' => 'zengfangpin@kingsoft.com' }
  spec.summary      = 'KSYRTCLiveSDK 是 金山云的连麦SDK.'
  spec.description  = <<-DESC
      KSYRTCLiveSDK 是 金山云的连麦SDK.
      需要依赖KSYGPULive, 在直播的基础上添加实时通信的功能, 达到连麦直播的目的.
  DESC
  spec.platform     = :ios, '7.0'
  spec.requires_arc = true
  spec.frameworks   = 'VideoToolbox'
  spec.dependency 'libksygpulive/KSYGPUResource','1.8.7'
  spec.dependency 'libksygpulive/libksygpulive','1.8.7'
  spec.ios.library = 'z', 'iconv', 'stdc++.6'
  spec.source = { :git => 'https://github.com/ksvc/KSYRTCLive_iOS.git', :tag => 'v1.9.0'}
  spec.vendored_frameworks = 'framework/libksyrtclivedy.framework'
end


Pod::Spec.new do |s|
  s.name = "CancelForPromiseKit"

  `xcodebuild -project CancelForPromiseKit.xcodeproj -showBuildSettings` =~ /CURRENT_PROJECT_VERSION = ((\d\.)+\d)/
  abort("No version detected") if $1.nil?
  s.version = $1

  s.source = {
    :git => "https://github.com/dougzilla32/#{s.name}.git",
    :tag => s.version,
    :submodules => true
  }

  s.license = 'MIT'
  s.summary = 'Cancellable Promises for Swift.'
  s.homepage = 'https://github.com/dougzilla32/CancelForPromiseKit.git'
  s.description = 'Provides clear, concise and complete cancellation abilities for PromiseKit and the PromiseKit Extensions.'
# s.social_media_url = ''
  s.authors  = { 'Doug Stein' => 'dougstein@gmail.com' }
  s.documentation_url = 'https://dougzilla32.github.io/CancelForPromiseKit/api/'
  s.default_subspecs = 'CorePromise', 'Foundation'
  s.requires_arc = true
  s.swift_version = '4.0'

  # CocoaPods requires us to specify the root deployment targets
  # even though for us it is nonsense. Our root spec has no
  # sources.
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.11'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'
  
  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-DCPKCocoaPods',
  }

  s.subspec 'Alamofire' do |ss|
    ss.source_files = 'Extensions/Alamofire/Sources/*'
    ss.dependency 'Alamofire', '~> 4.0'
    ss.dependency 'PromiseKit/Alamofire', '~> 6.0'
    ss.dependency 'CancelForPromiseKit/CorePromise'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.11'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'

    ss.test_spec do |test_spec|
        test_spec.source_files = Dir['Extensions/Alamofire/Tests/*']
        test_spec.dependency 'OHHTTPStubs/Swift'
    end
  end

#  s.subspec 'Bolts' do |ss|
#    ss.source_files = 'Extensions/Bolts/Sources/*'
#    ss.dependency 'CancelForPromiseKit/CorePromise'
#    ss.dependency 'Bolts', '~> 1.9.0'
#    ss.ios.deployment_target = '8.0'
#    ss.osx.deployment_target = '10.11'
#    ss.watchos.deployment_target = '2.0'
#    ss.tvos.deployment_target = '9.0'
#  end
#
#  s.subspec 'CloudKit' do |ss|
#    ss.source_files = 'Extensions/CloudKit/Sources/*'
#    ss.frameworks = 'CloudKit'
#    ss.dependency 'CancelForPromiseKit/CorePromise'
#    ss.ios.deployment_target = '8.0'
#    ss.osx.deployment_target = '10.10'
#    ss.tvos.deployment_target = '9.0'
#    ss.watchos.deployment_target = '3.0'
#  end

  s.subspec 'CorePromise' do |ss|
    hh = Dir['Sources/*.h'] # - Dir['Sources/*+Private.h']

    cc = Dir['Sources/*.swift'] # - ['Sources/SwiftPM.swift']
    cc << 'Sources/{after,CancellableAnyPromise}.m'
    cc += hh
    
    ss.source_files = cc
    ss.public_header_files = hh
    # ss.preserve_paths = 'Sources/AnyPromise+Private.h', 'Sources/PMKCallVariadicBlock.m', 'Sources/NSMethodSignatureForBlock.m'
    ss.dependency 'PromiseKit/CorePromise', '~> 6.3.4'
    ss.frameworks = 'Foundation'
    
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.11'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'CoreLocation' do |ss|
    ss.source_files = 'Extensions/CoreLocation/Sources/*'
    ss.watchos.source_files = 'Extensions/CoreLocation/Sources/CLGeocoder*'
    ss.dependency 'PromiseKit/CoreLocation', '~> 6.0'
    ss.dependency 'CancelForPromiseKit/CorePromise'
    ss.frameworks = 'CoreLocation'

    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.11'
    ss.watchos.deployment_target = '3.0'
    ss.tvos.deployment_target = '9.0'
  end

  s.subspec 'Foundation' do |ss|
    ss.source_files = Dir['Extensions/Foundation/Sources/*']
    ss.dependency 'PromiseKit/Foundation', '~> 6.0'
    ss.dependency 'CancelForPromiseKit/CorePromise'
    ss.frameworks = 'Foundation'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.11'
    ss.watchos.deployment_target = '2.0'
    ss.tvos.deployment_target = '9.0'
    ss.test_spec do |test_spec|
        test_spec.source_files = Dir['Extensions/Foundation/Tests/*']
        test_spec.dependency 'OHHTTPStubs/Swift'
    end
 end
  
#  s.subspec 'MapKit' do |ss|
#    ss.ios.source_files = ss.osx.source_files = ss.tvos.source_files = 'Extensions/MapKit/Sources/*'
#    ss.ios.frameworks = ss.osx.frameworks = ss.tvos.frameworks = 'MapKit'
#    ss.dependency 'CancelForPromiseKit/CorePromise'
#    ss.ios.deployment_target = '8.0'
#    ss.osx.deployment_target = '10.11'
#    ss.watchos.deployment_target = '2.0'
#    ss.tvos.deployment_target = '9.2'
#  end
#
#  s.subspec 'OMGHTTPURLRQ' do |ss|
#    ss.source_files = 'Extensions/OMGHTTPURLRQ/Sources/*'
#    ss.dependency 'CancelForPromiseKit/Foundation'
#    ss.dependency 'OMGHTTPURLRQ', '~> 3.2'
#    ss.ios.deployment_target = '8.0'
#    ss.osx.deployment_target = '10.11'
#    ss.watchos.deployment_target = '2.0'
#    ss.tvos.deployment_target = '9.0'
#  end
#
#  https://developer.apple.com/documentation/storekit/skrequest/1385526-cancel
#  s.subspec 'StoreKit' do |ss|
#    ss.ios.source_files = ss.osx.source_files = ss.tvos.source_files = 'Extensions/StoreKit/Sources/*'
#    ss.ios.frameworks = ss.osx.frameworks = ss.tvos.frameworks = 'StoreKit'
#    ss.dependency 'CancelForPromiseKit/CorePromise'
#    ss.ios.deployment_target = '8.0'
#    ss.osx.deployment_target = '10.11'
#    ss.tvos.deployment_target = '9.0'
#  end
#
# https://stackoverflow.com/questions/39194716/wcsession-is-it-possible-to-cancel-queued-message?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
#  s.subspec 'WatchConnectivity' do |ss|
#    ss.ios.source_files = ss.watchos.source_files = 'Extensions/WatchConnectivity/Sources/*'
#    ss.ios.frameworks = ss.watchos.frameworks = 'WatchConnectivity'
#    ss.dependency 'CancelForPromiseKit/CorePromise'
#    ss.ios.deployment_target = '8.0'
#    ss.watchos.deployment_target = '2.0'
#  end
end

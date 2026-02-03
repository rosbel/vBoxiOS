source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '13.0'

# Ensure pods use the same Swift version as the main target
use_frameworks!

target 'vBox' do
  pod 'GoogleMaps'
end

target 'vBoxTests' do
  inherit! :search_paths
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end

project 'NavCog3'
inhibit_all_warnings!

target 'NavCog3' do
  platform :ios, '8.4'
  pod 'OpenCV-Dynamic', :podspec => "https://raw.githubusercontent.com/hulop/blelocpp/v1.3.6/platform/ios/podspecs/OpenCV-Dynamic.podspec"
  pod 'FormatterKit'
end

target 'NavCogFP' do
  platform :ios, '8.4'
  pod 'OpenCV-Dynamic', :podspec => "https://raw.githubusercontent.com/hulop/blelocpp/v1.3.6/platform/ios/podspecs/OpenCV-Dynamic.podspec"
  pod 'FormatterKit'
end

target 'NavCogTool' do
  platform :osx, '10.10'
  pod 'FormatterKit'
end

target 'NavCogPreview' do
  platform :ios, '8.4'
  pod 'OpenCV-Dynamic', :podspec => "https://raw.githubusercontent.com/hulop/blelocpp/v1.3.6/platform/ios/podspecs/OpenCV-Dynamic.podspec"
  pod 'FormatterKit'
end

target 'NavCogMiraikan' do
  platform :ios, '13.0'
  pod 'OpenCV-Dynamic', :podspec => "https://raw.githubusercontent.com/hulop/blelocpp/v1.3.6/platform/ios/podspecs/OpenCV-Dynamic.podspec"
  pod 'FormatterKit'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end
  end
end
#
# Be sure to run `pod lib lint FYPhoto.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FYPhoto'
  s.version          = '2.2.10'
  s.summary          = 'FYPhoto is a photo/video picker and image browser library for iOS written in pure Swift'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
	FYPhoto is a photo/video picker and image browser library for iOS written in pure Swift. It is feature-rich and highly customizable to match your App's requirements.
  DESC

  s.homepage         = 'https://github.com/T2Je'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 't2je' => 't2je@icloud.com' }
  s.source           = { :git => 'https://github.com/T2Je/FYPhoto.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

   s.ios.deployment_target = '11'
   s.swift_version = '5'

   s.source_files = 'Sources/FYPhoto/Classes/**/*'

   s.resource_bundles = {
       'FYPhoto' => ['Sources/FYPhoto/Assets/*.{xcassets}', 'Sources/FYPhoto/Assets/*.lproj/*.strings']
   }

   s.frameworks = 'UIKit', 'Photos'

   s.dependency 'SDWebImage/Core'
   s.dependency 'FYVideoCompressor'
   
end

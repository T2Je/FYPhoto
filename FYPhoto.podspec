#
# Be sure to run `pod lib lint FYPhoto.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FYPhoto'
  s.version          = '1.0.1'
  s.summary          = 'A short description of FYPhoto.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'http://git.feeyo.com/'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xiaoyang' => 'xiaoyang@variflight.com' }
  s.source           = { :git => 'http://git.feeyo.com/acdm-ios-base/fyphoto.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

   s.ios.deployment_target = '11'
   s.swift_version = '5'

   s.source_files = 'FYPhoto/Classes/**/*'

   s.resource_bundles = {
       'FYPhoto' => ['FYPhoto/Assets/*.{xcassets}', 'FYPhoto/Assets/*.lproj/*.strings']
   }

   s.frameworks = 'UIKit', 'Photos'

   s.dependency 'SDWebImage/Core'
   s.dependency 'UICircularProgressRing'
end

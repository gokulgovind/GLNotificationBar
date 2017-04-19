#
# Be sure to run `pod lib lint GLNotificationBar.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GLNotificationBar'
  s.version          = '2.3.3'
  s.summary          = 'GLNotificationBar lets user to handle push  notification when app is active.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
 GLNotificationBar is a open source library that lets developers to display push notification or any alert message to end user as banner. iOS below 10 does't displays notification when app is active. This library is inspired by Apple's ios10 notification bar.
                       DESC

  s.homepage         = 'https://github.com/gokulgovind/GLNotificationBar'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'gokul' => 'gokulece26@gmail.com' }
  s.source           = { :git => 'https://github.com/gokulgovind/GLNotificationBar.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/gokulgovind_'

  s.ios.deployment_target = '8.0'

  s.source_files = 'GLNotificationBar/Classes/**/*'
  
   s.resource_bundles = {
     'GLNotificationBar' => ['GLNotificationBar/Classes/*.xib','GLNotificationBar/Assets/*.png']
   }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

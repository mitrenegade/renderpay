#
# Be sure to run `pod lib lint RenderPay.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RenderPay'
  s.version          = '0.1.1'
  s.summary          = 'Handles Stripe connect'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Payment library using Stripe
                       DESC

  s.homepage         = 'https://github.com/bobbyren/RenderPay'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'bobbyren' => 'bobbyren@gmail.com' }
  s.source           = { :git => 'git@bitbucket.org:renderapps/renderpay.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'
  s.swift_version = '4.1'
  s.static_framework = true
  s.source_files = 'RenderPay/Classes/**/*'
  
  # s.resource_bundles = {
  #   'RenderPay' => ['RenderPay/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'MapKit', 'FirebaseCore', 'FirebaseAuth', 'FirebaseDatabase', 'FirebaseStorage', 'FirebaseRemoteConfig', 'RxSwift', 'RxCocoa'
  s.dependency 'Firebase'
  s.dependency 'Firebase/Core'
  s.dependency 'Firebase/Auth'
  s.dependency 'Firebase/Database'
  s.dependency 'Firebase/Storage'
  s.dependency 'Firebase/RemoteConfig'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'RxOptional'
  s.dependency 'RenderCloud', '~> 1.1.0'
  s.dependency 'Stripe'
end

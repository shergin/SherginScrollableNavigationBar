#
# Be sure to run `pod lib lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = "SherginScrollableNavigationBar"
  s.version          = "0.1.0"
  s.summary          = "A scrollable UINavigationBar that follows a UIScrollView."
  s.description      = <<-DESC
                       A scrollable UINavigationBar that follows a UIScrollView.
                       This project was inspired by the navigation bar functionality
                       seen in the Chrome, Facebook and Instagram iOS apps.
                       This description and some implementation ideas was inspired by
                       GTScrollNavigationBar.
                       DESC
  s.homepage         = "https://github.com/shergin/SherginScrollableNavigationBar"
  # s.screenshots      = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Valentin Shergin" => "valentin@shergin.com" }
  s.source           = { :git => "http://EXAMPLE/NAME.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/shergin'

  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.source_files = 'Classes'
  s.resources = 'Assets/*.png'

  s.ios.exclude_files = 'Classes/osx'
  s.osx.exclude_files = 'Classes/ios'
  s.public_header_files = 'Classes/**/*.h'
  # s.frameworks = 'SomeFramework', 'AnotherFramework'
  # s.dependency 'JSONKit', '~> 1.4'
end

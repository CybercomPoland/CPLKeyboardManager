#
#  Be sure to run `pod spec lint CPLKeyboardManager.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "CPLKeyboardManager"
  s.version      = "1.0.0"
  s.summary      = "A manager that helps to keep keyboard logic outside of view controllers."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
CPLKeyboardManager helps to keep view controllers cleaner by removing keyboard appearance logic out of them.
                   DESC

  s.homepage     = "https://github.com/CybercomPoland/CPLKeyboardManager"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

 
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author	 = { "Michał Ziętera" => "Michal.Zietera@cybercom.com" }
  s.source	 = { :git => "https://github.com/CybercomPoland/CPLKeyboardManager.git", :tag => s.version.to_s }

  s.ios.deployment_target = "8.0"

  s.source_files = "Source/**/*"

  s.dependency "Quick", "~> 1.1.0"
  s.dependency "Nimble", "~> 6.1.0"

end

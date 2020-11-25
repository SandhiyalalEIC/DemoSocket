Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '11.0'
s.name = "SoftAponboarding"
s.summary = "SoftAponboarding flavor."
s.requires_arc = true

# 2
s.version = "0.1.0"

s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "einfochips1" => "sandhiya.lal@einfocips.com" }

s.homepage = "https://github.com/einfochips1/DemoSocket"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/einfochips1/DemoSocket.git",
             :tag => "#{s.version}" }

# 7
s.framework = "UIKit"
s.dependency 'RxSwift'
s.dependency 'RxCocoa'
s.dependency 'CryptoSwift'

# 8
s.source_files = "SoftAponboarding/**/*.{swift}"

# 10
s.swift_version = "5"

end

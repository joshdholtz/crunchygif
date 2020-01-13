source "https://rubygems.org"

#gem "fastlane", "2.133.0"
#gem "xcodeproj", :path => "../Xcodeproj"
gem "fastlane", :path => "../fastlane/fastlane"
#gem "fastlane", :git => "https://github.com/fastlane/fastlane.git", :branch => "joshdholtz-post_for_testflight_review-new-api"
#gem "fastlane", :git => "https://github.com/chronweigle/fastlane.git", :branch => "app-store-connect"
# gem 'fastlane', :git => 'https://github.com/fastlane/fastlane.git', :branch => 'joshdholtz-remove-basename-from-itc-uploaded-ipa'
#gem 'fastlane', :git => 'https://github.com/fastlane/fastlane.git', :branch => 'joshdholtz-signet'
gem "pry"
gem "xcov"
gem "cocoapods"
gem "rest-client"
gem "slather"

gem "xcpretty-teamcity-formatter"

# gem "jwt", "~> 1.5"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)

NAME = 'RubySolitaire'

XCWORKSPACE = "#{NAME}.xcworkspace"
XCODEPROJ   = "#{NAME}.xcodeproj"
PBXPROJ     = "#{XCODEPROJ}/project.pbxproj"

BUNDLE_DIR = 'vendor/bundle'
PODS_DIR   = 'Pods'


task :default => :build

task :build => 'xcode:build'

task :xcode => 'xcode:open'

task :update => %w[bundle pods].map {|s| "#{s}:update"}

task :clean => %w[xcode].map {|s| "#{s}:clean"}

task :clobber => %w[xcode bundle pods].map {|s| "#{s}:clobber"}


namespace :xcode do
  task :clean do
    sh %( xcodebuild clean ) if File.exist?(PBXPROJ)
  end

  task :clobber => 'xcode:clean' do
    sh %( rm -rf #{XCWORKSPACE} #{XCODEPROJ} )
  end

  task :build => XCWORKSPACE do
    sh %( xcodebuild build )
  end

  task :open => XCWORKSPACE do
    sh %( open #{XCWORKSPACE} )
  end

  file XCWORKSPACE => [BUNDLE_DIR, PODS_DIR]

  file PBXPROJ do
    sh %( xcodegen generate )
  end
end


namespace :bundle do
  task :clobber do
    sh %( rm -rf #{BUNDLE_DIR} )
  end

  task :update do
    sh %( bundle update )
  end

  file BUNDLE_DIR do
    sh %( bundle install )
    raise "failed to install gems" unless File.exist? BUNDLE_DIR
  end
end


namespace :pods do
  task :clobber do
    sh %( rm -rf #{PODS_DIR} )
  end

  task :update => BUNDLE_DIR do
    sh %( bundle exec pod update --verbose )
  end

  file PODS_DIR => [BUNDLE_DIR, PBXPROJ] do
    sh %( bundle exec pod install --verbose --repo-update )
  end
end

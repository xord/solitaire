
NAME = 'RubySolitaire'

XCWORKSPACE = "#{NAME}.xcworkspace"
XCODEPROJ   = "#{NAME}.xcodeproj"
PBXPROJ     = "#{XCODEPROJ}/project.pbxproj"

BUNDLE_DIR = 'vendor/bundle'
PODS_DIR   = 'Pods'


task :default => :build

task :build => XCWORKSPACE do
  sh %( xcodebuild build )
end

task :xcode => XCWORKSPACE do
  sh %( open #{XCWORKSPACE} )
end

task :update => %w[bundle:update pods:update]

task :bundle => BUNDLE_DIR

task :pods => PODS_DIR

task :clean do
  sh %( xcodebuild clean ) if File.exist?(PBXPROJ)
end

task :clobber => [:clean, 'bundle:clobber', 'pods:clobber'] do
  sh %( rm -rf #{XCWORKSPACE} #{XCODEPROJ} )
end

file XCWORKSPACE => [BUNDLE_DIR, PODS_DIR]

file PBXPROJ do
  sh %( xcodegen generate )
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

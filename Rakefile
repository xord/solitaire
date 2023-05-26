NAME     = 'solitaire'
NAME_IOS = "Ruby#{NAME.capitalize}"

GEMSPEC = "#{NAME}.gemspec"

XCWORKSPACE = "#{NAME_IOS}.xcworkspace"
XCODEPROJ   = "#{NAME_IOS}.xcodeproj"

BUNDLE_DIR = 'vendor/bundle'
PODS_DIR   = 'Pods'


def version()
  File.read(GEMSPEC)[%r|\.version\s*=\s*\'([\d\.]+)\'|, 1]
end


task :default => :build

task :build => 'xcode:build'

task :xcode => 'xcode:open'

task :update => %w[bundle pods].map {|s| "#{s}:update"}

task :clean => %w[gem xcode].map {|s| "#{s}:clean"}

task :clobber => %w[xcode bundle pods].map {|s| "#{s}:clobber"}

task :run do
  libs = %w[xot rucy beeps rays reflex processing rubysketch]
    .map {|lib| "-I#{ENV['ALL']}/#{lib}/lib"}
  sh %( ruby #{libs.join ' '} -Ilib -rrubysketch/solitaire -e '' )
end

task :gem => 'gem:build'


namespace :gem do
  gemname = File.read(GEMSPEC)[%r|\.name\s*=\s*\'([^\']+)\'|, 1]
  gemfile = "#{gemname}-#{version}.gem"

  task :build do
    sh %( gem build #{GEMSPEC} )
  end

  task :clean do
    sh %( rm -f #{gemfile} )
  end
end


namespace :xcode do
  task :clean do
    sh %( xcodebuild clean ) if File.exist?(XCODEPROJ)
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

  file XCODEPROJ do
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
    raise "failed to bundle install" unless File.exist? BUNDLE_DIR
  end
end


namespace :pods do
  task :clobber do
    sh %( rm -rf #{PODS_DIR} )
  end

  task :update => [BUNDLE_DIR, XCODEPROJ] do
    sh %( bundle exec pod update --verbose )
  end

  file PODS_DIR => [BUNDLE_DIR, XCODEPROJ] do
    sh %( bundle exec pod install --verbose --repo-update )
  end
end

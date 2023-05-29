# -*- mode: ruby -*-


%w[../xot  .]
  .map  {|s| File.expand_path "#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/rake'

require 'xot/extension'
require 'rubysketch/solitaire/extension'


EXTENSIONS = [RubySketch::Solitaire]

GEMNAME  = "rubysketch-#{target.name.downcase}"

NAME_IOS = "Ruby#{target.name}"
XCWORKSPACE = "#{NAME_IOS}.xcworkspace"
XCODEPROJ   = "#{NAME_IOS}.xcodeproj"

BUNDLE_DIR = 'vendor/bundle'
PODS_DIR   = 'Pods'


default_tasks
build_ruby_gem


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

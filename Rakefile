# -*- mode: ruby -*-


%w[../xot  .]
  .map  {|s| File.expand_path "#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/rake'

require 'xot/extension'
require 'rubysketch/solitaire/extension'


EXTENSIONS = [RubySketch::Solitaire]

GEMNAME  = "rubysketch-#{target.name.downcase}"

PROJECT   = 'project.yml'
CHANGELOG = 'ChangeLog.md'

APP_NAME    = ENV['APP_NAME'] = "Ruby#{target.name}"
XCWORKSPACE = "#{APP_NAME}.xcworkspace"
XCODEPROJ   = "#{APP_NAME}.xcodeproj"

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
    sh %( fastlane setup_code_signing )
  end
end# xcode


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
end# bundle


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
end# pods


namespace :version do
  task :update do
    versions = File.read(CHANGELOG)
      .split(/^\s*##\s*\[\s*v([\d\.]+)\s*\].*$/)
      .slice(1..-1)
      .each_slice(2)
      .to_h
      .transform_values do |changes|
        changes.strip.lines
          .group_by {|line| line[/(\[\w{2}\])/, 1]}
          .map {|lang, lines|
            [
              lang[/\w+/],
              lines.map {|line| line.sub(lang, '')}.join
            ]
          }
          .to_h
      end

    filter_file PROJECT do |body|
      version           = versions.keys.first
      marketing_version = version.split('.')
        .map(&:to_i)
        .tap {|a| a.pop while a.size > 3}
        .join '.'
      replace = -> s, key, ver {s.gsub /#{key}:\s*[\d\.]+/, "#{key}: #{ver}"}

      body = replace.call body, 'CURRENT_PROJECT_VERSION', version
      body = replace.call body, 'MARKETING_VERSION',       marketing_version
    end

    versions.values.first.tap do |changes|
      changes.each do |lang, lines|
        path = Dir.glob("fastlane/metadata/#{lang}*/release_notes.txt").first
        filter_file(path) {lines}
      end
    end
  end
end


namespace :release do
  task :testflight do
    sh %( fastlane testflight )
  end

  namespace :match do
    task(:update) {sh %( fastlane match_update )}
    task(:fetch)  {sh %( fastlane match_fetch  )}
    task(:delete) {sh %( fastlane match_delete )}

    task :refresh => ['fastlane:match:delete', 'fastlane:match:update']

    task :fetch_new_devices do
      sh %( fastlane match development --force_for_new_devices )
    end
  end# match
end# fastlane

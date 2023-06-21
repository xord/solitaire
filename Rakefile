# -*- mode: ruby -*-


%w[../xot  .]
  .map  {|s| File.expand_path "#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'yaml'
require 'base64'
require 'xot/rake'

require 'xot/extension'
require 'rubysketch/solitaire/extension'


EXTENSIONS = [RubySketch::Solitaire]

GIT_URL = 'https://github.com/xord/solitaire'
GEMNAME = "rubysketch-#{target.name.downcase}"

PROJECT   = 'project.yml'
CHANGELOG = 'ChangeLog.md'

APP_NAME    = ENV['APP_NAME'] = "Ruby#{target.name}"
APP_ID      = ENV['APP_ID']   = "org.xord.#{APP_NAME}"
XCWORKSPACE = "#{APP_NAME}.xcworkspace"
XCODEPROJ   = "#{APP_NAME}.xcodeproj"
GINFO_PLIST = 'RubySolitaire/GoogleService-Info.plist'

BUNDLE_DIR = 'vendor/bundle'
PODS_DIR   = 'Pods'


def config(key)
  $config ||= YAML.load_file(File.expand_path 'config.yml', __dir__) rescue {}
  key = key.to_s.upcase
  ENV[key] or $config[key]
end

def versions()
  File.read(CHANGELOG)
    .split(/^\s*##\s*\[\s*v([\d\.]+)\s*\].*$/)
    .slice(1..-1)
    .each_slice(2)
    .to_h
    .transform_values do |changes|
      changes.strip.lines
        .group_by {|line| line[/^\W*(\[\w{2}\])/, 1]}
        .map {|lang, lines|
          [
            lang[/\w+/],
            lines.map {|line| line.sub(lang, '')}.join
          ]
        }
        .to_h
    end
end

def clone_tmp(url, dir_name, &block)
  Dir.chdir '/tmp' do
    sh %( rm -rf #{dir_name} )
    sh %( git clone #{url} #{dir_name} )
    chdir dir_name do
      block.call
    end
  end
end

def ci?()
  ENV['CI'] == 'true'
end


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

task :testflight do |t|
  clone_tmp GIT_URL, "#{APP_NAME}-#{t.name.split(':').last}" do
    puts Dir.pwd
    sh %( cp #{ENV['CONFIG_PATH'] or raise} . )
    sh %( rake release:testflight )
  end
end


namespace :xcode do
  xcodebuild = "xcodebuild -workspace #{XCWORKSPACE} -scheme #{APP_NAME}"

  task :clean do
    sh %( #{xcodebuild} clean ) if File.exist?(XCWORKSPACE)
  end

  task :clobber do
    sh %( rm -rf #{XCWORKSPACE} #{XCODEPROJ} #{GINFO_PLIST} )
  end

  task :build => XCWORKSPACE do
    sh %( #{xcodebuild} build )
  end

  task :open => XCWORKSPACE do
    sh %( open #{XCWORKSPACE} )
  end

  file XCWORKSPACE => [BUNDLE_DIR, PODS_DIR]

  file XCODEPROJ => 'scripts:setup' do
    plist = config(:ginfo_plist)&.then {|s| Base64.decode64 s}
    File.write GINFO_PLIST, plist if plist

    sh %( xcodegen generate )
    sh %( bundle exec fastlane setup_code_signing ) unless ci?
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


namespace :match do
  task :update do
    sh %( bundle exec fastlane match_update )
  end

  task :fetch do
    sh %( bundle exec fastlane match_fetch )
  end

  task :delete do
    sh %( bundle exec fastlane match_delete )
  end

  task :refresh => ['match:delete', 'match:update']

  task :fetch_new_devices do
    sh %( bundle exec fastlane match development --force_for_new_devices )
  end
end# match


namespace :release do
  task :testflight => 'release:setup' do
    ENV['MATCH_TYPE'] = 'AppStore'
    sh %( bundle exec fastlane setup_code_signing )

    ENV['CHANGELOG']  = versions.values.first['en']
    sh %( bundle exec fastlane release_testflight )
  end

  task :setup => ['xcode:clobber', :clobber, XCWORKSPACE] do
    replace = -> s, key, value {s.gsub /#{key}:\s*.+/, "#{key}: #{value}"}

    filter_file PROJECT do |body|
      body = replace.call(
        body,
        'GADApplicationIdentifier',
        config(:gad_app_id))
      body = replace.call(
        body,
        'GADGameScreenBottomBanner',
        config(:gad_game_screen_bottom_banner))
      body = replace.call(
        body,
        'GADGameScreenInterstitial',
        config(:gad_game_screen_interstitial))
    end
  end
end# release


namespace :scripts do
  task :setup => 'scripts:hooks:setup'

  namespace :hooks do
    hooks = Dir.glob('.hooks/*')
      .map {|path| [path, ".git/hooks/#{File.basename path}"]}
      .to_h

    task :setup => hooks.values

    hooks.each do |from, to|
      file to => from do
        sh %( cp #{from} #{to} )
      end
    end
  end
end# scripts

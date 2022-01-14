NAME      = 'RubySolitaire'
XCODEPROJ = "#{NAME}.xcodeproj"
PBXPROJ   = "#{XCODEPROJ}/project.pbxproj"

task :default => :build

task :build => :xcodeproj

task :xcode => :xcodeproj do
  sh %( open #{XCODEPROJ} )
end

task :xcodeproj => PBXPROJ

task :clean do
  sh %( rm -rf #{XCODEPROJ} )
end

file PBXPROJ do
  sh %( xcodegen generate )
end

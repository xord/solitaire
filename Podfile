# -*- mode: ruby -*-

platform :ios, '13.0'

%w[RubySolitaire RubySolitaireTests].each do |t|
  target t do
    pod 'CRuby',     git: 'https://github.com/xord/cruby.git', tag: 'v3.1.0'
    pod 'Reflexion', git: 'https://github.com/xord/reflexion.git'
  end
end


post_install do |installer|
  each_build_configuration installer do |c|
    c.build_settings['ARCHS']          = 'arm64'
    c.build_settings['VALID_ARCHS']    = 'arm64'
    c.build_settings['ENABLE_BITCODE'] = 'NO'
  end
end

def each_build_configuration (installer, &block)
  installer.pods_project.build_configurations.each do |config|
    block.call config
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      block.call config
    end
  end
end

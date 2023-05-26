# -*- mode: ruby -*-


Gem::Specification.new do |s|
  s.name        = 'rubysketch-solitaire'
  s.version     = '0.1.0'
  s.license     = 'MIT'
  s.summary     = 'Solitaire game made with RubySketch.'
  s.description = 'Solitaire game made with RubySketch.'
  s.authors     = %w[xordog]
  s.email       = 'xordog@gmail.com'
  s.homepage    = "https://github.com/xord/solitaire"

  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.0.0'

  s.add_runtime_dependency 'rubysketch', '~> 0.5.11'

  s.add_development_dependency 'rake'

  s.files = `git ls-files`.split $/
end

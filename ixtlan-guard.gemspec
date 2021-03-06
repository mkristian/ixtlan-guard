# -*- mode: ruby -*-
Gem::Specification.new do |s|
  s.name = 'ixtlan-guard'
  s.version = '0.9.0'

  s.summary = 'guard your controller actions'
  s.description = 'simple authorization framework for rails controllers'
  s.homepage = 'http://github.com/mkristian/ixtlan-guard'

  s.authors = ['mkristian']
  s.email = ['m.kristian@web.de']

  s.files = Dir['MIT-LICENSE']
  s.licenses << 'MIT-LICENSE'
#  s.files += Dir['History.txt']
  s.files += Dir['README.md']
  s.files += Dir['lib/**/*']
  s.files += Dir['spec/**/*']
  s.files += Dir['features/**/*rb']
  s.files += Dir['features/**/*feature']
  s.test_files += Dir['spec/**/*_spec.rb']
  s.test_files += Dir['features/*.feature']
  s.test_files += Dir['features/step_definitions/*.rb']
#  s.add_runtime_dependency 'ixtlan-core', '~>0.8.0'
  s.add_runtime_dependency 'virtus', '~>0.5'
  s.add_development_dependency 'railties', '~> 3.2.9'
  s.add_development_dependency 'rspec', '~> 2.7'
#  s.add_development_dependency 'cucumber', '0.9.4'
  s.add_development_dependency 'rake', '~> 10.0.3'
#  s.add_development_dependency 'ruby-maven', '3.0.4.0.29.0'
end

# vim: syntax=Ruby

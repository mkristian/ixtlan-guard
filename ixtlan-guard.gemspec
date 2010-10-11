Gem::Specification.new do |s|
  s.name = 'ixtlan-guard'
  s.version = '0.1.0'

  s.summary = 'guard your controller actions'
  s.description = 'simple authorization framework for rails controllers'
  s.homepage = 'http://github.com/mkristian/ixtlan-guard'

  s.authors = ['mkristian']
  s.email = ['m.kristian@web.de']

  s.files = Dir['MIT-LICENSE']
  s.licenses << 'MIT-LICENSE'
#  s.files += Dir['History.txt']
  s.files += Dir['README.textile']
#  s.extra_rdoc_files = ['History.txt','README.textile']
  s.rdoc_options = ['--main','README.textile']
  s.files += Dir['lib/**/*']
  s.files += Dir['spec/**/*']
  s.test_files += Dir['spec/**/*_spec.rb']
  s.add_development_dependency 'rails', '~> 3.0.0'
  s.add_development_dependency 'rspec', '~> 1.3.0'
  s.add_development_dependency 'rake', '0.8.7'
end

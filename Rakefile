# -*- mode: ruby -*-

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => [ :spec ]

task :headers do
  require 'rubygems'
  require 'copyright_header'

  s = Gem::Specification.load( Dir["*gemspec"].first )

  args = {
    :license => s.license, 
    :copyright_software => s.name,
    :copyright_software_description => s.description,
    :copyright_holders => s.authors,
    :copyright_years => [Time.now.year],
    :add_path => 'lib',
    :output_dir => './'
  }

  command_line = CopyrightHeader::CommandLine.new( args )
  command_line.execute
end
# vim: syntax=Ruby

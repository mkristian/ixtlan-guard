require 'fileutils'
Given /^I create new rails application with template "(.*)"$/ do |template|
  name = template.sub(/.template$/, '')
  directory = File.join('target', name)
  rails_version = '3.0.0'
  ruby = defined?(JRUBY_VERSION) ? "jruby" : "ruby"
  command = "-S rails _#{rails_version}_ new #{directory} -f -m templates/#{template}"
  FileUtils.rm_rf(directory)
  system "#{ruby} #{command}"
  
  @result = File.read("target/simple/out.txt")
  puts @result
end

Then /^the output should contain (\".*\")$/ do |expected|
  (@result =~ /.*#{expected}.*/).should be_nil
end


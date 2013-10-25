require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/*.rb'
  test.verbose = true
end
#require 'rake/testtask'
#
#Rake::TestTask.new do |t|
#  t.libs << 'test'
#end
#
#desc "Run tests"
#task :default => :test
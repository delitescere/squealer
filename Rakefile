# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

Rake::Task[:default].clear
task :default => [:spec]

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "squealer"
    gemspec.summary = "Document-oriented to Relational database exporter"
    gemspec.description = "Exports mongodb to mysql. More later."
    gemspec.email = "joshua.graham@grahamis.com"
    gemspec.homepage = "http://github.com/deltiscere/squealer/"
    gemspec.authors = ["Josh Graham", "Durran Jordan"]
    gem.add_dependency('mysql', '>= 2.8.1')
    gem.add_dependency('mongo', '>= 0.18.3')
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end


# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'

task :default => [:spec]
Rake::Task[:default].clear

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "squealer"
    gemspec.summary = "Document-oriented to Relational database exporter"
    gemspec.description = "Exports mongodb to mysql. More later."
    gemspec.email = "joshua.graham@grahamis.com"
    gemspec.homepage = "http://github.com/delitescere/squealer/"
    gemspec.authors = ["Josh Graham", "Durran Jordan"]
    gemspec.add_dependency('mysql', '>= 2.8.1')
    gemspec.add_dependency('mongo', '>= 0.18.3')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end


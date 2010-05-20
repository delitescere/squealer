# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "squealer"
    gemspec.summary = "Document-oriented to Relational database exporter"
    gemspec.description = "Exports mongodb to mysql. More later."
    gemspec.email = "joshua.graham@grahamis.com"
    gemspec.homepage = "http://github.com/delitescere/squealer/"
    gemspec.authors = ["Josh Graham", "Durran Jordan", "Matt Yoho", "Bernerd Schaefer"]

    gemspec.default_executable = "skewer"
    gemspec.executables = ["skewer"]

    gemspec.add_dependency('mysql', '>= 2.8.1')
    gemspec.add_dependency('mongo', '>= 0.18.3')
    gemspec.add_dependency('bson_ext', '>= 1.0.1')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

desc "Run all specs in spec directory (excluding plugin specs)"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*/*_spec.rb']
end

task :default => [:spec]

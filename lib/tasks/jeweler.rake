begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "squealer"
    gemspec.summary = "Document-oriented to Relational database exporter"
    gemspec.description = "Exports mongodb to mysql or postgresql. More later."
    gemspec.email = "joshua.graham@grahamis.com"
    gemspec.homepage = "http://github.com/delitescere/squealer/"
    gemspec.authors = ["Josh Graham", "Durran Jordan"]
    gem.add_dependency('mysql', '>= 2.8.1')
    gem.add_dependency('mongo', '>= 0.18.3')
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
